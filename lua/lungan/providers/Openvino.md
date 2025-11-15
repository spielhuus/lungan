# Openvino
  
# Preparation
  
To usse Openvino you need to install the python libraries. you can find the required packages in openvino_requirements.txt.
  
# Use the provider
 
add this to lungangs setup function:
 
```lua
providers = {
    Openvino = require("lungan.providers.Openvino"):new({}),
    -- Other providers
},
```
 
## send requests
 
```md
---
provider:
  name: Openvino
  model: Phi-3-mini-4k-instruct-int4-cw-ov
name: Openvino
stream: true
system_prompt: |
  You are a senior software developer in different languages.
  Answer the users question in the tone of a geek and precise and concise.
options:
  temperature: 10
  top_p: 1
  max_new_tokens: 20
---
```
 
## Available parameters
 
### General Generation Parameters
 
*   **max_new_tokens**: The maximum number of tokens to generate, not including the tokens in the prompt. This setting has priority over `max_length`.
*   **min_new_tokens**: The minimum number of tokens to generate. For the first `min_new_tokens`, the probability of the `eos_token_id` is set to 0.
*   **max_length**: The maximum length of the entire generation sequence, including the prompt. The effect of this parameter is overridden by `max_new_tokens` if it is also set.
*   **echo**: If set to `True`, the model will include the prompt in the output.
*   **rng_seed**: The seed for the random number generator, used for reproducible results.
*   **num_return_sequences**: The number of different sequences to generate from a single prompt.
 
### Stopping Conditions
 
*   **eos_token_id**: The token ID that signifies the end of a sentence. Generation will stop when this token is produced, unless `ignore_eos` is set.
*   **ignore_eos**: If set to `True`, the generation process will not stop even if an end-of-sentence (`<eos>`) token is generated.
*   **stop_strings**: A set of strings that, when generated, will cause the pipeline to stop generating more tokens.
*   **include_stop_str_in_output**: If set to `True`, the stop string that caused the generation to stop will be included in the output. The default is `False`.
*   **stop_token_ids**: A set of token IDs that will cause the generation to stop.
*   **stop_criteria**: Defines the condition for stopping the generation process. It can be set to:
    *   `EARLY`: Stops as soon as `num_beams` complete candidates are found.
    *   `HEURISTIC`: Stops when it's unlikely to find better candidates.
    *   `NEVER`: Stops only when no better candidates can be found (canonical beam search).
 
### Penalty and Repetition Control
 
*   **frequency_penalty**: A value that penalizes new tokens based on their existing frequency in the text so far, which can decrease the likelihood of the model repeating the same lines.
*   **presence_penalty**: A value that penalizes new tokens based on whether they have already appeared in the text, which can increase the model's likelihood to talk about new topics.
*   **repetition_penalty**: A penalty applied to repeated tokens to discourage the model from repeating itself.
*   **length_penalty**: A penalty applied to the length of the generated sequence, often used in beam search to favor longer or shorter sequences.
*   **no_repeat_ngram_size**: If set to an integer greater than 0, it prevents n-grams of that size from appearing more than once.
*   **max_ngram_size**: The maximum size of n-grams to consider for certain operations.
 
### Sampling and Beam Search
 
*   **num_beams**: The number of beams to use for beam search.
*   **num_beam_groups**: The number of groups to divide the beams into, which can be used to ensure diversity among the generated sequences.
*   **temperature**: A value used to control the randomness of the output in random sampling. Higher values lead to more random outputs.
*   **top_k**: In top-k sampling, only the `k` most likely next tokens are considered for generation.
*   **top_p**: In top-p (nucleus) sampling, the model considers the smallest set of most probable tokens whose cumulative probability exceeds the value `p`.
 
### Other Parameters
 
*   **num_assistant_tokens**: The number of tokens to use from an assistant model in speculative decoding.
*   **structured_output_config**: This parameter is used to configure structured output generation by combining regular sampling with structural tags.
 
 
