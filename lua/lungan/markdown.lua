local str = require("lungan.str")
local tbl = require("lungan.tbl")

---@class Markdown
---@field tree table
local Markdown = {}

Markdown.types = {
	HEADER = "header",
	PARAGRAPH = "paragraph",
	CODE = "code",
	FRONTMATTER = "frontmatter",
	LIST = "list",
	CHAT = "chat",
}

function Markdown:_parse(lines)
	local tree = {}
	local i = 1
	while i <= #lines do
		local line = lines[i]
		local heading, text = string.match(line, "([#]+)%s([%s|%w|%p]*)")
		local code = string.match(line, "```(.*)")
		local frontmatter = string.match(line, "^---[%s]*$")
		local list_level, list_item, list_text = string.match(line, "^([%s]*)([\\*|-]) (.*)$")
		local num_list_level, num_list_item, num_list_text = string.match(line, "^([%s]*)(%d+)[\\.|\\)] (.*)$")
		local chat = string.match(line, "^<==%s(%w+)([%s]*)$")

		if frontmatter and i == 1 then
			local node = { type = Markdown.types.FRONTMATTER, from = i }
			local yaml = {}
			i = i + 1
			local break_matter = false
			while i <= #lines and break_matter == false do
				frontmatter = string.match(lines[i], "^---[%s]*$")
				if frontmatter then
					break_matter = true
				else
					table.insert(yaml, lines[i])
					i = i + 1
				end
			end
			node.to = i
			node.text = table.concat(yaml, "\n")
			table.insert(tree, node)
			self.fm = require("lungan.yaml"):new(nil, yaml)
		elseif chat then
			local node = { type = Markdown.types.CHAT, role = chat, from = i }
			local chat_text = {}
			i = i + 1
			local endchat = false
			while i <= #lines and endchat == false do
				local chat_fin = string.match(lines[i], "^==>$")
				if chat_fin then
					endchat = true
				else
					table.insert(chat_text, lines[i])
					i = i + 1
				end
			end
			node.to = i
			node.text = table.concat(chat_text, "\n")
			table.insert(tree, node)
		elseif heading then
			table.insert(tree, { type = Markdown.types.HEADER, heading = #heading, text = text, from = i, to = i })
		elseif list_level and list_item then
			table.insert(tree, {
				type = Markdown.types.LIST,
				char = list_item,
				level = #list_level,
				text = list_text,
				from = i,
				to = i,
			})
		elseif num_list_level and num_list_item then
			table.insert(tree, {
				type = Markdown.types.LIST,
				char = num_list_item,
				level = #num_list_level,
				text = num_list_text,
				from = i,
				to = i,
			})
		elseif code then
			local node = { type = Markdown.types.CODE, from = i, lang = code }
			-- get params
			local function params(body)
				local lang, rest = body:match("^{(%w+)%s+(.*)}$")
				local tokens = str.spaces(rest)
				local sparams = str.params(tokens)
				node.lang = lang
				local tparams = {}
				for key, val in pairs(sparams) do
					tbl.set_with_path(tparams, key, val)
				end
				node.params = tparams
			end
			local endcode = false
			-- parse the first line
			if string.match(code, "{(.*)}```") then -- single line params
				params(code:sub(1, -4))
				node.to = i
				table.insert(tree, node)
				endcode = true
			elseif string.match(code, "{(.*)}") then -- multiline
				params(code)
			end
			-- collect the lines
			local source = {}
			if endcode == false then
				i = i + 1
				while i <= #lines and endcode == false do
					if lines[i] == "```" then
						endcode = true
					else
						table.insert(source, lines[i])
						i = i + 1
					end
				end
				node.text = table.concat(source, "\n")
			end
			node.to = i
			table.insert(tree, node)
		else
			table.insert(tree, { type = Markdown.types.PARAGRAPH, text = line, from = i, to = i })
		end
		i = i + 1
	end
	return tree
end

---return integer number of items in the tree
function Markdown:size()
	return #self.tree
end

---@return table The frontmatter data
function Markdown:frontmatter()
	return self.fm.tree
end

---@return boolean
function Markdown:has_frontmatter()
	return self.fm ~= nil
end

---Get the entry at line number
---@return table|nil the result or nil
function Markdown:get(linenr)
	for _, line in ipairs(self.tree) do
		if linenr >= line.from and linenr <= line.to then
			return line
		end
	end
	return nil
end

function Markdown:iter()
	local i = 0
	local n = #self.tree
	return function()
		i = i + 1
		if i <= n then
			return self.tree[i]
		end
	end
end

---Markdown parser
---@param o any
---@param lines string[] the markdown as array of lines.
---@return any
function Markdown:new(o, lines)
	o = o or {}
	setmetatable(o, { __index = self, __name = "Markdown" })
	o.content = lines
	o.tree = o:_parse(lines)
	self.fm = nil
	return o
end

return Markdown
