local log = require("log")
local str = require("lungan.str")

local Http = {}
Http.__index = Http

--- Executes a GET request to the specified URL using `curl`.
---
---This function initiates an HTTP GET request via `curl`, capturing the output and errors in separate buffers. It supports custom callback functions for handling standard output (`on_stdout`), standard error (`on_stderr`), and exit status (`on_exit`). If no `on_exit` is provided, the function waits for the job to complete and returns the response.
---
---@param url string The URL to which the GET request will be sent.
---@param on_exit function (optional) A callback function called upon completion of the HTTP request. This function receives the exit code as its first argument and a table containing the response data as its second argument.
---@param on_stdout function (optional) A callback function for handling standard output from `curl`. The default behavior is to log the output at trace level.
---@param on_stderr function (optional) A callback function for handling standard error from `curl`. The default behavior is to log the error at trace level.
---@return
---- If no `on_exit` callback is provided, returns a tuple containing:
---  - An integer representing the exit status of the curl command.
---  - A table containing the response data obtained from the server.
---- Otherwise, does not return anything and relies on the custom `on_exit` function to handle completion logic.
---
---@usage
---local http = require('your_module')
---http:get("http://example.com", function(code, response)
---  if code == 0 then
---    print(vim.inspect(response))
---  else
---    print("Failed with exit code: " .. code)
---  end
---end)
function Http:get(url, on_exit, on_stdout, on_stderr)
	self.stdout = {} -- clean previous session
	self.stderr = {}
	local status = -1
	local args = { "curl", "--silent", "--no-buffer", "-X", "GET" }
	table.insert(args, url)
	log.debug("GET" .. table.concat(args, " "))
	self.job_id = vim.fn.jobstart(table.concat(args, " "), {
		on_stdout = on_stdout or function(_, data, _)
			if data then
				log.trace("STDOUT: " .. vim.inspect(data))
				local clean_table = str.clean_table(data)
				if #clean_table > 0 then
					for _, token in ipairs(clean_table) do
						table.insert(self.stdout, token)
					end
				end
			end
		end,
		on_stderr = on_stderr or function(_, data, _)
			if data then
				local clean_table = str.clean_table(data)
				if #clean_table > 0 then
					for _, token in ipairs(clean_table) do
						table.insert(self.stderr, token)
					end
				end
			end
		end,
		on_exit = on_exit or function(_, code)
			status = code
			if on_exit then
				print("call on_exit")
				on_exit(code, self:response())
			end
		end,
	})
	if not on_exit then
		vim.fn.jobwait({ self.job_id }, -1)
		self.job_id = nil
		return status, self:response()
	end
end

function Http:post(request, on_exit, on_stdout, on_stderr)
	self.stdout = {} -- clean previous session
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
	table.insert(args, request.url)
	log.debug("POST" .. table.concat(args, " "))
	self.job_id = vim.fn.jobstart(table.concat(args, " "), {
		on_stdout = on_stdout or function(_, data, _)
			log.trace("<<<", data)
			if data then
				local clean_table = str.clean_table(data)
				if #clean_table > 0 then
					for _, token in ipairs(clean_table) do
						table.insert(self.stdout, token)
					end
				end
			end
		end,
		on_stderr = on_stderr or function(_, data, _)
			if data then
				local clean_table = str.clean_table(data)
				if #clean_table > 0 then
					for _, token in ipairs(clean_table) do
						table.insert(self.stderr, token)
					end
				end
			end
		end,
		on_exit = on_exit or function(_, code)
			status = code
			if on_exit then
				print("call on_exit")
				on_exit(code, self:response())
			end
		end,
	})
	if not on_exit then
		print("wait for job")
		vim.fn.jobwait({ self.job_id }, -1)
		self.jobid = nil
		return status, self:response()
	end
end

function Http:response()
	return table.concat(self.stdout, "")
end

function Http:new()
	local o = {}
	setmetatable(o, self)
	o.stdout = {}
	o.stderr = {}
	return o
end

return Http
