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
	error("plugin dir not found")
end
pythonpath = (pythonpath and (pythonpath .. ":") or "") .. plugindir .. "/python3"
vim.env.PYTHONPATH = pythonpath
vim.env.LUNGAN = "neovim"

-- -- local llm = require("lungan.llm")
--
-- local M = {}
--
-- M.options = require("lungan.nvim.defaults")
--
-- M.chats = {} -- TODO delete closed chats
-- M.sessions = {}
--
-- M.get_chat = function(buffer)
-- 	for _, c in ipairs(M.chats) do
-- 		if c.buffer == buffer then
-- 			return c
-- 		end
-- 	end
-- 	return nil
-- end
--
-- M.attach = function()
-- 	local win = vim.api.nvim_get_current_win()
-- 	local buffer = vim.api.nvim_win_get_buf(win)
-- 	require("lungan.Page"):new(nil, M.options, vim.api.nvim_buf_get_name(buffer)):attach(win, buffer)
-- end
--
-- ---Load the prompts
-- M.prompts = function()
-- 	local results = {}
-- 	for _, p in ipairs(M.options.prompt_path) do
-- 		for _, file in ipairs(vim.fn.glob(p .. "/*.md", true, true)) do
-- 			table.insert(results, require("lungan.Prompt"):new(nil, M.options, file))
-- 		end
-- 	end
-- 	return results
-- end
--
-- M.yank_result = function(args)
-- 	local c = M.get_chat(args.buffer)
-- 	if c then
-- 		-- call preview function
-- 		local func, err = load(c.prompt.data.fm.tree.commit)
-- 		if not func then
-- 			error(err)
-- 		end
-- 		func()(M.options, c.data)
-- 	end
-- end
--
-- M.run = function(args)
-- 	llm.chat(M.options, M.sessions[args.source_buf])
-- end
--
-- M.setup = function(opts)
-- 	vim.tbl_deep_extend("force", opts, M.options)
-- 	-- set the highligh groups
-- 	for _, hl in ipairs(M.options.theme.hl) do
-- 		vim.api.nvim_set_hl(0, hl[1], hl[2])
-- 	end
-- 	-- register user commands
-- 	vim.api.nvim_create_user_command("Lungan", function(arg)
-- 		arg.source_buf = vim.api.nvim_win_get_buf(0)
-- 		arg.source_win = vim.api.nvim_get_current_win()
--
-- 		if arg.args == "Attach" then
-- 			M.attach()
-- 		elseif arg.args == "Chat" then
-- 			M.options.picker.prompts({}, M.prompts(), function(p)
-- 				local chat = require("lungan.Chat"):new(nil, M.options, arg, p)
-- 				chat:open()
-- 				table.insert(M.chats, chat)
-- 			end)
-- 		elseif arg.args == "Run" then
-- 			M.run(arg)
-- 		elseif arg.args == "Notebooks" then
-- 			local notebook = require("lungan.Notebook"):new(nil, M.options, ".")
-- 			M.options.picker.notebooks({}, notebook.pages, function(entry)
-- 				entry.data:open()
-- 				M.attach()
-- 			end)
-- 		else
-- 			print("Unknown command: " .. arg.args) -- TODO use notify
-- 		end
-- 	end, {
-- 		range = true,
-- 		nargs = "?",
-- 		complete = function()
-- 			return { "Attach", "Notebooks", "Chat", "Run", "Toggle" }
-- 		end,
-- 	})
--
-- 	-- local group = vim.api.nvim_create_augroup("LunganGlobal", { clear = true })
-- 	-- vim.api.nvim_create_autocmd("BufWinEnter", {
-- 	--     group = group,
-- 	--     callback = function()
-- 	--         local win = vim.api.nvim_get_current_win()
-- 	--         local buffer = vim.api.nvim_win_get_buf(0)
-- 	--         if M.sessions[buffer] and not M.sessions[buffer].initialized then
-- 	--             if
-- 	--                 M.options.selected_prompt
-- 	--                 and M.options.selected_prompt["data"][1]["content"]["autorun"]
-- 	--                 and M.options.selected_prompt["data"][1]["content"]["autorun"] == true
-- 	--             then
-- 	--                 M.run({ source_buf = buffer })
-- 	--             end
-- 	--             -- fold the frontmatter
-- 	--             vim.api.nvim_win_call(win, function()
-- 	--                 -- Manually set the fold start and end lines
-- 	--                 local content = M.sessions[buffer]["data"][1]
-- 	--                 if content and content.name == "frontmatter" then
-- 	--                     vim.opt.foldmethod = "manual"
-- 	--                     vim.cmd(content.row_start + 1 .. "," .. content.row_end .. "fold")
-- 	--                 end
-- 	--             end)
-- 	--             M.sessions[buffer].initialized = true
-- 	--         end
-- 	--     end,
-- 	-- })
-- end
--
-- return M
