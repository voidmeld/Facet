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

t.describe("native parity restore: Table multi-select keys", function()
	local held: { [string]: boolean } = {}
	local function racers(): { { id: string, name: string } }
		return {
			{ id = "razz", name = "Razz" },
			{ id = "bolt", name = "Bolt" },
			{ id = "josh", name = "Josh" },
			{ id = "mint", name = "Mint" },
			{ id = "nova", name = "Nova" },
		}
	end
	local function tableWorld(mode: string?): (World, any, any)
		table.clear(held)
		local selection = Compose.cell({})
		local focus: any = {}
		local w = world(function(UI)
			return UI.Table "Racers" {
				from = racers(),
				key = "id",
				itemSize = 40,
				focus = focus,
				selection = selection,
				selectionMode = mode or "multi",
				columns = {
					{
						id = "name",
						label = "Racer",
						value = function(item)
							return item.name
						end,
					},
				},
			}
		end)
		w.input.IsKeyDown = function(_, key: any)
			return held[key.Name] == true
		end
		local body = find(w.screen, "Body")
		body.AbsoluteWindowSize = w.engine.types.Vector2.new(300, 400)
		return w, selection, focus
	end
	local function hit(w: World, key: string): any
		return find(find(w.screen, "Body"), key):FindFirstChild("RowHit", true)
	end
	local function click(w: World, key: string, ...: string)
		for _, name in { ... } do
			held[name] = true
		end
		hit(w, key).Activated.fire({ UserInputType = w.engine.types.Enum.UserInputType.MouseButton1 }, 1)
		table.clear(held)
	end
	local function tap(w: World, key: string)
		hit(w, key).Activated.fire({ UserInputType = w.engine.types.Enum.UserInputType.Touch }, 1)
	end
	local function returnKey(w: World, key: string)
		local E = w.engine.types.Enum
		hit(w, key).Activated.fire({ UserInputType = E.UserInputType.Keyboard, KeyCode = E.KeyCode.Return }, 1)
	end
	local function arrow(w: World, name: string)
		w.screen:FindFirstChild("FacetCollection" .. name):FindFirstChild("Collection" .. name).Pressed.fire()
	end
	local function selected(selection: any): { string }
		local out: { string } = {}
		for key, on in selection:peek() do
			if on then
				table.insert(out, key)
			end
		end
		table.sort(out)
		return out
	end

	t.it("replaces a multi selection on a plain mouse click", function()
		local w, selection = tableWorld()
		tap(w, "razz")
		tap(w, "bolt")
		t.expect(selected(selection)).toEqual({ "bolt", "razz" })
		click(w, "josh")
		t.expect(selected(selection)).toEqual({ "josh" })
		w.stop()
	end)

	t.it("toggles rows in and out of a multi selection on a Ctrl-click and a Cmd-click", function()
		for _, modifier in { "LeftControl", "RightControl", "LeftMeta", "RightMeta", "LeftSuper" } do
			local w, selection = tableWorld()
			click(w, "razz")
			click(w, "josh", modifier)
			t.expect(selected(selection)).toEqual({ "josh", "razz" })
			click(w, "razz", modifier)
			t.expect(selected(selection)).toEqual({ "josh" })
			w.stop()
		end
	end)

	t.it("extends a contiguous range from the anchor on a Shift-click and re-ranges from the same anchor", function()
		local w, selection = tableWorld()
		click(w, "razz")
		click(w, "josh", "LeftShift")
		t.expect(selected(selection)).toEqual({ "bolt", "josh", "razz" })
		click(w, "bolt", "RightShift")
		t.expect(selected(selection)).toEqual({ "bolt", "razz" })
		w.stop()
	end)

	t.it("selects a reversed range when a Shift-click goes from a later row to an earlier one", function()
		local w, selection = tableWorld()
		click(w, "josh")
		click(w, "razz", "LeftShift")
		t.expect(selected(selection)).toEqual({ "bolt", "josh", "razz" })
		w.stop()
	end)

	t.it("keeps Ctrl-toggled rows when a Shift-click ranges from a toggled anchor", function()
		local w, selection = tableWorld()
		click(w, "razz")
		click(w, "josh", "LeftControl")
		click(w, "nova", "LeftShift")
		t.expect(selected(selection)).toEqual({ "josh", "mint", "nova", "razz" })
		w.stop()
	end)

	t.it("keeps the additive toggle for a touch tap and a gamepad press", function()
		local w, selection = tableWorld()
		tap(w, "razz")
		tap(w, "josh")
		t.expect(selected(selection)).toEqual({ "josh", "razz" })
		local E = w.engine.types.Enum
		hit(w, "razz").Activated.fire({ UserInputType = E.UserInputType.Gamepad1, KeyCode = E.KeyCode.ButtonA }, 1)
		t.expect(selected(selection)).toEqual({ "josh" })
		w.stop()
	end)

	t.it("honors held modifiers on a keyboard Return", function()
		local w, selection = tableWorld()
		returnKey(w, "razz")
		t.expect(selected(selection)).toEqual({ "razz" })
		held.LeftControl = true
		returnKey(w, "razz")
		t.expect(selected(selection)).toEqual({})
		table.clear(held)
		returnKey(w, "bolt")
		held.LeftShift = true
		returnKey(w, "mint")
		t.expect(selected(selection)).toEqual({ "bolt", "josh", "mint" })
		w.stop()
	end)

	t.it("extends the selection from the anchor with Shift and an arrow, and moves focus with it", function()
		local w, selection, focus = tableWorld()
		focus.focus("bolt")
		t.expect(w.gui.SelectedObject).toBe(hit(w, "bolt"))
		returnKey(w, "bolt")
		t.expect(selected(selection)).toEqual({ "bolt" })
		held.LeftShift = true
		arrow(w, "Down")
		arrow(w, "Down")
		t.expect(focus.current:peek()).toBe("mint")
		t.expect(selected(selection)).toEqual({ "bolt", "josh", "mint" })
		arrow(w, "Up")
		t.expect(selected(selection)).toEqual({ "bolt", "josh" })
		arrow(w, "Up")
		arrow(w, "Up")
		t.expect(focus.current:peek()).toBe("razz")
		t.expect(selected(selection)).toEqual({ "bolt", "razz" })
		w.stop()
	end)

	t.it("extends to the first and the last row with Shift and Home or End", function()
		local w, selection, focus = tableWorld()
		focus.focus("josh")
		returnKey(w, "josh")
		held.LeftShift = true
		arrow(w, "Last")
		t.expect(focus.current:peek()).toBe("nova")
		t.expect(selected(selection)).toEqual({ "josh", "mint", "nova" })
		arrow(w, "First")
		t.expect(selected(selection)).toEqual({ "bolt", "josh", "razz" })
		w.stop()
	end)

	t.it("starts a keyboard range at the focused row when nothing anchors it", function()
		local w, selection, focus = tableWorld()
		focus.focus("josh")
		held.RightShift = true
		arrow(w, "Down")
		t.expect(selected(selection)).toEqual({ "josh", "mint" })
		w.stop()
	end)

	t.it("moves focus with Ctrl and an arrow and with a plain arrow without changing the selection", function()
		local w, selection, focus = tableWorld()
		focus.focus("razz")
		returnKey(w, "razz")
		held.LeftControl = true
		arrow(w, "Down")
		arrow(w, "Down")
		t.expect(focus.current:peek()).toBe("josh")
		t.expect(selected(selection)).toEqual({ "razz" })
		table.clear(held)
		arrow(w, "Down")
		t.expect(focus.current:peek()).toBe("mint")
		t.expect(selected(selection)).toEqual({ "razz" })
		w.stop()
	end)

	t.it("replaces in single mode whatever the modifiers and ignores a Shift-arrow", function()
		local w, selection, focus = tableWorld("single")
		click(w, "razz")
		click(w, "josh", "LeftControl")
		t.expect(selected(selection)).toEqual({ "josh" })
		click(w, "mint", "LeftShift")
		t.expect(selected(selection)).toEqual({ "mint" })
		focus.focus("mint")
		held.LeftShift = true
		arrow(w, "Down")
		t.expect(selected(selection)).toEqual({ "mint" })
		w.stop()
	end)
end)
