local _, devicons = pcall(require, "nvim-web-devicons")

local namespace = vim.api.nvim_create_namespace("lungan")

local M = {
	default_prompts = true,
	prompt_path = {
		vim.env.HOME .. "/.config/lungan",
		"samples/prompts",
		".nvim/lungan",
	},
	provider = "Ollama",
	providers = {
		Ollama = require("lungan.providers.Ollama"):new(require("lungan.nvim.Http"):new()),
		Openrouter = require("lungan.providers.Openrouter"):new(require("lungan.nvim.Http"):new()),
		-- Replicate = require("lungan.providers.replicate").setup(),
	},
	picker = {
		models = require("lungan.nvim.telescope.models"),
		prompts = require("lungan.nvim.telescope.prompts"),
		notebooks = require("lungan.nvim.telescope.notebooks"),
	},
	prompts = {},

	ignore = {
		".gitignore",
		".git",
		".luarocks",
		".nvim",
		"test/spec",
	},
	linewidth = 80, -- the linewidth for the textwrapper
	loglevel = "trace",
	theme = {
		header_signs = { "󰬺", "󰬻", "󰬼", "󰬽", "󰬾", "󰬿", "󰭀", "󰭁", "󰭂", "󰿩" },
		clear = function(_, _, buffer, from, to)
			vim.api.nvim_buf_clear_namespace(buffer, namespace, from or 0, to or -1)
		end,
		header = function(options, win, buffer, data)
			local cols = vim.api.nvim_win_get_width(win)
			local indent = 2 * (data.heading - 1)
			local text = (data.text or "")
			local hide = cols - indent - #text - 20
			vim.api.nvim_buf_set_extmark(buffer, namespace, data.from - 1, 0, {
				virt_text_pos = "overlay",
				virt_text = {
					{ string.rep(" ", indent), "" },
					{ text .. string.rep(" ", hide), "LunganHeader" .. data.heading },
				},
				sign_text = options.theme.header_signs[data.heading],
				sign_hl_group = "LunganHeaderSign" .. data.heading,
				hl_mode = "combine",
			})
		end,
		code = function(_, _, buffer, data)
			local icon, hl = devicons.get_icon(nil, data.lang, { default = true })
			-- prepare and draw the header
			local header = { { (data.lang or "") .. "    ", hl } }
			if data.params then
				table.insert(header, { vim.inspect(data.params), "" })
			end
			for i = data.from + 1, data.to - 1 do
				vim.api.nvim_buf_set_extmark(buffer, namespace, i - 1, 0, {
					virt_text_pos = "inline",
					virt_text = {
						{
							string.format("%" .. #tostring(data.to - data.from) .. "s", i - data.from),
							"LunganLineNr",
						},
						{ "│ ", hl },
					},
					hl_mode = "combine",
				})
			end
			vim.api.nvim_buf_set_extmark(buffer, namespace, data.from - 1, 0, {
				virt_text_pos = "overlay",
				virt_text = header,
				-- virt_text = {
				--     { string.rep(" ", 2), hl },
				--     { (data.lang or "") .. " ", hl },
				-- },
				sign_text = icon,
				sign_hl_group = hl,
				line_hl_group = "LunganCode",
				hl_mode = "combine",
			})
		end,
		chat = function(_, win, buffer, data)
			if data.role ~= nil then
				local win_width = vim.api.nvim_win_get_width(win)
				if data.role == "user" then
					vim.api.nvim_buf_set_extmark(buffer, namespace, data.from - 1, 0, {
						virt_text_pos = "overlay",
						virt_text = {
							{
								"   ",
								"",
							},
							{
								string.rep(" ", win_width - #data.role - 7) .. data.role .. " ",
								"LunganChat",
							},
						},
						sign_text = "",
						hl_mode = "replace",
						conceal = " ",
					})
					vim.api.nvim_buf_set_extmark(buffer, namespace, data.to - 1, 0, {
						virt_text_pos = "overlay",
						virt_text = {
							{
								"    ",
								"",
							},
							{
								string.rep(" ", win_width - 6),
								"LunganChat",
							},
						},
						hl_mode = "replace",
						conceal = " ",
					})

					for i = data.from, data.to - 2 do
						local line = vim.api.nvim_buf_get_lines(buffer, i, i + 1, true)[1]
						vim.api.nvim_buf_set_extmark(buffer, namespace, i, 0, {
							virt_text_pos = "inline",
							virt_text = {
								{
									"   ",
									"",
								},
								{
									" ",
									"LunganChat",
								},
							},
						})
						vim.api.nvim_buf_set_extmark(buffer, namespace, i, 0, {
							virt_text_pos = "overlay",
							virt_text = {
								{
									line .. string.rep(" ", win_width - #line - 7),
									"LunganChat",
								},
							},
							hl_mode = "combine",
						})
					end
				else
					vim.api.nvim_buf_set_extmark(buffer, namespace, data.from - 1, 0, {
						virt_text_pos = "overlay",
						virt_text = {
							{
								" " .. data.role .. string.rep(" ", win_width - #data.role - 8),
								"LunganChat",
							},
						},
						sign_text = "",
						hl_mode = "replace",
						conceal = " ",
					})
					vim.api.nvim_buf_set_extmark(buffer, namespace, data.to - 1, 0, {
						virt_text_pos = "overlay",
						virt_text = {
							{
								string.rep(" ", win_width - 7),
								"LunganChat",
							},
							{
								"   ",
								"",
							},
						},
						hl_mode = "replace",
						conceal = " ",
					})

					for i = data.from, data.to - 2 do
						local line = vim.api.nvim_buf_get_lines(buffer, i, i + 1, true)[1]
						vim.api.nvim_buf_set_extmark(buffer, namespace, i, 0, {
							virt_text_pos = "overlay",
							virt_text = {
								{
									line .. string.rep(" ", win_width - vim.fn.strdisplaywidth(line) - 7),
									"LunganChat",
								},
							},
							hl_mode = "combine",
						})
					end
				end
			end
		end,
		error = function(_, _, buffer, data)
			vim.api.nvim_buf_set_extmark(buffer, namespace, data.line - 1, 0, {
				virt_text_pos = "eol",
				virt_text = {
					{ "\t\t " .. data.error.name .. ": ", "DiagnosticError" },
					{ data.error.desc, "DiagnosticError" },
				},

				hl_mode = "combine",
			})
		end,
		out = function(_, _, buffer, data)
			if #data.out > 0 then
				if #data.out == 1 then
					vim.api.nvim_buf_set_extmark(buffer, namespace, data.line - 1, 0, {
						virt_text_pos = "eol",
						virt_text = {
							{ " => " .. data.out[1], "LunganOut" },
						},

						hl_mode = "combine",
					})
				else
					vim.api.nvim_buf_set_extmark(buffer, namespace, data.line - 1, 0, {
						virt_lines = {
							{
								{ table.concat(data.out, "\n"), "" },
							},
						},
						hl_mode = "combine",
					})
				end
			end
		end,
		stdout = function(_, _, buffer, data)
			local lines = {}
			for _, line in ipairs(data.stdout) do
				table.insert(lines, { { line, "@comment" } })
			end
			vim.api.nvim_buf_set_extmark(buffer, namespace, data.line - 1, 0, {
				virt_lines = lines,
				hl_mode = "combine",
			})
		end,
		image = function(_, _, buffer, data)
			local lines = {}
			local total_rows = 0
			for _, image in ipairs(data.images) do
				local term = require("lungan.nvim.termutils")
				term.update_cell_size()
				total_rows = total_rows + math.ceil(image.height / term.cell_size.y)
			end
			for _ = 1, total_rows do
				table.insert(lines, { { "", "@comment" } })
			end
			vim.api.nvim_buf_set_extmark(buffer, namespace, data.line - 1, 0, {
				virt_lines = lines,
				hl_mode = "combine",
			})
		end,
		hl = {
			-- TODO: add icons here
			{ "LunganChat", { bg = "#181818", default = false } },
			{ "LunganHeader1", { fg = "#FFFFFF", underdouble = true, bold = true, default = false } },
			{ "LunganHeader2", { fg = "#FFFFFF", underline = true, bold = true, default = false } },
			{ "LunganHeader3", { fg = "#AFAFAF", underdotted = true, bold = true, default = false } },
			{ "LunganHeader4", { fg = "#AFAFAF", underdashed = true, bold = false, default = false } },
			{ "LunganHeader5", { fg = "#AFAFAF", undercurl = true, bold = false, default = false } },
			{ "LunganHeader6", { fg = "#AFAFAF", default = false } },
			{ "LunganHeader7", { fg = "#AFAFAF", default = false } },
			{ "LunganHeader8", { fg = "#AFAFAF", default = false } },
			{ "LunganHeader9", { fg = "#AFAFAF", default = false } },
			{ "LunganLineNr", { fg = "#AFAFAF", default = false } },
			{ "LunganOut", { fg = "#AFAFAF", default = false } },
			{ "LunganErrorTitle", { fg = "#FF0000", default = false, bold = true } },
			{ "LunganError", { fg = "#FF0000", default = false } },
		},
	},
}

return M
