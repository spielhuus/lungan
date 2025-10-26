---
provider:
  model: models/gemini-2.0-flash
  name: AiStudio
stream: true
name: NeovimPlugins
icon:
  character: 󰢱
  highlight: DevIconBlueprint
system_prompt: |
  Your job is it to create a documentation of the installed plugins.
context: |
  return function(buf, line1, line2)
    plugins = require("lazy.core.config").plugins
    return {
            code = plugins
    }
  end
options:
  temperature: 0.01
  num_ctx: 8000
---

<== user

create a markdown table with the data from lazy.
the table should have two colums: 
  name with a link to the plugin url
  plugin description

{{code}}
==>
