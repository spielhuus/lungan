local log = require("lungan.log")

local AISTUDIO_API_TOKEN = os.getenv("AISTUDIO_API_TOKEN") or ""

---@class AiStudio
---@field options table
---@field http Http
local AiStudio = {}

local defaults = {
	name = "AiStudio",
	url = "https://generativelanguage.googleapis.com/v1beta",
}

---Creates a new instance of the AiStudio object.
---@param http table The Http implementation to use
---@param opts table An optional table containing configuration options.
---@return AiStudio A new instance of AiStudio with the specified options.
function AiStudio:new(http, opts)
	local o = {}
	setmetatable(o, { __index = self })
	o.__name = "aistudio"
	local in_opts = opts or {}
	local options = defaults
	for k, v in pairs(in_opts) do
		defaults[k] = v
	end
	o.options = options
	o.http = http
	o.content = {}
	return o
end

function AiStudio:__parse_prompt(prompt)
	local output = {
		system_instruction = { parts = { text = prompt.system_prompt } },
		contents = {},
	}

	-- if prompt.options then
	-- 	for key, val in pairs(prompt.options) do
	-- 		output[key] = val
	-- 	end
	-- end

	for _, line in ipairs(prompt.messages) do
		local role
		if line.role == "user" then
			role = "user"
		elseif line.role == "assistant" then
			role = "model"
		else
			error("unknown role: " .. line.role)
		end
		table.insert(output.contents, { role = role, parts = { { text = line.content } } })
	end
	log.trace("Prompt: ", output)
	return output
end

function AiStudio:__parse_response(data)
	assert(#data["candidates"] == 1, "AiStudion returned more then one candidate")
	local finish = false
	if data["candidates"][1]["finishReason"] == "STOP" then
		finish = true
	end

	local role = data["candidates"][1]["content"]["role"]
	if role == "model" then
		role = "assistant"
	end

	local message = ""
	assert(#data["candidates"][1]["content"]["parts"] == 1, "Aistudio response has more then one part")
	for _, part in ipairs(data["candidates"][1]["content"]["parts"]) do
		message = part.text
	end

	local output = {
		done = finish,
		message = {
			content = message,
			role = role,
		},
	}
	log.debug("Response", output)
	return output
end

---Stop a running request
function AiStudio:stop()
	self.http:cancel()
end

-- Fetches a list of models from the AiStudio API.
-- @param self (AiStudio) The AiStudio instance on which this method is called.
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
function AiStudio:models(callback)
	local status, response = self.http:get("'" .. self.options.url .. "/models?key=" .. AISTUDIO_API_TOKEN .. "'")
	assert(callback ~= nil)
	if response then
		log.info(response)
		local t_result = vim.json.decode(response)
		local result = {}
		for _, model in ipairs(t_result.models) do
			table.insert(result, {
				description = model.description,
				model = model.name,
				name = model.displayName,
				context_length = model.context_length,
				pricing = model.pricing,
				version = model.version,
				inputTokenLimit = model.inputTokenLimit,
				outputTokenLimit = model.outputTokenLimit,
				temperature = model.temperature,
				topP = model.topP,
				topK = model.topK,
			})
		end
		callback(status, result)
	end
end
-- {
--   "models": [
--     {
--       "inputTokenLimit": 4096,
--       "outputTokenLimit": 1024,
--       "supportedGenerationMethods": [
--         "generateMessage",
--         "countMessageTokens"
--       ],
--       "temperature": 0.25,
--       "topP": 0.95,
--       "topK": 40
--     },

--- Sends a chat request to the AiStudio API
--- @param self table The AiStudio instance.
--- @param session Chat The session object containing the chat context. -- TODO: posibble wrong type
--- @param stdout function Function to handle standard output messages.
--- @param stderr function  Function to handle error messages.
--- @param exit function Function to handle process exit status.
function AiStudio:chat(session, stdout, stderr, exit)
	local request = {
		url = self.options.url .. "/" .. session.provider.model .. ":generateContent?key=" .. AISTUDIO_API_TOKEN,
		headers = {
			' -H "Content-Type: application/json"',
		},
		body = vim.json.encode(self:__parse_prompt(session)),
	}
	local collected_doc = ""
	local status, err = self.http:post(request, function(_, b)
		if b ~= 0 then
			log.trace("Exit: " .. b)
			if exit then
				exit(b)
			end
		end
	end, function(_, data, _)
		if data then
			log.trace(">>>", #data, " ", table.concat(data))
			local datas = table.concat(data, "")
			if #datas > 0 then
				log.info("recieved data: " .. #datas)
				collected_doc = collected_doc .. datas
			else
				log.info("empty data received, decode json.")
				log.info(collected_doc)
				local mes = vim.json.decode(collected_doc)
				stdout(self:__parse_response(mes))
				collected_doc = ""
			end
		else
			log.info("no data received.")
		end
	end, function(_, data, _)
		if stderr then
			stderr(data)
		end
	end)
	return status, err
end

return AiStudio
