local log = require("lungan.log")
local utils = require("lungan.utils")

local M = {}

local function extract_chat(data)
	local user_chat = {}
	for message in data:iter() do
		if message.type == "chat" and message.role == "assistant" then
			log.trace("chatData: " .. vim.inspect(message.text))
			table.insert(user_chat, vim.split(message.text, "\n"))
		end
	end
	return user_chat
end

---Clean result table
---Retrieves a buffer line with strings.
---The buffer looks like this:
---{ "", "```", "content", "```", "" }
---This function shall remove all leading and trailing empty entries ("") and fences ("```").
---The fence can also contain a language, like this: "```markdown"
---
---@param text string[] The input string.
---@return string[]
M.__clean_result = function(text)
	local start = 1
	while start <= #text and (text[start] == "" or text[start]:match("^%s*%`%`%`")) do
		start = start + 1
	end
	local finish = #text
	while finish >= start and (text[finish] == "" or text[finish]:match("^%s*%`%`%`")) do
		finish = finish - 1
	end
	if start > finish then
		return {}
	else
		return vim.list_slice(text, start, finish)
	end
end

M.namespace = vim.api.nvim_create_namespace("lungan.diff")

---Find the Longest Common Subsequence
---Given two stings:
--- Orignal: lorem ipsum
--- Modified: lorem kipsum
---
--- Find thee LCS:
---     LCS of lorem ipsum and lorem kipsum is lorem ipsm.
---@param left string the left string
---@param right string the right string
---@return string LCS
M.lcs = function(left, right)
	local len1, len2 = #left, #right
	local dp = {}

	for i = 0, len1 do
		dp[i] = {}
		for j = 0, len2 do
			if i == 0 or j == 0 then
				dp[i][j] = ""
			elseif left:sub(i, i) == right:sub(j, j) then
				dp[i][j] = dp[i - 1][j - 1] .. left:sub(i, i)
			else
				if #dp[i - 1][j] > #dp[i][j - 1] then
					dp[i][j] = dp[i - 1][j]
				else
					dp[i][j] = dp[i][j - 1]
				end
			end
		end
	end

	return dp[len1][len2]
end

M.diff_buffer = function(args, data)
	print(vim.inspect(args))
	local chat_data = extract_chat(data)
	if #chat_data > 0 then
		local code, lang = utils.get_code_fence(chat_data[#chat_data])
		print(vim.inspect(code))
		local source = vim.api.nvim_buf_get_lines(args.source_buf, 0, -1, false)
		local new_buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_set_option_value("filetype", lang, { buf = new_buf })
		vim.api.nvim_buf_set_lines(new_buf, 0, -1, false, source)
		vim.api.nvim_buf_set_lines(new_buf, args.line1 - 1, args.line2, false, M.__clean_result(code))
		vim.cmd("buffer " .. new_buf)
		vim.cmd("diffthis")
		vim.api.nvim_set_current_win(args.source_win)
		-- vim.api.nvim_command("buffer " .. args.source_buf)
		vim.cmd("diffthis")
	else
		log.warn("lungan: No code found in chat response")
	end
end

M.diff = function(left, right)
	local lcs_str = M.lcs(left, right)
	print(lcs_str)
	local i, j, k = 1, 1, 1
	local result = {}

	while i <= #left or j <= #right do
		if
			k <= #lcs_str
			and i <= #left
			and j <= #right
			and string.sub(left, i, i) == string.sub(right, j, j)
			and string.sub(left, i, i) == string.sub(lcs_str, k, k)
		then
			table.insert(result, { string.sub(left, i, i), "@comment" })
			i = i + 1
			j = j + 1
			k = k + 1
		else
			if i <= #left and (k >= #lcs_str or string.sub(left, i, i) ~= string.sub(lcs_str, k, k)) then
				table.insert(result, { string.sub(left, i, i), "@label" })
				i = i + 1
			elseif j <= #right and (k >= #lcs_str or string.sub(right, j, j) ~= string.sub(lcs_str, k, k)) then
				table.insert(result, { string.sub(right, j, j), "@error" })
				j = j + 1
			else
				error("no match")
			end
		end
	end
	return result
end

M.clear_marks = function(args)
	vim.api.nvim_buf_clear_namespace(args.source_buf, M.namespace, args.line1 - 1, args.line2)
end

M.preview = function(args, data)
	local user_chat = {}
	for message in data:iter() do
		if message.type == "chat" and message.role == "assistant" then
			table.insert(user_chat, M.__clean_result(vim.split(message.text, "\n")))
		end
	end
	-- preview the lines
	local line_nr = args.line1 - 1
	for _, left in ipairs(user_chat[#user_chat]) do
		local right = vim.api.nvim_buf_get_lines(args.source_buf, line_nr, line_nr + 1, true)
		if left == right[1] then
			vim.api.nvim_buf_set_extmark(args.source_buf, M.namespace, line_nr, 0, {
				virt_text_pos = "overlay",
				virt_text = { { left, "@comment" } },
				sign_text = "",
				sign_hl_group = "@diff.plus",
				hl_mode = "replace",
				conceal = "",
			})
		else
			vim.api.nvim_buf_set_extmark(args.source_buf, M.namespace, line_nr, 0, {
				virt_text_pos = "overlay",
				virt_text = M.diff(left, right[1]),
				sign_text = "",
				sign_hl_group = "@diff.delta",
				hl_mode = "replace",
				conceal = "",
			})
		end
		line_nr = line_nr + 1
	end
end

M.replace = function(args, data)
	local user_chat = {}
	for message in data:iter() do
		if message.type == "chat" and message.role == "assistant" then
			user_chat = M.__clean_result(vim.split(message.text, "\n"))
		end
	end
	M.clear_marks(args)
	print(vim.inspect(user_chat))
	vim.api.nvim_buf_set_lines(args.source_buf, args.line1 - 1, args.line2, true, user_chat)
end

return M
