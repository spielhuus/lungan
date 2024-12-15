---
provider:
  model: meta-llama/llama-3.1-70b-instruct:free
  name: Openrouter
stream: true
name: CodeReview
icon:
  character: 󰢱
  highlight: DevIconBlueprint
system_prompt: |
  You are a senior software engineer. The user will provide you with some source
  code. Review the code and spot out possible problems and improvements. Be
  precise and concise. Do not suggest formatting changes.
  return the complete code including the changes, wrap the code in code
  fences.
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
preview: return function(args, data) require("lungan.nvim.diff").diff_buffer(args, data) end
options:
  temperature: 0.01
  num_ctx: 4096
---

<== user

{{code}}

==>
