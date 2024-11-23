

## models 

example for the list of models:

```lua
{
  {
    details = {
      families = { "llama" },
      family = "llama",
      format = "gguf",
      parameter_size = "20.4B",
      parent_model = "",
      quantization_level = "Q4_K_M"
    },
    digest = "5a2bfc42029214f66bb4fb6f0897c7b13a97a37583e9da5b0e5f3f57f8abd67a", 
    description = "" -- required
    model = "vanilj/theia-21b-v1:latest", -- required
    name = "vanilj/theia-21b-v1:latest", -- required
    modified_at = "2024-08-28T08:07:14.022036563+02:00",
    size = 12362930035
  },
  {
      ...
  }
}
```

response from openrouter

```json
{
  {
    "id": "undi95/toppy-m-7b:free",
    "name": "Toppy M 7B (free)",
    "created": 1699574400,
    "description": "A wild 7B parameter model that merges several models using the new task_arithmetic merge method from mergekit.\nList of merged models:\n- NousResearch/Nous-Capybara-7B-V1.9\n- [HuggingFaceH4/zephyr-7b-beta](/huggingfaceh4/zephyr-7b-beta)\n- lemonilia/AshhLimaRP-Mistral-7B\n- Vulkane/120-Days-of-Sodom-LoRA-Mistral-7b\n- Undi95/Mistral-pippa-sharegpt-7b-qlora\n\n#merge #uncensored\n\n_These are free, rate-limited endpoints for [Toppy M 7B](/undi95/toppy-m-7b). Outputs may be cached. Read about rate limits [here](/docs/limits)._",
    "context_length": 4096,
    "architecture": {
      "modality": "text->text",
      "tokenizer": "Mistral",
      "instruct_type": "alpaca"
    },
    "pricing": {
      "prompt": "0",
      "completion": "0",
      "image": "0",
      "request": "0"
    },
    "top_provider": {
      "context_length": 4096,
      "max_completion_tokens": 2048,
      "is_moderated": false
    },
    "per_request_limits": null
  },  
  {
      ...
  }
}
```
