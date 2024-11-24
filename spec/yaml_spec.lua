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
end)
