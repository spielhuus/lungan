local textwrap = {}

function textwrap:__push_word(word)
	if word:match("<think>") and self.hide_think then
		self.is_think = true
  elseif word:match("</think>") and self.hide_think then
		self.is_think = false
  elseif self.is_think then
    return
  elseif not self.is_code and word:match("```[%w]*") then
		self.is_code = true
		self.chat:append({ word })
	elseif self.is_code == true or self.should_wrap == false then
		if word == "```" then
			self.is_code = false
			self.chat:append({ word })
		else
			self.chat:append({ word .. " " })
		end
	elseif self.line_width + #word + 1 >= self.max_width then
		self:__push_nl()
		self.chat:append({ word })
		self.line_width = self.line_width + #word
	else
		if self.line_width > 0 then
			self.chat:append({ " " })
			self.line_width = self.line_width + 1
		end
		self.chat:append({ word })
		self.line_width = self.line_width + #word
	end
end

function textwrap:__push_nl()
	self.chat:append({ "\n" })
	self.line_width = 0
end

---Pushes a token into the text wrapping context.
---@param token table[string] A list of strings to be processed and wrapped.
function textwrap:push(token)
	for _, item in ipairs(token) do
		for i = 1, #item do
			if string.sub(item, i, i):match("[ \t]") then
				self:__push_word(self.act_word)
				self.act_word = ""
			elseif string.sub(item, i, i) == "\n" then
				self:__push_word(self.act_word)
				self:__push_nl()
				self.act_word = ""
			else
				self.act_word = self.act_word .. string.sub(item, i, i)
			end
		end
	end
end

---Drain the buffer
function textwrap:flush()
	self:__push_word(self.act_word)
end

---Creates a new textwrap instance.
---@param o table|nil The object to initialize. If nil, a new table is created.
---@param options table Configuration options for the text wrap.
---@param chat Chat Chat buffer to write the text to
---@param should_wrap boolean if the text should be wrapped
---@param hide_think boolean if the thikning output should be hidden
---@return table A new textwrap instance with initialized properties and methods.
function textwrap:new(o, options, chat, should_wrap, hide_think)
	o = o or {}
	setmetatable(o, { __index = self })
	o.options = options
	o.chat = chat
	o.act_word = ""
	o.line_width = 0
	o.max_width = options.linewidth or 70
	o.is_code = false
  o.should_wrap = should_wrap or true and should_wrap
  o.hide_think = hide_think or false and hide_think
	return o
end

return textwrap
