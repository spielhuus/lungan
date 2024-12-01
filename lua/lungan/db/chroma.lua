local log = require("lungan.log")
local str = require("lungan.str")

local json
if vim ~= nil then
	json = vim.json
else
	json = require("rapidjson")
end

local Chroma = {}

local defaults = {
	name = "Chroma",
	url = "http://127.0.0.1:8000",
}

---Creates a new instance of the Chroma object.
---@class Chroma
---@param o table The Http implementation to use
---@param opts table An optional table containing configuration options.
---@return Chroma A new instance of Chroma with the specified options.
function Chroma:new(o, opts)
	local instance = setmetatable(self, { __index = o })
	instance.__index = Chroma
	instance.__name = "chroma"
	local in_opts = opts or {}
	local options = defaults
	for k, v in pairs(in_opts) do
		defaults[k] = v
	end
	instance.options = options
	return instance
end

function Chroma:get_or_create_collection(opts, tenant, database, collection, stdout, stderr, exit)
	tenant = tenant or "default_tenant"
	database = database or "default_database"

	local request = {
		url = self.options.url .. "/api/v1/collections?tenant=" .. tenant .. "&database=" .. database,
		body = json.encode({ name = collection, get_or_create = true }),
		headers = {
			"-H",
			"accept: application/json",
			"-H",
			"Content-Type: application/json",
		},
	}

	local on_exit
	if exit ~= nil then
		on_exit = function(_, b)
			if b ~= 0 then
				log.trace("Exit: " .. b)
				if exit then
					exit(b)
				end
			end
		end
	end

	local status, _ = self:post(request, on_exit, function(_, data, _)
		log.trace("<<", data)
		if data then
			local clean_table = str.clean_table(data)
			if #clean_table > 0 then
				stdout(json.decode(table.concat(data, "")))
			end
		end
	end, function(_, data, _)
		if stderr then
			stderr(data)
		end
	end)
	-- return client
end

function Chroma:get_collections_count(opts, collection, stdout, stderr, exit)
	tenant = tenant or "default_tenant"
	database = database or "default_database"

	local request = {
		url = self.options.url .. "/api/v1/collections/" .. collection .. "/count",
		headers = {
			"-H",
			"accept: application/json",
		},
	}

	local on_exit
	if exit ~= nil then
		on_exit = function(_, b)
			if b ~= 0 then
				log.trace("Exit: " .. b)
				if exit then
					exit(b)
				end
			end
		end
	end

	local status, err = self:get(request.url) --, on_exit, function(_, data, _)
	-- 	log.trace("<<", data)
	-- 	if data then
	-- 		local clean_table = str.clean_table(data)
	-- 		if #clean_table > 0 then
	-- 			stdout(json.decode(table.concat(data, "")))
	--
	-- 		end
	-- 	end
	-- end, function(_, data, _)
	-- 	if stderr then
	-- 		stderr(data)
	-- 	end
	-- end)
	-- return client
	return status, err
end

function Chroma:collection_add(opts, collection, embeddings, metadata, uris, ids, text, stdout, stderr, exit)
	local request = {
		url = self.options.url .. "/api/v1/collections/" .. collection.id .. "/add",
		body = json.encode({
			embeddings = embeddings,
			metadatas = metadata,
			uris = uris,
			ids = ids,
			documents = text,
		}),
		headers = {
			"-H",
			"accept: application/json",
			"-H",
			"Content-Type: application/json",
		},
	}

	local on_exit
	if exit ~= nil then
		on_exit = function(_, b)
			if b ~= 0 then
				log.trace("Exit: " .. b)
				if exit then
					exit(b)
				end
			end
		end
	end

	local status, err = self:post(request, on_exit, function(_, data, _)
		log.trace("<<", data)
		if data then
			local clean_table = str.clean_table(data)
			if #clean_table > 0 then
				stdout(json.decode(table.concat(data, "")))
			end
		end
	end, function(_, data, _)
		if stderr then
			stderr(data)
		end
	end)
	-- return client
	return status, err
end

function Chroma:collection_query(opts, collection, query, count, stdout, stderr, exit)
	local request = {
		url = self.options.url .. "/api/v1/collections/" .. collection.id .. "/query",
		body = json.encode({
			query_embeddings = query,
			n_results = count,
			include = {
				"metadatas",
				"documents",
				"distances",
			},
		}),
		headers = {
			"-H",
			"accept: application/json",
			"-H",
			"Content-Type: application/json",
		},
	}

	local on_exit
	if exit ~= nil then
		on_exit = function(_, b)
			if b ~= 0 then
				log.trace("Exit: " .. b)
				if exit then
					exit(b)
				end
			end
		end
	end

	log.debug("create embeddings")
	local status, err = self:post(request, on_exit, function(_, data, _)
		log.trace("<<", data)
		if data then
			local clean_table = str.clean_table(data)
			if #clean_table > 0 then
				log.debug("<<<", data)
				stdout(json.decode(table.concat(data, "")))
			end
		end
	end, function(_, data, _)
		local clean_table = str.clean_table(data)
		if #clean_table > 0 then
			stderr(clean_table)
		end
	end)
	-- return client
	return status, err
end

return Chroma
