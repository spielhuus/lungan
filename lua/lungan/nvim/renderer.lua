local log = require("lungan.log")
local M = {}

local namespace = vim.api.nvim_create_namespace("lungan.images")

function M.render(options, win, buffer, data, results)
	options.theme.clear(options, win, buffer)
	for line in data:iter() do
		local res, mes = pcall(options.theme[line.type], options, win, buffer, line)
		if not res then
			log.info("Markdown type '" .. line.type .. "' not found. (" .. mes .. ")")
		end
	end
	if results then
		for _, line in ipairs(results) do
			-- TODO what does happen if we have both stdout and out
			if line.error then
				local res, mes = pcall(options.theme.error, options, win, buffer, line)
				if not res then
					log.warn("Can not render out. (" .. mes .. ")")
				end
			end
			if line.out then
				local res, mes = pcall(options.theme.out, options, win, buffer, line)
				if not res then
					log.warn("Can not render out. (" .. mes .. ")")
				end
			end
			if line.stdout and not line.error then
				local res, mes = pcall(options.theme.stdout, options, win, buffer, line)
				if not res then
					log.warn("Can not render stdout. (" .. mes .. ")")
				end
			end
			if line.images then
				local res, mes = pcall(options.theme.image, options, win, buffer, line)
				require("lungan.nvim.image").render(win, line)
			end
			-- TODO is there also stderr?
		end
	end
end

return M
