local uv = require("luv")
local log = require("lungan.log")

---@class LuvHttp
---@as Http
local LuvHttp = {}

---HTTP client using curl
function LuvHttp:new()
	local o = {}
	setmetatable(o, { __index = self })
	o.stdout = {}
	o.stderr = {}
	return o
end

function LuvHttp:get(url, on_exit, on_stdout, on_stderr)
	self.stdout = {}
	self.stderr = {}

	local stdout = uv.new_pipe()
	local stderr = uv.new_pipe()

	self.job_id = uv.spawn("curl", {
		args = { "--silent", "--no-buffer", "-X", "GET", url },
		stdio = { nil, stdout, stderr },
	}, function(code) -- on_exit
		log.trace("EXIT: " .. code)
		uv.close(stdout)
		uv.close(stderr)
		uv.close(self.job_id)
		if on_exit then
			on_exit(code, self:response())
		end
	end)

	uv.read_start(stderr, on_stderr or function(err, data)
		if data then
			log.trace("STDERR:", err, data)
			if #data > 0 then
				table.insert(self.stderr, data)
			end
		end
	end)

	uv.read_start(stdout, on_stdout or function(err, data)
		if data then
			log.trace("STDOUT:", err, data)
			if #data > 0 then
				table.insert(self.stdout, data)
			end
		end
	end)

	if not on_exit then
		local res = uv.run()
		return res, self:response()
	end
	return self.job_id
end

function LuvHttp:post(request, on_exit, on_stdout, on_stderr)
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
	log.debug("curl ", args)

	local stdout = uv.new_pipe()
	local stderr = uv.new_pipe()

	local handle, pid
	handle, pid = uv.spawn("curl", {
		args = args,
		stdio = { nil, stdout, stderr },
	}, function(code)
		log.debug("EXIT: " .. code)
		uv.close(stdout)
		uv.close(stderr)
		uv.close(handle)
		if on_exit then
			on_exit(code, self:response())
		end
	end)

	uv.read_start(stderr, on_stderr or function(err, data)
		if data then
			log.trace("STDERR:", err, data)
			if #data > 0 then
				table.insert(self.stderr, data)
			end
		end
	end)

	uv.read_start(stdout, on_stdout or function(err, data)
		if data then
			log.trace("STDOUT:", err, data)
			if #data > 0 then
				table.insert(self.stdout, data)
			end
		end
	end)

	if not on_exit then
		uv.run()
		return 0, self:response()
	end
	return handle, pid
end

function LuvHttp:response()
	return table.concat(self.stdout, "")
end

return LuvHttp
