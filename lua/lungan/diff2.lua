local log = require("lungan.log")
local str = require("lungan.str")
local utils = require("lungan.utils")

--- Compares two diff chunks to see if they are semantically identical.
-- @param a table The first diff chunk.
-- @param b table The second diff chunk.
-- @return boolean True if they are the same, false otherwise.
local function diff_equal(a, b)
  if a == nil and b == nil then return true end
  if a == nil or b == nil then return false end

  return a.change == b.change
      and a.content == b.content
      and a.position_a == b.position_a
      and a.position_b == b.position_b
end

-- the diff class type

---@class DiffClass
---@field args table
---@field data table
---@field delta table
local DiffClass = {}
DiffClass.__index = DiffClass

function DiffClass:new(options, args, data)
  assert(options, "options is required")
  assert(args, "args is required")
  assert(data, "data is required")
  local o = {}
  setmetatable(o, { __index = self, __name = "DiffClass" })
  o.options = options
  o.args = args
  o.data = data
  o.delta = {}
  o.position = { line = -1, col = -1 }
  o.namespace = vim.api.nvim_create_namespace("lungan.diff");
  vim.notify("lungan: All differences applied", vim.log.levels.INFO);
  o.result = o:extract_chat();
  o:update(0)
  return o
end

function DiffClass:update(line_idx)
  error("method update not implemented: ", line_idx)
end

---Clean result table
---Retrieves a buffer line with strings.
---The buffer looks like this:
---{ "", "```", "content", "```", "" }
---This function shall remove all leading and trailing empty entries ("") and fences ("```").
---The fence can also contain a language, like this: "```markdown"
---
---@param text string[] The input string.
---@return string[]
function DiffClass:clean_result(text)
  local start = 1
  while start <= #text and (text[start] == "" or text[start]:match("^%`%`%%s*`")) do
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

---Extract the last chat result from the data table
function DiffClass:extract_chat()
  local message = {}
  -- extract the last assistant message
  for m in self.data:iter() do
    if m.type == "chat" and m.role == "assistant" then
      message = self:clean_result(vim.split(m.text, "\n"))
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
      if i - begin_line > self.args.line2 - self.args.line1 + 1 then
        if require("str").trim(line) ~= "" then
          print("NON empty extra line: ", line)
        else
          print("empty extra line")
        end
      else
        table.insert(result, line)
      end
    end
  end

  return result
end

function DiffClass:has_diffs()
  for _, delta_line in ipairs(self.delta) do
    for _, chunk in ipairs(delta_line) do
      if chunk.change ~= "=" then
        return true -- Found at least one diff
      end
    end
  end
  return false -- No diffs found at all
end

function DiffClass:apply_all()
  error("apply_all is not implemented")
end

-- inplement the inline diff

local InlineDiff = {}
InlineDiff.__index = InlineDiff
setmetatable(InlineDiff, { __index = DiffClass })

--- Updates the extmark for a single line after a change has been applied to the buffer.
-- @param args table The original arguments.
function InlineDiff:update()
  vim.api.nvim_buf_clear_namespace(self.args.source_buf, self.namespace, self.args.line1 - 1, self.args.line2 + 1)
  local original_text = vim.api.nvim_buf_get_lines(self.args.source_buf, self.args.line1 - 1, self.args.line2, true)
  assert(#self.result == #original_text, "Original and new text must have the same number of lines")
  self.delta = {}
  for i = 1, #self.result do
    local diff = require("luvar.diff").from_chars(original_text[i], self.result[i])
    local d = diff:diff()
    table.insert(self.delta, d)

    local line_has_changes = false
    local virt_text_delta = {}
    local virt_text_len = 0
    for _, c in ipairs(d) do
      if c.change == "=" then
        table.insert(virt_text_delta, { c.content, "diffLine" })
      elseif c.change == "+" then
        if i == self.position.line and diff_equal(self.position.delta, c) then
          table.insert(virt_text_delta, { c.content, "diffText" })
        else
          table.insert(virt_text_delta, { c.content, "diffAdded" })
        end
        line_has_changes = true
      elseif c.change == "-" then
        if i == self.position.line and diff_equal(self.position.delta, c) then
          table.insert(virt_text_delta, { c.content, "diffText" })
        else
          table.insert(virt_text_delta, { c.content, "diffRemoved" })
        end
        line_has_changes = true
      end
      virt_text_len = virt_text_len + vim.fn.strwidth(c.content)
    end

    local buf_line = self.args.line1 + i - 2
    vim.api.nvim_buf_set_extmark(self.args.source_buf, self.namespace, buf_line, 0, {
      virt_text_pos = "overlay",
      virt_text = virt_text_delta,
      sign_text = "",
      sign_hl_group = line_has_changes and "@diff.delta" or "@diff.plus",
      hl_mode = "replace",
    })
  end
end

function InlineDiff:search_next(position)
  for i, delta_line in ipairs(self.delta) do
    for j = 1, #delta_line do
      if self.delta[i][j].change ~= "=" then
        if i > position.line or (i == position.line and j > position.col) then
          return { line = i, col = j, delta = self.delta[i][j] }
        end
      end
    end
  end
  if self:has_diffs() then
    return self:search_next({ line = -1, col = -1 });
  end
  return nil
end

function InlineDiff:apply_all()
  vim.api.nvim_buf_set_lines(self.args.source_buf, self.args.line1 - 1, self.args.line2, true, self.result)
end

function InlineDiff:diff_item(line, col)
  local diffline = self.delta[line - self.args.line1 + 1];
  for _, d in ipairs(diffline) do
    if d.change ~= "=" then
      if d.position_a == col + 1 or d.position_b == col + 1 then
        return d
      end
    end
  end
  return nil
end

function InlineDiff:apply()
  local line = self.position.line + self.args.line1 - 1;
  local line_text = vim.api.nvim_buf_get_lines(
    self.args.source_buf, line - 1, line, true)[1]
  local new_line_text
  if self.position.delta.change == "-" then
    local content_len = #self.position.delta.content
    new_line_text = line_text:sub(1, self.position.delta.position_a - 1) ..
        line_text:sub(self.position.delta.position_a - 1 + content_len + 1)
  elseif self.position.delta.change == "+" then
    new_line_text = line_text:sub(1, self.position.delta.position_b - 1) ..
        self.position.delta.content .. line_text:sub(self.position.delta.position_b - 1 + 1)
  else
    return
  end
  vim.api.nvim_buf_set_lines(self.args.source_buf, line - 1, line, true, { new_line_text })
end

-- the diff class

local Diff = {}
Diff.__index = Diff

function Diff:new(differ)
  local o = {}
  setmetatable(o, { __index = self, __name = "Diff" });
  o.differ = differ;
  o.position = { line = 0, col = 0 }

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
  self.differ.position = self.differ:search_next(self.differ.position);
  if self.differ.position then
    self.differ:update();
  else
    log.info("lungan: No more differences.")
    self.differ.position = { line = -1, col = -1 }
    self.differ:update()
  end
end

function Diff:apply()
  self.differ:apply();
  self:next();
  print(vim.inspect(self.differ.position))
end

function Diff:apply_all()
  self.differ:apply_all();
  self:clear();
end

function Diff:clear()
  vim.api.nvim_buf_clear_namespace(self.differ.args.source_buf, self.differ.namespace, 0, -1) -- self.differ.args.line1, self.differ.args.line2)
end

return {
  inline = function(options, args, data)
    local idiff = InlineDiff:new(options, args, data)
    Diff:new(idiff)
  end
}
