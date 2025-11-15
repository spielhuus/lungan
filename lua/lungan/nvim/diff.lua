local log = require("lungan.log")
local str = require("lungan.str")
local utils = require("lungan.utils")

local M = {}

M.delta = {}
M.position = { line = 0, col = 0 }
M.line_marks = {}
M.target_text = {}

M.delta = {}
M.position = { line = 0, col = 0 }
M.line_marks = {}
M.target_text = {}

local function extract_chat(data)
  local message = {}
  -- extract the last assistant message
  for m in data:iter() do
    if m.type == "chat" and m.role == "assistant" then
      message = M.__clean_result(vim.split(m.text, "\n"))
    end
  end

  local begin_line = -1
  local end_line = 0

  -- search the first and last code fence marker
  for i, line in ipairs(message) do
    log.debug("line '" .. line .. "'")
    if begin_line == -1 and line == "```markdown" then
      begin_line = i
    elseif line == "```" then
      end_line = i
    end
  end

  local result = {}
  for i, line in ipairs(message) do
    if i > begin_line and i < end_line then
      table.insert(result, line)
    end
  end

  return result
end

-- the diff class type

---@class DiffClass
---@field options table
---@field http Http

local DiffClass = {}
DiffClass.__index = DiffClass

---Stop a running request
function DiffClass:stop()
  error("provider:stop is not implemented")
end

-- inplement the inline diff

local InlineDiff = {}
InlineDiff.__index = InlineDiff

function InlineDiff:new(left, right)
  local o = {}
  setmetatable(o, { __index = DiffClass, __name = "InlineDiff" })
  o.left = left
  o.right = right
  o.trace = o:shortest_edit()
  return o
end

--

-- the diff class

local Diff = {}
Diff.__index = Diff

function Diff:new(differ)
  local o = {}
  setmetatable(o, { __index = self, __name = "Diff" });
  o.namespace = vim.api.nvim_create_namespace("lungan.diff");
  o.differ = differ;

  vim.keymap.set("n", "<C-n>", function()
    o:next();
  end, {
    nowait = true,
    noremap = true,
    silent = true,
    buffer = differ.args.source_buf,
  })
  vim.keymap.set("n", "<C-y>", function()
    o:apply();
  end, {
    nowait = true,
    noremap = true,
    silent = true,
    buffer = differ.args.source_buf,
  })
  vim.keymap.set("n", "<C-a>", function()
    o:apply_all();
  end, {
    nowait = true,
    noremap = true,
    silent = true,
    buffer = differ.args.source_buf,
  })
  vim.keymap.set("n", "<C-c>", function()
    o:clear();
  end, {
    nowait = true,
    noremap = true,
    silent = true,
    buffer = differ.args.source_buf,
  })
  return o
end

function Diff:preview()
end

function Diff:next()
end

function Diff:apply()
end

function Diff:apply_all()
end

function Diff:clear()
  vim.api.nvim_buf_clear_namespace(self.o.args.source_buf, self.o.namespace, self.o.args.line1 - 1, self.o.args.line2)
end

--



---Clean result table
---Retrieves a buffer line with strings.
---The buffer looks like this:
---{ "", "```", "content", "```", "" }
---This function shall remove all leading and trailing empty entries ("") and fences ("```").
---The fence can also contain a language, like this: "```markdown"
---
---@param text string[] The input string.
---@return string[]
M.__clean_result = function(text)
  local start = 1
  while start <= #text and (text[start] == "" or text[start]:match("^%s*%`%`%`")) do
    start = start + 1
  end
  local finish = #text
  while finish >= start and (text[finish] == "" or text[finish]:match("^%s*%`%`%`")) do
    finish = finish - 1
  end
  if start > finish then
    return {}
  else
    local result = {}
    for i = start, finish do
      table.insert(result, str.rtrim(text[i]))
    end
    return result
  end
end

M.namespace = vim.api.nvim_create_namespace("lungan.diff")

-- ---Find the Longest Common Subsequence
-- ---Given two strings:
-- ---Original: lorem ipsum
-- ---Modified: lorem kipsum
-- ---
-- ---Find the LCS:
-- ---    LCS of lorem ipsum and lorem kipsum is lorem ipsum.
-- ---@param left string the left string
-- ---@param right string the right string
-- ---@return string LCS
-- M.lcs = function(left, right)
--   local len1, len2 = #left, #right
--   local dp = {}
--
--   for i = 0, len1 do
--     dp[i] = {}
--     for j = 0, len2 do
--       if i == 0 or j == 0 then
--         dp[i][j] = ""
--       elseif left:sub(i, i) == right:sub(j, j) then
--         dp[i][j] = dp[i - 1][j - 1] .. left:sub(i, i)
--       else
--         if #dp[i - 1][j] > #dp[i][j - 1] then
--           dp[i][j] = dp[i - 1][j]
--         else
--           dp[i][j] = dp[i][j - 1]
--         end
--       end
--     end
--   end
--
--   return dp[len1][len2]
-- end

M.diff_buffer = function(args, data)
  local chat_data = extract_chat(data)
  if #chat_data > 0 then
    local code, lang = utils.get_code_fence(chat_data[#chat_data])
    local source = vim.api.nvim_buf_get_lines(args.source_buf, 0, -1, false)
    local new_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value("filetype", lang, { buf = new_buf })
    vim.api.nvim_buf_set_lines(new_buf, 0, -1, false, source)
    vim.api.nvim_buf_set_lines(new_buf, args.line1 - 1, args.line2, false, M.__clean_result(code))
    vim.cmd("buffer " .. new_buf)
    vim.cmd("diffthis")
    vim.api.nvim_set_current_win(args.source_win)
    -- vim.api.nvim_command("buffer " .. args.source_buf)
    vim.cmd("diffthis")
  else
    log.warn("lungan: No code found in chat response")
  end
end

-- M.diff = function(left, right)
--   local lcs_str = M.lcs(left, right)
--   local i, j, k = 1, 1, 1
--   local result = {}
--
--   while i <= #left or j <= #right do
--     if
--         k <= #lcs_str
--         and i <= #left
--         and j <= #right
--         and string.sub(left, i, i) == string.sub(right, j, j)
--         and string.sub(left, i, i) == string.sub(lcs_str, k, k)
--     then
--       table.insert(result, { string.sub(left, i, i), "@comment" })
--       i = i + 1
--       j = j + 1
--       k = k + 1
--     else
--       if i <= #left and (k >= #lcs_str or string.sub(left, i, i) ~= string.sub(lcs_str, k, k)) then
--         table.insert(result, { string.sub(left, i, i), "@label" })
--         i = i + 1
--       elseif j <= #right and (k >= #lcs_str or string.sub(right, j, j) ~= string.sub(lcs_str, k, k)) then
--         table.insert(result, { string.sub(right, j, j), "@error" })
--         j = j + 1
--       else
--         error("no match")
--       end
--     end
--   end
--   for _, line in ipairs(result) do
--     print("Result: " .. vim.inspect(line))
--   end
--   return result
-- end

M.clear_marks = function(args)
  vim.api.nvim_buf_clear_namespace(args.source_buf, M.namespace, args.line1 - 1, args.line2)
end

M.has_diffs = function()
  for _, delta_line in ipairs(M.delta) do
    for _, chunk in ipairs(delta_line) do
      if chunk.change ~= "=" then
        return true -- Found at least one diff
      end
    end
  end
  return false -- No diffs found at all
end

M.search_diff = function(position)
  for i, delta_line in ipairs(M.delta) do
    for j = 1, #delta_line do
      if M.delta[i][j].change ~= "=" then
        if i > position.line or (i == position.line and j > position.col) then
          return { line = i, col = j, delta = M.delta[i][j] }
        end
      end
    end
  end
  if M.has_diffs() then
    return M.search_diff({ line = -1, col = -1 });
  end
  return nil
end

M.clear_overlay = function(args, data)
  local func, err = load(data.fm.tree.clear)
  if not func then
    error(err)
  end
  func()(args, data)
end

--- Updates the extmark for a single line after a change has been applied to the buffer.
-- @param args table The original arguments.
-- @param line_idx number The 1-based index of the line within the diffed region.
M.update_marks = function(args, line_idx)
  local buf_line_nr = args.line1 + line_idx - 2 -- 0-indexed buffer line

  -- 1. Get the newly modified line text from the buffer
  local current_line_text = vim.api.nvim_buf_get_lines(args.source_buf, buf_line_nr, buf_line_nr + 1, true)[1]

  -- 2. Get the target text for this line
  local target_line_text = M.target_text[line_idx]

  -- 3. Re-calculate the diff for just this line
  local diff = require("luvar.diff").from_chars(current_line_text, target_line_text)
  local new_delta_for_line = diff:diff()

  -- 4. Update our master delta table with the new diff
  M.delta[line_idx] = new_delta_for_line

  -- 5. Re-create the virt_text table for the extmark
  local virt_text_delta = {}
  local line_has_changes = false
  for _, c in ipairs(new_delta_for_line) do
    if c.change == "=" then
      table.insert(virt_text_delta, { c.content, "diffLine" })
    elseif c.change == "+" then
      table.insert(virt_text_delta, { c.content, "diffAdded" })
      line_has_changes = true
    elseif c.change == "-" then
      table.insert(virt_text_delta, { c.content, "diffRemoved" })
      line_has_changes = true
    end
  end

  -- 6. Get the stored mark ID for this line
  local mark_id = M.line_marks[buf_line_nr]
  if not mark_id then
    log.warn("lungan: Could not find extmark ID to update for line " .. buf_line_nr)
    return
  end

  -- 7. Update the existing extmark by providing its ID
  vim.api.nvim_buf_set_extmark(args.source_buf, M.namespace, buf_line_nr, 0, {
    id = mark_id, -- THIS IS THE KEY: it tells Neovim to update the mark
    virt_text_pos = "overlay",
    virt_text = virt_text_delta,
    sign_text = "",
    sign_hl_group = line_has_changes and "@diff.delta" or "@diff.plus",
    hl_mode = "replace",
  })
end
-- M.update_marks = function(args, data, delta)
--   -- M.clear_overlay(args, data);
--
--   print("get extmarks: ")
--   local marks = vim.api.nvim_buf_get_extmarks(args.source_buf, M.namespace, { args.line1 + delta.line - 1, 0 },
--     { args.line1 + delta.line - 1, 0 }, {});
--   print(vim.inspect(marks))
-- end

M.preview = function(args, data)
  -- hide the chat window
  vim.api.nvim_win_close(args.win, true);

  M.target_text = extract_chat(data)
  M.delta = {}
  M.line_marks = {}

  local original_text = vim.api.nvim_buf_get_lines(args.source_buf, args.line1 - 1, args.line2, true)
  assert(#M.target_text == #original_text, "Original and new text must have the same number of lines")

  for i = 1, #M.target_text do
    local diff = require("luvar.diff").from_chars(original_text[i], M.target_text[i])
    local d = diff:diff()
    table.insert(M.delta, d)

    local line_has_changes = false
    local virt_text_delta = {}
    for _, c in ipairs(d) do
      if c.change == "=" then
        table.insert(virt_text_delta, { c.content, "diffLine" })
      elseif c.change == "+" then
        table.insert(virt_text_delta, { c.content, "diffAdded" })
        line_has_changes = true
      elseif c.change == "-" then
        table.insert(virt_text_delta, { c.content, "diffRemoved" })
        line_has_changes = true
      end
    end

    local buf_line = args.line1 + i - 2
    local mark_id = vim.api.nvim_buf_set_extmark(args.source_buf, M.namespace, buf_line, 0, {
      virt_text_pos = "overlay",
      virt_text = virt_text_delta,
      sign_text = "",
      sign_hl_group = line_has_changes and "@diff.delta" or "@diff.plus",
      hl_mode = "replace",
    })

    M.line_marks[buf_line] = mark_id
  end

  -- register the keymaps
  vim.keymap.set("n", "<C-n>", function()
    M.position = M.search_diff(M.position);
    vim.api.nvim_win_set_cursor(0, { M.position.line + args.line1 - 1, M.position.col - 1 })
  end, {
    nowait = true,
    noremap = true,
    silent = true,
    buffer = args.source_buffer,
  })
  -- vim.keymap.set("n", "<C-n>", function()
  --   if not M.position or not M.position.line then M.position = { line = 0, col = 0 } end
  --
  --   local next_pos = M.search_diff(M.position)
  --   if next_pos then
  --     M.position = next_pos
  --     local char_col = M.position.delta.position_a - 1
  --     print("move to position: ",
  --     vim.api.nvim_win_set_cursor(0, { M.position.line + args.line1 - 1, char_col })
  --   else
  --     log.info("lungan: No more differences.")
  --   end
  -- end, {
  --   nowait = true,
  --   noremap = true,
  --   silent = true,
  --   buffer = args.source_buf,
  -- })

  vim.keymap.set("n", "<C-y>", function()
    if not M.position or not M.position.delta then
      log.warn("lungan: No diff position to apply.")
      return
    end

    local pos = M.position or { line = 0, col = 0 }
    local line_idx = pos.line
    local buf_line_nr = args.line1 + line_idx - 2

    local _, cur_col = unpack(vim.api.nvim_win_get_cursor(0))
    local line_text = vim.api.nvim_buf_get_lines(args.source_buf, buf_line_nr, buf_line_nr + 1, true)[1]
    local new_line_text

    if pos.delta.change == "-" then
      local content_len = #pos.delta.content
      new_line_text = line_text:sub(1, cur_col) .. line_text:sub(cur_col + content_len + 1)
    elseif pos.delta.change == "+" then
      new_line_text = line_text:sub(1, cur_col) .. pos.delta.content .. line_text:sub(cur_col + 1)
    else
      return
    end

    vim.api.nvim_buf_set_lines(args.source_buf, buf_line_nr, buf_line_nr + 1, true, { new_line_text })

    -- This invalidates the old `pos` object by rebuilding M.delta[line_idx]
    M.update_marks(args, line_idx)

    -- *** THE FIX ***
    -- Instead of using the stale `pos` object, we search again using the known-good
    -- line number and the chunk index we just processed as our starting point.
    local next_pos = M.search_diff(pos)
    if next_pos then
      M.position = next_pos
      vim.api.nvim_win_set_cursor(0, { M.position.line + args.line1 - 1, M.position.col - 1 })
    else
      log.info(".")
      vim.notify("lungan: All differences applied", vim.log.levels.INFO);
      M.clear_marks(args);
      --TODO: close buffer
      M.position = nil
    end
  end, {
    nowait = true,
    noremap = true,
    silent = true,
    buffer = args.source_buf,
  })
  --
  --
  --
  --
  --
  -- vim.keymap.set("n", "<C-n>", function()
  --   local next_pos = M.search_diff(M.position)
  --   if next_pos then
  --     M.position = next_pos
  --     -- FIX: Use the character position from the diff data for the cursor, not the chunk index.
  --     local char_col = M.position.delta.position_a - 1
  --     vim.api.nvim_win_set_cursor(0, { M.position.line + args.line1 - 1, char_col })
  --   else
  --     log.info("lungan: No more differences.")
  --   end
  -- end, {
  --   nowait = true,
  --   noremap = true,
  --   silent = true,
  --   buffer = args.source_buf, -- Use args.source_buf consistently
  -- })
  --
  -- vim.keymap.set("n", "<C-y>", function()
  --   if not M.position or not M.position.delta then
  --     log.warn("lungan: No diff position to apply.")
  --     return
  --   end
  --
  --   local pos = M.position
  --   local line_idx = pos.line
  --   local buf_line_nr = args.line1 + line_idx - 2
  --
  --   local _, cur_col = unpack(vim.api.nvim_win_get_cursor(0))
  --   local line_text = vim.api.nvim_buf_get_lines(args.source_buf, buf_line_nr, buf_line_nr + 1, true)[1]
  --   local new_line_text
  --
  --   if pos.delta.change == "-" then
  --     local content_len = #pos.delta.content
  --     new_line_text = line_text:sub(1, cur_col) .. line_text:sub(cur_col + content_len + 1)
  --   elseif pos.delta.change == "+" then
  --     new_line_text = line_text:sub(1, cur_col) .. pos.delta.content .. line_text:sub(cur_col + 1)
  --   else
  --     return
  --   end
  --
  --   vim.api.nvim_buf_set_lines(args.source_buf, buf_line_nr, buf_line_nr + 1, true, { new_line_text })
  --   M.update_marks(args, line_idx)
  --
  --   -- FIX: Find the next position and handle the case where there are no more diffs.
  --   local next_pos = M.search_diff(pos)
  --   if next_pos then
  --     M.position = next_pos
  --     -- FIX: Use the correct character position for the cursor.
  --     local char_col = M.position.delta.position_a - 1
  --     vim.api.nvim_win_set_cursor(0, { M.position.line + args.line1 - 1, char_col })
  --   else
  --     log.info("lungan: All differences applied.")
  --     M.position = nil -- Clear the position to indicate we are done.
  --   end
  -- end, {
  --   nowait = true,
  --   noremap = true,
  --   silent = true,
  --   buffer = args.source_buf,
  -- })

  vim.keymap.set("n", "<C-a>", function()
    local func, err = load(data.fm.tree.commit)
    if not func then
      error(err)
    end
    func()(args, data)
  end, {
    nowait = true,
    noremap = true,
    silent = true,
    buffer = args.source_buf,
  })

  vim.keymap.set("n", "<C-c>", function()
    M.clear_overlay(args, data)
  end, {
    nowait = true,
    noremap = true,
    silent = true,
    buffer = args.source_buf,
  })
  --
  --
  --
  --
  --
  --
  --

  --
  --
  -- vim.keymap.set("n", "<C-y>", function()
  --   print("replace diff@" .. M.position.line .. ":" .. M.position.col .. " -> " .. vim.inspect(M.position.delta))
  --   if M.position.delta.change == "-" then
  --     print("delete char")
  --     vim.fn.feedkeys('x', 'n')
  --   elseif M.position.delta.change == "+" then
  --     print("add char")
  --     local esc = vim.api.nvim_replace_termcodes('<Esc>', true, true, true)
  --     vim.api.nvim_feedkeys('i' .. M.position.cotent .. esc, 'n', false)
  --   else
  --     print("ohua")
  --   end
  --   M.update_marks(args, data, M.position);
  -- end, {
  --   nowait = true,
  --   noremap = true,
  --   silent = true,
  --   buffer = args.source_buf,
  -- })
  vim.keymap.set("n", "<C-a>", function()
    local func, err = load(data.fm.tree.commit)
    if not func then
      error(err)
    end
    func()(args, data)
  end, {
    nowait = true,
    noremap = true,
    silent = true,
    buffer = args.source_buf,
  })
  vim.keymap.set("n", "<C-c>", function()
    M.clear_overlay(args, data);
  end, {
    nowait = true,
    noremap = true,
    silent = true,
    buffer = args.source_buf,
  })
end

M.replace = function(args, data)
  local user_chat = extract_chat(data)
  M.clear_marks(args)
  vim.api.nvim_buf_set_lines(args.source_buf, args.line1 - 1, args.line2, true, user_chat)
end

return M
