local log = require("log")
local M = {}

local namespace = vim.api.nvim_create_namespace("lungan.images")

local stdout = vim.loop.new_tty(1, false)
if not stdout then
	error("failed to open stdout")
end

--- split the input into chunks of 4096 bytes
--- @param data string the input string
local chunks = function(data)
	local result = {}
	for i = 1, #data, 4096 do
		table.insert(result, data:sub(i, i + 4095))
	end
	return result
end

local function send_image_to_kitty(image)
	local chunked = chunks(image.base64)
	-- <ESC>_Gs=100,v=30,m=1;<encoded pixel data first chunk><ESC>\
	-- <ESC>_Gm=1;<encoded pixel data second chunk><ESC>\
	-- <ESC>_Gm=0;<encoded pixel data last chunk><ESC>\
	local control_payload = "a=T,f=100"
	local m = #chunked > 1 and 1 or 0
	control_payload = control_payload .. ",m=" .. m
	for i = 1, #chunked do
		stdout:write("\x1b_G" .. control_payload .. ";" .. chunked[i] .. "\x1b\\")
		if i == #chunked - 1 then
			control_payload = "m=0"
		else
			control_payload = "m=1"
		end
		vim.uv.sleep(1)
	end
	-- display the image
	-- <ESC>_Gi=<id>;OK<ESC>\
	-- stdout:write("\x1b_Gi=1;OK\x1b\\")
end

function M.render(options, win, buffer, data, results)
	options.theme.clear(options, win, buffer)
	for line in data:iter() do
		local res, mes = pcall(options.theme[line.type], options, win, buffer, line)
		if not res then
			-- TODO: log.warn("Markdown type '" .. line.type .. "' not found. (" .. mes .. ")")
		end
	end
	if results then
		for _, line in ipairs(results) do
			-- print("RENDER RESULT:" .. vim.inspect(results))
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
				for _, image in ipairs(line.images) do
					local tbl = { "1", "2", "3", "4" }
					vim.api.nvim_buf_set_extmark(buffer, namespace, line.line - 1, 0, {
						virt_lines = {
							{
								{ table.concat(tbl, "\n"), "" },
							},
						},
						hl_mode = "combine",
					})
					send_image_to_kitty(image)
				end
			end
			-- TODO is there also stderr?
		end
	end
end

return M
