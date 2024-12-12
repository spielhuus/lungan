local Http = require("lungan.lua.Http")
local Chroma = require("lungan.db.chroma")
local Ollama = require("lungan.providers.Ollama")
local str = require("lungan.str")

require("lungan.log").level = "info"

local http = Http:new()
local chroma = Chroma:new(http, {})
local ollama = Ollama:new(http, {})

local function read_file(path)
	local file = io.open(path, "r")
	if not file then
		return nil, "File not found"
	end

	local content = file:read("*all")
	file:close()

	return content
end

local function embed(text)
	local res
	ollama:embeddings({
		model = "nomic-embed-text:latest",
		prompt = text,
	}, function(out)
		if out ~= nil then
			assert(not res)
			res = out
		end
	end, function(err)
		print(str.to_string(err))
	end, nil)
	return res
end

local function insert(id, file, line, text, embedding)
	chroma:collection_add(id, embedding, nil, nil, file .. ":" .. line, text, function(data)
		print(data)
	end, function(data)
		print(data)
	end, nil)
end

local uuid
chroma:get_or_create_collection(nil, nil, "NEOVIM", function(data)
	uuid = data
end, function(err)
	print("ERR: " .. err)
end, nil)
print("Chroma Collection: " .. uuid.id)

err, count = chroma:get_collections_count(uuid.id) --, function(data)
-- end, function(err)
-- 	print("ERR: " .. err)
-- end, nil)
print("Chroma Collection count: " .. count)

local query = "what are the buffer events"
local embedded_query = embed(query)
local res = chroma:collection_query(uuid, { embedded_query.embedding }, function(data)
	print("###" .. str.to_string(data.documents[1]))
end, function(data)
	print(data)
end, nil)
