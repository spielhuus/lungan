---
provider:
  name: Ollama
  model: llama3.2:3b-instruct-q4_K_M
name: Weather
stream: false
system_prompt: |
  You are a weather chatbot and answer the users questions about the weather.
options:
  temperature: 0.8
  top_k: 0.3
  top_p: 1
  min_p: 0.1
  repeat_penalty: 1
  num_ctx: 4096
tools:
  - type: function
    function:
      name: get_current_weather
      description: Get the current weather for a location
      parameters:
        type: object
        properties:
          location:
            type: string
            description: The location to get the weather for, e.g. San Francisco, CA
          format:
            type: string
            description: The format to return the weather in, e.g. 'celsius' or 'fahrenheit'
            enum:
              - celsius
              - fahrenheit
        required:
          - location
          - format
---

<== user

what is the weather in rapperswil

==>



