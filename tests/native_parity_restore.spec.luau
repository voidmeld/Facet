--!strict
local t = require("./lib/testkit")
local Facet = require("../src")
local engineLib = require("./lib/native_engine")
local Compose = Facet.Compose

type World = {
	engine: any,
	runtime: any,
	UI: any,
	Host: any,
	gui: any,
	input: any,
	screen: any,
	stop: () -> (),
}

local function world(build: (any, any, any) -> any, options: { [string]: any }?, engineOptions: any?): World
	local engine: any = engineLib.new(engineOptions)
	local runtime = Facet.Roblox.createRuntime(engine)
	local gui = engine.new("GuiService")
	local input = engine.new("UserInputService")
	input.GetFocusedTextBox = function()
		return nil
	end
	input.IsKeyDown = function()
		return false
	end
	local config: { [string]: any } = {
		types = engine.types,
		guiService = gui,
		reducedMotion = true,
		services = { GuiService = gui, UserInputService = input },
	}
	for key, value in (options or {}) :: { [string]: any } do
		config[key] = value
	end
	local UI = Facet.controls(runtime, config :: any)
	local Host = runtime.constructors
	local stop, screen = runtime.mount(function()
		return Host.ScreenGui({ build(UI, Host, engine) })
	end, engine.new("Folder"))
	return {
		engine = engine,
		runtime = runtime,
		UI = UI,
		Host = Host,
		gui = gui,
		input = input,
		screen = screen,
		stop = function()
			stop()
			runtime:dispose()
		end,
	}
end

local function find(root: any, name: string): any
	if root.Name == name then
		return root
	end
	for _, child in root:GetChildren() do
		local found = find(child, name)
		if found then
			return found
		end
	end
	return nil
end

t.describe("native parity restore: ErrorBoundary", function()
	t.it("renders its view when healthy and does not mount the fallback", function()
		local w = world(function(UI, Host)
			return UI.ErrorBoundary "EB" {
				view = function()
					return Host.TextLabel "Happy" { Text = "ok" }
				end,
				fallback = function()
					return Host.TextLabel "Fallback" { Text = "broken" }
				end,
			}
		end)
		local boundary = find(w.screen, "EB")
		t.expect(boundary ~= nil).toBe(true)
		t.expect(find(boundary, "Happy") ~= nil).toBe(true)
		t.expect(find(w.screen, "Fallback")).toBeNil()
		t.expect(boundary:GetAttribute("FacetError")).toBeNil()
		w.stop()
	end)

	t.it("swaps a view that throws at mount to its fallback, reports once and keeps siblings", function()
		local reported: { string } = {}
		local w = world(function(UI, Host)
			return Host.Frame "Column" {
				Host.TextLabel "Sibling" { Text = "alive" },
				UI.ErrorBoundary({
					Name = "EB",
					view = function()
						error("factory exploded", 0)
					end,
					fallback = function(failure)
						return Host.TextLabel "Fallback" { Text = tostring(failure) }
					end,
					onError = function(failure)
						table.insert(reported, tostring(failure))
					end,
				}),
			}
		end)
		t.expect(find(w.screen, "Sibling") ~= nil).toBe(true)
		local fallback = find(find(w.screen, "EB"), "Fallback")
		t.expect(fallback ~= nil).toBe(true)
		t.expect(fallback.Text).toBe("factory exploded")
		t.expect(reported).toEqual({ "factory exploded" })
		t.expect(find(w.screen, "EB"):GetAttribute("FacetError")).toBe("factory exploded")
		w.stop()
	end)

	t.it("trips at runtime when a structural rebuild inside it throws, and the writer survives", function()
		local explode = Compose.cell(false)
		local viewCleanups = 0
		local w = world(function(UI, Host)
			return UI.ErrorBoundary "EB" {
				view = function()
					Compose.cleanup(function()
						viewCleanups += 1
					end)
					return Host.Frame "V" {
						Compose.show(explode, function()
							error("branch exploded", 0)
						end),
						Host.TextLabel "Content" { Text = "fine" },
					}
				end,
				fallback = function(failure)
					return Host.TextLabel "Fallback" { Text = tostring(failure) }
				end,
			}
		end)
		t.expect(find(w.screen, "Content") ~= nil).toBe(true)
		local ok = pcall(function()
			explode:set(true)
		end)
		t.expect(ok).toBe(true)
		t.expect(find(w.screen, "Content")).toBeNil()
		t.expect(find(w.screen, "Fallback").Text).toBe("branch exploded")
		t.expect(viewCleanups).toBe(1)
		local probe = Compose.cell(1)
		probe:set(2)
		t.expect(probe:peek()).toBe(2)
		w.stop()
	end)

	t.it("retries the view from the fallback and clears the reported error", function()
		local broken = true
		local w = world(function(UI, Host)
			return UI.ErrorBoundary "EB" {
				view = function()
					if broken then
						error("not ready", 0)
					end
					return Host.TextLabel "Ready" { Text = "ready" }
				end,
				fallback = function(_, retry)
					return Host.TextButton "Retry" {
						Text = "Retry",
						Activated = retry,
					}
				end,
			}
		end)
		local boundary = find(w.screen, "EB")
		t.expect(boundary:GetAttribute("FacetError")).toBe("not ready")
		find(boundary, "Retry").Activated.fire()
		t.expect(find(boundary, "Retry") ~= nil).toBe(true)
		broken = false
		find(boundary, "Retry").Activated.fire()
		t.expect(find(boundary, "Retry")).toBeNil()
		t.expect(find(boundary, "Ready") ~= nil).toBe(true)
		t.expect(boundary:GetAttribute("FacetError")).toBeNil()
		w.stop()
	end)

	t.it("sends a failure to the factory onError when the boundary has no onError", function()
		local reported: { string } = {}
		local w = world(function(UI, Host)
			return UI.ErrorBoundary "EB" {
				view = function()
					error("unowned", 0)
				end,
				fallback = function()
					return Host.Frame "Fallback" {}
				end,
			}
		end, {
			onError = function(failure)
				table.insert(reported, tostring(failure))
			end,
		})
		t.expect(reported).toEqual({ "unowned" })
		w.stop()
	end)

	t.it("contains a throwing keyed row factory and releases every owner on disposal", function()
		local rows = Compose.cell({ { id = "a" }, { id = "b" } })
		local live = 0
		local w = world(function(UI, Host)
			return UI.ErrorBoundary "EB" {
				view = function()
					return Host.Frame "Rows" {
						Compose.keyed({
							from = rows,
							key = function(row)
								return row.id
							end,
							render = function(row)
								if row:peek().id == "c" then
									error("row factory throws for c", 0)
								end
								live += 1
								Compose.cleanup(function()
									live -= 1
								end)
								return Host.TextLabel({ Name = row:peek().id })
							end,
						}),
					}
				end,
				fallback = function()
					live += 1
					Compose.cleanup(function()
						live -= 1
					end)
					return Host.TextLabel "Fallback" { Text = "broken" }
				end,
			}
		end)
		t.expect(live).toBe(2)
		rows:set({ { id = "a" }, { id = "c" } })
		t.expect(find(w.screen, "Fallback") ~= nil).toBe(true)
		t.expect(find(w.screen, "a")).toBeNil()
		t.expect(live).toBe(1)
		w.stop()
		t.expect(live).toBe(0)
	end)

	t.it("leaves a failure outside any boundary a hard mount error", function()
		local engine: any = engineLib.new()
		local runtime = Facet.Roblox.createRuntime(engine)
		local Host = runtime.constructors
		local ok, message = pcall(function()
			runtime.mount(function()
				return Host.Frame({
					Compose.show(Compose.cell(true), function()
						error("no boundary here", 0)
					end),
				})
			end, engine.new("ScreenGui"))
		end)
		runtime:dispose()
		t.expect(ok).toBe(false)
		t.expect(string.find(tostring(message), "no boundary here", 1, true) ~= nil).toBe(true)
	end)

	t.it("accepts both construction forms and refuses a boundary without a view or a fallback", function()
		local w = world(function(UI, Host)
			return Host.Frame({
				UI.ErrorBoundary({
					Name = "Healthy",
					view = function()
						return Host.TextLabel "Ok" { Text = "ok" }
					end,
					fallback = function()
						return Host.TextLabel "HealthyFallback" {}
					end,
				}),
				UI.ErrorBoundary "Broken" {
					view = function(): any
						error("factory exploded", 0)
					end,
					fallback = function()
						return Host.TextLabel "BrokenFallback" {}
					end,
				},
			})
		end)
		t.expect(find(find(w.screen, "Healthy"), "Ok") ~= nil).toBe(true)
		t.expect(find(w.screen, "HealthyFallback")).toBeNil()
		t.expect(find(find(w.screen, "Broken"), "BrokenFallback") ~= nil).toBe(true)
		for _, spec in
			{
				{ fallback = function() end },
				{ view = function() end },
			} :: { any }
		do
			local refused = pcall(function()
				local probe = world(function(UI)
					return UI.ErrorBoundary(spec)
				end)
				probe.stop()
			end)
			t.expect(refused).toBe(false)
		end
		w.stop()
	end)
end)

local function ratio(first: any, second: any): number
	local function luminance(value: any): number
		local function linear(channel: number): number
			return if channel <= 0.04045 then channel / 12.92 else ((channel + 0.055) / 1.055) ^ 2.4
		end
		return 0.2126 * linear(value.r) + 0.7152 * linear(value.g) + 0.0722 * linear(value.b)
	end
	local a, b = luminance(first), luminance(second)
	return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05)
end

local function sortedKeys(value: { [string]: any }): { string }
	local keys: { string } = {}
	for key in value do
		table.insert(keys, key)
	end
	table.sort(keys)
	return keys
end

t.describe("native parity restore: Facet Neutral Light", function()
	t.it("declares Dark then Light and both palettes pass the contrast gate", function()
		local themes = Facet.themes
		local neutral = themes.neutralPackage()
		t.expect(neutral.style.defaultTheme).toBe("Dark")
		t.expect(#neutral.style.themes).toBe(2)
		local dark, light = neutral.style.themes[1], neutral.style.themes[2]
		t.expect(dark.name).toBe("Dark")
		t.expect(light.name).toBe("Light")
		t.expect(sortedKeys(light.colors)).toEqual(sortedKeys(dark.colors))
		t.expect(sortedKeys(light.extra)).toEqual(sortedKeys(dark.extra))
		local defined, report = themes.define(neutral)
		t.expect(defined ~= nil).toBe(true)
		t.expect(report.ok).toBe(true)
		t.expect(#report.contrast).toBe(14)
		for _, result in report.contrast do
			t.expect(result.ok).toBe(true)
		end
		for _, pair in { { "content", "surface" }, { "contentStrong", "surfaceStrong" }, { "onAccent", "accent" } } do
			t.expect(ratio(light.colors[pair[1]], light.colors[pair[2]]) >= 4.5).toBe(true)
		end
		t.expect(ratio(light.colors.content, light.extra.controlSelected) >= 4.5).toBe(true)
		t.expect(ratio(light.extra.contentSecondary, light.colors.surface) >= 4.5).toBe(true)
		t.expect(ratio(light.colors.content, light.extra.control) >= 4.5).toBe(true)
		t.expect(ratio(light.colors.surface, dark.colors.surface) > 10).toBe(true)
	end)

	t.it("keeps a derived package to its own palettes and inherits only the first", function()
		local themes = Facet.themes
		local plain = assert(themes.define({
			identity = { id = "derived", displayName = "Derived", version = "1.0.0" },
		} :: any))
		t.expect(#plain.style.themes).toBe(1)
		t.expect(plain.style.themes[1].name).toBe("Dark")
		local based = assert(themes.define({
			base = themes.neutralPackage(),
			identity = { id = "based", displayName = "Based", version = "1.0.0" },
		} :: any))
		t.expect(#based.style.themes).toBe(1)
		local paired = assert(themes.define({
			identity = { id = "paired", displayName = "Paired", version = "1.0.0" },
			style = { defaultTheme = "Day", themes = { { name = "Day" }, { name = "Night" } } },
		} :: any))
		t.expect(#paired.style.themes).toBe(2)
		t.expect(#themes.neutralPackage().style.themes).toBe(2)
	end)

	t.it("paints each Neutral palette through the native sheet and follows a palette change", function()
		local themes = Facet.themes
		local engine: any = engineLib.new()
		local runtime = Facet.Roblox.createRuntime(engine)
		local neutral = themes.neutralPackage()
		local selected = Compose.cell("Dark")
		local stop, sheet = runtime.mount(function()
			return themes.createStyleSheet(runtime, neutral, { types = engine.types, theme = selected } :: any)
		end, engine.new("Folder"))
		local function textColor(): any
			for _, rule in sheet:GetChildren() do
				if rule.Selector == ".facet-text" then
					return rule:GetProperties().TextColor3
				end
			end
			return nil
		end
		local function expected(palette: any): any
			local value = palette.colors.content
			return engine.types.Color3.new(value.r, value.g, value.b)
		end
		t.expect(textColor()).toBe(expected(neutral.style.themes[1]))
		selected:set("Light")
		t.expect(textColor()).toBe(expected(neutral.style.themes[2]))
		stop()
		runtime:dispose()
	end)
end)
