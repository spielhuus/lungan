local log = require("lungan.log")

---class Yaml
local Yaml = {}

local MATCH_KEY = "^%s*([%w|_]+):%s*$"
local MATCH_KEY_VAL = "^%s*([%w|_]+):%s*(.+)$"
local MATCH_TEXT_BLOCK = "^%s*([%w|_]+):%s*|%s*"
local MATCH_LIST_KEY = "^%s*-%s+([%w|%p]+)$"
local MATCH_LIST_KEY_VAL = "^%s*-%s+([%w|%p]+): (.+)$"

function Yaml:_parse(lines, indent, index)
	local tree = {}
	while index <= #lines do
		local next_indent = string.match(lines[index], "^( *)")
		if #next_indent < indent then
			return tree, index - 1
		end
		if string.match(lines[index], MATCH_TEXT_BLOCK) then
			local key = string.match(lines[index], MATCH_TEXT_BLOCK)
			local text = ""
			index = index + 1
			local end_text = false
			while index <= #lines and end_text == false do
				local text_indent = string.match(lines[index], "^( *)")
				if #text_indent < indent + 1 then
					end_text = true
				else
					text = text .. (#text == 0 and "" or "\n") .. require("lungan.str").trim(lines[index])
					index = index + 1
				end
			end
			tree[key] = text
			index = index - 1
		elseif string.match(lines[index], MATCH_KEY) then
			local key = string.match(lines[index], MATCH_KEY)
			local subtree
			subtree, index = self:_parse(lines, #next_indent + 1, index + 1)
			tree[key] = subtree
		elseif string.match(lines[index], MATCH_KEY_VAL) then
			local key, val = string.match(lines[index], MATCH_KEY_VAL)
			if string.lower(val) == "false" then
				tree[key] = false
			elseif string.lower(val) == "true" then
				tree[key] = true
			else
				tree[key] = tonumber(val) or val
			end
		elseif string.match(lines[index], MATCH_LIST_KEY) then
			local list_item = string.match(lines[index], MATCH_LIST_KEY)
			table.insert(tree, list_item)
		elseif string.match(lines[index], MATCH_LIST_KEY_VAL) then
			local list_key, list_val = string.match(lines[index], MATCH_LIST_KEY_VAL)
			local subtree
			subtree, index = self:_parse(lines, #next_indent + 1, index + 1)
			subtree[list_key] = list_val
			table.insert(tree, subtree)
		elseif string.match(lines[index], "%s*-") then
			print("Inkown: " .. lines[index])
			log.debug("unknown: " .. require("lungan.str").to_string(lines[index]))
			-- error("what to do here")
		else
			log.info(">" .. lines[index])
		end
		index = index + 1
	end
	return tree, index
end

--- Parse YAML content from an array of lines
function Yaml:new(o, lines)
	o = o or {}
	setmetatable(o, { __index = self })
	o.content = lines
	o.tree = o:_parse(lines, 0, 1)
	return o
end

return Yaml
