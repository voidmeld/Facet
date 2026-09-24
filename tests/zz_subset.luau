local process = require("@lune/process")
local testkit = require("./lib/testkit")
for _, name in string.split(process.args[1], ",") do
	local fs = require("@lune/fs")
	local ending = if fs.isFile("tests/" .. name .. ".spec.luau") then ".spec" else "_spec"
	require("./" .. name .. ending)
end
if not testkit.run({ tier = "one", registeredSpecs = 1 }) then
	process.exit(1)
end
