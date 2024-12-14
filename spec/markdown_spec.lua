assert = require("luassert")
describe("Test the markdown parser", function()
	it("should pass the paragraphs", function()
		local lines = {
			"Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
		}
		local types = require("lungan.markdown").types
		local markdown = require("lungan.markdown"):new(nil, lines)
		assert.is.Equal(1, markdown:size())
		assert.same({
			type = types.PARAGRAPH,
			text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
			from = 1,
			to = 1,
		}, markdown:get(1))
	end)
	it("should return the headers", function()
		local lines = {
			"# Header 1",
			"## Header 2",
			"### Header 3",
			"",
			"Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
		}
		local markdown = require("lungan.markdown"):new(nil, lines)
		assert.is.Equal(5, markdown:size())
		assert.same({ type = "header", heading = 1, text = "Header 1", from = 1, to = 1 }, markdown:get(1))
	end)
	it("should return the headers with a smiley", function()
		local lines = {
			"# Header 1 ;)",
			"## Header 2",
			"### Header 3",
			"",
			"Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
		}
		local markdown = require("lungan.markdown"):new(nil, lines)
		assert.is.Equal(5, markdown:size())
		assert.same({ type = "header", heading = 1, text = "Header 1 ;)", from = 1, to = 1 }, markdown:get(1))
	end)
	it("should parse codeblocks", function()
		local lines = {
			"# Header 1",
			"```java",
			"public interface ImAHappyJavaProgrammer {",
			"}",
			"```",
			"Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
		}
		local markdown = require("lungan.markdown"):new(nil, lines)
		assert.is.Equal(3, markdown:size())
		assert.same(
			{ type = "code", lang = "java", from = 2, to = 5, text = "public interface ImAHappyJavaProgrammer {\n}" },
			markdown:get(2)
		)
	end)
	it("should parse codeblocks with parameters", function()
		local lines = {
			"# Header 1",
			'```{java output=true result=false fig.align="center"}',
			"public interface ImAHappyJavaProgrammer {",
			"}",
			"```",
			"Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
		}
		local markdown = require("lungan.markdown"):new(nil, lines)
		assert.is.Equal(3, markdown:size())
		assert.same({
			type = "code",
			lang = "java",
			from = 2,
			to = 5,
			text = "public interface ImAHappyJavaProgrammer {\n}",
			params = { output = true, result = false, fig = { align = "center" } },
		}, markdown:get(2))
	end)
	it("should parse single line codeblocks with parameters", function()
		local lines = {
			"# Header 1",
			'```{d3 element="am" x="x" y="INPUT,DSBSC" data="py$am" fig.cap="Figure 1: Amplitude modulation"}```',
			"Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
		}
		local markdown = require("lungan.markdown"):new(nil, lines)
		-- assert.is.Equal(3, markdown:size())
		assert.same({
			type = "code",
			lang = "d3",
			from = 2,
			to = 2,
			params = {
				element = "am",
				x = "x",
				y = "INPUT,DSBSC",
				data = "py$am",
				fig = { cap = "Figure 1: Amplitude modulation" },
			},
		}, markdown:get(2))
	end)
	it("should parse markdown lists", function()
		local lines = {
			"# Header 1",
			"",
			"- list item 1",
			"- list item 2",
			" - list item 3",
			"* list item 4",
			"* list item 5",
			" * list item 6",
			"1. list item 4",
			"2. list item 5",
			" 1. list item 6",
			"1) list item 4",
			"2) list item 5",
			" 1) list item 6",
		}
		local markdown = require("lungan.markdown"):new(nil, lines)
		assert.is.Equal(14, markdown:size())
		assert.same({ type = "list", from = 3, to = 3, text = "list item 1", level = 0, char = "-" }, markdown:get(3))
		assert.same({ type = "list", from = 4, to = 4, text = "list item 2", level = 0, char = "-" }, markdown:get(4))
		assert.same({ type = "list", from = 5, to = 5, text = "list item 3", level = 1, char = "-" }, markdown:get(5))
		assert.same({ type = "list", from = 6, to = 6, text = "list item 4", level = 0, char = "*" }, markdown:get(6))
		assert.same({ type = "list", from = 7, to = 7, text = "list item 5", level = 0, char = "*" }, markdown:get(7))
		assert.same({ type = "list", from = 8, to = 8, text = "list item 6", level = 1, char = "*" }, markdown:get(8))

		assert.same({ type = "list", from = 9, to = 9, text = "list item 4", level = 0, char = "1" }, markdown:get(9))
		assert.same(
			{ type = "list", from = 10, to = 10, text = "list item 5", level = 0, char = "2" },
			markdown:get(10)
		)
		assert.same(
			{ type = "list", from = 11, to = 11, text = "list item 6", level = 1, char = "1" },
			markdown:get(11)
		)
		assert.same(
			{ type = "list", from = 12, to = 12, text = "list item 4", level = 0, char = "1" },
			markdown:get(12)
		)
		assert.same(
			{ type = "list", from = 13, to = 13, text = "list item 5", level = 0, char = "2" },
			markdown:get(13)
		)
		assert.same(
			{ type = "list", from = 14, to = 14, text = "list item 6", level = 1, char = "1" },
			markdown:get(14)
		)
	end)
	it("should parse frontmatter blocks", function()
		local lines = {
			"---",
			"name: frank",
			"---",
			"# Header 1",
			"",
			"Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
		}
		local markdown = require("lungan.markdown"):new(nil, lines)
		assert.is.Equal(4, markdown:size())
		assert.is.True(markdown:has_frontmatter())
		assert.same({ type = "frontmatter", from = 1, to = 3, text = "name: frank" }, markdown:get(1))
		assert.same({ name = "frank" }, markdown:frontmatter())
	end)
	it("should parse chat blocks", function()
		local lines = {
			"---",
			"name: frank",
			"---",
			"# Header 1",
			"",
			"<== user",
			"chat text",
			"==>",
		}
		local markdown = require("lungan.markdown"):new(nil, lines)
		assert.is.Equal(4, markdown:size())
		assert.is.True(markdown:has_frontmatter())
		assert.same({ type = "frontmatter", from = 1, to = 3, text = "name: frank" }, markdown:get(1))
		assert.is.Equal("chat text", markdown:get(6).text)
		assert.is.Equal("user", markdown:get(6).role)
	end)
	it("should parse a chat prompt", function()
		local handle = io.open(".nvim/lungan/lua.md", "r")
		if not handle then
			error("unable to open file: '.nvim/lungan/lua.md'")
		end
		assert.is.True(handle ~= nil)
		local content = handle:read("*a")
		handle:close()
		local lines = vim.split(content, "\n")
		local markdown = require("lungan.markdown"):new(nil, lines)
		assert.is.Equal(4, markdown:size())

		assert.is.True(markdown:has_frontmatter())
		assert.is.Equal(1, markdown:get(1).from)
		assert.is.Equal(28, markdown:get(1).to)
		assert.is.Equal("Ollama", markdown:frontmatter().provider.name)
	end)

	it("it should parse the full example file", function()
		local handle = io.open("./samples/Full-Markdown.md", "r")
		if not handle then
			return
		end
		local content = handle:read("*a")
		handle:close()
		local lines = vim.split(content, "\n")
		local markdown = require("lungan.markdown"):new(nil, lines)

		assert.is.Equal(313, markdown:size())
		assert.is.False(markdown:has_frontmatter())
	end)
end)
