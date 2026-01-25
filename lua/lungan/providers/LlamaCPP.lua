local log = require("lungan.log")

---@class LlamaCPP
---@field options table
---@field http Http
local LlamaCPP = {}

local defaults = {
	name = "LlamaCPP",
	url = "http://127.0.0.1:8080",
}

---Creates a new instance of the Ollama object.
---@param http table The Http implementation to use
---@param opts table An optional table containing configuration options.
---@return LlamaCPP A new instance of LlamaCPP with the specified options.
function LlamaCPP:new(http, opts)
	local o = {}
	setmetatable(o, { __index = self })
	o.__name = "llamacpp"
	local in_opts = opts or {}
	local options = defaults
	for k, v in pairs(in_opts) do
		defaults[k] = v
	end
	o.options = options
	o.http = http
	o.message_role = nil
	return o
end

function LlamaCPP:__parse_prompt(prompt)
	local output = {
		model = prompt.provider.model,
		stream = prompt.stream or false,
		messages = {},
	}

	if prompt.functions then
		local tools = {}
		for _, tool in pairs(prompt.functions.result.tools) do
			local fun = {}
			fun.name = tool.name
			fun.description = (tool.description or "")
			fun.type = tool.type

			local properties = {}
			for name, prop in pairs(tool.inputSchema.properties) do
				local arg = {}
				arg.type = prop.type
				arg.description = (prop.description or "")
				properties[name] = arg
			end
			fun.parameters = {}
			fun.parameters.type = tool.inputSchema.type
			fun.parameters.properties = properties
			fun.parameters.required = tool.inputSchema.required

			local entry = {}
			entry["type"] = "function"
			entry["function"] = fun
			table.insert(tools, entry)
		end
		output.tools = tools
	end

	if prompt.system_prompt and prompt.system_prompt ~= "" then
		table.insert(output.messages, { role = "system", content = prompt.system_prompt })
	end

	for _, message in ipairs(prompt.messages) do
		local msg = {
			role = message.role,
			content = message.content,
		}
		if message.tool_calls then
			msg.tool_calls = message.tool_calls
		end
		if message.tool_call_id then
			msg.tool_call_id = message.tool_call_id
		end
		table.insert(output.messages, msg)
	end

	if prompt.options then
		-- Direct mapping for compatible parameters
		output.temperature = prompt.options.temperature
		output.top_p = prompt.options.top_p
		output.repeat_penalty = prompt.options.repeat_penalty
		output.min_p = prompt.options.min_p

		-- Note on 'num_ctx': This parameter is generally set when the server starts,
		-- not per-request on the OpenAI-compatible chat endpoint.
		-- The equivalent per-request parameter to limit output length is 'max_tokens'.
		-- If you want to control the context size for this specific request,
		-- you might be looking for `n_ctx`, but it's not part of the standard chat API.
		-- You should add `max_tokens` to your options if you need to control response length.
		-- For example: output.max_tokens = prompt.options.max_tokens
	end

	return output
end

function LlamaCPP:__parse_response(data)
	-- Helper function to check for both standard nil and Neovim's vim.NIL
	local function is_nil(value)
		return value == nil or value == vim.NIL
	end

	-- Handle a STREAMING response chunk
	if data.object == "chat.completion.chunk" then
		assert(data.choices and #data.choices <= 1)
		local choice = data.choices and data.choices[1]
		-- The stream is 'done' only if the finish_reason is NOT nil or vim.NIL.
		local done = not is_nil(choice.finish_reason)
		-- The 'delta' table contains the new piece of information for this chunk.
		-- We now explicitly check for vim.NIL before assigning content.
		if not is_nil(choice.delta.role) then
			self.message_role = choice.delta.role
		end
		assert(self.message_role)

		local message

		-- Tool Calls
		if choice.delta.tool_calls then
			message = {
				role = self.message_role,
				tools_call = choice.delta.tool_calls,
			}

		-- Reasoning
		elseif choice.delta.reasoning_content then
			message = {
				role = self.message_role,
				resoning_content = choice.delta.reasoning_content,
			}

		-- Standard Content (Must check explicitly against vim.NIL)
		elseif choice.delta.content and choice.delta.content ~= vim.NIL then
			message = {
				role = self.message_role,
				content = choice.delta.content,
			}

		-- Empty Delta (Common when finish_reason is set)
		-- If delta is empty or content is NIL, return empty string.
		-- LLM.lua ignores empty strings, so nothing prints to buffer.
		else
			message = {
				role = self.message_role,
				content = "",
			}
		end

		return { done = done, finish_reason = choice.finish_reason, message = message }

	-- Handle a COMPLETE, NON-STREAMING response
	elseif data.object == "chat.completion" then
		return {
			done = true,
			-- TODO finsih reason
			message = data.choices[1].message,
		}
	end

	return {
		done = true,
		message = { content = "[Error: Unknown response format]" },
	}
end

---Stop a running request
function LlamaCPP:stop()
	self.http:cancel()
end

-- Fetches a list of models from the LlamaCPP API.
-- @param self (LlamaCPP) The LlamaCPP instance on which this method is called.
-- @param callback (function) A function that will be called with two arguments:
--                           1. `status` (number): The HTTP status code of the response.
--                           2. `result` (table): A table containing details about each model, including:
--                              - `description` (string): The description of the model.
--                              - `model` (string): The ID of the model.
--                              - `name` (string): The name of the model.
--                              - `context_length` (number): The context length of the model.
--                              - `pricing` (table): Pricing information for the model.
--
-- @return nil
function LlamaCPP:models(callback)
	local status, response = self.http:get(self.options.url .. "/models")
	assert(callback ~= nil)
	if response then
		local t_result = vim.json.decode(response)
		local result = {}
		for _, model in ipairs(t_result.data) do
			table.insert(result, {
				description = model.id,
				model = model.id,
				name = model.id,
				context_length = model["status"]["args"]["--context_size"], --TODO parse args
				pricing = model.pricing,
			})
		end
		log.debug("Models:" .. vim.inspect(result))
		callback(0, result)
	end
end

--- Sends a chat request to the LlamaCPP API
--- @param self table The LlamaCPP instance.
--- @param session Chat The session object containing the chat context.
--- @param stdout function Function to handle standard output messages.
--- @param stderr function  Function to handle error messages.
--- @param exit function Function to handle process exit status.
function LlamaCPP:chat(session, stdout, stderr, exit)
	local request = {
		url = self.options.url .. "/v1/chat/completions",
		body = vim.json.encode(self:__parse_prompt(session)),
	}
	local status, err = self.http:post(request, function(_, b)
		if b ~= 0 then
			log.trace("Exit: " .. b)
			if exit then
				exit(b)
			end
		end
	end, function(_, data, _)
		if data then
			log.trace(">>>", data)
			for _, message in ipairs(data) do
				if #message > 0 then
					if message == ": OPENROUTER PROCESSING" then
						goto next
					end
					if message == "data: [DONE]" then
						goto next
					end
					local ds, de = message:find("^data: ")
					if ds then
						-- log.info("make table: " .. message)
						message = string.sub(message, de + 1)
					end

					local mes = vim.json.decode(message)
					log.debug(vim.inspect(mes))
					if mes["error"] then
						log.error("LlamaCPP Error: " .. vim.inspect(mes["error"]))
					else
						stdout(self:__parse_response(mes))
					end
				end
				::next::
			end
		end
	end, function(_, data, _)
		if stderr then
			stderr(data)
		end
	end)
	return status, err
end

return LlamaCPP
