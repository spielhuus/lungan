local log = require("lungan.log")

local OPENROUTER_API_TOKEN = os.getenv("OPENROUTER_API_TOKEN") or ""

local Openrouter = {}

local defaults = {
	name = "Openrouter",
	url = "https://openrouter.ai",
}

---Creates a new instance of the Ollama object.
---@class Openrouter
---@param http table The Http implementation to use
---@param opts table An optional table containing configuration options.
---@return Openrouter A new instance of Openrouter with the specified options.
function Openrouter:new(http, opts)
	local o = {}
	setmetatable(o, { __index = self })
	o.__name = "openrouter"
	local in_opts = opts or {}
	local options = defaults
	for k, v in pairs(in_opts) do
		defaults[k] = v
	end
	o.options = options
	o.http = http
	return o
end

function Openrouter:__parse_prompt(prompt)
	local output = {
		model = prompt.provider.model,
		messages = { { role = "system", content = prompt.system_prompt } },
		stream = prompt.stream,
	}

	if prompt.options then
		for key, val in pairs(prompt.options) do
			output[key] = val
		end
	end

	for _, line in ipairs(prompt.messages) do
		table.insert(output.messages, { role = line.role, content = line.content })
	end
	log.trace("Prompt: ", output)
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

---Stop a running request
function Openrouter:stop()
	self.http:cancel()
end

-- Fetches a list of models from the Openrouter API.
-- @param self (Openrouter) The Openrouter instance on which this method is called.
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
function Openrouter:models(callback)
	local status, response = self.http:get(self.options.url .. "/api/v1/models")
	assert(callback ~= nil)
	if response then
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

--- Sends a chat request to the Openrouter API
--- @param self table The Openrouter instance.
--- @param session Chat The session object containing the chat context.
--- @param stdout function Function to handle standard output messages.
--- @param stderr function  Function to handle error messages.
--- @param exit function Function to handle process exit status.
function Openrouter:chat(session, stdout, stderr, exit)
	local request = {
		url = self.options.url .. "/api/v1/chat/completions",
		headers = {
			' -H "Authorization: Bearer ' .. OPENROUTER_API_TOKEN .. '"',
			' -H "Content-Type: application/json"',
		},
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
						log.info("make table: " .. message)
						message = string.sub(message, de + 1)
					end

					log.debug(message)
					local mes = vim.json.decode(message)
					if mes["error"] then
						log.error("Openrouter Error: " .. mes["error"]["metadata"]["raw"])
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

return Openrouter
