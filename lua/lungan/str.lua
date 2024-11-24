local str = {}

str.trim = function(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end

---Cleans a table by removing empty strings and whitespace-only strings.
---@param data table The table containing string elements to be cleaned.
---@return table A new table with only non-empty, non-whitespace strings from the original table.
str.clean_table = function(data)
	local cleaned = {}
	for _, value in ipairs(data) do
		if type(value) == "string" and #value > 0 and not value:match("^%s*$") then
			table.insert(cleaned, value)
		end
	end
	return cleaned
end

str.stripnl = function(s)
	return s:gsub("%s+$", "")
end

str.lines = function(input)
	local result = {}
	local index, last = 1, 1
	while index <= #input do
		local c = input:sub(index, index)
		if c == "\r" or c == "\n" then
			table.insert(result, input:sub(last, index - 1))
			if index + 1 <= #input and c == "\r" and input:sub(index + 1, index + 1) == "\n" then
				index = index + 1
			end
			last = index + 1
		end
		index = index + 1
	end
	if last < index then
		table.insert(result, input:sub(last, index))
	end
	return result
end

str.spaces = function(text)
	local index = 1
	local result = {}
	local collect = {}

	local in_quoted = false
	local in_single_quoted = false

	while index <= #text do
		local c = string.sub(text, index, index)
		if c == '"' then
			if index > 1 then
				local cl = string.sub(text, index - 1, index - 1)
				if cl ~= "\\" then
					in_quoted = not in_quoted
				end
			end
			table.insert(collect, c)
		elseif c == "'" then
			if index > 1 then
				local cl = string.sub(text, index - 1, index - 1)
				if cl ~= "\\" then
					in_single_quoted = not in_single_quoted
				end
			end
			table.insert(collect, c)
		elseif c == " " and not in_quoted and not in_single_quoted then
			table.insert(result, table.concat(collect, ""))
			collect = {}
		else
			table.insert(collect, c)
		end
		index = index + 1
	end
	if collect then
		table.insert(result, table.concat(collect, ""))
	end
	return result
end

str.params = function(tokens)
	local pairs = {}
	local index = 1
	while index <= #tokens do
		if index < #tokens and tokens[index + 1] == "=" then
			table.insert(pairs, tokens[index] .. tokens[index + 1] .. tokens[index + 2])
			index = index + 2
		else
			table.insert(pairs, tokens[index])
		end
		index = index + 1
	end
	-- convert to table
	local result = {}
	for _, item in ipairs(pairs) do
		local key, val = item:match("^(.*=)(.*)$")
		if key then
			result[string.sub(key, 1, -2)] = assert(load("return " .. val))() -- TODO clever casting method!
		else
			error("can not parse " .. item)
		end
	end
	return result
end

str.to_string = function(value)
	local t = type(value)
	if t == "nil" then
		return "nil"
	elseif t == "boolean" then
		return tostring(value)
	elseif t == "number" then
		return tostring(value)
	elseif t == "string" then
		return '"' .. value .. '"'
	elseif t == "table" then
		local result = "{ "
		for k, v in pairs(value) do
			result = result .. "[" .. str.to_string(k) .. "] = " .. str.to_string(v) .. ", "
		end
		return result:sub(1, -3) .. " }"
	elseif t == "function" then
		return "<function>"
	elseif t == "userdata" or t == "thread" then
		return tostring(value)
	else
		return "<unknown type>"
	end
end

return str
