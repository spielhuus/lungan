local context = {}
local str = require("lungan.str")

local json
if vim ~= nil then
	json = vim.json
else
	json = require("rapidjson")
end

function context.search(collection, text)
	print("Query: " .. text)
	local http = require("lungan.nvim.Http"):new()
	local ollama = require("lungan.providers.Ollama"):new(http, {})
	local chroma = require("lungan.db.chroma"):new(http, {})

	local uuid
	chroma:get_or_create_collection({}, nil, nil, "NEOVIM", function(data)
		uuid = data
	end, function(err)
		print("ERR: " .. table.concat(err, " "))
	end, nil)

	local res = ""
	ollama:embeddings({}, {
		model = "nomic-embed-text:latest",
		prompt = text,
	}, function(out)
		if out ~= nil then
			res = res .. table.concat(out, "")
		end
	end, function(err)
		print(str.to_string(err))
	end, nil)
	local embeddings = json.decode(res)

	local result = ""
	local res = chroma:collection_query({}, uuid, { embeddings.embedding }, 1, function(data)
		result = result .. str.to_string(data.documents)
	end, function(data)
		print("ERR:" .. table.concat(data, " "))
	end, nil)
	print(result)
	return result
end

return context
