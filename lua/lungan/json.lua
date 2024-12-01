local json

if vim ~= nil then
	json = vim.json
else
	json = require("rapidjson")
end

return json
