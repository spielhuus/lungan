local json = require("lungan.json")
local str = require("lungan.str")
local log = require("lungan.log")

local dispatchers = {}

---@class Openvino: Provider
---@field options table
---@field http Http
local Openvino = {}
Openvino.__index = Openvino

local defaults = {
	name = "Openvino",
	model = "llama3.1",
	url = os.getenv('HOME') .. "/.models/OpenVINO/",
}

---Creates a new instance of the Openvino object.
---@param http table The Http implementation to use
---@param opts table An optional table containing configuration options.
---@return Openvino A new instance of Openvino with the specified options.
function Openvino:new(http, opts)
	-- local o = {}
	setmetatable(self, { __index = require("lungan.providers.Provider") })
	self.__name = "ollama"
	local in_opts = opts or {}
	local options = defaults
	for k, v in pairs(in_opts) do
		options[k] = v
	end
	self.options = options
	self.http = http -- TODO remove
  self.id = math.random(1, 100000)
	return self
end

function Openvino:__parse_prompt(prompt)
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

function Openvino:__parse_gen_prompt(prompt)
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
function Openvino:stop()
  vim.fn.OpenvinoStop()
end

function Openvino:models(callback)
  local folders = vim.fn.readdir(self.options.url)
  local models = {}
  for _, folder in ipairs(folders) do
			table.insert(models, {
				description = folder,
				model = folder,
				name = folder,
			})
  end
  if callback ~= nil then
    callback(1, models)
  end
end

function Openvino:chat(prompt, stdout, stderr, exit)
  prompt['provider']['path'] = self.options.url
  _G.vino_callbacks[self.id] = {
    on_exit = function(content)
      print(vim.inspect(content))
    end,
    on_stdout = function(content)
		  stdout(content)
    end,
    on_stderr = function(content)
      print(vim.inspect(content))
		  stderr(content)
    end
  }
  vim.fn.OpenvinoChat(vim.api.nvim_get_current_buf(), self.id, prompt)
end

function Openvino:generate(prompt, stdout, stderr, exit)
  print(vim.inspect(prompt))
	-- local request = {
	-- 	url = self.options.url .. "/api/generate",
	-- 	body = json.encode(self:__parse_gen_prompt(prompt)),
	-- }
	--
	-- local on_exit
	-- if exit ~= nil then
	-- 	on_exit = function(_, b)
	-- 		if b ~= 0 then
	-- 			exit(b)
	-- 		end
	-- 	end
	-- end
	-- local status, err = self.http:post(request, on_exit, function(_, data, _)
	-- 	if data then
	-- 		local clean_table = str.clean_table(data)
	-- 		if #clean_table > 0 then
	-- 			stdout(json.decode(table.concat(data, "")))
	-- 		end
	-- 	end
	-- end, function(_, data, _)
	-- 	if stderr then
	-- 		stderr(data)
	-- 	end
	-- end)
	-- return status, err
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
function Openvino:embeddings(request, stdout, stderr, exit)
  -- TODO
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

return Openvino
