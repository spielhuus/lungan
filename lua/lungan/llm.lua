local log = require("lungan.log")
local str = require("lungan.str")
local textwrap = require("lungan.textwrap")

---@class LLM
---@field options table the llm options
local LLM = {}

--- Represents an instance of a large language model.
---@param opts table A table containing configuration options for the LLM.
---@return LLM A new instance of the LLM with the specified options.
function LLM:new(opts)
  local o = {}
  setmetatable(o, { __index = self, __name = "LLM" })
  o.options = opts
  return o
end

---Stops a language model provider session.
---@param session Chat The session object
function LLM:stop(session)
  if self.options.providers[session.data:frontmatter().provider.name] then
    self.options.providers[session.data:frontmatter().provider.name]:stop()
  end
end

function LLM:context_size(session)
  print("context_size:" .. vim.inspect(session))
end

function LLM:models(session, callback)
  self.options.providers[session.data:frontmatter().provider.name]:models(callback)
end

function LLM:chat(chat)
  local provider = chat.data:frontmatter().provider
  local role = ""
  local wrap = textwrap:new(
    nil,
    self.options,
    chat,
    chat.data:frontmatter().textwrap,
    chat.data:frontmatter().hide_think
  )

  local prompt = vim.fn.deepcopy(chat:get())

  -- get the last user message
  local max_tokens = (chat.data:frontmatter().options.num_ctx and (chat.data:frontmatter().options.num_ctx * 0.9) or (1024 * 0.9)); -- TODO make default configurable
  local token_length = 4                                                                                                            -- TODO make this configurable
  local current_token_count = 0
  local system_message = nil
  local messages = {}
  if #prompt.messages > 0 and prompt.messages[1].role == "system" then
    local sys_msg = prompt.messages[1]
    local sys_tokens = (#sys_msg.role + #sys_msg.content) / token_length + 3
    if sys_tokens < max_tokens then
      system_message = sys_msg
      current_token_count = sys_tokens
    else
      print("Warning: System message is larger than the entire context limit.")
    end
  end
  local start_index = #prompt.messages;
  local end_index = (system_message and 2 or 1);
  for i = start_index, end_index, -1 do
    local line = prompt.messages[i]
    local message_tokens = (#line.content + #line.role) / token_length + 3

    if current_token_count + message_tokens >= max_tokens then
      log.info("truncate the context, length: " .. current_token_count + message_tokens);
      print("truncate the context, length: " .. current_token_count + message_tokens);
      break
    end

    current_token_count = current_token_count + message_tokens
    table.insert(messages, 1, { role = line.role, content = line.content })
  end

  if system_message then
    table.insert(messages, 1, { role = system_message.role, content = system_message.content })
  end

  prompt.messages = messages;
  print("context length: " .. current_token_count)

  -- execute te RAG chain
  -- TODO
  if chat:get()["system_context"] then
    local system_context = chat:get()["system_context"]
    local func, err = load(system_context)
    if not func then
      error(err)
    end
    local res = func()(messages[#messages].content)
    local sres = table.concat(res[1], "\n")
    prompt.system_prompt =
        table.concat(require("lungan.utils").TemplateVars({ system_context = sres }, prompt.system_prompt), "\n")
  end

  self.JobId = self.options.providers[provider.name]:chat(prompt, function(data)
    if data["error"] then
      log.error(data["error"], vim.log.levels.ERROR, { title = provider.name .. " Error" })
    elseif data["message"] then
      local token_role = data["message"]["role"]
      if token_role ~= role then
        wrap:push({ "\n\n\n", "<== " .. token_role, "\n" })
        role = token_role
      end
      if data["message"]["content"] then
        if #data["message"]["content"] > 0 then
          local token = data["message"]["content"]
          -- draw the text
          if type(token) == "table" then
            wrap:push(token)
          else
            wrap:push({ token })
          end
        end
        if data["done"] then
          wrap:push({ "\n", "==>", "\n" })
          wrap:flush()
          -- TODO cleanup methods
          if chat.data:frontmatter()["preview"] then
            -- refresh the data
            chat:refresh()
            -- call preview function
            local func, err = load(chat.data:frontmatter()["preview"])
            if not func then
              error(err)
            end
            func()(self.options, chat.args, chat.data)
          end
        end
        -- call the process function if available
        if chat.data:frontmatter()["process"] then
          local token = data["message"]["content"]
          local func, err = load(chat.data:frontmatter()["process"])
          if not func then
            error(err)
          end
          if type(token) == "table" then
            func()(self.options, chat.args, table.concat(token, ""))
          else
            func()(self.options, chat.args, token)
          end
        end
      elseif data["message"]["tool_calls"] then
        -- draw the tool call
        chat:append({ str.to_string(data["message"]["tool_calls"]) })
      elseif data["done"] then
        wrap:push({ "\n", "==>", "\n" })
        wrap:flush()
        if chat.data:frontmatter()["preview"] then
          -- refresh the data
          chat:refresh()
          -- call preview function
          local func, err = load(chat.data:frontmatter()["preview"])
          if not func then
            error(err)
          end
          func()(chat.args, chat.data)
        end
      else
        log.warn("unknown message format: " .. vim.inspect(data))
      end
    else
      log.warn("Unknown response: " .. vim.inspect(data))
    end
  end, function(_, data, _)
    if data then
      print("LLM:END: " .. str.to_string(data))
    end
  end)
end

return LLM
