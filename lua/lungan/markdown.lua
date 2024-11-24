local str = require("lungan.str")
local tbl = require("lungan.tbl")

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
			while i <= #lines do
				frontmatter = string.match(lines[i], "^---[%s]*$")
				if frontmatter then
					goto endmatter
				end
				table.insert(yaml, lines[i])
				i = i + 1
			end
			::endmatter::
			node.to = i
			node.text = table.concat(yaml, "\n")
			table.insert(tree, node)
			self.fm = require("lungan.yaml"):new(nil, yaml)
			goto next
		end

		if chat then
			local node = { type = Markdown.types.CHAT, role = chat, from = i }
			local chat_text = {}
			i = i + 1
			while i <= #lines do
				local chat_fin = string.match(lines[i], "^==>$")
				if chat_fin then
					goto endchat
				end
				table.insert(chat_text, lines[i])
				i = i + 1
			end
			::endchat::
			node.to = i
			node.text = table.concat(chat_text, "\n")
			table.insert(tree, node)
			goto next
		end

		if heading then
			table.insert(tree, { type = Markdown.types.HEADER, heading = #heading, text = text, from = i, to = i })
			goto next
		end

		if list_level and list_item then
			table.insert(tree, {
				type = Markdown.types.LIST,
				char = list_item,
				level = #list_level,
				text = list_text,
				from = i,
				to = i,
			})
			goto next
		end

		if num_list_level and num_list_item then
			table.insert(tree, {
				type = Markdown.types.LIST,
				char = num_list_item,
				level = #num_list_level,
				text = num_list_text,
				from = i,
				to = i,
			})
			goto next
		end

		if code then
			local node = { type = Markdown.types.CODE, from = i, lang = code }
			-- get params
			local function params(body)
				print("body" .. body)
				local lang, rest = body:match("^{(%w+)%s+(.*)}$")
				print("PARSE:" .. rest)
				local tokens = str.spaces(rest)
				local sparams = str.params(tokens)
				node.lang = lang
				local tparams = {}
				for key, val in pairs(sparams) do
					tbl.set_with_path(tparams, key, val)
				end
				node.params = tparams
			end
			-- parse the first line
			if string.match(code, "{(.*)}```") then -- single line params
				params(code:sub(1, -4))
				node.to = i
				table.insert(tree, node)
				goto next
			elseif string.match(code, "{(.*)}") then -- multiline
				params(code)
			end
			-- collect the lines
			local source = {}
			i = i + 1
			while i <= #lines do
				if lines[i] == "```" then
					goto endcode
				end
				table.insert(source, lines[i])
				i = i + 1
			end
			::endcode::
			node.to = i
			node.text = table.concat(source, "\n")
			table.insert(tree, node)
			goto next
		end

		table.insert(tree, { type = Markdown.types.PARAGRAPH, text = line, from = i, to = i })

		::next::
		i = i + 1
	end
	return tree
end

function Markdown:size()
	return #self.tree
end

function Markdown:frontmatter()
	return self.fm.tree
end

function Markdown:has_frontmatter()
	return self.fm ~= nil
end

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
