local text = [[
--- Gets `extmarks` in "traversal order" from a `charwise` region defined by
--- buffer positions (inclusive, 0-indexed `api-indexing`).
---
--- Region can be given as (row,col) tuples, or valid extmark ids (whose
--- positions define the bounds). 0 and -1 are understood as (0,0) and (-1,-1)
--- respectively, thus the following are equivalent:
---]]
--- ```lua
--- vim.api.nvim_buf_get_extmarks(0, my_ns, 0, -1, {})
--- vim.api.nvim_buf_get_extmarks(0, my_ns, {0,0}, {-1,-1}, {})
--- ```
---
--- If `end` is less than `start`, traversal works backwards. (Useful
--- with `limit`, to get the first marks prior to a given position.)
---
--- Note: when using extmark ranges (marks with a end_row/end_col position)
--- the `overlap` option might be useful. Otherwise only the start position
--- of an extmark will be considered.
---
--- Note: legacy signs placed through the `:sign` commands are implemented
--- as extmarks and will show up here. Their details array will contain a
--- `sign_name` field.
---
--- Example:
---
--- ```lua
--- local api = vim.api
--- local pos = api.nvim_win_get_cursor(0)
--- local ns  = api.nvim_create_namespace('my-plugin')
--- -- Create new extmark at line 1, column 1.
--- local m1  = api.nvim_buf_set_extmark(0, ns, 0, 0, {})
--- -- Create new extmark at line 3, column 1.
--- local m2  = api.nvim_buf_set_extmark(0, ns, 2, 0, {})
--- -- Get extmarks only from line 3.
--- local ms  = api.nvim_buf_get_extmarks(1, ns, {2,0}, {2,0}, {})
--- -- Get all marks in this buffer + namespace.
--- local all = api.nvim_buf_get_extmarks(0, ns, 0, -1, {})
--- vim.print(ms)
--- ```
---]]

text2 = [[
--- Gets a line-range from the buffer.
---
--- Indexing is zero-based, end-exclusive. Negative indices are interpreted
--- as length+1+index: -1 refers to the index past the end. So to get the
--- last element use start=-2 and end=-1.
---
--- Out-of-bounds indices are clamped to the nearest valid value, unless
--- `strict_indexing` is set.
---
--- @param buffer integer Buffer handle, or 0 for current buffer
--- @param start integer First line index
--- @param end_ integer Last line index, exclusive
--- @param strict_indexing boolean Whether out-of-bounds should be an error.
--- @return string[] # Array of lines, or empty array for unloaded buffer.
function vim.api.nvim_buf_get_lines(buffer, start, end_, strict_indexing) end]]

local Http = require("lungan.lua.Http")
local Ollama = require("lungan.providers.Ollama")
local str = require("lungan.str")

require("lungan.log").level = "warn"

-- create a new ollama binding
local http = Http:new()
local ollama = Ollama:new(http, {})

print("\n\ncreate embeddings")
local result = {}
ollama:embeddings({}, {
	model = "nomic-embed-text:latest",
	prompt = text,
}, function(out)
	for _, val in pairs(out) do
		table.insert(result, val)
	end
	-- io.write(out["message"]["content"])
	-- io.write(str.to_string(out))
	-- io.flush()
end, function(err)
	print(str.to_string(err))
end, nil)

local str = require("rapidjson").encode(result)
print(str)

print("\n\ncreate query")
local result = {}
ollama:embeddings({}, {
	model = "nomic-embed-text:latest",
	prompt = "get extmarks from buffer",
}, function(out)
	for _, val in pairs(out) do
		table.insert(result, val)
	end
	-- io.write(out["message"]["content"])
	-- io.write(str.to_string(out))
	-- io.flush()
end, function(err)
	print(str.to_string(err))
end, nil)

local str = require("rapidjson").encode(result)
print(str)
