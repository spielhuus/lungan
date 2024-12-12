---
provider:
  model: llama3.2:1b
  name: Ollama
stream: false
name: Vimdoc
icon:
  character: 
  highlight: DevIconVim
system_prompt: |
  You are a chatbot that can answer questions about neovim.
  In the Context there is a snipped from the neovim docs.
  Use this snipped as knowledge to answer the question.
  
  Context:
  {{system_context}}
system_context: |
  return function(query)
    local Http = require("lungan.nvim.Http")
    local Chroma = require("lungan.db.chroma")
    local http = Http:new()
    local Ollama = require("lungan.providers.Ollama")
    local chroma = Chroma:new(http, {})
    local ollama = Ollama:new(http, {})
    local function collection_id()
    	local uuid
    	chroma:get_or_create_collection(nil, nil, "NEOVIM", function(data)
    		uuid = data
    	end, function(err)
    		print("ERR: " .. vim.inspect(err))
    	end, nil)
    	return uuid
    end
    local function embed(text)
    	local res = ""
    	ollama:embeddings({}, {
    		model = "nomic-embed-text:latest",
    		prompt = text,
    	}, function(out)
    		if out ~= nil then
    			res = res .. table.concat(out, "")
    		end
    	end, function(err)
    		print(vim.inspect(err))
    	end, nil)
    	return vim.json.decode(res)
    end
    local result = { "none" }
  	local uuid = collection_id()
  	local embeddings = embed(query)
  	local data = chroma:collection_query({}, uuid, { embeddings.embedding }, 5, function(data)
        result = data.documents
  	end, function(data)
  		print(data)
  	end, nil)
    return result
  end
options:
  temperature: 0.01
  num_ctx: 4096
---

<== user

==>
