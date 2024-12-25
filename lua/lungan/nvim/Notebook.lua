--- *Markdown Page*
--- A markdown Notebook. Handles all the markdown pages in the project.

---@class Notebook
---@field options table
---@field pages Page the Pages
local Notebook = {}

local Page = require("lungan.nvim.page")

local function ends_with(str, suffix)
	local suffix_len = #suffix
	return str:sub(-suffix_len) == suffix
end

--- Retrieves the .gitignore file and extracts its contents.
--- @param path string: Path to the directory where the .gitignore file is expected to be located.
--- @return string[]: A table containing the contents of the .gitignore file,
---                   or an empty table if the file is not found.
function Notebook:_gitignore(path)
	local files = vim.fn.glob(path .. "/.gitignore", true, true)
	if not files then
		return {}
	end -- Return empty table if file is not found
	local lines = {}
	for _, file in ipairs(files) do
		for line in io.lines(file) do
			if line:sub(1, 1) == "#" then
				goto next
			end
			if line:match("^%s*$") ~= nil then
				goto next
			end
			table.insert(lines, line)
			::next::
		end
	end
	return lines
end

--- Checks whether a given path matches any of the ignore patterns.
function Notebook:_is_ignore(path, ignore)
	local filename = string.match(path, "[^\\/]+$")
	for _, pattern in ipairs(ignore) do
		if filename == pattern then
			return true
		elseif string.match(pattern, "/+") and string.match(path, pattern) then
			return true
		else
			local regex = vim.fn.glob2regpat(pattern)
			if vim.fn.matchstr(path, regex) ~= "" then
				return true
			end
		end
	end
	return false
end

---Load a notebook from a path
---loads all the markdown pages from the path and
---stores the filename and all the regerences in the
---page. the references are marked like this: [link]
function Notebook:_load(path, ignore)
	local pages = {}
	local journals = {}
	local function readdir(p)
		local files = vim.fn.readdir(p, function(file)
			if self:_is_ignore(p .. "/" .. file, ignore) then
				return 0
			else
				return 1
			end
		end)
		for _, file in ipairs(files) do
			if vim.fn.isdirectory(p .. "/" .. file) == 1 then
				readdir(p .. "/" .. file)
			elseif ends_with(file, ".md") then
				local year, month, day = string.match(file, "^(%d+)_(%d+)_(%d+).md$")
				if year and month and day then
					table.insert(journals, p .. "/" .. file)
				else
					table.insert(pages, Page:new(nil, self.options, p .. "/" .. file))
				end
			end
		end
	end
	readdir(path)
	return pages, journals
end

function Notebook:get_page(name)
	local abs_name = vim.fn.fnamemodify(name, ":p")
	for _, page in ipairs(self.pages) do
		if vim.fn.fnamemodify(page:filename(), ":p") == abs_name then
			return page
		end
	end
	return nil
end

function Notebook:new(o, options, path)
	o = o or {}
	setmetatable(o, { __index = self })
	o.options = options
	o.ignore = options["ignore"] or {}
	for _, v in ipairs(o:_gitignore(path)) do
		table.insert(o.ignore, v)
	end

	o.pages, o.journals = o:_load(path, o.ignore)
	return o
end

return Notebook
