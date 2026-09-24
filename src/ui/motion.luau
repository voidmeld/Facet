--!strict
local Compose = require("../vendor/compose/core")
local Shared = require("./types")

return function(ctx: Shared.Context): (Compose.Use?) -> boolean
	local config = ctx.config
	local gui = config.guiService
	local native: Compose.Cell<boolean>? = if gui then ctx.observe(gui, "ReducedMotionEnabled") else nil
	return function(use: Compose.Use?): boolean
		if ctx.read(config.reducedMotion, use) == true then
			return true
		end
		if native == nil then
			return false
		end
		return (if use then use(native) else native:peek()) == true
	end
end
