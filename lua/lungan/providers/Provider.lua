---@class Provider
---@field options table
---@field http Http

local Provider = {}
Provider.__index = Provider

---Stop a running request
function Provider:stop()
	error("provider:stop is not implemented")
end

---Get the available models from the provider
function Provider:models(callback) end

---Chat with the LLM
---@param prompt any
---@param stdout fun()
---@param stderr fun()
---@param exit fun()
---@return string|nil, string|nil
function Provider:chat(prompt, stdout, stderr, exit)
	return nil, "provider:chat is not implemented"
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
---@return string|nil, string|nil error message
function Provider:embeddings(request, stdout, stderr, exit)
	return nil, "Provider:embeddings is not implemented"
end

return Provider
