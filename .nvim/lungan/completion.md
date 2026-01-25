---
provider:
  model: Qwen2.5-Coder-1.5B-Instruct-int4-ov
  name: LlamaCPP
stream: true
name: Code Completion
command: CodeCompletion
autorun: true
icon:
  character: 󰢱
  highlight: DevIconBlueprint
system_prompt: |
  You are a code completion assistant in lua
context: |
  return function(buf, line1, line2)
    local lines_before = vim.api.nvim_buf_get_lines(buf, 0, line1, false)
    local lines_after = vim.api.nvim_buf_get_lines(buf, line1, -1, false)
    return {
            lines_before = table.concat(lines_before, "\n"),
            lines_after = table.concat(lines_after, "\n"),
            lang = vim.bo.filetype
    }
  end
preview: |
  return function(...)
    require("lungan.phantom").preview(...)
  end
options:
  temperature: 0.1
  num_ctx: 100000
---

<== user
Complete this code:
<|fim_prefix|>
{{lines_before}}
<|fim_suffix|>
{{lines_after}}
<|fim_middle|>
==>

