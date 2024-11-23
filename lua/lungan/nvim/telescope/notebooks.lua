local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")

local M = function(opts, notebooks, cb)
	opts = opts or {}
	notebooks = notebooks

	pickers
		.new(opts, {
			prompt_title = "Notebooks",
			finder = finders.new_table({
				results = notebooks,
				entry_maker = function(entry)
					return {
						-- value = entry.plain,
						display = entry:name(),
						ordinal = entry:filename(),
						plain = entry:name(),
						content = entry:content(),
						data = entry,
					}
				end,
			}),

			sorter = conf.generic_sorter(opts),

			attach_mappings = function(prompt_bufnr, _)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					cb(selection)
				end)
				return true
			end,

			previewer = previewers.new_buffer_previewer({
				title = "Prompt Details",
				define_preview = function(self, entry, _)
					vim.api.nvim_set_option_value("filetype", "markdown", { buf = self.state.bufnr })
					vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, entry.content)
				end,
			}),
		})
		:find()
end

return M
