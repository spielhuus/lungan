local Http = require("lungan.lua.Http")
local Ollama = require("lungan.providers.Ollama")
local str = require("lungan.str")

require("lungan.log").level = "trace"

-- create a new ollama binding
local http = Http:new()
local ollama = Ollama:new(http, {})

-- get the available models from the server
print("get ollama models")
ollama:models(function(_, data)
	print(require("lungan.str").to_string(data))
end)

print("chat with ollama")
ollama:chat({
	provider = {
		model = "llama3.2:1b",
		name = "Ollama",
	},
	messages = {
		{ role = "system", content = "You are a funny housewife" },
		{ role = "uesr", content = "Hi, how are you?" },
	},
	stream = true,
}, function(out)
	io.write(out["message"]["content"])
	io.flush()
end, function(err)
	print(str.to_string(err))
end, nil)

print("\n\ncreate embeddings")
ollama:embeddings({
	model = "nomic-embed-text:latest",
	prompt = "mom likes embeddings",
}, function(out)
	-- io.write(out["message"]["content"])
	io.write(str.to_string(out))
	io.flush()
end, function(err)
	print(str.to_string(err))
end, nil)
