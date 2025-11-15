-- local llm = require("lungan.llm")


local M = {}


_G.debug_callback = function(str)
  require('lungan.log').debug(str)
end

_G.vino_callbacks = {}

_G.vino = function(payload)
  local data_table = vim.json.decode(payload)
  if data_table['error'] then
    _G.vino_callbacks[data_table['dispatcher']].on_stderr(data_table)
  else
    _G.vino_callbacks[data_table['dispatcher']].on_stdout(data_table)
  end
end

M.options = require("lungan.nvim.defaults")

M.chats = {}
M.sessions = {}

M.get_chat = function(buffer)
  for _, c in ipairs(M.chats) do
    if c.buffer == buffer then
      return c
    end
  end
  return nil
end

M.attach = function()
  local win = vim.api.nvim_get_current_win()
  local buffer = vim.api.nvim_win_get_buf(win)
  require("lungan.nvim.page"):new(nil, M.options, vim.api.nvim_buf_get_name(buffer)):attach(win, buffer)
end

---Load the prompts
M.prompts = function()
  local results = {}
  for _, p in ipairs(M.options.prompt_path()) do
    for _, file in ipairs(vim.fn.glob(p .. "/*.md", true, true)) do
      table.insert(results, require("lungan.nvim.Prompt"):new(nil, M.options, file))
    end
  end
  return results
end

M.setup = function(opts)
  vim.tbl_deep_extend("force", opts, M.options)
  -- setup the logger
  require("lungan.log").level = M.options.loglevel or "info"
  require("lungan.log").outfile =
      string.format("%s/%s.log", vim.api.nvim_call_function("stdpath", { "log" }), "lungan")
  require("lungan.log").error = function(err)
    vim.notify("lungan: " .. vim.inspect(err), vim.log.levels.ERROR)
  end
  require("lungan.log").warn = function(err)
    vim.notify("lungan: " .. vim.inspect(err), vim.log.levels.WARN)
  end
  -- set the highligh groups
  for _, hl in ipairs(M.options.theme.hl) do
    vim.api.nvim_set_hl(0, hl[1], hl[2])
  end
  -- register user commands
  vim.api.nvim_create_user_command("Lg", function(arg)
    arg.source_buf = vim.api.nvim_win_get_buf(0)
    arg.source_win = vim.api.nvim_get_current_win()

    if arg.args == "Attach" then
      M.attach()
    elseif arg.args == "Chat" then
      M.options.picker.prompts({}, M.prompts(), function(prompt)
        local chat = require("lungan.nvim.chat"):new(M.options, arg, prompt)
        chat:open()
        table.insert(M.chats, chat)
      end)
    elseif arg.args == "Run" then
      M.run(arg)
    elseif arg.args == "Notebooks" then
      local notebook = require("lungan.nvim.Notebook"):new(nil, M.options, ".")
      M.options.picker.notebooks({}, notebook.pages, function(entry)
        entry.data:open()
        M.attach()
      end)
    else
      vim.notify("Lungan: Unknown command '" .. arg.args .. "'", vim.log.levels.ERROR)
    end
  end, {
    range = true,
    nargs = "?",
    complete = function()
      return { "Attach", "Notebooks", "Chat", "Run", "Toggle" }
    end,
  })

  -- local group = vim.api.nvim_create_augroup("LunganGlobal", { clear = true })
  -- vim.api.nvim_create_autocmd("BufWinEnter", {
  --     group = group,
  --     callback = function()
  --         local win = vim.api.nvim_get_current_win()
  --         local buffer = vim.api.nvim_win_get_buf(0)
  --         if M.sessions[buffer] and not M.sessions[buffer].initialized then
  --             if
  --                 M.options.selected_prompt
  --                 and M.options.selected_prompt["data"][1]["content"]["autorun"]
  --                 and M.options.selected_prompt["data"][1]["content"]["autorun"] == true
  --             then
  --                 M.run({ source_buf = buffer })
  --             end
  --             -- fold the frontmatter
  --             vim.api.nvim_win_call(win, function()
  --                 -- Manually set the fold start and end lines
  --                 local content = M.sessions[buffer]["data"][1]
  --                 if content and content.name == "frontmatter" then
  --                     vim.opt.foldmethod = "manual"
  --                     vim.cmd(content.row_start + 1 .. "," .. content.row_end .. "fold")
  --                 end
  --             end)
  --             M.sessions[buffer].initialized = true
  --         end
  --     end,
  -- })
end

return M
