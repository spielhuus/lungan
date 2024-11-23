describe("Test the notebook class", function()
	describe("read the gitignore file", function()
		it("should read the content of the example file", function()
			local notebook = require("lungan.nvim.Notebook")
			local expected = { ".cache", ".luarocks", ".nvim", "test/xdg" }
			assert.same(expected, notebook:_gitignore("spec/notebook"))
		end)
	end)
	describe("test the ignore function", function()
		it("should handle relative paths", function()
			local notebook = require("lungan.nvim.Notebook")
			assert.True(notebook:_is_ignore(".cache", { ".cache" }))
			assert.False(notebook:_is_ignore("lua/luafile.lua", { ".cache" }))
		end)
		it("should handle path patterns", function()
			local notebook = require("lungan.nvim.Notebook")
			assert.True(notebook:_is_ignore("lua/file.bak", { "*.bak" }))
			assert.False(notebook:_is_ignore("lua/luafile.lua", { "*.bak" }))
		end)
		it("should match subdirectories", function()
			local notebook = require("lungan.nvim.Notebook")
			assert.True(notebook:_is_ignore("lua/.cache", { ".cache" }))
		end)
		it("should match subdirectories", function()
			local notebook = require("lungan.nvim.Notebook")
			assert.True(notebook:_is_ignore("test/xdg/local/file.md", { "test/xdg" }))
		end)
	end)
	describe("load the notebooks", function()
		it("should find the example notebooks", function()
			local notebook = require("lungan.nvim.Notebook")
			local expected_pages = {
				{ path = "spec/notebook/logseq/pages/contents.md" },
				{ path = "spec/notebook/logseq/pages/the page.md" },
			}
			local expected_journals = {
				"spec/notebook/journals/2024_06_24.md",
				"spec/notebook/journals/2024_07_21.md",
				"spec/notebook/journals/2024_08_05.md",
				"spec/notebook/journals/2024_09_17.md",
				"spec/notebook/logseq/journals/2024_10_11.md",
			}
			local ignore = notebook:_gitignore("spec/notebook")
			local pages, journals = notebook:_load("spec/notebook", ignore)
			assert.same(expected_pages, pages)
			assert.same(expected_journals, journals)
		end)
	end)
	describe("use the complete notebook class", function()
		it("should create a new notebook and load pages", function()
			local notebook = require("lungan.nvim.Notebook")
			local expected_pages = {
				{ path = "spec/notebook/logseq/pages/contents.md" },
				{ path = "spec/notebook/logseq/pages/the page.md" },
			}
			local expected_journals = {
				"spec/notebook/journals/2024_06_24.md",
				"spec/notebook/journals/2024_07_21.md",
				"spec/notebook/journals/2024_08_05.md",
				"spec/notebook/journals/2024_09_17.md",
				"spec/notebook/logseq/journals/2024_10_11.md",
			}
			local ignore = { ignore = notebook:_gitignore("spec/notebook") }
			local book = notebook:new(nil, ignore, "spec/notebook")
			assert.is.Equal(#expected_pages, #book.pages)
			assert.is.Equal(expected_pages[1].path, book.pages[1].path)
			assert.is.Equal(expected_pages[2].path, book.pages[2].path)
			assert.same(expected_journals, book.journals)
		end)
		it("should get a page by filename", function()
			local notebook = require("lungan.nvim.Notebook")
			local expected_page = "spec/notebook/logseq/pages/contents.md"
			local ignore = { ignore = notebook:_gitignore("spec/notebook") }
			local book = notebook:new(nil, ignore, "spec/notebook")
			assert.is.Equal(expected_page, book:get_page("spec/notebook/logseq/pages/contents.md"):filename())
		end)
		it("should find page when name is an absolute path", function()
			local notebook = require("lungan.nvim.Notebook")
			local expected_page = "spec/notebook/logseq/pages/contents.md"
			local ignore = { ignore = notebook:_gitignore("spec/notebook") }
			local book = notebook:new(nil, ignore, "spec/notebook")
			local root = vim.fn.fnamemodify(vim.fn.getcwd(), ":p")
			assert.is.Equal(expected_page, book:get_page(root .. "spec/notebook/logseq/pages/contents.md"):filename())
		end)
	end)
end)
