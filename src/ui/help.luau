--!strict
local Types = require("./types")

type Show = (GuiObject, Types.Value<string>) -> ()

local registry = setmetatable({} :: { [Types.Context]: Show }, { __mode = "k" })

local help = {}

function help.register(ctx: Types.Context, show: Show)
	registry[ctx] = show
end

function help.attach(ctx: Types.Context, anchor: GuiObject, text: Types.Value<string>)
	local show = registry[ctx]
	if show then
		show(anchor, text)
	end
end

return help
