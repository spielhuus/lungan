local json = require("lungan.json")
local str = require("lungan.str")

---@class Ollama
---@field options table
---@field http Http
local Ollama = {}

local defaults = {
	name = "Ollama",
	model = "llama3.1",
	url = "http://127.0.0.1:11434",
}

---Creates a new instance of the Ollama object.
---@param http table The Http implementation to use
---@param opts table An optional table containing configuration options.
---@return Ollama A new instance of Ollama with the specified options.
function Ollama:new(http, opts)
	local o = {}
	setmetatable(o, { __index = self })
	o.__name = "ollama"
	local in_opts = opts or {}
	local options = defaults
	for k, v in pairs(in_opts) do
		options[k] = v
	end
	o.options = options
	o.http = http
	return o
end

function Ollama:__parse_prompt(prompt)
	local output = {
		model = prompt.provider.model,
		messages = { { role = "system", content = prompt.system_prompt } },
		options = prompt.options,
		stream = prompt.stream,
		tools = prompt.tools,
		images = prompt.images,
	}
	for _, line in ipairs(prompt.messages) do
		table.insert(output.messages, { role = line.role, content = line.content })
	end
	return output
end

function Ollama:__parse_gen_prompt(prompt)
	local output = {
		model = prompt.provider.model,
		prompt = prompt.prompt,
		options = prompt.options,
		stream = prompt.stream,
		tools = prompt.tools,
		images = prompt.images,
	}
	return output
end

---Stop a running request
function Ollama:stop()
	self.http:cancel()
end

function Ollama:models(callback)
	local status, response = self.http:get(self.options.url .. "/api/tags")
	assert(callback ~= nil)
	if response then
		callback(status, json.decode(response).models)
	end
end

function Ollama:chat(prompt, stdout, stderr, exit)
	local request = {
		url = self.options.url .. "/api/chat",
		body = json.encode(self:__parse_prompt(prompt)),
	}

	local on_exit
	if exit ~= nil then
		on_exit = function(_, b)
			if b ~= 0 then
				exit(b)
			end
		end
	end
	local status, err = self.http:post(request, on_exit, function(_, data, _)
		if data then
			if type(data) == "string" then
				stdout(json.decode(data))
			else
				local clean_table = str.clean_table(data)
				if #clean_table > 0 then
					stdout(json.decode(table.concat(data, "")))
				end
			end
		end
	end, function(_, data, _)
		if stderr then
			stderr(data)
		end
	end)
	return status, err
end

function Ollama:generate(prompt, stdout, stderr, exit)
	local request = {
		url = self.options.url .. "/api/generate",
		body = json.encode(self:__parse_gen_prompt(prompt)),
	}

	local on_exit
	if exit ~= nil then
		on_exit = function(_, b)
			if b ~= 0 then
				exit(b)
			end
		end
	end
	local status, err = self.http:post(request, on_exit, function(_, data, _)
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
	return status, err
end

---Creates embeddings for a given prompt using the specified model.
---example request
---{
---  "model": "nomic-embed-text",
---  "prompt": "The sky is blue because of Rayleigh scattering"
---}'
---@param request table The request to be sent, containing:
---  - model: The name of the model to use for generating embeddings.
---  - prompt: The input text for which embeddings are to be generated.
---@param stdout fun(data: table) A callback function to handle standard output data.
---@param stderr fun(data: table) A callback function to handle standard error data.
---@param exit fun(code: number)|nil A callback function to handle the exit status code.
---@return integer return code
---@return string error message
function Ollama:embeddings(request, stdout, stderr, exit)
	local parsed_request = {
		url = self.options.url .. "/api/embeddings",
		body = json.encode(request),
	}

	local on_exit
	if exit ~= nil then
		on_exit = function(_, b)
			if b ~= 0 then
				exit(b)
			end
		end
	end

	local status, err = self.http:post(parsed_request, on_exit, function(_, data, _)
		if data then -- TODO this should return a lua table
			if type(data) == "string" then
				stdout({ data })
			else
				local clean_table = str.clean_table(data)
				if #clean_table > 0 then
					stdout(clean_table)
				end
			end
		end
	end, function(_, data, _)
		if stderr then
			stderr(data)
		end
	end)
	return status, err
end

return Ollama
