local Yaml = {}

function Yaml:_parse(lines, indent, line)
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
	o.tree = o:_parse(lines)
	return o
end

return Yaml
