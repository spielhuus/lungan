local function dir_exists(path)
	local stat = vim.loop.fs_stat(path)
	return stat and stat.type == "directory"
end
local path = vim.api.nvim_call_function("stdpath", { "data" })
local pythonpath = os.getenv("PYTHONPATH")
local plugindir
if dir_exists(path .. "/lazy/lungan") then
	plugindir = path .. "/lazy/lungan"
elseif dir_exists(path .. "/lazy-rocks/lungan/lib/luarocks/rocks-5.1/lungan/scm-1") then
	plugindir = path .. "/lazy-rocks/lungan/lib/luarocks/rocks-5.1/lungan/scm-1"
else
	plugindir = "/home/etienne/github/lungan"
	-- TODO error("plugin dir not found in " .. path)
end
pythonpath = (pythonpath and (pythonpath .. ":") or "") .. plugindir .. "/python3"
vim.env.PYTHONPATH = pythonpath
vim.env.LUNGAN = "neovim"
