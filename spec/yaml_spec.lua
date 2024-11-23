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
end)
