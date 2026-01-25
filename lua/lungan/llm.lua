local log = require("lungan.log")
local str = require("lungan.str")
local textwrap = require("lungan.textwrap")

---@class LLM
---@field options table the llm options
local LLM = {}

--- Represents an instance of a large language model.
---@param opts table A table containing configuration options for the LLM.
---@return LLM A new instance of the LLM with the specified options.
function LLM:new(opts)
	local o = {}
	setmetatable(o, { __index = self, __name = "LLM" })
	o.options = opts
	return o
end

---Stops a language model provider session.
---@param session Chat The session object
function LLM:stop(session)
	if self.options.providers[session.data:frontmatter().provider.name] then
		self.options.providers[session.data:frontmatter().provider.name]:stop()
	end
end

function LLM:context_size(session)
	log.info("context_size:" .. vim.inspect(session))
end

function LLM:models(session, callback)
	self.options.providers[session.data:frontmatter().provider.name]:models(callback)
end

function LLM:chat(chat)
	local provider = chat.data:frontmatter().provider
	local role = "" -- Tracks the current open block in the buffer
	local wrap =
		textwrap:new(nil, self.options, chat, chat.data:frontmatter().textwrap, chat.data:frontmatter().hide_think)

	local prompt = vim.fn.deepcopy(chat:get())

	-- get the last user message
	local max_tokens = (
		chat.data:frontmatter().options.num_ctx and (chat.data:frontmatter().options.num_ctx * 0.9) or (1024 * 0.9)
	)
	local token_length = 4
	local current_token_count = 0
	local system_message = nil
	local messages = {}
	if #prompt.messages > 0 and prompt.messages[1].role == "system" then
		local sys_msg = prompt.messages[1]
		local sys_tokens = (#sys_msg.role + #sys_msg.content) / token_length + 3
		if sys_tokens < max_tokens then
			system_message = sys_msg
			current_token_count = sys_tokens
		else
			log.warn("Warning: System message is larger than the entire context limit.")
		end
	end
	local start_index = #prompt.messages
	local end_index = (system_message and 2 or 1)
	for i = start_index, end_index, -1 do
		local line = prompt.messages[i]

		-- Handle nil content safely (e.g. for tool calls)
		local content_len = 0
		if line.content then
			content_len = #line.content
		elseif line.tool_calls then
			-- Rough estimate for tool calls if content is nil
			content_len = 100
		end

		local message_tokens = (content_len + #line.role) / token_length + 3

		if current_token_count + message_tokens >= max_tokens then
			log.info("truncate the context, length: " .. current_token_count + message_tokens)
			break
		end

		current_token_count = current_token_count + message_tokens

		-- Insert the full line object to preserve tool_calls and tool_call_id
		table.insert(messages, 1, line)
	end

	if system_message then
		table.insert(messages, 1, { role = system_message.role, content = system_message.content })
	end

	prompt.messages = messages
	log.debug("context length: " .. current_token_count)

	if chat:get()["system_context"] then
		local system_context = chat:get()["system_context"]
		local func, err = load(system_context)
		if not func then
			error(err)
		end
		local res = func()(messages[#messages].content)
		local sres = table.concat(res[1], "\n")
		prompt.system_prompt =
			table.concat(require("lungan.utils").TemplateVars({ system_context = sres }, prompt.system_prompt), "\n")
	end

	if chat:get()["mcp"] then
		prompt.functions = chat.prompt["tools"]
	end

	-- Accumulator for tool calls within this request
	local current_tool_calls = {}

	self.JobId = self.options.providers[provider.name]:chat(prompt, function(data)
		if data["error"] then
			log.error(data["error"], vim.log.levels.ERROR, { title = provider.name .. " Error" })
		elseif data["message"] then
			local msg = data["message"]

			local content_type = nil -- "thought" | "assistant"
			local text_to_write = nil

			-- Check for Reasoning
			if msg["reasoning_content"] and #msg["reasoning_content"] > 0 then
				content_type = "thought"
				text_to_write = msg["reasoning_content"]

			-- Check for Tool Calls
			elseif msg["tool_calls"] or msg["tools_call"] then
				local tcs = msg["tool_calls"] or msg["tools_call"]
				for _, delta in ipairs(tcs) do
					local idx = (delta.index or 0) + 1
					if not current_tool_calls[idx] then
						current_tool_calls[idx] = {
							index = delta.index or 0,
							id = delta.id or "",
							type = "function",
							["function"] = { name = "", arguments = "" },
						}
					end
					if delta.id then
						current_tool_calls[idx].id = delta.id
					end
					if delta["function"] then
						if delta["function"].name then
							current_tool_calls[idx]["function"].name = current_tool_calls[idx]["function"].name
								.. delta["function"].name
						end
						if delta["function"].arguments then
							current_tool_calls[idx]["function"].arguments = current_tool_calls[idx]["function"].arguments
								.. delta["function"].arguments
						end
					end
				end
				content_type = "assistant"
				chat:call_tools(data)

			-- Check for Standard Content
			elseif msg["content"] then
				if type(msg["content"]) == "string" and #msg["content"] > 0 then
					content_type = "assistant"
					text_to_write = msg["content"]
				elseif type(msg["content"]) == "table" then
					content_type = "assistant"
					text_to_write = table.concat(msg["content"], "")
				end
			end

			-- Handle Role Switching
			if content_type then
				if content_type ~= role then
					-- Close previous block if it exists
					if role ~= "" then
						wrap:push({ "\n==>\n" })
					end

					-- Open new block
					wrap:push({ "\n\n", "<== " .. content_type, "\n" })
					role = content_type
				end

				-- Write the content (ONLY if it's text, not tool accumulators)
				if text_to_write then
					wrap:push({ text_to_write })
				end
			end

			-- Handle Tool Execution Logic (End of Stream)
			if data["finish_reason"] == "tool_calls" then
				-- Write the accumulated tool calls as a valid JSON array to the buffer
				if next(current_tool_calls) ~= nil then
					if role ~= "assistant" then
						wrap:push({ "\n\n", "<== assistant", "\n" })
						role = "assistant"
					end

					local tool_list = {}
					for _, tc in pairs(current_tool_calls) do
						table.insert(tool_list, tc)
					end

					local success, json_str = pcall(vim.json.encode, tool_list)
					if success then
						wrap:push({ json_str })
					else
						log.error("Failed to encode tool calls for buffer")
					end

					wrap:push({ "\n==>\n" })
					role = ""
				end

				chat:call_tools(data)
			end

			if data["done"] then
				if role ~= "" then
					wrap:push({ "\n", "==>", "\n" })
				end
				wrap:flush()

				if chat.data:frontmatter()["preview"] then
					chat:refresh()
					local func, err = load(chat.data:frontmatter()["preview"])
					if not func then
						error(err)
					end
					func()(self.options, chat.args, chat.data)
				end

				if chat.data:frontmatter()["process"] and msg["content"] then
					local token = msg["content"]
					local func, err = load(chat.data:frontmatter()["process"])
					if not func then
						error(err)
					end
					if type(token) == "table" then
						func()(self.options, chat.args, table.concat(token, ""))
					else
						func()(self.options, chat.args, token)
					end
				end
			end
		else
			-- Ignored purely empty messages
			if not (data["finish_reason"] == "tool_calls" or data["finish_reason"] == "stop") then
				log.warn("Unknown response: " .. vim.inspect(data))
			end
		end
	end, function(_, data, _)
		if data then
			log.info("LLM:END: " .. str.to_string(data))
		end
	end)
end

return LLM
