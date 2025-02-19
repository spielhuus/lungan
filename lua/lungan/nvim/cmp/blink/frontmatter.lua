local env = {}

function env.new(opts)
	local default_opts = {
		item_kind = require("blink.cmp.types").CompletionItemKind.Variable,
		show_braces = false,
		show_documentation_window = true,
	}

	opts = vim.tbl_deep_extend("keep", opts, default_opts, { cached_results = false, completion_items = {} })

	return setmetatable(opts, { __index = env })
end

function env:enabled()
	return vim.bo.filetype == "markdown"
end

function env:get_completions(ctx, callback)
	local items = {}
	local c = ctx.get_cursor()
	local cursor_line = ctx.line
	local cursor = {
		row = c[1],
		col = c[2] + 1,
		line = c[1] - 1,
	}
	local before_line = string.sub(cursor_line, 1, cursor.col - 1)
	if before_line:match("^%s*model:%s*(.-)%s*$") then
		local name = before_line:match("^%s*model:%s*(.-)%s*$")
		local session = require("lungan.nvim").get_chat(ctx.bufnr)
		if session then
			local provider = session.data:frontmatter().provider
			local opts = require("lungan.nvim").options
			local llm = require("lungan.llm"):new(opts)
			-- opts.providers[provider.name]:models(opts, name, function(content)
			llm:models(session, function(status, content)
				for _, model in ipairs(content) do
					table.insert(items, {
						label = model.name,
						insertText = model.model,
						detail = model.description,
						-- kind = cmp.lsp.CompletionItemKind.Folder,
						documentation = model.description,
					})
				end
			end)
		end
	end
	-- handle the providers
	if before_line:match("^%s*name:%s*(.-)%s*$") then
		for k, _ in pairs(require("lungan.nvim").options.providers) do
			table.insert(items, {
				label = k,
				insertText = k,
				detail = k,
				-- kind = cmp.lsp.CompletionItemKind.Folder,
			})
		end
	end

	callback({
		is_incomplete_forward = false,
		is_incomplete_backward = false,
		items = items,
	})

	return function() end
end

return env
