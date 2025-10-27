# lungan.nvim

[![Build Status](https://img.shields.io/github/actions/workflow/status/spielhuus/lungan/busted.yml?branch=main&style=for-the-badge&label=Tests)](https://github.com/spielhuus/lungan/actions/workflows/test.yml)
[![Neovim v0.10+](https://img.shields.io/badge/Neovim-v0.10+-blueviolet?style=for-the-badge&logo=neovim)](https://neovim.io/)
[![License-MIT](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](https://github.com/spielhuus/lungan/blob/main/LICENSE)

**lungan.nvim** is a Neovim plugin that transforms your editor into an interactive development environment. It seamlessly integrates notebook-style file management, REPL-driven code execution, and powerful Large Language Model (LLM) integration, allowing you to organize, document, and develop your projects all within markdown files.
 
Chat with local and remote LLMs, execute code blocks on the fly, and maintain a rich, interactive logbook of your project's lifecycle.

## Goals

*   **Organize** your work with interactive notebook files.
*   **Chat** with various LLMs about your project and files.
*   **Maintain** a persistent history of your chat sessions.
*   **Use** your project's source code as context for LLMs.
*   **Create** predefined tasks and snippets to streamline your workflow.
*   **Develop and document** your project simultaneously with executable markdown.

## Features

*   **Executable Notebooks**: Create runnable notebooks using standard markdown files.
*   **Multi-Language REPL**: Execute code blocks in both **Lua** and **Python** directly from your notebook.
*   **Unified Project View**: Parse all markdown files in your project directory as a single, navigable notebook.
*   **Local & Remote LLM Integration**: Connect to a wide range of LLMs, including local instances via Ollama and remote services like OpenRouter and Google AI Studio.
*   **Optimized Local Inference**: Supports Intel hardware acceleration through **OpenVINO**.
*   **Intelligent AI Prompts**: Craft sophisticated prompts in markdown that support RAG (Retrieval-Augmented Generation) and function calling.
*   **Interactive Chat**: Work collaboratively with an LLM on your files in a dedicated chat window.
*   **Live Preview**: Instantly preview and apply changes suggested by the LLM.

## Dependencies

*   [Neovim v0.10+](https://github.com/neovim/neovim)
*   [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (for prompt picking)
*   Python 3 environment for Neovim (`pynvim` package).

## Installation

You can install `lungan.nvim` using your favorite plugin manager.

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
-- lua/plugins/lungan.lua
return {
  "spielhuus/lungan",
  dependencies = { "nvim-telescope/telescope.nvim" },
  config = function()
    require("lungan.nvim").setup({
      -- Backend configuration goes here. See the "Supported LLM Backends" section below.
    })
  end,
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
-- init.lua
use {
  "spielhuus/lungan",
  requires = { "nvim-telescope/telescope.nvim" },
  config = function()
    require("lungan.nvim").setup({
      -- Backend configuration goes here.
    })
  end,
}
```

## Supported LLM Backends

Lungan supports a variety of local and remote LLM backends. You can enable and configure them in the `setup()` function.

### Ollama

Connect to a local Ollama server for fast, private inference.

*   **Prerequisites**: [Ollama](https://ollama.com/) must be installed and running.
*   **Configuration**:
    ```lua
    require("lungan.nvim").setup({
      providers = {
        Ollama = require("lungan.providers.Ollama"):new(require("lungan.nvim.Http"):new(), {
          url = "http://127.0.0.1:11434", -- Default Ollama URL
        }),
      },
    })
    ```

### OpenVINO

Run GGUF and native OpenVINO models optimized for Intel hardware (including integrated GPUs). This backend uses the `openvino-genai` Python library via Neovim's remote plugin host.

*   **Prerequisites**:
    1.  The `pynvim` Python package must be installed (`pip install pynvim`).
    2.  Install the required OpenVINO packages: `pip install -r openvino-requirements.txt`.
    3.  Download your OpenVINO models to the directory specified in the `url` option.
*   **Configuration**:
    ```lua
    require("lungan.nvim").setup({
      providers = {
        Openvino = require("lungan.providers.Openvino"):new(nil, {
          url = vim.fn.expand("~") .. "/.models/OpenVINO/", -- Path to your models
        }),
      },
    })
    ```

### OpenRouter

Access a wide variety of models from different providers through the OpenRouter API.

*   **Prerequisites**: You must set your API key as an environment variable: `export OPENROUTER_API_TOKEN="your_api_key"`.
*   **Configuration**:
    ```lua
    require("lungan.nvim").setup({
      providers = {
        Openrouter = require("lungan.providers.Openrouter"):new(require("lungan.nvim.Http"):new(), {}),
      },
    })
    ```

### Google AI Studio

Use Google's Gemini family of models via the AI Studio API.

*   **Prerequisites**: You must set your API key as an environment variable: `export AISTUDIO_API_TOKEN="your_api_key"`.
*   **Configuration**:
    ```lua
    require("lungan.nvim").setup({
      providers = {
        AiStudio = require("lungan.providers.AiStudio"):new(require("lungan.nvim.Http"):new(), {}),
      },
    })
    ```

## Usage

Lungan provides two primary modes of operation: interactive notebooks (REPL) and chatting with an LLM.

### Commands

| Command | Description |
|---|---|
| `:Lg Chat` | Open a Telescope picker to select and start a chat with an LLM. |
| `:Lg Attach`| Attach lungan's REPL and rendering capabilities to the current markdown buffer. |
| `:Lg Notebooks`| Open a Telescope picker to browse and open notebook files in your project. |

### 1. Interactive Notebooks (REPL)

Turn any markdown file into an executable notebook. First, open a markdown file and attach Lungan to it.

```
:Lg Attach
```

Once attached, you can execute code blocks directly within the buffer.

| Keybinding | Description |
|---|---|
| `<leader>nr` | Run the code cell currently under the cursor. |
| `<leader>na` | Run all code cells in the current notebook from top to bottom. |
| `<leader>nc` | Clear all execution results from the notebook view. |

The output, including plots from libraries like `matplotlib`, will be rendered directly below the code cell.

### 2. Chat with an LLM

Start a conversation with an AI assistant to get help with your code, generate documentation, or refactor a selection.

1.  **(Optional)** Select a region of code in visual mode or place your cursor on a code block.
2.  Run the `:Lg Chat` command.
3.  Choose a prompt from the Telescope picker.

This will open a dedicated chat window. The frontmatter of the chat buffer allows you to configure the provider, model, and other parameters for the session.

| Keybinding (in Chat Buffer) | Description |
|---|---|
| `<C-r>` | Run the chat and send the prompt to the LLM. |
| `<C-c>` | Stop a currently running LLM request. |
| `<C-y>` | **Preview** the changes suggested by the LLM as a diff in the original buffer. |
| `<C-a>` | **Apply** the suggested changes to your original buffer. |
| `<C-l>` | Clear the preview diff marks from the original buffer. |
| `<C-n>` | Insert a new user message template to continue the conversation. |
