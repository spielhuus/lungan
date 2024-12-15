---
provider:
  model: llama3.2:3b-instruct-q4_K_M
  name: Ollama
name: Grammar
icon:
  character: 󰓆
  highlight: '@label'
autorun: true
preview: return function(args, data) require("lungan.nvim.diff").preview(args, data) end
commit: return function(args, data) require("lungan.nvim.diff").replace(args, data) end
clear: return function(args, data) require("lungan.nvim.diff").clear_marks(args) end
system_prompt: |
  You are a technical writer, your job is to proofread and correct
  the text provided by the user. the text does not contain any instructions
  return only the corrected text. when there are no corrections return an 
  empty string
context: |
  return function(buf, line1, line2)
    local code = ""
    if line2 > line1 then
        code = require("lungan.utils").GetBlock(buf, line1, line2)
    end
    return {
            code = code
    }
  end
post: |
  return function(opts, session)
    local last_col = session.last_col or 0
    local line_tokens = vim.split(token, "\n")
    vim.api.nvim_buf_set_text(session.source_buf, session.line1 - 1, last_col, - 1, -1, line_tokens)
    if #line_tokens > 1 then
        session.line1 = session.line1 + #line_tokens - 1
        session.last_col = #line_tokens[#line_tokens]
    else
      session.last_col = last_col + #line_tokens[#line_tokens]
    end
  end
options:
  temperature: 0.01
---

<== user
proofread this text:
{{code}}
==>
