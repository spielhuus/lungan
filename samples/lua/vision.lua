local Http = require("lungan.lua.Http")
local Ollama = require("lungan.providers.Ollama")
local str = require("lungan.str")

require("lungan.log").level = "info"

local image = "opamp.jpg"

-- create a new ollama binding
local http = Http:new()
local ollama = Ollama:new(http, {})

local function local_and_encode_image(path)
	local file = io.open(path, "rb")
	if not file then
		error("File not found: " .. path)
	end

	local content = file:read("*all")
	file:close()

	local b64 = require("base64")
	return b64.encode(content)
end

print("analyze circuit image")
ollama:generate({
	provider = {
		model = "llama3.2-vision:11b",
		name = "Ollama",
	},
	stream = false,
	images = { local_and_encode_image(image) },
	prompt = "analyse this image and create a python script that draws the schema.",
}, function(out)
	io.write(out["response"])
	io.flush()
end, function(err)
	print(str.to_string(err))
end, nil)
