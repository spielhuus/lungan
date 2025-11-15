-- Splits a string into a table of single characters.
local function string_to_char_table(str)
  if str == nil or str == "" then return {} end
  local t = {}
  -- The pattern now uses %z for the null byte to avoid terminating the string.
  local utf8_pattern = "([%z\1-\x7F\xC2-\xF4][\x80-\xBF]*)"
  for char in string.gmatch(str, utf8_pattern) do
    table.insert(t, char)
  end
  return t
end

-- Splits a string into a table of lines.
local function string_to_line_table(str)
  local t = {}
  if str == nil or str == '' then return t end

  local str_with_nl = str .. '\n'

  for line in str_with_nl:gmatch("(.-)[\r\n]") do
    table.insert(t, line)
  end
  return t
end

local function clone(t)
  local out = {}
  for k, v in pairs(t) do out[k] = v end
  return out
end

---@class DiffItem
---@field change DiffType
---@field position_a number
---@field position_b number
---@field content string

---@alias DiffType '+'|'-'|'='

---@class Diff
---@field left string[]
---@field right string[]
---@field trace table
local Diff = {}
Diff.__index = Diff

--- Creates a new Diff object.
---@param left table The "left" sequence to compare (a table of strings).
---@param right table The "right" sequence to compare (a table of strings).
---@return Diff The new Diff instance.
function Diff:new(left, right)
  local o = {}
  setmetatable(o, { __index = self, __name = "Diff" })
  o.left = left
  o.right = right
  o.trace = o:shortest_edit()
  return o
end

--- Creates a new Diff object by comparing two strings character by character.
---@param left_string string The "left" string.
---@param right_string string The "right" string.
---@return Diff The new Diff instance.
function Diff.from_chars(left_string, right_string)
  local left_table = string_to_char_table(left_string)
  local right_table = string_to_char_table(right_string)
  return Diff:new(left_table, right_table)
end

--- Creates a new Diff object by comparing two strings line by line.
---@param left_string string The "left" string.
---@param right_string string The "right" string.
---@return Diff The new Diff instance.
function Diff.from_lines(left_string, right_string)
  local left_table = string_to_line_table(left_string)
  local right_table = string_to_line_table(right_string)
  return Diff:new(left_table, right_table)
end

function Diff:shortest_edit()
  local n = #self.left;
  local m = #self.right;
  local max = n + m;
  local offset = max + 1;

  local v = {}
  for i = 1, 2 * max + 1 do
    v[i] = -1;
  end
  v[1 + offset] = 0;

  local trace = {};

  for d = 0, max do
    table.insert(trace, clone(v));

    for k = -d, d, 2 do
      local x;

      if (k == -d or (k ~= d and v[k + offset - 1] < v[k + offset + 1])) then
        -- Move down (insertion)
        x = v[k + offset + 1];
      else
        -- Move right (deletion)
        x = v[k + offset - 1] + 1;
      end

      local y = x - k;

      while (x < n and y < m and self.left[x + 1] == self.right[y + 1]) do
        x = x + 1;
        y = y + 1;
      end

      v[k + offset] = x;

      if (x >= n and y >= m) then
        table.insert(trace, clone(v));
        return trace;
      end
    end
  end
end

--- Computes the differences between the left and right inputs.
---@return DiffItem[] A table of DiffItem objects representing the changes.
function Diff:diff()
  local n = #self.left;
  local m = #self.right;
  local max = n + m;
  local offset = max + 1;

  local result = {};
  local x = n;
  local y = m;
  local prev_k, prev_y, edit_type;

  for d = #self.trace - 2, 0, -1 do
    local v = self.trace[d + 1];
    local k = x - y;

    if (k == -d or (k ~= d and ((v[k + offset - 1] or -1) < (v[k + offset + 1])))) then
      prev_k = k + 1
      edit_type = "+";
    else
      prev_k = k - 1
      edit_type = "-";
    end

    local prev_x = v[prev_k + offset];
    prev_y = prev_x - prev_k;

    while (x > prev_x and y > prev_y) do
      table.insert(result, {
        change = "=",
        position_a = x,
        position_b = y,
        content = self.left[x],
      });
      x = x - 1;
      y = y - 1;
    end

    if (d > 0) then
      if (edit_type == "+") then
        table.insert(result, {
          change = "+",
          position_a = 0,
          position_b = y,
          content = self.right[y],
        });
      else -- DiffType.Delete
        table.insert(result, {
          change = "-",
          position_a = x,
          position_b = 0,
          content = self.left[x],
        });
      end
    end

    x = prev_x;
    y = prev_y;

    if (x == 0 and y == 0) then break; end
  end

  -- Reverse the results to get the correct chronological order
  local reversed_result = {}
  for i = #result, 1, -1 do
    table.insert(reversed_result, result[i])
  end

  return reversed_result
end

return Diff
