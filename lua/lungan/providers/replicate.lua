local log = require("lungan.utils.log")

local REPLICATE_API_TOKEN = os.getenv("REPLICATE_API_TOKEN")

local max_polls = 10 -- Set the maximum number of poll attempts
local poll_interval = 4000 -- Time between polls in milliseconds (2 seconds)
local current_poll = 0 -- Track how many times we've polled
local job_done = false -- Flag to indicate if the job has succeeded
local cancel_url = nil

local function create_request(session)
	local system_prompt = session.data[1].content.system_prompt
	local messages = {}
	for _, v in pairs(session.data) do
		if v.name == "chat" then
			if v.role == "user" then
				table.insert(messages, "[INST]" .. table.concat(v.text, "\n") .. "[/INST]")
			else
				table.insert(messages, table.concat(v.text, "\n"))
			end
		end
	end
	return {
		input = {
			system_prompt = system_prompt,
			prompt = table.concat(messages, "\n"),
			-- TODO add options
		},
		stream = session.data[1].content.stream or true and session.data[1].content.stream == true,
	}
end

local function parse_stream_response() end

local function poll_job(cmd, initial_delay, stdout, stderr, exit)
	log.trace("Poll Job")
	-- Function to start polling
	local function start_polling()
		log.trace("> Poll:" .. current_poll)
		current_poll = current_poll + 1

		-- Check if we've exceeded max polls
		if current_poll > max_polls then
			log.error("Max polling attempts reached.")
			return
		end

		-- Start the curl command
		vim.fn.jobstart(cmd, {
			on_stdout = function(_, data, _)
				log.trace("<<< '", vim.inspect(data) .. "'")
				if data ~= "" and table.concat(data, "") ~= "" then
					local response = vim.json.decode(table.concat(data, ""))
					if response.status == "succeeded" then
						stdout({
							message = {
								done = true,
								role = "assistant",
								content = response.output,
							},
						})
						job_done = true -- Mark job as done
					end
				end

				-- If not succeeded, schedule another poll after a delay
				if not job_done then
					vim.defer_fn(function()
						start_polling() -- Recursive polling
					end, poll_interval)
				end
			end,

			on_stderr = function(_, data, _)
				log.error("<<< ", vim.inspect(data))
				if stderr then
					stderr(data)
				end
			end,

			on_exit = function(_, b)
				if b ~= 0 then
					log.trace("Exit: " .. b)
					if exit then
						exit(b)
					end
				end
			end,
		})
	end

	-- Start polling with an initial delay
	vim.defer_fn(function()
		start_polling()
	end, initial_delay or poll_interval)
end

local function stream_job(cmd, stdout, stderr, exit)
	local tokens = {}
	local job_id = nil
	job_id = vim.fn.jobstart(cmd, {
		on_stdout = function(_, data, _)
			if data ~= "" and table.concat(data, "") ~= "" then
				local text = table.concat(data, "\n")
				local lines = vim.split(text, "\n")
				log.trace("<<<", vim.inspect(lines))
				local first_data = false
				for _, line in ipairs(lines) do
					if line:match("^event: (%w+)") then
						local event = line:match("^event: (%w+)")
						stdout({
							message = {
								role = "assistant",
								content = tokens,
							},
							done = event == "done",
						})
						if event == "done" then
							vim.fn.jobstop(job_id)
							return
						end
						tokens = {}
						first_data = false
					elseif line:match("^data:") then
						local token = string.sub(line, 7)
						if not first_data then
							first_data = true
						else
							table.insert(tokens, "\n")
						end
						if token ~= "" then
							table.insert(tokens, token)
						end
					end
				end
			end
		end,
		on_stderr = function(_, data, _)
			log.error("<<< ", vim.inspect(data))
			if stderr then
				stderr(data)
			end
		end,

		on_exit = function(_, b)
			log.trace("ExitStream: " .. b)
			if b ~= 0 then
				if exit then
					exit(b)
				end
			end
		end,
	})
	return job_id
end

local models = function(opts, query)
	local status = 0
	local cmd = "curl --silent --no-buffer -X QUERY "
		.. ' -H "Authorization: Bearer '
		.. REPLICATE_API_TOKEN
		.. '"'
		.. ' -H "Content-Type: text/plain"'
		.. ' -d "'
		.. query
		.. '"'
		.. " https://api.replicate.com/v1/models"
	log.debug("QUERY:" .. cmd)
	local result = {}
	local job_id = vim.fn.jobstart(cmd, {
		on_stdout = function(chan_id, data, name)
			if table.concat(data, "") ~= "" then
				table.insert(result, table.concat(data, ""))
			end
		end,
		on_stderr = function(chan_id, data, name)
			if table.concat(data, "") ~= "" then
				log.error("chan: " .. chan_id .. ", data:'" .. table.concat(data, "") .. "', name:" .. name)
			end
		end,
		on_exit = function(chan_id, code)
			status = code
		end,
	})
	vim.fn.jobwait({ job_id }, -1)

	-- log.debug("Response:" .. status .. ":" .. vim.inspect(result))
	if status > 0 then
		vim.notify("Error: " .. vim.inspect(status) .. "\n" .. vim.inspect(result), vim.log.levels.ERROR)
		return nil
	else
		local res_string = table.concat(result, "")
		local rec_model = vim.json.decode(res_string)
		local items = {}
		for _, model in ipairs(rec_model.results) do
			table.insert(items, {
				url = model.url,
				owner = model.owner,
				name = model.owner .. "/" .. model.name,
				model = model.model,
				description = model.description,
				visibility = model.visibility,
				github_url = model.github_url,
			})
		end
		return items
	end
end

local function prediction(cmd)
	log.trace(cmd) -- TODO traces the replicate token
	local get_url, cancel_url, stream_url, error = nil, nil, nil, 0
	Job_id = vim.fn.jobstart(cmd, { -- send request
		on_stdout = function(_, data, _)
			log.trace("stdout:", table.concat(data, "\n"))
			if table.concat(data, "") ~= "" then
				local response = vim.json.decode(table.concat(data, ""))
				cancel_url = response["urls"]["cancel"]
				get_url = response["urls"]["get"]
				stream_url = response["urls"]["stream"]
			end
		end,
		on_stderr = function(_, data, _)
			if table.concat(data, "") ~= "" then
				log.error(vim.inspect(data))
			end
		end,
		on_exit = function(_, b)
			if b ~= 0 then
				error = b
			end
		end,
	})
	local status, _ = pcall(vim.fn.jobwait, { Job_id }, 1000)
	if not status then
		return false, "Replicate prediction timeout reached"
	end
	if error > 0 then
		return false, "error is: " .. error
	end
	return true, get_url, cancel_url, stream_url
end

local chat = function(opts, content, stdout, stderr, exit)
	local request = vim.fn.shellescape(vim.json.encode(create_request(content)))
	local cmd = "curl --silent --no-buffer -X POST https://api.replicate.com/v1/models/"
		.. content.data[1].content.provider.model
		.. "/predictions"
		.. ' -H "Authorization: Bearer '
		.. REPLICATE_API_TOKEN
		.. '"'
		.. " -H 'Content-Type: application/json'"
		.. " -d "
		.. request
	local sucess, get_url, cancel_url, stream_url = prediction(cmd)
	if sucess == false then
		log.error("Exit: " .. get_url)
		return
	elseif content.data[1].content.stream == true and stream_url then
		cmd = "curl --silent --no-buffer -X GET "
			.. stream_url
			.. ' -H "Authorization: Bearer '
			.. REPLICATE_API_TOKEN
			.. '"'
			.. ' -H "Accept: text/event-stream"'
		log.trace("STREAM:CURL", cmd)
		JobId = stream_job(cmd, stdout, stderr, exit)

		-- we need to poll the result until it is ready
	elseif get_url then
		cmd = "curl --silent --no-buffer -X GET "
			.. get_url
			.. ' -H "Authorization: Bearer '
			.. REPLICATE_API_TOKEN
			.. '"'
		log.trace("GET:CURL", cmd)
		JobId = poll_job(cmd, 3000, stdout, stderr, exit)
	else
		log.warn("no strategy matches")
	end
end

local complete = function(opts, content, stdout, stderr, exit)
	log.trace(vim.inspect(content))
	local get_url, cancel_url, stream_url = nil, nil, nil
	local rep_request = create_request(content)
	log.debug("Replicate Request: " .. vim.inspect(rep_request))
	local cmd = "curl --silent --no-buffer -X POST https://api.replicate.com/v1/models/"
		.. content.data[1].content.provider.model
		.. "/predictions"
		.. ' -H "Authorization: Bearer '
		.. REPLICATE_API_TOKEN
		.. '"'
		.. " -H 'Content-Type: application/json'"
		.. " -d "
		.. vim.fn.shellescape(vim.json.encode(rep_request))

	log.debug("CURL", cmd)

	Job_id = vim.fn.jobstart(cmd, { -- send request
		on_stdout = function(_, data, _)
			log.trace("<<< ", table.concat(data, "\n"))
			if table.concat(data, "") ~= "" then
				local response = vim.json.decode(table.concat(data, ""))
				cancel_url = response["urls"]["cancel"]
				get_url = response["urls"]["get"]
				stream_url = response["urls"]["stream"]
			end
		end,
		on_stderr = function(_, data, _)
			log.error("<<< ", vim.inspect(data))
			if stderr then
				stderr(data)
			end
		end,
		on_exit = function(_, b)
			if b ~= 0 then
				log.trace("Exit: " .. b)
				if exit then
					exit(b)
				end
			end
		end,
	})
	vim.fn.jobwait({ Job_id }, 10000)

	if not get_url then
		print("no get_url")
		return
	end

	local cmd = "curl --silent --no-buffer -X GET "
		.. get_url
		.. ' -H "Authorization: Bearer '
		.. REPLICATE_API_TOKEN
		.. '"'
	log.trace("CURL", cmd)
	-- we need to poll the result until it is ready
	poll_job(cmd, 3000, stdout, stderr, exit)
end

-- TODO remove
local defaults = {
	name = "Ollama",
	model = "llama3.1",
	host = "127.0.0.1",
	port = "11434",
	chat = chat,
	models = models,
}

return {
	setup = function(opts)
		local in_opts = opts or {}
		local options = defaults
		for k, v in pairs(in_opts) do
			defaults[k] = v
		end
		return options
	end,
}
