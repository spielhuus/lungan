---
provider:
  model: models/gemini-2.0-flash
  name: AiStudio
stream: true
name: NeovimKeymaps
icon:
  character: 󰢱
  highlight: DevIconBlueprint
system_prompt: |
  Your job is it to create a documentation of the installed plugins.
context: |
  return function(buf, line1, line2)
    plugins = vim.api.nvim_exec('verbose map', true)
    return {
            code = plugins
    }
  end
options:
  temperature: 0.01
  num_ctx: 8000
---

<== user

create a markdown table with the keymaps from neovim.

{{code}}
==>
