local M = function(_, prompts, cb)
	local Snacks = require("snacks")
	Snacks.picker({
		finder = function()
			local items = {}
			for i, entry in ipairs(prompts) do
				table.insert(items, {
					idx = i,
					text = entry.data:frontmatter().name,
					file = entry.path,
					data = entry,
				})
			end
			return items
		end,
		layout = {
			layout = {
				box = "horizontal",
				width = 0.5,
				height = 0.5,
				{
					box = "vertical",
					border = "rounded",
					title = "Find directory",
					{ win = "input", height = 1, border = "bottom" },
					{ win = "list", border = "none" },
				},
			},
		},
		format = function(item, _)
			local file = item.text
			local ret = {}
			local a = Snacks.picker.util.align
			local icon, icon_hl = Snacks.util.icon(file, "directory")
			ret[#ret + 1] = { a(icon, 3), icon_hl }
			ret[#ret + 1] = { " " }
			ret[#ret + 1] = { a(file, 20) }

			return ret
		end,
		confirm = function(picker, item)
			picker:close()
			cb(item.data)
		end,
	})
end

return M
