local termutils = {}

termutils.cell_size = {
	x = 0,
	y = 0,
}

termutils.screen_size = {
	x = 0,
	y = 0,
	cols = 0,
	rows = 0,
}

function termutils.update_cell_size()
	local ffi = require("ffi")
	ffi.cdef([[
        typedef struct {
            unsigned short row;
            unsigned short col;
            unsigned short xpixel;
            unsigned short ypixel;
        } winsize;

        int ioctl(int, int, ...);
    ]])

	local TIOCGWINSZ = nil
	if vim.fn.has("linux") == 1 then
		TIOCGWINSZ = 0x5413
	elseif vim.fn.has("mac") == 1 then
		TIOCGWINSZ = 0x40087468
	elseif vim.fn.has("bsd") == 1 then
		TIOCGWINSZ = 0x40087468
	end

	local sz = ffi.new("winsize")
	assert(ffi.C.ioctl(1, TIOCGWINSZ, sz) == 0, "Hologram failed to get screen size: detected OS is not supported.")

	termutils.screen_size.x = sz.xpixel ---@diagnostic disable-line
	termutils.screen_size.y = sz.ypixel ---@diagnostic disable-line
	termutils.screen_size.cols = sz.col ---@diagnostic disable-line
	termutils.screen_size.rows = sz.row ---@diagnostic disable-line
	termutils.cell_size.x = sz.xpixel / sz.col ---@diagnostic disable-line
	termutils.cell_size.y = sz.ypixel / sz.row ---@diagnostic disable-line
end

local stdout = vim.loop.new_tty(1, false)

function termutils.move_cursor(row, col)
	termutils.write("\x1b[s")
	termutils.write("\x1b[" .. row .. ":" .. col .. "H")
	vim.uv.sleep(1)
end

function termutils.restore_cursor()
	termutils.write("\x1b[u")
	vim.uv.sleep(1)
end

-- glob together writes to stdout
function termutils.write(data) -- vim.schedule_wrap(function(data)
	assert(stdout)
	stdout:write(data)
end

return termutils
