local Yaml = {}

local MATCH_KEY = "^%s*([%w|_]+):%s*$"
local MATCH_KEY_VAL = "^%s*([%w|_]+):%s*([%w|%p|%s]+)$"
local MATCH_TEXT_BLOCK = "^%s*([%w|_]+):%s*|%s*"
local MATCH_LIST_KEY = "^%s*-%s+([%w|%p]+)$"
local MATCH_LIST_KEY_VAL = "^%s*-%s+([%w|%p]+): ([%w|%p]+)$"

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
			while index <= #lines do
				local text_indent = string.match(lines[index], "^( *)")
				if #text_indent < indent + 1 then
					goto end_text
				end
				text = text .. (#text == 0 and "" or "\n") .. require("lungan.str").trim(lines[index])
				index = index + 1
			end
			::end_text::
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
		else
			print(">" .. lines[index])
		end
		index = index + 1
	end
	return tree, index
end

function Yaml:_parse_old(lines, indent, line)
	indent = indent or 0
	local i = line or 1
	local tree = {}
	while i <= #lines do
		local act_indent = string.match(lines[i], "( *)")
		if #(act_indent or "") < indent then
			return tree, i - 1
		end

		local key, val = string.match(lines[i], "^%s*([%w|_]+): ?(.+)$")
		local key_only = string.match(lines[i], "^%s*([%w|_]+): *$")
		local text = string.match(lines[i], "^%s*([%w|_]+): *|$")
		local list = string.match(lines[i], "^%s*-%s*([%w|_]+)$")
		local list_map, map = string.match(lines[i], "^%s*-%s*([%w|_]+): ([%w|_]+)$")

		-- if list_map then
		-- 	local body = {}
		-- 	body[list_map] = tonumber(map) or map
		-- 	i = i + 1
		-- 	while i <= #lines do
		-- 		local next_indent = string.match(lines[i], "( *)")
		-- 		if #(next_indent or "") <= #(act_indent or "") then
		-- 			i = i - 1
		-- 			goto endtext
		-- 		end
		-- 		local list_key, list_val = string.match(lines[i], "^%s*([%w|_]+): ?(.+)$")
		-- 		local list_key_only = string.match(lines[i], "^%s*([%w|_]+): *$")
		-- 		if list_key then
		-- 			body[list_key] = tonumber(list_val) or list_val
		-- 		elseif list_key_only then
		-- 			print("KEY: " .. list_key_only)
		-- 			local next_indent = #(string.match(lines[i + 1], "( *)") or "")
		-- 			local node
		-- 			node, i = self:_parse(lines, next_indent, i + 1)
		-- 			tree[string.sub(key_only, #(act_indent or "") + 1)] = node
		-- 		end
		-- 		i = i + 1
		-- 	end
		-- 	::endtext::
		-- 	table.insert(tree, body)
		-- 	goto next
		-- end

		if list then
			table.insert(tree, list)
			goto next
		end

		if text then
			local body = {}
			i = i + 1
			while i <= #lines do
				local next_indent = string.match(lines[i], "( *)")
				if #(next_indent or "") <= #(act_indent or "") then
					i = i - 1
					goto endtext
				end
				table.insert(body, string.sub(lines[i], #(next_indent or "") + 1))
				i = i + 1
			end
			::endtext::
			tree[string.sub(text, #(act_indent or "") + 1)] = table.concat(body, "\n")
			goto next
		end

		if key and val then
			if val == "true" or val == "false" then
				tree[key] = val == "true"
			else
				tree[key] = tonumber(val, 10) or val
			end
			goto next
		end

		if key_only then
			local next_indent = #(string.match(lines[i + 1], "( *)") or "")
			local node
			node, i = self:_parse(lines, next_indent, i + 1)
			tree[string.sub(key_only, #(act_indent or "") + 1)] = node
			goto next
		end
		::next::
		i = i + 1
	end
	return tree, i
end

function Yaml:new(o, lines)
	o = o or {}
	setmetatable(o, { __index = self })
	o.content = lines
	o.tree = o:_parse(lines, 0, 1)
	return o
end

return Yaml
