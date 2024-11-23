local log = require("log")
local str = require("lungan.str")
local textwrap = require("lungan.textwrap")

local LLM = {}

function LLM:new(opts)
	local o = {}
	setmetatable(o, { __index = self, __name = "LLM" })
	o.options = opts
	return o
end

function LLM:stop()
	print("STOP" .. vim.inspect(self.JobId))
	if self.JobId ~= nil then
		self.JobId:stop()
		self.JobId = nil
	end
end

function LLM:models(session, callback)
	self.options.providers[session.data:frontmatter().provider.name]:models(callback)
end

function LLM:chat(chat)
	local buffer = chat.args.buffer
	local provider = chat.data:frontmatter().provider
	local role = ""
	local wrap = textwrap:new(nil, self.options, chat)
	self.JobId = self.options.providers[provider.name]:chat(self.options, chat:get(), function(data)
		if data["error"] then
			vim.notify(data["error"], vim.log.levels.ERROR, { title = provider.name .. " Error" })
		elseif data["message"] then
			local token_role = data["message"]["role"]
			if token_role ~= role then
				wrap:push({ "\n\n", "<== " .. token_role, "\n" })
				role = token_role
			end
			if data["message"]["content"] then
				local token = data["message"]["content"]
				-- draw the text
				if type(token) == "table" then
					wrap:push(token)
				else
					wrap:push({ token })
				end
				-- call the process function if available
				-- if session.data:frontmatter()["process"] then
				--     local func, err = load(session.data:frontmatter()["process"])
				--     if not func then
				--         error(err)
				--     end
				--     if type(token) == "table" then
				--         func()(self.options, session, table.concat(token, ""))
				--     else
				--         func()(self.options, session, token)
				--     end
				-- end
			else
				log.warn("unknown message format: " .. vim.inspect(data))
			end
			if data["done"] then
				wrap:push({ "\n", "==>", "\n" })
				wrap:flush()

				-- if session.data:frontmatter()["preview"] then
				--     -- refresh the data
				--     local res, new_data = pcall(require("workbench.parser").parse, M.options, buffer)
				--     if res then
				--         session.data = new_data
				--     else
				--         print("Error:" .. new_data)
				--     end
				--     -- call preview function
				--     local func, err = load(session["data"][1]["content"]["preview"])
				--     if not func then
				--         error(err)
				--     end
				--     func()(opts, session)
				-- end
			end
		else
			log.warn("Unknown response: " .. vim.inspect(data))
		end
	end, function(_, data, _)
		print("ERR: " .. str.to_string(data))
	end, function(_, data, _)
		print("END: " .. str.to_string(data))
	end)
end

return LLM
