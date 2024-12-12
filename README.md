# lungan

| <!-- -->     | <!-- -->                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
|--------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Build Status | [![unittests](https://img.shields.io/github/actions/workflow/status/spielhuus/lungan/busted.yml?branch=main&style=for-the-badge&label=Unittests)](https://github.com/spielhuus/lungan/actions/workflows/test.yml)  [![documentation](https://img.shields.io/github/actions/workflow/status/spielhuus/lungan/documentation.yml?branch=main&style=for-the-badge&label=Documentation)](https://github.com/spielhuus/lungan/actions/workflows/documentation.yml)  [![luacheck](https://img.shields.io/github/actions/workflow/status/spielhuus/lungan/luacheck.yml?branch=main&style=for-the-badge&label=Luacheck)](https://github.com/spielhuus/lungan/actions/workflows/luacheck.yml) [![llscheck](https://img.shields.io/github/actions/workflow/status/spielhuus/lungan/llscheck.yml?branch=main&style=for-the-badge&label=llscheck)](https://github.com/spielhuus/lungan/actions/workflows/llscheck.yml) |
| License      | [![License-MIT](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](https://github.com/spielhuus/lungan/blob/main/LICENSE)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| Social       | [![RSS](https://img.shields.io/badge/rss-F88900?style=for-the-badge&logo=rss&logoColor=white)](https://github.com/spielhuus/lungan/commits/main/doc/news.txt.atom)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |

# title 1

create me a README.md template for a neovim plugin project on github.
it shall contain all the usual features.
the plugin name is 'lungan.nvim'

the goals are:
- orgnanize your work wirh notebok files
- chat with various LLMs about your project and notebook files
- maintain a history of the chat sessions
- use project sources code as context
- create predefined tasks for the project and snippets
- markdown files as project logbook and documentation
- executable markdown files, use markdown to develop and document your project

the features are:
- create runnable notebooks with markdown files
- the files can contain executable code blocks using lua and python 
- parse all the mardown files in the project directory as one notebook
- navigate the notebook using links
- full obsidian markdown support
- integration of local and remote llms
- work togheter with the llm on your file
- create intelligent prompts in markdown that supports RAG und function calling
- preview of your notebook

the plugin home is: https://github.com/spielhuus/lungan/
the supported neovim version is 0.10
descibe the installation process with lazy and packer

create banners for the version, release, neovim  version and github action test run

dependencies are: 
- https://github.com/nvim-telescope/telescope.nvim



## second

# lungan

Lungan is a neovim plugin for ollama and llamacpp integration into neovim. 
with llamacode you can create your own prompts and content receiver. 



## Markdown Format

To display LLM expressions in Markdown, a rather unusual syntax is used. 
The requirements are that the syntax must be parseable with Tree-sitter
and that syntax highlighting for Markdown and code in fences still works.
The chosen format is `[role](command) hello assistant [/role]`. This parses
as Markdown links and gives us the possibility to use different targets
(URLs) like prompt or embed, among other options.

## utility functions

```py
import matplotlib
import sys
matplotlib.use('module://lungan')
import lungan

```


There are util function to receive content:

get the entire buffer:

```py
for i in range(10):
    print(i)
```

get the code block under the cursor.

```lua
print("hello from lua") 
```

get the *visual* selection

```py
a = 44
b = 25
a + b
```
aaa

```py
a = 44
a/0
```

```py
import matplotlib
matplotlib.use('module://lungan')

import matplotlib.pyplot as plt
import numpy as np

xpoints = np.array([1, 8])
ypoints = np.array([3, 10])

plt.plot(xpoints, ypoints)
plt.show()
```


```py
a = "hello mom"
```

```py
print(a)
```

## chat templates

### methods

- preview(args, data)

## test with busted

[https://mrcjkb.dev/posts/2023-06-06-luarocks-test.html](Test your Neovim plugins with luarocks & busted)
[https://hiphish.github.io/blog/2024/01/29/testing-neovim-plugins-with-busted/](Testing Neovim plugins with Busted)

run the docker file

```docker
docker run --user 1000:1000 -it -v /home/etienne:/home/etienne nvim
```

### other content

# Credits

- [neovim plugin template](https://github.com/ColinKennedy/nvim-best-practices-plugin-template/tree/main)


- [A tiny logging module for Lua](https://github.com/rxi/log.lua)



# TODO

- catch error when ipython could not be found
- support for images
- is completion support needed?
- tools calling
- chromadb integration
- refactor logger
- dont execute luarocks when in neovim
- add openrouter prices to cmp description
- create api doc

# other notes

reso
