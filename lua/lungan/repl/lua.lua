local Lua = {}

function Lua:_result_clean(line)
    local indexes = {}
    for i, v in ipairs(self.messages) do
        if v.line == line then
            table.insert(indexes, i)
        end
    end
    for _, del in ipairs(indexes) do
        table.remove(self.messages, del)
    end
end

function Lua:run(cell)
    local handle = io.popen("lua -e '" .. vim.fn.shellescape(vim.json.encode(cell.text)) .. "'")
    if not handle then
        error("io.popen returned nil, is it supported on your system?")
    end
    local result = handle:read("*a")
    if not self.response.stdout then
        self.response.stdout = {}
    end
    for _, l in ipairs(vim.split(result, "\n")) do
        table.insert(self.response.stdout, l)
    end
    handle:close()

    local response = {
        line = cell.to,
        stdout = self.response.stdout,
        stderr = self.response.stderr,
        out = self.response.out,
    }
    self:_result_clean(cell.to)
    table.insert(self.messages, response)
    self.response = {}
    -- local env = setmetatable({}, { __index = _G })
    -- local func, errmsg = load(cell.text, "=(execute)", "t", env)
    -- if func then
    --     local old_stdout = io.stdout
    --     local t = {}
    --     io.stdout = {
    --         write = function(_, ...)
    --             for _, v in ipairs({ ... }) do
    --                 print("STDOUT:" .. v)
    --                 table.insert(t, tostring(v))
    --             end
    --         end,
    --     }
    --     func()
    --     io.stdout = old_stdout
    --     local stdout = table.concat(t, "")
    --     print("RES_OUT" .. vim.inspect(stdout))
    --     print("RES_DATA" .. vim.inspect(env))
    -- else
    --     error(errmsg)
    -- end
end

function Lua:new(o, options, on_message)
    o = o or {}
    setmetatable(o, { __index = self })
    o.options = options
    o.term = {}
    o.messages = {}
    o.on_message = on_message
    o.count = 1
    o.response = {}
    o.sent = {}
    return o
end

return Lua
