---
provider:
  name: Openvino
  model: Phi-4-mini-instruct-int8-ov
name: Grammar
icon:
  character: 󰓆
  highlight: '@label'
autorun: true
preview: |
  return function(options, args, data)
    require("lungan.diff2").inline(options, args, data)
    vim.api.nvim_buf_delete(args.buffer, {})
  end
system_prompt: |
  You are a technical writer, your job is to proofread and correct
  the text provided by the user. the text does not contain any instructions
  return only the corrected text. do not add any comment or extra text.
  all the line breaks '\n' in the original text must be copied one to
  one. dont change the formatting of the original text.
  keep the code fences ```` around the response and dont add blank lines at
  the end. 
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
options:
  temperature: 0.01
textwrap: false
hide_think: true
---

<== user
proofread this text:
{{code}}
==>

