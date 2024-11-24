local log = require("log")
local str = require("lungan.str")

local json
if vim ~= nil then
	json = vim.json
else
	json = require("rapidjson")
end

local Ollama = {}

local defaults = {
	name = "Ollama",
	model = "llama3.1",
	url = "http://127.0.0.1:11434",
}

---Creates a new instance of the Ollama object.
---@class Ollama
---@param o table The Http implementation to use
---@param opts table An optional table containing configuration options.
---@return Ollama A new instance of Ollama with the specified options.
function Ollama:new(o, opts)
	local instance = setmetatable(self, { __index = o })
	instance.__index = Ollama
	instance.__name = "ollama"
	local in_opts = opts or {}
	local options = defaults
	for k, v in pairs(in_opts) do
		defaults[k] = v
	end
	instance.options = options
	return instance
end

function Ollama:__parse_prompt(_, prompt)
	local output = {
		model = prompt.provider.model,
		messages = { { role = "system", content = prompt.system_prompt } },
		options = prompt.options,
		stream = prompt.stream,
	}
	for _, line in ipairs(prompt.messages) do
		table.insert(output.messages, { role = line.role, content = line.content })
	end
	return output
end

function Ollama:models(callback)
	local status, response = self:get(self.options.url .. "/api/tags")
	assert(callback ~= nil)
	if response then
		callback(status, json.decode(response).models)
	end
end

function Ollama:chat(opts, prompt, stdout, stderr, exit)
	local request = {
		url = self.options.url .. "/api/chat",
		body = json.encode(self:__parse_prompt(opts, prompt)),
	}

	local on_exit
	if exit ~= nil then
		on_exit = function(_, b)
			if b ~= 0 then
				log.trace("Exit: " .. b)
				if exit then
					exit(b)
				end
			end
		end
	end

	local status, _ = self:post(request, on_exit, function(_, data, _)
		if data then
			local clean_table = str.clean_table(data)
			if #clean_table > 0 then
				stdout(json.decode(table.concat(data, "")))
			end
		end
	end, function(_, data, _)
		if stderr then
			stderr(data)
		end
	end)
	-- return client
end

-- local complete = function(opts, session, stdout, stderr, exit)
-- 	local job_id = http.post(
-- 		opts.providers[opts.provider].host, -- TODO get the provider frmo the session
-- 		opts.providers[opts.provider].port,
-- 		"/api/generate",
-- 		{
-- 			model = session.model,
-- 			prompt = session.prompt,
-- 			stream = false,
-- 		},
-- 		-- parse_prompt(opts, session),
-- 		function(_, data, _)
-- 			stdout(vim.json.decode(data))
-- 		end,
-- 		function(_, data, _)
-- 			log.error("<<< ", vim.inspect(data))
-- 			if stderr then
-- 				stderr(data)
-- 			end
-- 		end,
-- 		function(_, b)
-- 			if b ~= 0 then
-- 				log.trace("Exit: " .. b)
-- 				if exit then
-- 					exit(b)
-- 				end
-- 			end
-- 		end
-- 	)
-- 	return job_id
-- end

--- get embeddings
--- example request
--- {
---   "model": "nomic-embed-text",
---   "prompt": "The sky is blue because of Rayleigh scattering"
--- }'

function Ollama:embeddings(opts, request, stdout, stderr, exit)
	local request = {
		url = self.options.url .. "/api/embeddings",
		body = json.encode(request),
	}

	local on_exit
	if exit ~= nil then
		on_exit = function(_, b)
			if b ~= 0 then
				log.trace("Exit: " .. b)
				if exit then
					exit(b)
				end
			end
		end
	end

	local status, _ = self:post(request, on_exit, function(_, data, _)
		log.trace(str.to_string(data))
		if data then
			local clean_table = str.clean_table(data)
			if #clean_table > 0 then
				stdout(json.decode(table.concat(data, "")))
			end
		end
	end, function(_, data, _)
		log.error("<<< ", str.to_string(data))
		if stderr then
			stderr(data)
		end
	end)
	-- return client
end

return Ollama
