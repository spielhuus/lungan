
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
---@param opts table An optional table containing configuration options.
---@return Openvino A new instance of Openvino with the specified options.
function Openvino:new(opts)
	-- local o = {}
	setmetatable(self, { __index = require("lungan.providers.Provider") })
	self.__name = "ollama"
	local in_opts = opts or {}
	local options = defaults
	for k, v in pairs(in_opts) do
		options[k] = v
	end
	self.options = options
  self.id = math.random(1, 100000)
	return self
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
      exit(content)
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

-- function Openvino:embeddings(request, stdout, stderr, exit)
  -- TODO
	-- local parsed_request = {
	-- 	url = self.options.url .. "/api/embeddings",
	-- 	body = json.encode(request),
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
	--
	-- local status, err = self.http:post(parsed_request, on_exit, function(_, data, _)
	-- 	if data then -- TODO this should return a lua table
	-- 		if type(data) == "string" then
	-- 			stdout({ data })
	-- 		else
	-- 			local clean_table = str.clean_table(data)
	-- 			if #clean_table > 0 then
	-- 				stdout(clean_table)
	-- 			end
	-- 		end
	-- 	end
	-- end, function(_, data, _)
	-- 	if stderr then
	-- 		stderr(data)
	-- 	end
	-- end)
	-- return status, err
-- end

return Openvino
