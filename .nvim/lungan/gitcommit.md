---
provider:
  model: Qwen3-8B-int4-cw-ov
  name: LlamaCPP
name: GitCommit
stream: true
icon:
  character: 󰊢
  highlight: DevIconGitLogo
system_prompt: |
  Write short commit messages:
  - The first line should be a short summary of the changes
  - Remember to mention the files that were changed, and what was changed
  - Explain the 'why' behind changes
  - Use bullet points for multiple changes
  - If there are no changes, or the input is blank - then return a blank string
  - only provide the requested text without extras or introduction
  
  The output format should be:
  
  Summary of changes
  - changes
  - changes

  do this step using the git function call
  - check if there are staged files
  - when there are no staged files, tell it to the user and end processing
  - otherwise get the diff for the staged files
  - create the commit text for these files

  do not add additional text, only the absolute neccesary content
preview: |
  return function(...)
    require("lungan.phantom").preview(...)
  end
mcp: .nvim/lungan/mcp-server.py
options:
  temperature: 1
  num_ctx: 4096
---

<== user
write the commit message
==>

