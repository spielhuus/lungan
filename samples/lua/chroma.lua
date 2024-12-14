local Http = require("lungan.lua.Http")
local Chroma = require("lungan.db.chroma")
local Ollama = require("lungan.providers.Ollama")
local str = require("lungan.str")
local json = require("rapidjson")

require("lungan.log").level = "trace"
require("lungan.log").outfile = "log.txt"

local http = Http:new()
local chroma = Chroma:new(http, {})
local ollama = Ollama:new(http, {})

local function embed(text)
	local res = ""
	ollama:embeddings({
		model = "nomic-embed-text:latest",
		prompt = text,
	}, function(out)
		if out ~= nil then
			res = res .. table.concat(out, "")
		end
	end, function(err)
		print(str.to_string(err))
	end, nil)
	return json.decode(res)
end

local function insert(id, file, line, text, embedding)
	chroma:collection_add(id, { embedding }, nil, nil, { file .. ":" .. line }, { text }, function(data)
		print(str.to_string(data))
	end, function(data)
		print(data)
	end, nil)
end

local function collection_id()
	local uuid
	chroma:get_or_create_collection(nil, nil, "NEOVIM", function(data)
		uuid = data
	end, function(err)
		print("ERR: " .. err)
	end, nil)
	return uuid
end
local function print_usage()
	print("Parse and Query the neovim documentation.")
	print("> luajit <command>")
	print("Commands")
	print("- import path     import the neovim docs in path")
	print("- search term n   search the term and retrieve n documents")
end

local function read_file(path)
	local file = io.open(path, "r")
	if not file then
		return nil, "File not found"
	end

	local content = file:read("*all")
	file:close()

	return content
end

local function import_file(file)
	local junks = {}
	local junk = nil
	local content = read_file(file)
	if content == nil then
		print("no file content")
	end
	local preamble = true
	for i, line in ipairs(str.lines(content)) do
		-- skip the header of the document
		if line == "==============================================================================" then
			preamble = false
			goto next
		end

		if string.match(line, "[%s]+(%*.*%*)") then
			if junk then
				table.insert(junks, junk)
				junk = {}
			end
			local name = string.match(line, "[%s]+(%*.*%*)")
			junk = { name = name, file = file, line = i, content = line }
		elseif string.match(line, "(.*)[%s]+(%*.*%*)") then
			if junk then
				table.insert(junks, junk)
				junk = {}
			end
			local _, name = string.match(line, "(.*)[%s]+(%*.*%*)")
			junk = { name = name, file = file, line = i, content = line }
		elseif junk then
			junk.content = junk.content .. "\n" .. line
		else
			-- print(">" .. i .. ":" .. line)
		end
		::next::
	end
	return junks
end

local function import(path)
	local documents = {}
	-- print("import documents from path: " .. path)
	for file in io.popen("ls " .. path):lines() do
		local docs = import_file(path .. "/" .. file)
		for _, d in ipairs(docs) do
			table.insert(documents, d)
		end
	end
	return documents
end

local function to_json(documents)
	local file = io.open("neovim.json", "w")
	if file then
		file:write(json.encode(documents))
		file:close()
	end
end

-- the 'main' part
if #arg == 0 then
	print_usage()
	return 1
end

if arg[1] == "import" then
	if #arg < 2 then
		print_usage()
		return 1
	end
	local documents = import(arg[2])

	local uuid = collection_id()
	print("insert " .. #documents .. " documents into database NEOVIM: " .. uuid.id)
	for i, d in ipairs(documents) do
		print(i .. "/" .. #documents .. " " .. d.name)
		local embeddings = embed(d.content)
		insert(uuid, d.file, d.line, d.content, embeddings.embedding)
	end
elseif arg[1] == "json" then
	local documents = import(arg[2])
	to_json(documents)
elseif arg[1] == "search" then
	print("Serch for: " .. arg[2])
	local uuid = collection_id()
	print("UUID: " .. str.to_string(uuid))
	local err, collections = chroma:get_collections_count(uuid.id)
	print("Chroma Collection count: " .. collections)
	local count = arg[3] or 1
	local embeddings = embed(arg[2])
	local data = chroma:collection_query(uuid, { embeddings.embedding }, count, function(data)
		print("###" .. str.to_string(data.documents))
	end, function(data)
		print(data)
	end, nil)
else
	print("unkown command: " .. arg[1])
	print_usage()
end
