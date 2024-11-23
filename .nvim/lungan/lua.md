---
provider:
  model: hf.co/bartowski/Qwen2.5.1-Coder-7B-Instruct-GGUF:Q8_0
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
preview: return function(args, data) require("lungan.nvim.diff").preview(args, data) end
options:
  temperature: 0.01
  num_ctx: 4096
---

<== user

{{code}}

==>
