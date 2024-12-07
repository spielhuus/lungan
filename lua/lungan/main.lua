local commands = {
	convert = {
		help = "convert a markdown file",
		fn = function(args)
			print("convert" .. args["--input"] .. " -> " .. args["--output"])
			if rawget(args, "--input") == nil or rawget(args, "--output") == nil then
				print("ERROR: input and output file must be provided.")
			end

			local file = io.open(args["--input"], "r")
			if not file then
				return nil
			end

			local lines = {}
			for line in file:lines() do
				table.insert(lines, line)
			end

			file:close()

			-- write the result
			local outfile = io.open(args["--output"], "w")
			if not outfile then
				return nil
			end
			local md = require("lungan.markdown"):new({}, lines)
			local result = require("lungan.lua.notebook").convert(md)
			for _, line in ipairs(result) do
				outfile:write(line)
				outfile:write("\n")
			end
			outfile:close()
		end,
	},
}

local function print_usage()
	print("lungan cli application usage: `lungan command [args]`\n")
	for k, v in pairs(commands) do
		print(k .. ": " .. v.help)
	end
	print("")
end

local function dispatch(args)
	if #args == 0 then
		print("ARGS not found")
		print_usage()
	else
		local command = args[1]
		local parsed_args = {}
		local i = 2
		while i <= #args do
			if args[i] == "--input" then
				parsed_args[args[i]] = args[i + 1]
			elseif args[i] == "--output" then
				parsed_args[args[i]] = args[i + 1]
			end
			i = i + 1
		end
		commands[command].fn(parsed_args)
	end
end

if arg ~= nil and arg[-1] ~= nil then
	dispatch(arg)
else
	print("library")
end
