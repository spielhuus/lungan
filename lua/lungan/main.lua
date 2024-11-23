local commands = {
	convert = {
		help = "convert a markdown file",
		fn = function(args)
			print(table.concat(args, ", "))
			if rawget(args, "--input") == nil or rawget(args, "--output") == nil then
				print("ERROR: input and output file must be provided.")
			end
			print("covert")
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
		print_usage()
	else
		local command = args[1]
		local parsed_args = {}
		local i = 2
		while i <= #args do
			if args[i] == "--input" then
				args[args[i]] = args[i + 1]
			elseif args[i] == "--output" then
				args[args[i]] = args[i + 1]
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
