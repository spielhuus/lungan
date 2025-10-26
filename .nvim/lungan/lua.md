---
provider:
  model: qwen2.5-coder:7b-instruct-q8_0
  name: Ollama
stream: true
name: Lua
icon:
  character: 󰢱
  highlight: DevIconBlueprint
system_prompt: |
  You are a senior Lua programmer specializing in Neovim plugins.
  Only answer the users question. be precise and concise.
  Do not add any examples, usages, outputs and for sure no introduction.
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
  temperature: 0.1
  num_ctx: 4096
---

<== user

{{code}}

==>
