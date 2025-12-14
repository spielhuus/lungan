---
provider:
  name: Openvino
  model: Qwen3-8B-int4-cw-ov
name: Default
stream: true
system_prompt: |
  You are a senior software developer in {{lang}}.
  Answer the users question in the tone of a geek and precise and concise.
context: |
  return function(buf, line1, line2)
    local code = ""
    if line2 > line1 then
        code = require("lungan.utils").GetBlock(buf, line1, line2)
    end
    return {
            code = code,
            lang = vim.bo.filetype
    }
  end
options:
  temperature: 0.8
  top_p: 1
  min_p:  0.1
  repeat_penalty: 1
  num_ctx: 4096
---

<== user

{{code}}

==>
