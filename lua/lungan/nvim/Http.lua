local log = require("lungan.log")
local str = require("lungan.str")

local Http = {}
Http.__index = Http

---HTTP client using curl
function Http:new()
	local o = {}
	setmetatable(o, self)
	o.stdout = {}
	o.stderr = {}
	return o
end

local function handle_output(self, data, handler)
	if data then
		log.trace(handler(data))
		local clean_table = str.clean_table(data)
		if #clean_table > 0 then
			for _, token in ipairs(clean_table) do
				table.insert(self.stdout, token)
			end
		end
	end
end

local function handle_exit(self, code, on_exit)
	self.job_id = nil
	if on_exit then
		on_exit(code, self:response())
	else
		return code, self:response()
	end
end

---Sends an HTTP GET request to the specified URL.
---
---If `on_exit` is `nil`, the method will not wait for the job to
---complete before returning; instead, it will return immediately with
---an exit status indicating the job's completion.
---
---When on_stdout and on_stderr are not set the responses will be collected
---and can then be accessed with Http:response()
---
--- @param url string The URL to send the GET request to.
--- @param on_exit function|nil An optional callback function to be called when the job exits.
--- @param on_stdout function|nil An optional callback function to handle standard output data.
--- @param on_stderr function|nil An optional callback function to handle standard error data.
--- @return nil If an exit callback is provided, returns immediately. Otherwise,
---                waits for job completion and returns the response.
function Http:get(url, on_exit, on_stdout, on_stderr)
	self.stdout = {}
	self.stderr = {}
	local status = -1
	local args = { "curl", "--silent", "--no-buffer", "-X", "GET", url }
	log.debug("GET:" .. table.concat(args, " "))
	self.job_id = vim.fn.jobstart(table.concat(args, " "), {
		on_stdout = on_stdout or function(_, data, _)
			handle_output(self, data, log.trace)
		end,
		on_stderr = on_stderr or function(_, data, _)
			handle_output(self, data, print)
		end,
		on_exit = on_exit or function(_, code)
			return handle_exit(self, code, on_exit)
		end,
	})
	if not on_exit then
		vim.fn.jobwait({ self.job_id }, -1)
		return handle_exit(self, status, nil)
	end
end

--- Sends a POST request using `curl`.
--
---If `on_exit` is `nil`, the method will not wait for the job to
---complete before returning; instead, it will return immediately with
---an exit status indicating the job's completion.
---
---When on_stdout and on_stderr are not set the responses will be collected
---and can then be accessed with Http:response()
---
-- @param self The instance of the Http class.
-- @param request A table containing the request details:
--   - `url` (string): The URL to send the POST request to.
--   - `headers` (table, optional): A list of headers to include in the request.
--   - `body` (string, optional): Data to be sent in the body of the request.
--- @param on_exit function|nil An optional callback function to be called when the job exits.
--- @param on_stdout function|nil An optional callback function to handle standard output data.
--- @param on_stderr function|nil An optional callback function to handle standard error data.
--- @return nil If an exit callback is provided, returns immediately. Otherwise,
---                waits for job completion and returns the response.
function Http:post(request, on_exit, on_stdout, on_stderr)
	self.stdout = {}
	self.stderr = {}
	local status = -1
	local args = { "curl", "--silent", "--no-buffer", "-X", "POST" }
	if request.headers then
		for _, header in ipairs(request.headers) do
			table.insert(args, header)
		end
	end

	if request.body then
		table.insert(args, "-d")
		table.insert(args, vim.fn.shellescape(request.body))
	end
	table.insert(args, "'" .. request.url .. "'")
	log.debug("POST" .. table.concat(args, " "))

	self.job_id = vim.fn.jobstart(table.concat(args, " "), {
		on_stdout = on_stdout or function(_, data, _)
			handle_output(self, data, log.trace)
		end,
		on_stderr = on_stderr or function(_, data, _)
			handle_output(self, data, print)
		end,
		on_exit = on_exit or function(_, code)
			return handle_exit(self, code, on_exit)
		end,
	})
	if not on_exit then
		vim.fn.jobwait({ self.job_id }, -1)
		return handle_exit(self, status, nil)
	end
end

--- Cancels the current HTTP request by stopping the associated job.
--- @return integer|nil, string Returns the job id and an error message if cancelling fails
function Http:cancel()
	if self.job_id ~= nil then
		local result = vim.fn.jobstop(self.job_id)
		if result == 0 then
			return self.job_id, "failed to stop job: " .. self.job_id
		end
		self.job_id = nil
	end
	return nil, ""
end

---Return the retrieved body
---@return string the body
function Http:response()
	return table.concat(self.stdout, "")
end

return Http
