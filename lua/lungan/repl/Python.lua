local log = require("lungan.log")
local str = require("lungan.str")

---@class IPython: IRepl
---@field prologue table
---@field on_message function
---@field term ITerm
local IPython = {}

local STARTUP_TIMEOUT = 5000
local EXECUTE_TIMEOUT = 10000

local ipython_cmd = {
	"ipython",
	"--simple-prompt",
	"--no-banner",
	"--quiet",
	"--no-pprint",
	"--no-color-info",
	"--no-term-title",
	"--colors=NoColor",
}

local state = {
	IDLE = 1,
	START = 2, -- server is starting
	WAIT = 3, -- wait for response
	CONT = 4, -- expect more content
}

function IPython:__parse_image(out)
	if out.stdout == nil then
		return out
	end

	local images = {}
	local image_chunks = {}
	local stdout = {}
	local width, height, data
	local index = 1
	local collect = false
	while index <= #out.stdout do
		if out.stdout[index]:match("PLOTS%([%d]+,[%d]+,.*") then
			if collect == true then
				error("start image while collecting")
			end
			width, height, data = out.stdout[index]:match("PLOTS%(([%d]+),([%d]+),(.*)")
			if data:match(".*%)$") then
				data = out.stdout[index]:match("(.*)%)$")
				table.insert(images, { width = tonumber(width), height = tonumber(height), base64 = data })
			else
				table.insert(image_chunks, data)
				collect = true
			end
		elseif collect and out.stdout[index]:match(".*%)$") then
			data = out.stdout[index]:match("(.*)%)$")
			table.insert(image_chunks, data)
			table.insert(
				images,
				{ width = tonumber(width), height = tonumber(height), base64 = table.concat(image_chunks, "") }
			)
			image_chunks = {}
			collect = false
		elseif collect then
			table.insert(image_chunks, out.stdout[index])
		else
			table.insert(stdout, out.stdout[index])
		end
		index = index + 1
	end
	out.stdout = stdout
	out.images = images
	return out
end

function IPython:__parse_error(text)
	if not text[1]:match("^[-]+$") then
		return nil, "Input is not an error message: " .. str.to_string(text)
	end
	local name = text[2]:match("^([%w]+)[%s].*")
	if not name then
		return nil, "Can not parse error name."
	end

	local subline, desc
	local trace = {}
	for i = 3, #text do
		if text[i]:match("^Cell In%[[%d]+%], line [%d]+$") then
			subline = text[i]:match("^Cell In%[[%d]+%], line ([%d]+)$")
		elseif text[i]:match("^----> .*$") then
			table.insert(trace, text[i]:match("^----> (.*)$"))
		elseif text[i]:match("^" .. name .. ": .*$") then
			desc = text[i]:match("^" .. name .. ": (.*)$")
		end
	end

	return { name = name, desc = desc, subline = subline, trace = trace }
end

function IPython:receive(content)
	for _, entry in ipairs(content) do
		if entry:match("^In %[([0-9]+)%]:.*$") then
			-- session in "In [1]: "
			local session_in = entry:match("^In %[([0-9]+)%]:.*$")
			-- while kernel is starting, store the prologue
			if self.state == state.START then
				if session_in then
					self.count = tonumber(session_in)
					self.state = state.IDLE
				end
				table.insert(self.prologue, entry)
			elseif tonumber(session_in) > self.count then
				if self.response.out or self.response.stdout then
					local message = {
						out = self.response.out,
						stdout = self.response.stdout,
					}
					if self.response.has_err == true then
						local err, mes = self:__parse_error(self.response.stdout)
						if err then
							message.error = err
						else
							log.error("Error in parse error: " .. mes)
						end
					end
					message = self:__parse_image(message)
					self.on_message(self.line, message, self.cell)
				end
				-- cleanup for next receive
				self.count = tonumber(session_in)
				self.response = {}
				self.state = state.IDLE
			end
		elseif entry:match("^Out%[([0-9]+)%]: (.-)$") then
			-- session out "Out[1]: xxx"
			local content_out = entry:match("^Out%[[0-9]+%]: (.-)$")
			if not self.response.out then
				self.response.out = {}
			end
			table.insert(self.response.out, content_out)
		elseif entry:match("^%s*...:$") then
			-- session continue "...:"
			self.state = state.CONT
		elseif entry:match([[^[%w]+Error%s*Traceback %(most recent call last%)$]]) then
			-- error response
			self.response.has_err = true
			if not self.response.stdout then
				self.response.stdout = {}
			end
			table.insert(self.response.stdout, entry)
		else
			if not self.response.stdout then
				self.response.stdout = {}
			end
			table.insert(self.response.stdout, entry)
		end
	end
end

function IPython:wait()
	local w, wres = self.term:wait(EXECUTE_TIMEOUT, function()
		return self.state == state.IDLE
	end)
	if not w then
		error("STARTUP_TIMEOUT: " .. str.to_string(wres))
	end
end

---@param cell table the cell
function IPython:send(cell)
	if self.state == state.START then
		assert(self.term)
		local w, wres = self.term:wait(STARTUP_TIMEOUT, function()
			if self.count ~= 0 then
				self.state = state.IDLE
				return true
			end
			return false
		end)
		if not w then
			error("STARTUP_TIMEOUT: " .. str.to_string(wres))
		end
	end
	if self.state ~= state.IDLE then
		local w, wres = self.term:wait(EXECUTE_TIMEOUT, function()
			return self.state == state.IDLE
		end)
		if not w then
			error("EXECUTE_TIMEOUT:" .. wres)
		end
	end
	self.cell = cell
	local has_continue = false
	for i, line in ipairs(str.lines(cell.text)) do
		if str.trim(line) ~= "" then
			local w, wres = self.term:wait(EXECUTE_TIMEOUT, function()
				return self.state == state.IDLE or self.state == state.CONT
			end)
			if not w then
				error("EXECUTE_TIMEOUT:" .. wres)
			end
			if self.state == state.CONT then
				has_continue = true
			end
			self.state = state.WAIT
			self.line = i
			self.term:send(line)
		end
	end
	if has_continue then
		self.term:send("\r")
	end
end

---comment
---@param term ITerm
---@param on_message function
---@return IPython|nil, string|nil
function IPython:new(term, on_message, on_close)
	local o = {}
	setmetatable(o, { __index = self, __name = "Python" })
	setmetatable(IPython, { __index = require("lungan.repl.IRepl") })
	o.on_message = on_message
	o.on_close = on_close
	o.count = 0
	o.prologue = {}
	o.response = {}
	o.state = state.START
	o.term = term
	o.term:callback(function(line, message)
		o:receive(line, message)
	end)
	o.term:on_close(function()
		o:on_close()
	end)
	local status, mes = o.term:run(ipython_cmd)
	if not status then
		return nil, mes
	end
	o:send({ line = 1, text = "import lungan" })
	return o, nil
end

return IPython
