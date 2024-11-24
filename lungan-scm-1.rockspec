rockspec_format = "3.0"
package = "lungan"
version = "scm-1"

dependencies = {
	"lua >= 5.1",
	"luv",
	"rapidjson",
}

test_dependencies = {
	"lua >= 5.1",
	"nlua",
	"luacheck",
	"luassert",
	"busted",
}

source = {
	url = "git://github.com/spielhuus/" .. package,
}

build = {
	type = "builtin",
	install = {
		bin = {
			lungan = "bin/lungan.lua",
		},
	},
}
