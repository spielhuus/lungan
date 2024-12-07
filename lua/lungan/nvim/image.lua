local log = require("lungan.log")
local term = require("lungan.nvim.termutils")

local image = {}

local image_id = 0

local function next_image_id()
	image_id = image_id + 1
	return image_id
end

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

local function send_image_to_kitty(img)
	local chunked = chunks(img.base64)
	local control_payload = "i=" .. img.id .. ",a=t,f=100,q=1"
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
end

local function show_image_in_kitty(img, chop_top, chop_bottom)
	local x, y, w, h = 0, chop_top, img.width, img.height - chop_bottom
	stdout:write(
		"\x1b_Ga=p,p="
			.. img.id
			.. ",i="
			.. img.id
			.. ",x="
			.. x
			.. ",y="
			.. y
			.. ",w="
			.. w
			.. ",h="
			.. h
			.. ",q=1;\x1b\\"
	)
end

local function hide_image_in_kitty(img)
	stdout:write("\x1b_Ga=d,i=" .. img.id .. ",q=1;\x1b\\")
end

---@return integer, integer the cols and rows
image.size = function(img)
	term.update_cell_size()
	return math.ceil(img.width / term.cell_size.x), math.ceil(img.height / term.cell_size.y)
end

image.render = function(win, cell)
	local info = vim.fn.getwininfo(win)[1]
	for _, img in ipairs(cell.images) do
		-- check if visible
		print(cell.line .. "->" .. info.topline .. "/" .. info.botline)
		local cols, rows = image.size(img)
		if cell.line < info.topline - 1 or cell.line > info.botline then
			if img.id then
				log.debug("hide image")
				hide_image_in_kitty(img)
				img.id = nil
			end
		else
			local chop_top = 0
			local chop_bottom = 0
			-- get the chop top
			if cell.line == info.topline - 1 then
				local topfill = vim.fn.winsaveview().topfill
				local cutoff_rows = math.max(0, rows - topfill)
				chop_top = cutoff_rows * term.cell_size.y
			end
			-- local chop = (cell.line + rows - info.topline) - info.height
			-- chop_bottom = chop < 0 and 0 or (chop * term.cell_size.y)
			-- get the chop bottom
			local chop = (cell.line + rows - info.topline) - info.height
			chop_bottom = chop < 0 and 0 or (chop * term.cell_size.y)
			-- get the top
			local row = cell.line - info.topline + 3
			require("lungan.nvim.termutils").move_cursor(row, 10)
			if not img.id then
				img.id = next_image_id()
				send_image_to_kitty(img)
			end
			show_image_in_kitty(img, chop_top, chop_bottom)
			require("lungan.nvim.termutils").restore_cursor()
		end
	end
end

return image
