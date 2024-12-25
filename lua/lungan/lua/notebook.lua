local Python = require("lungan.repl.Python")

local notebook = {}

local ipyrepl = nil

notebook.convert = function(md)
	local result = {}
	local callback = function(_, message, _)
		if message.out ~= nil then
			table.insert(result, "")
			table.insert(result, "```out")
			for _, val in ipairs(message.out) do
				table.insert(result, val)
			end
			table.insert(result, "```")
		end
		if message.stdout ~= nil then
			table.insert(result, "")
			table.insert(result, "```result")
			for _, val in ipairs(message.stdout) do
				table.insert(result, val)
			end
			table.insert(result, "```")
		end
		if message.stderr ~= nil then
			table.insert(result, "")
			table.insert(result, "```error")
			for _, val in ipairs(message.stderr) do
				table.insert(result, val)
			end
			table.insert(result, "```")
		end
		if message.images ~= nil then
			table.insert(result, "")
			table.insert(result, "```image")
			for _, val in ipairs(message.images) do
				table.insert(result, val.base64)
			end
			table.insert(result, "```")
		end
	end
	for _, entry in ipairs(md.tree) do
		if entry["type"] == "header" then
			table.insert(result, string.rep("#", entry.heading) .. " " .. entry.text)
		elseif entry["type"] == "list" then
			table.insert(result, string.rep(" ", entry.level) .. entry.char .. " " .. entry.text)
		elseif entry["type"] == "paragraph" then
			table.insert(result, entry.text)
		elseif entry["type"] == "code" then
			table.insert(result, "```" .. entry.lang)
			table.insert(result, entry.text)
			table.insert(result, "```")
			-- execute the code
			if entry.lang == "py" or entry.lang == "python" then
				if ipyrepl == nil then
					local mes
					ipyrepl, mes = Python:new(require("lungan.repl.NvimTerm"):new(), callback)
					if not ipyrepl then
						error("Unable to load Python: " .. mes)
					end
				end
				entry.text = entry.text .. "\nlungan.plots()"
				ipyrepl:send(entry)
				ipyrepl:wait()
			end
		else
			table.insert(result, entry.text)
		end
	end
	return result
end

return notebook
