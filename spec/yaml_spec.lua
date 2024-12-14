assert = require("luassert")
describe("Test the YAML parser", function()
	it("should parse key value pairs", function()
		local lines = {
			"name: frank",
			"age: 42",
		}
		local yaml = require("lungan.yaml"):new(nil, lines)
		assert.same({ name = "frank", age = 42 }, yaml.tree)
	end)
	it("should parse maps", function()
		local lines = {
			"person:",
			"  name: frank",
			"  age: 42",
			"name: Persons",
		}
		local yaml = require("lungan.yaml"):new(nil, lines)
		assert.same({ person = { name = "frank", age = 42 }, name = "Persons" }, yaml.tree)
	end)
	-- it("should parse null values", function() TODO
	-- 	local lines = {
	-- 		"name: frank",
	-- 		"age:",
	-- 	}
	-- 	local yaml = require("lungan.yaml"):new(nil, lines)
	-- 	assert.same({ name = "frank", age = nil }, yaml.tree)
	-- end)
	it("should parse numbers", function()
		local lines = {
			"count: 100",
			"price: 3.14",
		}
		local yaml = require("lungan.yaml"):new(nil, lines)
		assert.same({ count = 100, price = 3.14 }, yaml.tree)
	end)
	it("should parse maps with colon in value", function()
		local lines = {
			"provider:",
			"  model: llama3.2:3b",
			"  name: Ollama",
			"name: Llama",
		}
		local yaml = require("lungan.yaml"):new(nil, lines)
		assert.same({ provider = { model = "llama3.2:3b", name = "Ollama" }, name = "Llama" }, yaml.tree)
	end)
	it("should parse maps with special characters", function()
		local lines = {
			"provider:",
			"  model: llama3.2:3b",
			"  name: Ollama",
			"  stream: true",
			"name: Llama",
			"icon: ",
		}
		local yaml = require("lungan.yaml"):new(nil, lines)
		assert.same(
			{ provider = { model = "llama3.2:3b", name = "Ollama", stream = true }, name = "Llama", icon = "" },
			yaml.tree
		)
	end)
	it("should parse maps with boolean value", function()
		local lines = {
			"provider:",
			"  model: llama3.2:3b",
			"  name: Ollama",
			"  stream: true",
			"name: Llama",
		}
		local yaml = require("lungan.yaml"):new(nil, lines)
		assert.same({ provider = { model = "llama3.2:3b", name = "Ollama", stream = true }, name = "Llama" }, yaml.tree)
	end)
	it("should parse sequences", function()
		local lines = {
			"fruits:",
			"  - apple",
			"  - banana",
			"  - cherry",
		}
		local yaml = require("lungan.yaml"):new(nil, lines)
		assert.same({ fruits = { "apple", "banana", "cherry" } }, yaml.tree)
	end)
	it("should parse sequences with maps", function()
		local lines = {
			"people:",
			"  - name: frank",
			"    age: 42",
			"  - name: susi",
			"    age: 30",
		}
		local yaml = require("lungan.yaml"):new(nil, lines)
		assert.same({
			people = {
				{ name = "frank", age = 42 },
				{ name = "susi", age = 30 },
			},
		}, yaml.tree)
	end)
	it("should parse multiline text", function()
		local lines = {
			"prompt: |",
			"  here is the funny text",
			"  that spawns over multiple lines",
			"name: susi",
		}
		local expected = {
			prompt = "here is the funny text\nthat spawns over multiple lines",
			name = "susi",
		}
		local yaml = require("lungan.yaml"):new(nil, lines)
		assert.same(expected, yaml.tree)
	end)
	it("should parse multiline text, with underscore in key", function()
		local lines = {
			"my_prompt: |",
			"  here is the funny text",
			"  that spawns over multiple lines",
			"name: susi",
		}
		local expected = {
			my_prompt = "here is the funny text\nthat spawns over multiple lines",
			name = "susi",
		}
		local yaml = require("lungan.yaml"):new(nil, lines)
		assert.same(expected, yaml.tree)
	end)
	it("should parse the tool prompt", function()
		local lines = {
			"provider:",
			"  name: Ollama",
			"  model: llama3.2:3b-instruct-q4_K_M",
			"name: Weather",
			"stream: true",
			"system_prompt: |",
			"  You are a weather chatbot and answer the users questions about the weather.",
			"options:",
			"  temperature: 0.8",
			"  top_k: 0.3",
			"  top_p: 1",
			"  min_p: 0.1",
			"  repeat_penalty: 1",
			"  num_ctx: 4096",
			"tools:",
			"  - type: function",
			"    function:",
			"      name: get_current_weather",
			"      description: Get the current weather for a location",
			"      parameters:",
			"        type: object",
			"        properties:",
			"          location:",
			"            type: string",
			"            description: The location to get the weather for, e.g. San Francisco, CA",
			"          format:",
			"            type: string",
			"            description: The format to return the weather in, e.g. 'celsius' or 'fahrenheit'",
			"            enum:",
			"              - celsius",
			"              - fahrenheit",
			"        required:",
			"          - location",
			"          - format",
		}
		local expected = {
			provider = {
				model = "llama3.2:3b-instruct-q4_K_M",
				name = "Ollama",
			},
			name = "Weather",
			stream = true,
			system_prompt = "You are a weather chatbot and answer the users questions about the weather.",
			options = {
				min_p = 0.1,
				num_ctx = 4096,
				repeat_penalty = 1,
				temperature = 0.8,
				top_k = 0.3,
				top_p = 1,
			},
			tools = {
				{
					type = "function",
					["function"] = {
						name = "get_current_weather",
						description = "Get the current weather for a location",
						parameters = {
							["type"] = "object",
							properties = {
								location = {
									["type"] = "string",
									description = "The location to get the weather for, e.g. San Francisco, CA",
								},
								format = {
									["type"] = "string",
									description = "The format to return the weather in, e.g. 'celsius' or 'fahrenheit'",
									enum = {
										"celsius",
										"fahrenheit",
									},
								},
							},
							required = {
								"location",
								"format",
							},
						},
					},
				},
			},
		}
		local yaml = require("lungan.yaml"):new(nil, lines)
		assert.same(expected, yaml.tree)
	end)
end)
