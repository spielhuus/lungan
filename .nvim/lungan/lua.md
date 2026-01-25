---
provider:
  name: LlamaCPP
  model: Qwen3-8B-int4-cw-ov
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
mcp: true
options:
  temperature: 0.8
  top_k: 4
  top_p: 0
---

<== user

{{code}}

==>
