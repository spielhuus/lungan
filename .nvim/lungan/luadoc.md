---
provider:
  model: Qwen3-Coder-30B-A3B-Instruct-Q8_0 
  name: LlamaCPP
stream: true
name: Document Code
command: Doc
autorun: true
icon:
  character: 󰢱
  highlight: DevIconBlueprint
system_prompt: |
  You are a code completion assistant in {{lang}}
  Your Task is it to create code annotations for the given code.
  Just output the documentation and do not echo the provided code.
  Analyze the code and its functionality. Use the information for 
  creating the documentation. Do not make up things that can not
  be taken from the code information.
  when documenting a lua class, also document all fields created in the constructor
  just create a documentation for the section after the cursor. dont document 
  anything else. analyze what the section after the cursor is, what  
  the functionality is and carefully create a documentation.
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
  temperature: 0.7
  top_k: 20
  min_p: 0.01
  top_p: 0.8
  repeat_penalty: 1.05
  num_ctx: 65536
---

<== user
Complete this code:
<|fim_prefix|>
{{lines_before}}
<|fim_suffix|>
{{lines_after}}
<|fim_middle|>
==>
