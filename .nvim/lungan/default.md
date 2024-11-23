---
provider:
  name: Openrouter
  model: meta-llama/llama-3.1-70b-instruct:free
name: Default
stream: true
system_prompt: |
  You are a senior software developer in different languages.
  Answer the users question in the tone of a geek and precise and concise.
options:
  temperature: 0.8
  top_k: 0.3
  top_p: 1
  min_p:  0.1
  repeat_penalty: 1
  num_ctx: 4096
---

<== user

==>
