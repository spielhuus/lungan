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

mcp: .nvim/lungan/mcp-server.py
# context: |
#   return function(_, _, _)
#     local handle = io.popen("git diff -p --staged")
#     local result = handle:read("*all")
#     handle:close()
#     return {
#             gitdiff = vim.split(result, '\n')
#     }
#   end
process: |
  return function(opts, session, token)
    print(vim.inspect(token))
    local last_col = session.last_col or 0
    local line_tokens = vim.split(token, "\n")
    if token:match("<think>") then
        session.hide_think = true
    elseif token:match("</think>") then
        session.hide_think = false
    elseif not session.hide_think then
        vim.api.nvim_buf_set_text(session.source_buf, session.line1 - 1, last_col, - 1, -1, line_tokens)
        if #line_tokens > 1 then
            session.line1 = session.line1 + #line_tokens - 1
            session.last_col = #line_tokens[#line_tokens]
        else
          session.last_col = last_col + #line_tokens[#line_tokens]
        end
    end
  end
options:
  temperature: 0.01
  num_ctx: 4096
---

<== user
write the commit message from this diff:


==>

