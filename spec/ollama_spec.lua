local Ollama = require("lungan.providers.Ollama")
local HttpMock = {
	get = function(self, url)
		return 200, '{"models": ["model1", "model2"]}' -- TODO: return real response
	end,
	post = function(self, request, exit_callback, stdout_callback, stderr_callback)
		stdout_callback(nil, {
			'{"model":"llama3.2:1b","created_at":"2024-11-20T05:19:04.592750637Z","message":{"role":"assistant","content":" a"},"done":false}',
			"",
		})
		exit_callback(nil, 0)
	end,
}

describe("Ollama", function()
	before_each(function()
		require("lungan.log").level = "info"
	end)
	it("should initialize with default options", function()
		local ollama = Ollama:new(HttpMock)
		assert.are.equal(ollama.options.name, "Ollama")
		assert.are.equal(ollama.options.model, "llama3.1")
		assert.are.equal(ollama.options.url, "http://127.0.0.1:11434")
	end)

	it("should initialize with custom options", function()
		local ollama = Ollama:new(HttpMock, { model = "custom_model" })
		assert.are.equal(ollama.options.model, "custom_model")
	end)

	it("should parse prompt correctly", function()
		local input = {
			messages = {
				{
					content = "Hi Susi",
					role = "user",
				},
				{
					content = "Hi You",
					role = "assistant",
				},
			},
			name = "Susi",
			options = {
				min_p = 0.1,
				num_ctx = 4096,
				repeat_penalty = 1,
				temperature = 1.8,
				top_k = 0.3,
				top_p = 1,
			},
			provider = {
				model = "some/nice-roleplay:latest",
				name = "Ollama",
			},
			system_prompt = "You are Susi",
		}
		local parsed = Ollama:__parse_prompt(input)
		assert.are.equal("some/nice-roleplay:latest", parsed.model)
		assert.are.equal(3, #parsed.messages)
		assert.are.equal("system", parsed.messages[1].role)
		assert.are.equal("You are Susi", parsed.messages[1].content)
		assert.are.equal("user", parsed.messages[2].role)
		assert.are.equal("Hi Susi", parsed.messages[2].content)
		assert.are.equal("assistant", parsed.messages[3].role)
		assert.are.equal("Hi You", parsed.messages[3].content)
		assert.are.equal(0.1, parsed.options.min_p)
		assert.are.equal(0.3, parsed.options.top_k)
		assert.are.equal(1, parsed.options.top_p)
		assert.are.equal(4096, parsed.options.num_ctx)
		assert.are.equal(1, parsed.options.repeat_penalty)
		assert.are.equal(1.8, parsed.options.temperature)
	end)

	it("should fetch models correctly", function()
		local ollama = Ollama:new(HttpMock, {})
		local status, models
		ollama:models(function(s, m)
			status = s
			models = m
			return status, models
		end)
		assert.are.equal(200, status)
		assert.are.same({ "model1", "model2" }, models)
	end)

	it("should chat correctly", function()
		local input = {
			messages = {
				{
					content = "Hi Susi",
					role = "user",
				},
				{
					content = "Hi You",
					role = "assistant",
				},
			},
			name = "Susi",
			options = {
				min_p = 0.1,
				num_ctx = 4096,
				repeat_penalty = 1,
				temperature = 1.8,
				top_k = 0.3,
				top_p = 1,
			},
			provider = {
				model = "some/nice-roleplay:latest",
				name = "Ollama",
			},
			system_prompt = "You are Susi",
		}
		local ollama = Ollama:new(HttpMock, {})
		local out, ret
		ollama:chat(input, function(stdout)
			out = stdout
		end, function(stderr)
			print("ERR:" .. vim.inspect(stderr))
		end, function(exit)
			ret = exit
		end)
		assert.are.same(out, {
			model = "llama3.2:1b",
			created_at = "2024-11-20T05:19:04.592750637Z",
			message = { role = "assistant", content = " a" },
			done = false,
		})
		assert.are.equal(0, 0)
	end)
end)
