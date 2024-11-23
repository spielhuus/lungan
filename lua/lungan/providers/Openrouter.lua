local log = require("log")

local OPENROUTER_API_TOKEN = os.getenv("OPENROUTER_API_TOKEN") or ""

local Openrouter = {}

local defaults = {
	name = "Openrouter",
	url = "https://openrouter.ai",
}

function Openrouter:new(o, opts)
	local instance = setmetatable(self, { __index = o })
	instance.__index = Openrouter
	instance.__name = "openrouter"
	local in_opts = opts or {}
	local options = defaults
	for k, v in pairs(in_opts) do
		defaults[k] = v
	end
	instance.options = options
	return instance
end

function Openrouter:__parse_prompt(_, prompt)
	log.trace("Prompt: " .. vim.inspect(prompt))
	local output = {
		model = prompt.provider.model,
		messages = { { role = "system", content = prompt.system_prompt } },
		stream = prompt.stream,
	}

	for key, val in pairs(prompt.options) do
		output[key] = val
	end

	for _, line in ipairs(prompt.messages) do
		table.insert(output.messages, { role = line.role, content = line.content })
	end
	return output
end

function Openrouter:__parse_response(data)
	local finish = false
	if data["choices"][1]["finish_reason"] == "stop" then
		finish = true
	end
	if data["object"] == "chat.completion.chunk" then
		local output = {
			done = finish,
			message = {
				content = data["choices"][1]["delta"]["content"],
				role = data["choices"][1]["delta"]["role"],
			},
		}
		return output
	else
		local output = {
			done = finish,
			message = data["choices"][1]["message"],
		}
		return output
	end
end

function Openrouter:models(callback)
	local status, response = self:get(self.options.url .. "/api/v1/models")
	if status ~= 0 then
		print("ERROR in get")
		vim.notify("Error: " .. vim.inspect(status) .. "\n" .. vim.inspect(response), vim.log.levels.ERROR)
		return nil -- TODO return error
	else
		if #response > 0 then
			local t_result = vim.json.decode(response)
			local result = {}
			for _, model in ipairs(t_result.data) do
				table.insert(result, {
					description = model.description,
					model = model.id,
					name = model.name,
					context_length = model.context_length,
					pricing = model.pricing,
				})
			end
			callback(status, result)
		end
	end
end

function Openrouter:chat(opts, session, stdout, stderr, exit)
	local request = {
		url = self.options.url .. "/api/v1/chat/completions",
		headers = {
			' -H "Authorization: Bearer ' .. OPENROUTER_API_TOKEN .. '"',
			' -H "Content-Type: application/json"',
		},
		body = vim.fn.shellescape(vim.json.encode(self:__parse_prompt(opts, session))),
	}
	local status, _ = self:post(request, function(_, b)
		if b ~= 0 then
			log.trace("Exit: " .. b)
			if exit then
				exit(b)
			end
		end
	end, function(_, data, _)
		if data then
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
						log.warn("make table")
						message = string.sub(message, de + 1)
					end

					if #message > 0 then
						log.trace("RESPONSE:'" .. vim.inspect(message) .. "'")
						stdout(self:__parse_response(vim.json.decode(message)))
					end
				end
				::next::
			end
		end
	end, function(_, data, _)
		log.error("<<< ", vim.inspect(data))
		if stderr then
			stderr(data)
		end
	end)
	-- return client
end

-- local complete = function(opts, session, stdout, stderr, exit)
--     local job_id = http.post(
--         opts.providrs[opts.provider].host, -- TODO get the provider frmo the session
--         opts.providers[opts.provider].port,
--         "/api/generate",
--         {
--             model = session.model,
--             prompt = session.prompt,
--             stream = false,
--         },
--         -- __parse_prompt(opts, session),
--         function(_, data, _)
--             stdout(vim.json.decode(data))
--         end,
--         function(_, data, _)
--             log.error("<<< ", vim.inspect(data))
--             if stderr then
--                 stderr(data)
--             end
--         end,
--         function(_, b)
--             if b ~= 0 then
--                 log.trace("Exit: " .. b)
--                 if exit then
--                     exit(b)
--                 end
--             end
--         end
--     )
--     return job_id
-- end

return Openrouter
