--!strict
local ComposeTypes = require("../vendor/compose/core")
local Types = require("./types")
local ControlTypes = require("./control_types")
local ThemeTypes = require("./theme_types")
local Engine = require("./engine_types")

export type Component = () -> ComposeTypes.Child
export type AppOptions = Types.Config & {
	runtime: Types.Runtime?,
	parent: Instance?,
	name: string?,
}
export type App = {
	runtime: Types.Runtime,
	UI: ControlTypes.Controls,
	mount: (component: Component, parent: Instance?) -> (() -> (), ScreenGui),
	dispose: () -> (),
}
type RobloxModule = { createRuntime: () -> Types.Runtime }
type StyleLinkHost = { StyleLink: ({ StyleSheet: unknown }) -> Instance }

local function playerGui(): Instance
	local game = getfenv(0).game
	local players = game and game:GetService("Players")
	local player = players and players.LocalPlayer
	if player == nil then
		error("Facet app.mount: there is no PlayerGui here. Give a parent to Facet.app or to app.mount.", 3)
	end
	return player:WaitForChild("PlayerGui")
end

return function(
	Compose: Types.ComposeModule,
	roblox: RobloxModule,
	controls: ControlTypes.Factory,
	themes: ThemeTypes.Themes,
	options: AppOptions?
): App
	local settings: AppOptions = options or {}
	local owned = settings.runtime == nil
	local runtime = settings.runtime or roblox.createRuntime()
	local UI = controls(Compose, runtime, settings)
	local Host = (runtime.constructors :: unknown) :: Engine.Host
	local Links = (runtime.constructors :: unknown) :: StyleLinkHost
	local stops: { () -> () } = {}
	local disposed = false
	local function mount(component: Component, parent: Instance?): (() -> (), ScreenGui)
		assert(not disposed, "Facet app.mount: the app is disposed")
		assert(type(component) == "function", "Facet app.mount: expected a component function")
		local target = parent or settings.parent or playerGui()
		local stop, root = runtime.mount(function(): ComposeTypes.Child
			local sheet = themes.createStyleSheet(runtime, settings.theme, {
				types = settings.types,
				reducedMotion = settings.reducedMotion,
			})
			local props: { [unknown]: unknown } = {
				Name = settings.name or "Facet",
				ResetOnSpawn = false,
				sheet,
				Links.StyleLink({ StyleSheet = Compose.static(sheet) }),
				component(),
			}
			return Host.ScreenGui((props :: unknown) :: Engine.ScreenGuiNativeProps)
		end, target)
		local stopped = false
		local function release()
			if not stopped then
				stopped = true
				local index = table.find(stops, release)
				if index then
					table.remove(stops, index)
				end
				stop()
			end
		end
		table.insert(stops, release)
		return release, (root :: unknown) :: ScreenGui
	end
	local function dispose()
		if disposed then
			return
		end
		disposed = true
		for index = #stops, 1, -1 do
			stops[index]()
		end
		if owned then
			runtime:dispose()
		end
	end
	return table.freeze({ runtime = runtime, UI = UI, mount = mount, dispose = dispose })
end
