local tbl = {}

tbl.set_with_path = function(t, path, value)
    local keys = {}
    for s in string.gmatch(path, "[^%.]+") do
        table.insert(keys, s)
    end
    local last = table.remove(keys, #keys)
    local current_table = t
    for _, key in ipairs(keys) do
        if not current_table[key] then
            current_table[key] = {}
        end
        current_table = current_table[key]
    end
    current_table[last] = value
end

return tbl
