local Openrouter = require("lungan.providers.Openrouter")
local HttpMock = {
	get = function(self, url)
		local file = io.open("spec/openrouter_models.txt", "r")
		if file then
			local content = file:read("*all")
			file:close()
			return 0, content
		else
			return 1, "File not found"
		end
	end,
	post = function(self, request, exit_callback, stdout_callback, stderr_callback)
		stdout_callback(nil, {
			'{"id":"gen-1732085225-Btt5jnvYrsnrQqvkmbSI","provider":"DeepInfra","model":"meta-llama/llama-3.1-8b-instruct","object":"chat.completion.chunk","created":1732085225,"choices":[{"index":0,"delta":{"role":"assistant","content":" happy"},"finish_reason":null,"logprobs":null}]}',
		})
		exit_callback(nil, 0)
	end,
}

describe("Openrouter", function()
	before_each(function()
		require("lungan.log").level = "info"
	end)
	it("should initialize with default options", function()
		local openrouter = Openrouter:new(HttpMock)
		assert.are.equal(openrouter.options.name, "Openrouter")
		assert.are.equal(openrouter.options.url, "https://openrouter.ai")
	end)

	it("should initialize with custom options", function()
		local openrouter = Openrouter:new(HttpMock, { model = "custom_model" })
		assert.are.equal(openrouter.options.model, "custom_model")
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
			stream = true,
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
				name = "Openrouter",
			},
			system_prompt = "You are Susi",
		}
		local parsed = Openrouter:__parse_prompt(nil, input)
		assert.are.equal("some/nice-roleplay:latest", parsed.model)
		assert.are.equal(true, parsed.stream)
		assert.are.equal(3, #parsed.messages)
		assert.are.equal("system", parsed.messages[1].role)
		assert.are.equal("You are Susi", parsed.messages[1].content)
		assert.are.equal("user", parsed.messages[2].role)
		assert.are.equal("Hi Susi", parsed.messages[2].content)
		assert.are.equal("assistant", parsed.messages[3].role)
		assert.are.equal("Hi You", parsed.messages[3].content)
		assert.are.equal(0.1, parsed.min_p)
		assert.are.equal(0.3, parsed.top_k)
		assert.are.equal(1, parsed.top_p)
		assert.are.equal(4096, parsed.num_ctx)
		assert.are.equal(1, parsed.repeat_penalty)
		assert.are.equal(1.8, parsed.temperature)
	end)

	it("should fetch models correctly", function()
		local openrouter = Openrouter:new(HttpMock, {})
		local status, models
		openrouter:models(function(s, m)
			status = s
			models = m
			return status, models
		end)
		assert.are.equal(0, status)
		assert.are.same(195, #models)
		assert.are.equal("openai/gpt-3.5-turbo", models[195].model)
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
				name = "Openrouter",
			},
			system_prompt = "You are Susi",
		}
		local ollama = Openrouter:new(HttpMock, {})
		local out
		ollama:chat({}, input, function(stdout)
			out = stdout
		end, function(stderr)
			print("ERR:" .. vim.inspect(stderr))
		end, function(exit)
			print("EXIT:" .. exit)
		end)

		assert.are.same({
			done = false,
			message = {
				content = " happy",
				role = "assistant",
			},
		}, out)
	end)
end)
