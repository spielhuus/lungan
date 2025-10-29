# Lungan.nvim: Markdown Prompt Format

This document outlines the special markdown format used by `lungan.nvim` to create interactive and context-aware prompts for Large Language Models (LLMs). A Lungan prompt file is a standard markdown file composed of two main parts:

1.  **YAML Frontmatter**: A configuration block at the top of the file to define the model, provider, parameters, and special interactive behaviors.
2.  **Chat History**: The body of the file, which structures the conversation for the LLM.

---

## 1. The Frontmatter (YAML Configuration)

The frontmatter is a YAML block enclosed by `---` at the very beginning of the file. It controls every aspect of the LLM session.

### Example

Here is a comprehensive example showcasing many available options:

````yaml
---
# A unique name for this prompt, shown in the Telescope picker.
name: "Refactor Python Code"

# (Required) Specify the LLM provider and model.
provider:
  name: "Ollama"
  model: "codellama:13b"

# Controls whether the response is streamed token-by-token.
stream: true

# Instructions for the LLM. Note the use of a template variable.
system_prompt: |
  You are an expert Python programmer.
  Refactor the following code to be more idiomatic and efficient.
  Only output the refactored code block, with no explanations.

  ```python
  {{SELECTED_CODE}}
  ```

# (Required for context) A Lua function that returns a table of variables
# to be used in the system_prompt.
context: |
  return {
    SELECTED_CODE = require("lungan.utils").GetBlock(
      _A.source_buf, _A.line1, _A.line2
    )
  }

# Model-specific generation parameters.
options:
  temperature: 0.2
  top_p: 0.9
  num_ctx: 4096

# Lua functions to handle the LLM's response interactively.
preview: |
  return require("lungan.nvim.diff").preview(_A, _D)
commit: |
  return require("lungan.nvim.diff").replace(_A, _D)
clear: |
  return require("lungan.nvim.diff").clear_marks(_A)

# Controls automatic text wrapping in the chat buffer.
textwrap: false
---
````


### Key Reference

| Key | Type | Required | Description |
|---|---|---|---|
| `name` | String | Yes | The display name of the prompt in the picker UI. |
| `provider` | Table | Yes | A table containing the `name` of the backend (e.g., "Ollama", "Openrouter") and the `model` identifier. |
| `stream` | Boolean | No | If `true`, the response is displayed token-by-token. Defaults to `true`. |
| `system_prompt` | String | No | The core instruction or persona for the LLM. Can be a multi-line string and supports template variables. |
| `context` | String (Lua) | No | A string containing a Lua function that returns a table. This table's key-value pairs are used to populate `{{template_variables}}` in the `system_prompt`. This is the core of Lungan's context-awareness (RAG). The function receives a global `_A` table with arguments like `source_buf`, `line1`, and `line2`. |
| `options` | Table | No | A table of key-value pairs passed directly to the LLM provider to control generation (e.g., `temperature`, `top_k`, `num_ctx`). |
| `tools` | Table | No | A list of functions the model can call, following the OpenAI function-calling specification. Used for models that support tool use. |
| `preview` | String (Lua) | No | A Lua function string that is executed when you press `<C-y>` (preview). It receives global `_A` (args) and `_D` (parsed chat data) tables and is used to show a preview of the LLM's suggestion. |
| `commit` | String (Lua) | No | A Lua function string executed with `<C-a>` (apply). Used to apply the LLM's suggestion to the source buffer. |
| `clear` | String (Lua) | No | A Lua function string executed with `<C-l>` (clear). Used to remove any preview highlights or virtual text. |
| `textwrap` | Boolean | No | If `false`, long lines in the chat buffer will not be wrapped. Defaults to `true`. |
| `hide_think` | Boolean | No | If `true`, thinking output will be ignored, default `false`. |

## 2. The Chat History Format

The body of the markdown file is used to structure the conversation history. This is useful for providing few-shot examples or continuing a conversation.

Lungan uses a simple, human-readable format to define messages from different roles.

### Syntax

*   **Start of a message**: `<== <role>`
*   **End of a message**: `==>`

The `<role>` is typically `user` or `assistant`.

### Simple Example

This prompt asks the assistant a question. The LLM will generate the response that comes after the final `==>`.

```markdown
<== user

Hello! Can you explain what a closure is in Lua?

==>
```

### Multi-Turn (Few-Shot) Example

You can provide examples to guide the model's response format and tone.

```markdown
<== user

Translate this to French: "Hello, world!"

==>

<== assistant

Bonjour, le monde !

==>

<== user

Now translate this to French: "Where is the library?"

==>
```

---

## 3. Putting It All Together: Advanced Concepts

### Context Injection (RAG)

The `context` key is what makes Lungan so powerful. It runs a Lua function to collect information from your editor *before* sending the prompt to the LLM.

**Workflow:**
1.  You trigger the chat command, possibly with a visual selection.
2.  The Lua code inside the `context` key is executed. It uses utility functions like `require("lungan.utils").GetBlock` to grab the selected text.
3.  It returns a table, for example: `{ SELECTED_CODE = "your selected code here" }`.
4.  The `{{SELECTED_CODE}}` placeholder in your `system_prompt` is replaced with the actual code.
5.  The final, complete prompt is sent to the LLM.

### Interactive Previews

The `preview`, `commit`, and `clear` keys enable the interactive workflow:

*   When the LLM responds, you can press `<C-y>` to trigger the `preview` function. The `lungan.nvim.diff` module can show the LLM's suggested code as a diff against your original code.
*   If you like the suggestion, `<C-a>` triggers the `commit` function to apply the changes.
*   `<C-l>` triggers the `clear` function to remove the diff highlights.
