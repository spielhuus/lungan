---
provider:
  name: Openvino
  model: Qwen3-8B-int4-cw-ov
stream: true
name: LSP
icon:
  character: 󰢱
  highlight: DevIconBlueprint
system_prompt: |
  You are a software engineer. You will receive some code 
  and the LSP diagnostics. Analyze the code and the LSP
  Diagnostic, For each diagnotics explain the meaning 
  and make a suggestion for fixing it.
  Do not add any examples, usages, outputs and for sure no introduction.
context: |
  return function(buf, line1, line2)
    local current_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local diagnostics = vim.diagnostic.get(buf);
    print("diagnostics: " .. #diagnostics);
    code = table.concat(current_lines, "\n") .. "\nLSP diagnostics\n" .. vim.inspect(diagnostics);
    return {
            code = code
    }
  end
options:
  temperature: 0.8
  top_k: 4
  top_p: 0
---

<== user

{{code}}

==>
