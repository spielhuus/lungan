local cmp = require("cmp")

local Source = {}

function Source:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function Source.is_available()
	return vim.bo.filetype == "markdown"
end

function Source:complete(params, callback)
	local before_line = params.context.cursor_before_line
	local buffer = params.context.bufnr
	local items = {}
	-- handle the models
	if before_line:match("^%s*model:%s*(.-)%s*$") then
		local name = before_line:match("^%s*model:%s*(.-)%s*$")
		local session = require("lungan.nvim").get_chat(buffer)
		if session then
			local provider = session.data:frontmatter().provider
			local opts = require("lungan.nvim").options
			local llm = require("lungan.llm"):new(opts)
			-- opts.providers[provider.name]:models(opts, name, function(content)
			llm:models(session, function(status, content)
				for _, model in ipairs(content) do
					table.insert(items, {
						label = model.name,
						filterText = model.model,
						insertText = model.model,
						detail = model.description,
						kind = cmp.lsp.CompletionItemKind.Folder,
						description = model.description,
						data = {
							path = "meta",
						},
					})
				end
			end)
			-- require("luv").run()
		end
	end
	-- handle the providers
	if before_line:match("^%s*name:%s*(.-)%s*$") then
		for k, v in pairs(require("lungan.nvim").options.providers) do
			table.insert(items, {
				label = k,
				filterText = k,
				insertText = k,
				detail = "Provider",
				kind = cmp.lsp.CompletionItemKind.Folder,
				description = v.description or "",
				data = {
					path = "meta",
				},
			})
		end
	end
	callback(items)
end

-- source.resolve = function(self, completion_item, callback)
-- 	print("resovle: " .. vim.inspect(completion_item))
-- 	local data = completion_item.data
-- 	if data.stat and data.stat.type == "file" then
-- 		local ok, documentation = pcall(function()
-- 			return self:_get_documentation(data.path, constants.max_lines)
-- 		end)
-- 		if ok then
-- 			completion_item.documentation = documentation
-- 		end
-- 	end
-- 	callback(completion_item)
-- end

return Source
