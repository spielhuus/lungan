local uv = require("luv")
local log = require("lungan.log")
local str = require("lungan.str")

local Http = {}

function Http:get(url, on_exit, on_stdout, on_stderr)
	self.stdout = {}
	self.stderr = {}

	local stdout = uv.new_pipe()
	local stderr = uv.new_pipe()

	local handle = uv.spawn("curl", {
		args = { "--silent", "--no-buffer", "-X", "GET", url },
		stdio = { nil, stdout, stderr },
	}, function(code)
		if on_exit then
			on_exit(code, self:response())
		end
	end)

	uv.read_start(stdout, function(err, data)
		if err then
			return log.error("STDERR: " .. err)
		end
		if data then
			local clean_table = str.clean_table({ data })
			for _, token in ipairs(clean_table) do
				table.insert(self.stdout, token)
			end
		end
	end)

	uv.read_start(stderr, function(err, data)
		if err then
			return log.error("STDOUT: " .. err)
		end
		if data then
			log.trace("STDOUT: " .. data)
			local clean_table = str.clean_table({ data })
			for _, token in ipairs(clean_table) do
				table.insert(self.stderr, token)
			end
		end
	end)

	if not on_exit then
		uv.run()
		return 0, self:response()
	end
end

function Http:post(request, on_exit, on_stdout, on_stderr)
	self.stdout = {}
	self.stderr = {}
	local args = { "--silent", "--no-buffer", "-X", "POST" }
	if request.headers then
		for _, header in ipairs(request.headers) do
			table.insert(args, header)
		end
	end

	if request.body then
		table.insert(args, "-d")
		table.insert(args, request.body)
	end
	table.insert(args, request.url)

	log.trace("curl ", args)

	local stdout = uv.new_pipe()
	local stderr = uv.new_pipe()

	local handle, pid
	handle, pid = uv.spawn("curl", {
		args = args,
		stdio = { nil, stdout, stderr },
	}, function(code)
		log.debug("EXIT: " .. code)
		if on_exit then
			on_exit(code, self:response())
		end
		uv.close(stdout)
		uv.close(stderr)
		uv.close(handle)
	end)
	log.trace("process opened", handle, pid)

	uv.read_start(stderr, function(err, data)
		log.trace("STDERR: " .. (err or "nil") .. " " .. require("lungan.str").to_string(data))
		if err then
			return log.error("STDERR: " .. err)
		end
		if data then
			local clean_table = str.clean_table({ data })
			for _, token in ipairs(clean_table) do
				table.insert(self.stderr, token)
			end
		end
	end)

	uv.read_start(stdout, function(err, data)
		log.trace("STDOUT: " .. (err or "nil") .. " " .. require("lungan.str").to_string(data))
		if err then
			return log.error("STDOUT: " .. err)
		end
		if data then
			table.insert(self.stdout, data)
			on_stdout(err, { data })
		end
	end)

	if not on_exit then
		uv.run()
		return 0, self:response()
	end
end

function Http:response()
	return table.concat(self.stdout, "")
end

function Http:new()
	local o = {}
	setmetatable(o, { __index = self })
	o.stdout = {}
	o.stderr = {}
	return o
end

return Http
