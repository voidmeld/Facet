--!strict
local t = require("./lib/testkit")
local Facet = require("../src")
local icons = require("../src/ui/icons")
local engineLib = require("./lib/native_engine")
local Compose = Facet.Compose
local themes = Facet.themes

local SHIPPED: { any } = {
	require("../examples/themes/classic_desktop"),
	require("../examples/themes/compact_pointer"),
	require("../examples/themes/fantasy_ornate"),
	require("../examples/themes/fantasy_parchment"),
	require("../examples/themes/glossy_mobile"),
	require("../examples/themes/glossy_touch"),
	require("../examples/themes/pixel_quest"),
	require("../examples/themes/scifi_hud"),
}

local function make(options: { [string]: any }?): (any, any, any)
	local engine: any = engineLib.new()
	local runtime = Facet.Roblox.createRuntime(engine)
	local gui = engine.new("GuiService")
	local config: { [string]: any } = {
		types = engine.types,
		guiService = gui,
		services = { GuiService = gui },
	}
	for key, value in (options or {}) :: { [string]: any } do
		config[key] = value
	end
	return engine, runtime, Facet.controls(runtime, config :: any)
end

local function mount(engine: any, runtime: any, build: () -> any): (() -> (), any)
	local stop, root = runtime.mount(build, engine.new("ScreenGui"))
	return stop, root
end

local function refusal(build: (any, any) -> any, options: { [string]: any }?): { [string]: any }
	local engine, runtime, UI = make(options)
	local parent = engine.new("ScreenGui")
	local before = engine.census()
	local made = #engine.made
	local ok, message = pcall(function()
		runtime.mount(function()
			return build(UI, runtime.constructors)
		end, parent)
	end)
	local after = engine.census()
	runtime:dispose()
	return {
		message = if ok then nil else tostring(message),
		created = #engine.made - made,
		live = after.live - before.live,
		connections = after.connections - before.connections,
		heartbeat = engine.heartbeat.count(),
	}
end

local function refusedWith(result: { [string]: any }, fragment: string): boolean
	return result.message ~= nil and string.find(result.message, fragment, 1, true) ~= nil
end

local function style(sheet: any, selector: string): any
	for _, node in sheet:GetChildren() do
		if node.Selector == selector then
			return node
		end
	end
	error("No rule: " .. selector)
end

local function color(engine: any, value: any): any
	return engine.types.Color3.new(value.r, value.g, value.b)
end

local function statusTags(node: any): { string }
	local found = {}
	for _, tag in node:GetTags() do
		if string.match(tag, "^facet%-status%-") then
			table.insert(found, tag)
		end
	end
	table.sort(found)
	return found
end

local function progressReader(presentation: string, root: any): () -> number
	if presentation == "bar" then
		local fill = root:FindFirstChild("Fill1", true)
		return function()
			return fill.Position.X.Scale
		end
	elseif presentation == "circular" then
		local arc = root:FindFirstChild("RingFill", true)
		return function()
			local point = arc:GetControlPoints()[1].Position
			return point.X.Scale * 1000 + point.Y.Scale
		end
	end
	local dot = root:FindFirstChild("Segment1", true)
	return function()
		return dot.BackgroundTransparency
	end
end

local function distinctReadings(presentation: string, reduced: boolean, step: number, count: number): number
	local engine, runtime, UI = make({ reducedMotion = reduced })
	local stop, root = mount(engine, runtime, function()
		return UI.ProgressView({ presentation = presentation })
	end)
	local reading = progressReader(presentation, root)
	local seen, distinct = {}, 0
	local function record()
		local key = string.format("%.6f", reading())
		if not seen[key] then
			seen[key] = true
			distinct += 1
		end
	end
	record()
	for _ = 1, count do
		engine.heartbeat.fire(step)
		record()
	end
	stop()
	runtime:dispose()
	return distinct
end

t.describe("native parity media", function()
	t.describe("progress motion", function()
		t.it("sweeps an indeterminate bar segment inside its clipped track and repeats every second", function()
			local engine, runtime, UI = make()
			local stop, root = mount(engine, runtime, function()
				return UI.ProgressView({})
			end)
			local track = root:FindFirstChild("Track", true)
			local clip = track:FindFirstChild("FillClip")
			local fill = clip:FindFirstChild("Fill1")
			t.expect(track.ClipsDescendants).toBe(false)
			t.expect(clip.ClipsDescendants).toBe(true)
			t.expect(clip.Size).toBe(engine.types.UDim2.fromScale(1, 1))
			t.expect(fill.Parent).toBe(clip)
			t.expect(fill.Size.X.Scale).toBeCloseTo(0.3)
			t.expect(fill.Position.X.Scale).toBeCloseTo(-0.3)
			engine.heartbeat.fire(0.25)
			t.expect(fill.Position.X.Scale).toBeCloseTo(0.025)
			engine.heartbeat.fire(0.25)
			t.expect(fill.Position.X.Scale).toBeCloseTo(0.35)
			engine.heartbeat.fire(0.75)
			t.expect(fill.Position.X.Scale).toBeCloseTo(0.025)
			for _ = 1, 40 do
				engine.heartbeat.fire(0.037)
				local left = fill.Position.X.Scale
				t.expect(left).toBeGreaterThanOrEqual(-0.3 - 1e-6)
				t.expect(left).toBeLessThanOrEqual(1 + 1e-6)
				t.expect(left + fill.Size.X.Scale).toBeGreaterThanOrEqual(-1e-6)
				t.expect(fill.Size.X.Scale).toBeCloseTo(0.3)
			end
			t.expect(engine.heartbeat.count()).toBeGreaterThan(0)
			stop()
			t.expect(engine.heartbeat.count()).toBe(0)
			runtime:dispose()
		end)

		t.it("holds a reduced-motion indeterminate bar within a quarter and then steps", function()
			local engine, runtime, UI = make({ reducedMotion = true })
			local stop, root = mount(engine, runtime, function()
				return UI.ProgressView({})
			end)
			local fill = root:FindFirstChild("Fill1", true)
			local start = fill.Position.X.Scale
			t.expect(start).toBeCloseTo(-0.3)
			engine.heartbeat.fire(0.1)
			t.expect(fill.Position.X.Scale).toBe(start)
			engine.heartbeat.fire(0.1)
			t.expect(fill.Position.X.Scale).toBe(start)
			engine.heartbeat.fire(0.1)
			t.expect(fill.Position.X.Scale).toBeCloseTo(0.25 * 1.3 - 0.3)
			engine.heartbeat.fire(0.25)
			t.expect(fill.Position.X.Scale).toBeCloseTo(0.5 * 1.3 - 0.3)
			stop()
			runtime:dispose()
		end)

		t.it("shows four quarter poses per cycle under reduced motion for bar, circular and spinner", function()
			for _, presentation in { "bar", "circular", "spinner" } do
				t.expect(distinctReadings(presentation, true, 0.05, 19)).toBe(4)
				local full = distinctReadings(presentation, false, 0.02, 20)
				local reduced = distinctReadings(presentation, true, 0.02, 20)
				t.expect(full).toBe(21)
				t.expect(reduced).toBe(2)
				t.expect(full).toBeGreaterThan(reduced)
			end
		end)

		t.it("steps from the running phase when reduced motion turns on mid-cycle instead of restarting", function()
			local reduced = Compose.cell(false)
			local engine, runtime, UI = make({ reducedMotion = reduced })
			local stop, root = mount(engine, runtime, function()
				return UI.ProgressView({})
			end)
			local fill = root:FindFirstChild("Fill1", true)
			engine.heartbeat.fire(0.6)
			t.expect(fill.Position.X.Scale).toBeCloseTo(0.6 * 1.3 - 0.3)
			reduced:set(true)
			t.expect(fill.Position.X.Scale).toBeCloseTo(0.5 * 1.3 - 0.3)
			t.expect(math.abs(fill.Position.X.Scale - -0.3) > 0.1).toBe(true)
			engine.heartbeat.fire(0.1)
			t.expect(fill.Position.X.Scale).toBeCloseTo(0.5 * 1.3 - 0.3)
			engine.heartbeat.fire(0.1)
			t.expect(fill.Position.X.Scale).toBeCloseTo(0.75 * 1.3 - 0.3)
			reduced:set(false)
			t.expect(fill.Position.X.Scale).toBeCloseTo(0.8 * 1.3 - 0.3)
			stop()
			runtime:dispose()
		end)

		t.it("refuses an unknown progress presentation before creating native nodes or a clock", function()
			local refused = refusal(function(UI)
				return UI.ProgressView({ value = 1, presentation = "ring" })
			end)
			t.expect(refusedWith(refused, "presentation must be bar, circular or spinner")).toBe(true)
			t.expect(refused.created).toBe(0)
			t.expect(refused.heartbeat).toBe(0)
			for _, presentation in { "bar", "circular", "spinner" } do
				local accepted = refusal(function(UI)
					return UI.ProgressView({ value = 1, presentation = presentation })
				end)
				t.expect(accepted.message).toBeNil()
				t.expect(accepted.created).toBeGreaterThan(0)
			end
		end)

		t.it("authors distinct circular and spinner metrics in every shipped theme package", function()
			local neutral = themes.neutralPackage().metrics.controls.progress
			local smallest, largest = { size = math.huge, dot = math.huge }, { size = 0, dot = 0 }
			local engine, runtime = make()
			t.expect(#SHIPPED).toBe(8)
			for _, module in SHIPPED do
				local package, report = module.build(themes)
				t.expect(report.ok).toBe(true)
				local progress = package.metrics.controls.progress
				for _, field in { "circularSize", "circularThickness", "spinnerDotSize" } do
					t.expect(type(progress[field])).toBe("number")
					t.expect(progress[field]).toBeGreaterThan(0)
				end
				t.expect(
					progress.circularSize == neutral.circularSize
						and progress.circularThickness == neutral.circularThickness
						and progress.spinnerDotSize == neutral.spinnerDotSize
				).toBe(false)
				smallest.size = math.min(smallest.size, progress.circularSize)
				largest.size = math.max(largest.size, progress.circularSize)
				smallest.dot = math.min(smallest.dot, progress.spinnerDotSize)
				largest.dot = math.max(largest.dot, progress.spinnerDotSize)
				local themed: any = Facet.controls(runtime, { types = engine.types, theme = package } :: any)
				local stop, root = mount(engine, runtime, function()
					return runtime.constructors.Frame({
						themed.ProgressView "Ring" { value = 0.5, presentation = "circular" },
						themed.ProgressView "Spinner" { presentation = "spinner" },
					})
				end)
				local ring = root:FindFirstChild("Ring", true):FindFirstChild("Indicator", true)
				t.expect(ring.Size.X.Offset).toBe(progress.circularSize)
				t.expect(ring:FindFirstChild("RingFill").Thickness)
					.toBe(math.max(progress.circularThickness, math.round(progress.circularSize * 0.08)))
				t.expect(root:FindFirstChild("Spinner", true):FindFirstChild("Segment1", true).Size.X.Offset)
					.toBe(progress.spinnerDotSize)
				stop()
			end
			t.expect(largest.size / smallest.size).toBeGreaterThanOrEqual(2)
			t.expect(largest.dot / smallest.dot).toBeGreaterThanOrEqual(2)
			runtime:dispose()
		end)
	end)

	t.describe("badge", function()
		t.it("keeps one icon instance through every reactive status and repaints it with the partner color", function()
			local engine, runtime, UI = make()
			local status = Compose.cell("neutral")
			local package = themes.neutralPackage()
			local sheet, badge
			local stop = mount(engine, runtime, function()
				sheet = themes.createStyleSheet(runtime, package, { types = engine.types })
				badge = UI.Badge({ label = "Ready", icon = "checkmark", status = status })
				return runtime.constructors.Frame({ sheet, badge })
			end)
			local icon = badge:FindFirstChildWhichIsA("ImageLabel")
			local label = badge:FindFirstChild("Label")
			t.expect(icon:HasTag("facet-icon")).toBe(true)
			t.expect(icon.Parent).toBe(badge)
			t.expect(label.Parent).toBe(badge)
			local palette: any = package.style.themes[1]
			local partners = {
				neutral = palette.colors.surface,
				info = palette.colors.onAccent,
				success = palette.colors.onSuccess,
				warning = palette.colors.onWarning,
				error = palette.colors.onDanger,
				accent = palette.colors.onAccent,
			}
			for _, name in { "info", "success", "warning", "error", "accent", "neutral" } do
				status:set(name)
				t.expect(statusTags(badge)).toEqual({ "facet-status-" .. name })
				t.expect(badge:FindFirstChildWhichIsA("ImageLabel")).toBe(icon)
				t.expect(badge:FindFirstChild("Label")).toBe(label)
				t.expect(label.Text).toBe("Ready")
				t.expect(icon.Image).toBe(icons.ART.checkmark.contentId)
				t.expect(style(sheet, ".facet-status-" .. name .. " > .facet-icon"):GetProperties().ImageColor3)
					.toBe(color(engine, partners[name]))
			end
			t.expect(color(engine, partners.warning) ~= color(engine, palette.colors.content)).toBe(true)
			t.expect(pcall(function()
				status:set("danger")
			end)).toBe(false)
			status:set("warning")
			t.expect(statusTags(badge)).toEqual({ "facet-status-warning" })
			stop()
			runtime:dispose()
		end)

		t.it("gives an icon badge the plain caption height and orders the icon by its position", function()
			local engine, runtime, UI = make()
			local stop, root = mount(engine, runtime, function()
				return runtime.constructors.Frame({
					UI.Badge "Plain" { label = "Ranked" },
					UI.Badge "Leading" { label = "Ranked", icon = "checkmark" },
					UI.Badge "Trailing" { label = "Ranked", icon = "checkmark", iconPosition = "trailing" },
					UI.Badge "Large" { label = "Ranked", icon = "checkmark", controlSize = "large" },
				})
			end)
			local plain = root:FindFirstChild("Plain", true)
			local leading = root:FindFirstChild("Leading", true)
			local trailing = root:FindFirstChild("Trailing", true)
			local large = root:FindFirstChild("Large", true)
			t.expect(plain.ClassName).toBe("TextLabel")
			t.expect(plain.Size.Y.Offset).toBe(24)
			t.expect(leading.Size.Y.Offset).toBe(plain.Size.Y.Offset)
			t.expect(trailing.Size.Y.Offset).toBe(plain.Size.Y.Offset)
			t.expect(large.Size.Y.Offset).toBe(28)
			for _, badge in { leading, trailing } do
				t.expect(badge.ClassName).toBe("Frame")
				t.expect(badge:HasTag("facet-badge")).toBe(true)
				t.expect(#badge:GetChildren()).toBe(3)
				t.expect(badge:FindFirstChildWhichIsA("UIListLayout").SortOrder)
					.toBe(engine.types.Enum.SortOrder.LayoutOrder)
				t.expect(badge:FindFirstChildWhichIsA("ImageLabel").Size).toBe(engine.types.UDim2.fromOffset(14, 14))
			end
			t.expect(large:FindFirstChildWhichIsA("ImageLabel").Size).toBe(engine.types.UDim2.fromOffset(17, 17))
			local leadingIcon, leadingLabel =
				leading:FindFirstChildWhichIsA("ImageLabel"), leading:FindFirstChild("Label")
			local trailingIcon, trailingLabel =
				trailing:FindFirstChildWhichIsA("ImageLabel"), trailing:FindFirstChild("Label")
			t.expect(leadingIcon.LayoutOrder).toBeLessThan(leadingLabel.LayoutOrder)
			t.expect(trailingIcon.LayoutOrder).toBeGreaterThan(trailingLabel.LayoutOrder)
			stop()
			runtime:dispose()
		end)

		t.it("paints the status appearance as a neutral pill with a leading dot and utility as plateless", function()
			local engine, runtime, UI = make()
			local appearance = Compose.cell("status")
			local package = themes.neutralPackage()
			local sheet, badge
			local stop = mount(engine, runtime, function()
				sheet = themes.createStyleSheet(runtime, package, { types = engine.types })
				badge = UI.Badge({ label = "Live", status = "error", appearance = appearance })
				return runtime.constructors.Frame({ sheet, badge })
			end)
			local palette: any = package.style.themes[1]
			local statusRule, errorRule = style(sheet, ".facet-badge-status"), style(sheet, ".facet-status-error")
			t.expect(statusRule.Priority).toBeGreaterThan(errorRule.Priority)
			t.expect(statusRule:GetProperties().BackgroundColor3).toBe(color(engine, palette.extra.control))
			t.expect(errorRule:GetProperties().BackgroundColor3).toBe(color(engine, palette.colors.danger))
			t.expect(badge:HasTag("facet-badge-status")).toBe(true)
			local dot = badge:FindFirstChild("Status")
			t.expect(dot ~= nil).toBe(true)
			t.expect(dot:HasTag("facet-status-error")).toBe(true)
			t.expect(dot.LayoutOrder).toBe(-1)
			t.expect(dot.Size).toBe(engine.types.UDim2.fromOffset(8, 8))
			appearance:set("utility")
			t.expect(badge:HasTag("facet-badge-utility")).toBe(true)
			t.expect(badge:HasTag("facet-badge-status")).toBe(false)
			t.expect(badge:FindFirstChild("Status")).toBeNil()
			t.expect(dot.isDestroyed()).toBe(true)
			t.expect(style(sheet, ".facet-badge-utility"):GetProperties().BackgroundTransparency).toBe(1)
			t.expect(style(sheet, ".facet-badge-utility"):GetProperties().TextColor3)
				.toBe(color(engine, palette.extra.contentSecondary))
			appearance:set("standard")
			t.expect(badge:HasTag("facet-badge-standard")).toBe(true)
			t.expect(badge:HasTag("facet-badge-utility")).toBe(false)
			t.expect(badge:FindFirstChild("Status")).toBeNil()
			appearance:set("status")
			t.expect(badge:FindFirstChild("Status"):HasTag("facet-status-error")).toBe(true)
			stop()
			runtime:dispose()
		end)

		t.it("mounts and clears a live caption on a named icon badge while the plate and icon stay", function()
			local engine, runtime, UI = make()
			local caption = Compose.cell(nil :: string?)
			local stop, badge = mount(engine, runtime, function()
				return UI.Badge({ label = caption, icon = "checkmark", name = "Info" })
			end)
			local label, icon = badge:FindFirstChild("Label"), badge:FindFirstChildWhichIsA("ImageLabel")
			t.expect(label.Text).toBe("")
			t.expect(badge:GetAttribute("AccessibleLabel")).toBe(nil)
			t.expect(label:GetAttribute("AccessibleLabel")).toBe("Info")
			caption:set("Ready")
			t.expect(label.Text).toBe("Ready")
			t.expect(badge:FindFirstChild("Label")).toBe(label)
			t.expect(badge:FindFirstChildWhichIsA("ImageLabel")).toBe(icon)
			caption:set(nil)
			t.expect(label.Text).toBe("")
			t.expect(badge:FindFirstChild("Label")).toBe(label)
			t.expect(badge:FindFirstChildWhichIsA("ImageLabel")).toBe(icon)
			t.expect(label.isDestroyed()).toBe(false)
			t.expect(icon.isDestroyed()).toBe(false)
			stop()
			runtime:dispose()
		end)
	end)

	t.describe("avatar", function()
		t.it("suppresses the presence mark but keeps presence in the accessible label", function()
			local engine, runtime, UI = make()
			local members = {
				{ id = "a", name = "Ada", presence = "away" },
				{ id = "b", name = "Bo", presence = "online" },
			}
			local stop, root = mount(engine, runtime, function()
				return runtime.constructors.Frame({
					UI.Avatar "Hidden" { name = "Ada", presence = "away", presenceMark = false },
					UI.Avatar "Shown" { name = "Ada", presence = "away" },
					UI.AvatarGroup "Stacked" { items = members },
					UI.AvatarGroup "Spread" { items = members, layout = "spread" },
				})
			end)
			local hidden, shown = root:FindFirstChild("Hidden", true), root:FindFirstChild("Shown", true)
			t.expect(hidden:FindFirstChild("Presence")).toBeNil()
			t.expect(hidden:GetAttribute("AccessibleLabel")).toBe("Ada, away")
			t.expect(shown:FindFirstChild("Presence") ~= nil).toBe(true)
			t.expect(shown:GetAttribute("AccessibleLabel")).toBe("Ada, away")
			local stacked, spread = root:FindFirstChild("Stacked", true), root:FindFirstChild("Spread", true)
			for _, id in { "a", "b" } do
				t.expect(stacked:FindFirstChild(id):FindFirstChild("Presence")).toBeNil()
				t.expect(spread:FindFirstChild(id):FindFirstChild("Presence") ~= nil).toBe(true)
			end
			t.expect(stacked:FindFirstChild("a"):GetAttribute("AccessibleLabel")).toBe("Ada, away")
			t.expect(spread:FindFirstChild("b"):FindFirstChild("Presence"):HasTag("facet-status-success")).toBe(true)
			stop()
			runtime:dispose()
		end)

		t.it("refuses an invalid name, form, presence or option before acquiring the resource", function()
			local acquired = 0
			local function resource()
				acquired += 1
				return { state = Compose.cell("ready"), value = Compose.cell("rbxassetid://5") }
			end
			local cases: { { any } } = {
				{ {}, "Avatar name must be nonempty" },
				{ { name = "" }, "Avatar name must be nonempty" },
				{ { name = "A", form = "photo" }, "Avatar invalid form" },
				{ { name = "A", presence = "wrong" }, "Avatar invalid presence" },
				{ { name = "A", unexpected = true }, "Unknown Facet option unexpected" },
			}
			for _, case in cases do
				local spec = table.clone(case[1])
				spec.resource = resource
				local refused = refusal(function(UI)
					return UI.Avatar(spec)
				end)
				t.expect(refusedWith(refused, case[2])).toBe(true)
				t.expect(acquired).toBe(0)
			end
			local engine, runtime, UI = make()
			local stop, avatar = mount(engine, runtime, function()
				return UI.Avatar({ name = "A", resource = resource })
			end)
			t.expect(acquired).toBe(1)
			t.expect(avatar:FindFirstChild("Image", true).Image).toBe("rbxassetid://5")
			stop()
			runtime:dispose()
		end)

		t.it("refuses a non-string overflow label and recovers the next valid label", function()
			local engine, runtime, UI = make()
			local label = Compose.cell("More" :: any)
			local stop, group = mount(engine, runtime, function()
				return UI.AvatarGroup({
					items = {
						{ id = "a", name = "Ada" },
						{ id = "b", name = "Bo" },
						{ id = "c", name = "Cy" },
					},
					max = 1,
					overflowLabel = label,
				})
			end)
			local overflow = group:FindFirstChild("Overflow")
			t.expect(overflow:GetAttribute("AccessibleLabel")).toBe("More")
			t.expect(overflow.Text).toBe("+2")
			t.expect(pcall(function()
				label:set(42)
			end)).toBe(false)
			t.expect(overflow:GetAttribute("AccessibleLabel")).toBe("More")
			label:set("Tout")
			t.expect(overflow:GetAttribute("AccessibleLabel")).toBe("Tout")
			label:set(nil)
			t.expect(overflow:GetAttribute("AccessibleLabel")).toBe("2 more players")
			t.expect(group:FindFirstChild("Overflow")).toBe(overflow)
			stop()
			runtime:dispose()
		end)
	end)

	t.describe("skeleton and status indicator", function()
		t.it("sizes a skeleton by a bound rung, refuses an unknown rung and recovers", function()
			local engine, runtime, UI = make()
			local rung = Compose.cell("compact" :: string?)
			local stop, root = mount(engine, runtime, function()
				return runtime.constructors.Frame({
					UI.Skeleton "Circle" { form = "circle", controlSize = rung },
					UI.Skeleton "Line" { form = "line", controlSize = rung },
				})
			end)
			local circle = root:FindFirstChild("Circle", true):FindFirstChild("Placeholder1")
			local line = root:FindFirstChild("Line", true):FindFirstChild("Placeholder1")
			t.expect(circle.Size).toBe(engine.types.UDim2.fromOffset(36, 36))
			t.expect(line.Size).toBe(engine.types.UDim2.new(1, 0, 0, 16))
			rung:set("large")
			t.expect(circle.Size).toBe(engine.types.UDim2.fromOffset(56, 56))
			t.expect(line.Size).toBe(engine.types.UDim2.new(1, 0, 0, 24))
			rung:set(nil)
			t.expect(circle.Size).toBe(engine.types.UDim2.fromOffset(44, 44))
			t.expect(line.Size).toBe(engine.types.UDim2.new(1, 0, 0, 20))
			t.expect(pcall(function()
				rung:set("wrong")
			end)).toBe(false)
			t.expect(circle.Size).toBe(engine.types.UDim2.fromOffset(44, 44))
			rung:set("large")
			t.expect(circle.Size).toBe(engine.types.UDim2.fromOffset(56, 56))
			t.expect(line.Size).toBe(engine.types.UDim2.new(1, 0, 0, 24))
			stop()
			runtime:dispose()
		end)

		t.it("refuses malformed skeleton declarations and leaves no shared clock running", function()
			local cases: { { any } } = {
				{ { form = "wrong" }, "Skeleton invalid form" },
				{ { form = "box", lines = 2 }, "lines require line form" },
				{ { form = "line", lines = 0 }, "lines must be positive" },
				{ { form = "line", lines = 1.5 }, "lines must be positive" },
				{ { form = "circle", corners = "pill" }, "circle owns its corners" },
				{ { form = "box", surprise = true }, "Unknown Facet option surprise" },
			}
			for _, case in cases do
				local refused = refusal(function(UI)
					return UI.Skeleton(case[1])
				end)
				t.expect(refusedWith(refused, case[2])).toBe(true)
				t.expect(refused.heartbeat).toBe(0)
				t.expect(refused.live).toBe(0)
			end
		end)

		t.it("releases the shared skeleton clock after a construction refuses and restarts it for the next", function()
			local engine, runtime, UI = make()
			t.expect(function()
				mount(engine, runtime, function()
					return UI.Skeleton({ form = "box", controlSize = "wrong" })
				end)
			end).toThrow()
			t.expect(engine.heartbeat.count()).toBe(0)
			local stop, root = mount(engine, runtime, function()
				return UI.Skeleton({ form = "box" })
			end)
			t.expect(engine.heartbeat.count()).toBeGreaterThan(0)
			local shimmer = root:FindFirstChild("Shimmer", true)
			local before = shimmer.Offset.X
			engine.heartbeat.fire(0.2)
			t.expect(shimmer.Offset.X).toBeGreaterThan(before)
			stop()
			t.expect(engine.heartbeat.count()).toBe(0)
			runtime:dispose()
		end)

		t.it("sizes a status indicator by the checked rung metrics and falls back to regular", function()
			local engine, runtime, UI = make()
			local rung = Compose.cell("compact" :: string?)
			local stop, root = mount(engine, runtime, function()
				return runtime.constructors.Frame({
					UI.StatusIndicator "Sized" { status = "info", controlSize = rung },
					UI.StatusIndicator "Plain" { status = "info" },
				})
			end)
			local sized, plain = root:FindFirstChild("Sized", true), root:FindFirstChild("Plain", true)
			local metrics = themes.neutralPackage().metrics.controlSizes
			t.expect(sized.Size).toBe(engine.types.UDim2.fromOffset(metrics.compact.iconSize, metrics.compact.iconSize))
			t.expect(plain.Size).toBe(engine.types.UDim2.fromOffset(12, 12))
			rung:set("large")
			t.expect(sized.Size).toBe(engine.types.UDim2.fromOffset(metrics.large.iconSize, metrics.large.iconSize))
			rung:set(nil)
			t.expect(sized.Size).toBe(engine.types.UDim2.fromOffset(metrics.regular.iconSize, metrics.regular.iconSize))
			t.expect(pcall(function()
				rung:set("tiny")
			end)).toBe(false)
			t.expect(sized.Size).toBe(engine.types.UDim2.fromOffset(metrics.regular.iconSize, metrics.regular.iconSize))
			t.expect(plain.Size).toBe(engine.types.UDim2.fromOffset(12, 12))
			stop()
			runtime:dispose()
		end)
	end)

	t.describe("async image and stage", function()
		t.it("blends a bound dimmed image and restores it", function()
			local engine, runtime, UI = make()
			local dimmed = Compose.cell(false)
			local stop, root = mount(engine, runtime, function()
				return UI.AsyncImage({ image = "rbxassetid://1", dimmed = dimmed })
			end)
			local image = root:FindFirstChild("Image")
			t.expect(image.Image).toBe("rbxassetid://1")
			t.expect(image.ImageTransparency).toBe(0)
			dimmed:set(true)
			t.expect(image.ImageTransparency).toBe(0.35)
			dimmed:set(false)
			t.expect(image.ImageTransparency).toBe(0)
			t.expect(root:FindFirstChild("Image")).toBe(image)
			stop()
			runtime:dispose()
		end)

		t.it("places an owned stage camera by CFrame and field of view and destroys it with the stage", function()
			local engine, runtime, UI = make()
			local types = engine.types
			local first = types.CFrame.lookAt(types.Vector3.new(0, 4, 10), types.Vector3.new(0, 1, 0))
			local second = types.CFrame.lookAt(types.Vector3.new(6, 2, 0), types.Vector3.new(0, 0, 0))
			local placement, fieldOfView = Compose.cell(first), Compose.cell(55)
			local stop, stage = mount(engine, runtime, function()
				return UI.Stage({ camera = placement, fieldOfView = fieldOfView })
			end)
			local camera = stage.CurrentCamera
			t.expect(camera.ClassName).toBe("Camera")
			t.expect(camera.Parent).toBe(stage)
			t.expect(camera.CFrame).toBe(first)
			t.expect(camera.FieldOfView).toBe(55)
			fieldOfView:set(70)
			placement:set(second)
			t.expect(camera.FieldOfView).toBe(70)
			t.expect(camera.CFrame).toBe(second)
			t.expect(stage.CurrentCamera).toBe(camera)
			stop()
			t.expect(camera.isDestroyed()).toBe(true)
			local defaultStop, defaultStage = mount(engine, runtime, function()
				return UI.Stage({})
			end)
			t.expect(defaultStage.CurrentCamera.FieldOfView).toBe(45)
			t.expect(defaultStage.CurrentCamera.CFrame)
				.toBe(types.CFrame.lookAt(types.Vector3.new(0, 2, 8), types.Vector3.new(0, 0, 0)))
			defaultStop()
			runtime:dispose()
		end)
	end)

	t.describe("icons", function()
		t.it("resolves an unknown semantic icon to nothing and refuses to mount it", function()
			local neutral = themes.neutralPackage()
			t.expect(themes.resolveIcon(neutral, "not.an.icon")).toBeNil()
			t.expect(string.match(themes.resolveIcon(neutral, "close") or "", "^rbxassetid://%d+$") ~= nil).toBe(true)
			local label = refusal(function(UI)
				return UI.Label({ text = "x", icon = "not.an.icon" })
			end)
			t.expect(refusedWith(label, "Facet icon not.an.icon requires an image asset")).toBe(true)
			local button = refusal(function(UI)
				return UI.Button({ label = "x", icon = "nope" })
			end)
			t.expect(refusedWith(button, "Facet icon nope requires an image asset")).toBe(true)
			local accepted = refusal(function(UI)
				return UI.Label({ text = "x", icon = "close" })
			end)
			t.expect(accepted.message).toBeNil()
		end)

		t.it("resolves the common framework icons to their standard art", function()
			local neutral = themes.neutralPackage()
			for _, name in
				{
					"status.info",
					"status.success",
					"status.warning",
					"status.error",
					"calendar",
					"clock",
					"vote.up",
					"vote.down",
					"person",
					"chevron.first",
					"chevron.last",
				}
			do
				local art = icons.ART[name]
				t.expect(art ~= nil).toBe(true)
				t.expect(string.match(art.contentId, "^rbxassetid://%d+$") ~= nil).toBe(true)
				t.expect(themes.resolveIcon(neutral, name)).toBe(art.contentId)
			end
			t.expect(icons.ART["status.success"].contentId).toBe(icons.ART.checkmark.contentId)
			t.expect(icons.ART["status.warning"].contentId ~= icons.ART["status.error"].contentId).toBe(true)
		end)

		t.it("treats contentId and content as the same asset spelling for skins and icons", function()
			for _, field in { "content", "contentId" } do
				local engine, runtime = make()
				local package: any = themes.neutralPackage()
				package.assets.panel =
					{ [field] = "rbxassetid://9", sliceCenter = { x0 = 12, y0 = 12, x1 = 52, y1 = 52 } }
				package.chrome.panel = { kind = "nineSlice", asset = "panel" }
				package.icons["facet:search"] = { default = "panel" }
				local defined: any, report = themes.define(package)
				t.expect(report.ok).toBe(true)
				local stop, skin = mount(engine, runtime, function()
					return themes.skin(runtime, defined, "panel", { types = engine.types })
				end)
				local image = skin:FindFirstChild("panel1")
				t.expect(image.Image).toBe("rbxassetid://9")
				t.expect(image.ScaleType).toBe(engine.types.Enum.ScaleType.Slice)
				t.expect(image.SliceCenter).toBe(engine.types.Rect.new(12, 12, 52, 52))
				t.expect(themes.resolveIcon(defined, "facet:search")).toBe("rbxassetid://9")
				local themed: any = Facet.controls(runtime, { types = engine.types, theme = defined } :: any)
				local labelStop, label = mount(engine, runtime, function()
					return themed.Label({ text = "Find", icon = "facet:search" })
				end)
				t.expect(label:FindFirstChildWhichIsA("ImageLabel").Image).toBe("rbxassetid://9")
				labelStop()
				stop()
				runtime:dispose()
			end
		end)

		t.it("frames a button image by crop by default and by fit on request", function()
			local engine, runtime, UI = make()
			local stop, root = mount(engine, runtime, function()
				return runtime.constructors.Frame({
					UI.Button "Default" { label = "x", image = "rbxassetid://1" },
					UI.Button "Crop" { label = "x", image = "rbxassetid://1", imageFraming = "crop" },
					UI.Button "Fit" { label = "x", image = "rbxassetid://1", imageFraming = "fit" },
				})
			end)
			local Enum = engine.types.Enum
			t.expect(root:FindFirstChild("Default", true):FindFirstChild("Image", true).ScaleType)
				.toBe(Enum.ScaleType.Crop)
			t.expect(root:FindFirstChild("Crop", true):FindFirstChild("Image", true).ScaleType)
				.toBe(Enum.ScaleType.Crop)
			t.expect(root:FindFirstChild("Fit", true):FindFirstChild("Image", true).ScaleType).toBe(Enum.ScaleType.Fit)
			t.expect(root:FindFirstChild("Fit", true):FindFirstChild("Image", true).Image).toBe("rbxassetid://1")
			stop()
			runtime:dispose()
			for _, framing in { "stretch", { width = 256, height = 256 } } do
				local refused = refusal(function(UI)
					return UI.Button({ label = "x", image = "rbxassetid://1", imageFraming = framing })
				end)
				t.expect(refusedWith(refused, "imageFraming must be fit or crop")).toBe(true)
				t.expect(refused.live).toBe(0)
				t.expect(refused.connections).toBe(0)
			end
		end)
	end)

	t.describe("refusals", function()
		t.it("accepts every semantic button role and refuses an unknown one", function()
			local roles = { "default", "cancel", "destructive", "onIndicator" }
			for _, role in roles do
				local engine, runtime, UI = make()
				local stop, button = mount(engine, runtime, function()
					return UI.Button({ label = "x", role = role })
				end)
				for _, other in roles do
					t.expect(button:HasTag("facet-role-" .. other)).toBe(other == role)
				end
				t.expect(button:GetAttribute("role")).toBe(role)
				stop()
				runtime:dispose()
			end
			t.expect(refusedWith(
				refusal(function(UI)
					return UI.Button({ label = "x", role = "danger" })
				end),
				"Facet.Button: invalid semantic role"
			)).toBe(true)
			local engine, runtime, UI = make()
			local role = Compose.cell("cancel")
			local stop, button = mount(engine, runtime, function()
				return UI.Button({ label = "x", role = role })
			end)
			t.expect(pcall(function()
				role:set("danger")
			end)).toBe(false)
			t.expect(button:HasTag("facet-role-cancel")).toBe(true)
			t.expect(button:HasTag("facet-role-danger")).toBe(false)
			role:set("destructive")
			t.expect(button:HasTag("facet-role-destructive")).toBe(true)
			t.expect(button:HasTag("facet-role-cancel")).toBe(false)
			stop()
			runtime:dispose()
		end)

		t.it("refuses an unknown or reactive button shape at construction", function()
			for _, shape in { "oval", Compose.cell("circle") :: any } do
				local refused = refusal(function(UI)
					return UI.Button({ label = "x", shape = shape })
				end)
				t.expect(refusedWith(refused, "Facet.Button: shape must be rect or circle")).toBe(true)
				t.expect(refused.created).toBe(0)
			end
			local engine, runtime, UI = make()
			local stop, root = mount(engine, runtime, function()
				return runtime.constructors.Frame({
					UI.Button "Circle" { label = "x", shape = "circle" },
					UI.Button "Rect" { label = "x", shape = "rect" },
				})
			end)
			t.expect(root:FindFirstChild("Circle", true):HasTag("facet-shape-circle")).toBe(true)
			t.expect(root:FindFirstChild("Rect", true):HasTag("facet-shape-circle")).toBe(false)
			stop()
			runtime:dispose()
		end)

		t.it("refuses compactLabel on icon, image, subtitle and hint buttons", function()
			for _, extra in
				{
					{ icon = "rbxassetid://1" },
					{ trailingIcon = "rbxassetid://1" },
					{ image = "rbxassetid://1" },
					{ subtitle = "More" },
					{ hint = "More" },
				} :: { { [string]: any } }
			do
				local refused = refusal(function(UI)
					local spec: { [string]: any } = { label = "Continue", compactLabel = "Go" }
					for key, value in extra do
						spec[key] = value
					end
					return UI.Button(spec)
				end)
				t.expect(refusedWith(refused, "Facet.Button: compactLabel requires a text button")).toBe(true)
				t.expect(refused.live).toBe(0)
			end
			local engine, runtime, UI = make()
			local stop, button = mount(engine, runtime, function()
				return UI.Button({ label = "Continue", compactLabel = "Go" })
			end)
			t.expect(button:FindFirstChild("FullLabelMeasure").Text).toBe("Continue")
			t.expect(button.Text).toBe("Continue")
			stop()
			runtime:dispose()
		end)

		t.it("refuses a text input that supplies both enabled and disabled", function()
			local refused = refusal(function(UI)
				return UI.TextInput({ value = Compose.cell(""), enabled = true, disabled = false })
			end)
			t.expect(refusedWith(refused, "Facet.TextInput: use enabled or disabled, not both")).toBe(true)
			t.expect(refused.created).toBe(0)
			for _, spec in { { enabled = false }, { disabled = true } } :: { { [string]: any } } do
				local engine, runtime, UI = make()
				local stop, box = mount(engine, runtime, function()
					local options = table.clone(spec)
					options.value = Compose.cell("")
					return UI.TextInput(options)
				end)
				t.expect(box.TextEditable).toBe(false)
				stop()
				runtime:dispose()
			end
		end)

		t.it("refuses nonfinite or inverted numeric bounds and non-function numeric callbacks", function()
			local cases: { { any } } = {
				{ { min = 0 / 0 }, "numeric bounds must be finite" },
				{ { max = math.huge }, "numeric bounds must be finite" },
				{ { min = -math.huge }, "numeric bounds must be finite" },
				{ { min = "1" }, "numeric bounds must be finite" },
				{ { min = 5, max = 1 }, "min must not exceed max" },
				{ { parse = 5 }, "parse must be a function" },
				{ { format = true }, "format must be a function" },
				{ { validate = "x" }, "validate must be a function" },
			}
			for _, case in cases do
				local refused = refusal(function(UI)
					local spec = table.clone(case[1])
					spec.presentation = "number"
					spec.value = Compose.cell("1")
					spec.numericValue = Compose.cell(1)
					return UI.TextInput(spec)
				end)
				t.expect(refusedWith(refused, case[2])).toBe(true)
				t.expect(refused.created).toBe(0)
			end
			local accepted = refusal(function(UI)
				return UI.TextInput({
					presentation = "number",
					value = Compose.cell("1"),
					numericValue = Compose.cell(1),
					min = 1,
					max = 1,
					parse = tonumber,
					format = tostring,
				})
			end)
			t.expect(accepted.message).toBeNil()
		end)

		t.it("refuses an unknown control size and keeps the last legal size for a live rung", function()
			for _, build in
				{
					function(UI)
						return UI.Button({ label = "Go", controlSize = "tiny" })
					end,
					function(UI)
						return UI.ShortcutHint({ keys = { { "Ctrl", "K" } }, controlSize = "tiny" })
					end,
				} :: { (any) -> any }
			do
				t.expect(refusedWith(refusal(build), "Facet controlSize must be compact, regular or large")).toBe(true)
			end
			for _, bound in { "cell", "function" } do
				local engine, runtime, UI = make()
				local rung = Compose.cell("regular")
				local source: any = if bound == "cell"
					then rung
					else function(use)
						return use(rung)
					end
				local stop, root = mount(engine, runtime, function()
					return runtime.constructors.Frame({
						UI.Button "Go" { label = "Go", controlSize = source },
						UI.ShortcutHint "Hint" { keys = { { "Ctrl", "K" } }, controlSize = source },
					})
				end)
				local button, hint = root:FindFirstChild("Go", true), root:FindFirstChild("Hint", true)
				t.expect(button.Size.Y.Offset).toBe(44)
				t.expect(hint.Size.Y.Offset).toBe(28)
				t.expect(pcall(function()
					rung:set("tiny")
				end)).toBe(false)
				t.expect(button.Size.Y.Offset).toBe(44)
				t.expect(hint.Size.Y.Offset).toBe(28)
				rung:set("large")
				t.expect(button.Size.Y.Offset).toBe(56)
				t.expect(hint.Size.Y.Offset).toBe(32)
				rung:set("compact")
				t.expect(button.Size.Y.Offset).toBe(36)
				t.expect(hint.Size.Y.Offset).toBe(24)
				stop()
				runtime:dispose()
			end
		end)

		t.it(
			"refuses a combo box with a plain value, missing text, a non-function validator or an unknown key",
			function()
				local function spec(overrides: { [string]: any }): { [string]: any }
					local result: { [string]: any } = {
						value = Compose.cell("a"),
						text = Compose.cell("A"),
						options = { { value = "a", label = "A" } },
						acceptCustom = function()
							return false
						end,
					}
					for key, value in overrides do
						result[key] = if value == "nil" then nil else value
					end
					return result
				end
				local cases: { { any } } = {
					{ { value = "a" }, "ComboBox.value requires a writable Compose cell" },
					{ { value = Compose.cell(5) }, "ComboBox.value must be a string" },
					{ { options = "nil" }, "ComboBox requires options" },
					{ { options = "a" }, "ComboBox requires options" },
					{ { text = Compose.cell(5) }, "TextInput: value must resolve to a string" },
					{ { text = "nil" }, "ComboBox.text requires a writable Compose cell" },
					{ { text = "A" }, "ComboBox.text requires a writable Compose cell" },
					{ { acceptCustom = true }, "ComboBox requires acceptCustom" },
					{ { acceptCustom = "nil" }, "ComboBox requires acceptCustom" },
					{ { bogus = 1 }, "Unknown Facet option bogus" },
				}
				for _, case in cases do
					local refused = refusal(function(UI)
						return UI.ComboBox(spec(case[1]))
					end)
					t.expect(refusedWith(refused, case[2])).toBe(true)
					t.expect(refused.live).toBe(0)
					t.expect(refused.connections).toBe(0)
				end
				t.expect(refusal(function(UI)
					return UI.ComboBox(spec({}))
				end).message).toBeNil()
				t.expect(refusal(function(UI)
					return UI.ComboBox(spec({ options = Compose.cell({ { value = "a", label = "A" } }) }))
				end).message).toBeNil()
			end
		)

		t.it("refuses an unknown enumeration value on every documented vocabulary without leaking", function()
			local function content(Host: any): () -> any
				return function()
					return Host.Frame({})
				end
			end
			local function radial(option: string): (any, any, any) -> any
				return function(UI, _, value)
					local spec: { [string]: any } = { items = { { id = "a", label = "A", onSelect = function() end } } }
					spec[option] = value
					return UI.RadialMenu(spec)
				end
			end
			local cases: { { any } } = {
				{
					"Button shape",
					"circle",
					"oval",
					"shape must be rect or circle",
					function(UI, _, v)
						return UI.Button({ label = "Go", shape = v })
					end,
				},
				{
					"Button corners",
					"square",
					"rounded",
					"corners must be pill or square",
					function(UI, _, v)
						return UI.Button({ label = "Go", corners = v })
					end,
				},
				{
					"Button dialogAction",
					"cancel",
					"confirm",
					"invalid dialogAction",
					function(UI, _, v)
						return UI.Button({ label = "Go", dialogAction = v })
					end,
				},
				{
					"Button role",
					"destructive",
					"danger",
					"invalid semantic role",
					function(UI, _, v)
						return UI.Button({ label = "Go", role = v })
					end,
				},
				{
					"Button controlSize",
					"large",
					"tiny",
					"compact, regular or large",
					function(UI, _, v)
						return UI.Button({ label = "Go", controlSize = v })
					end,
				},
				{
					"Chip controlSize",
					"compact",
					"tiny",
					"compact, regular or large",
					function(UI, _, v)
						return UI.Chip({ label = "Go", selected = Compose.cell(false), controlSize = v })
					end,
				},
				{
					"Toggle presentation",
					"checkbox",
					"radio",
					"Toggle: invalid presentation",
					function(UI, _, v)
						return UI.Toggle({ value = Compose.cell(false), presentation = v })
					end,
				},
				{
					"Toggle indicatorPosition",
					"trailing",
					"above",
					"Toggle: invalid indicatorPosition",
					function(UI, _, v)
						return UI.Toggle({ value = Compose.cell(false), indicatorPosition = v })
					end,
				},
				{
					"TextInput presentation",
					"search",
					"email",
					"TextInput: invalid presentation",
					function(UI, _, v)
						return UI.TextInput({ value = Compose.cell(""), presentation = v })
					end,
				},
				{
					"TextInput clearButtonMode",
					"whileEditing",
					"often",
					"invalid clearButtonMode",
					function(UI, _, v)
						return UI.TextInput({ value = Compose.cell(""), clearButtonMode = v })
					end,
				},
				{
					"Rating starSize",
					"large",
					"huge",
					"invalid size",
					function(UI, _, v)
						return UI.Rating({ value = Compose.cell(1), starSize = v })
					end,
				},
				{
					"LevelPicker segment",
					"glyph",
					"dot",
					"invalid segment",
					function(UI, _, v)
						return UI.LevelPicker({ value = Compose.cell(1), segment = v })
					end,
				},
				{
					"LevelPicker segmentSize",
					"medium",
					"huge",
					"invalid size",
					function(UI, _, v)
						return UI.LevelPicker({ value = Compose.cell(1), segmentSize = v })
					end,
				},
				{
					"ShortcutHint controlSize",
					"large",
					"tiny",
					"compact, regular or large",
					function(UI, _, v)
						return UI.ShortcutHint({ keys = { { "Ctrl", "K" } }, controlSize = v })
					end,
				},
				{
					"Picker style",
					"inline",
					"carousel",
					"Unknown Picker style",
					function(UI, _, v)
						return UI.Picker({
							selected = Compose.cell("a"),
							options = { { value = "a", label = "A" } },
							style = v,
						})
					end,
				},
				{
					"Picker indicator",
					"underline",
					"dot",
					"Invalid Picker.indicator",
					function(UI, _, v)
						return UI.Picker({
							selected = Compose.cell("a"),
							options = { { value = "a", label = "A" } },
							style = "segmented",
							indicator = v,
						})
					end,
				},
				{
					"Picker axis",
					"y",
					"z",
					"Picker.axis must be x or y",
					function(UI, _, v)
						return UI.Picker({
							selected = Compose.cell("a"),
							options = { { value = "a", label = "A" } },
							style = "segmented",
							axis = v,
						})
					end,
				},
				{
					"Picker sizing",
					"hug",
					"auto",
					"Picker.sizing must be fill or hug",
					function(UI, _, v)
						return UI.Picker({
							selected = Compose.cell("a"),
							options = { { value = "a", label = "A" } },
							style = "segmented",
							sizing = v,
						})
					end,
				},
				{
					"TabView style",
					"collapsible",
					"floating",
					"Invalid TabView.style",
					function(UI, Host, v)
						return UI.TabView({
							selection = Compose.cell("a"),
							tabs = { { id = "a", label = "A", content = content(Host) } },
							style = v,
						})
					end,
				},
				{
					"TabView retention",
					"top",
					"some",
					"TabView.retention uses Compose all or top",
					function(UI, Host, v)
						return UI.TabView({
							selection = Compose.cell("a"),
							tabs = { { id = "a", label = "A", content = content(Host) } },
							retention = v,
						})
					end,
				},
				{
					"DisclosureGroup chevronPosition",
					"trailing",
					"above",
					"Invalid DisclosureGroup.chevronPosition",
					function(UI, Host, v)
						return UI.DisclosureGroup({
							label = "More",
							expanded = Compose.cell(false),
							content = content(Host),
							chevronPosition = v,
						})
					end,
				},
				{
					"DisclosureGroup appearance",
					"contained",
					"boxed",
					"Invalid DisclosureGroup.appearance",
					function(UI, Host, v)
						return UI.DisclosureGroup({
							label = "More",
							expanded = Compose.cell(false),
							content = content(Host),
							appearance = v,
						})
					end,
				},
				{
					"Alert surface",
					"fullScreen",
					"sheet",
					"Alert.surface must be dialog or fullScreen",
					function(UI, _, v)
						return UI.Alert({
							isPresented = Compose.cell(false),
							title = "Title",
							actions = { { id = "ok", label = "OK", role = "default" } },
							surface = v,
						})
					end,
				},
				{ "RadialMenu appearance", "buttons", "ring", "RadialMenu invalid appearance", radial("appearance") },
				{ "RadialMenu follow", "always", "never", "RadialMenu invalid follow", radial("follow") },
				{
					"RadialMenu gestureSelection",
					"direction",
					"angle",
					"RadialMenu invalid gestureSelection",
					radial("gestureSelection"),
				},
				{ "RadialMenu contentFit", "radial", "stretch", "RadialMenu invalid contentFit", radial("contentFit") },
				{ "RadialMenu navigation", "expand", "push", "RadialMenu invalid navigation", radial("navigation") },
				{ "RadialMenu expansion", "ring", "spiral", "RadialMenu invalid expansion", radial("expansion") },
				{ "RadialMenu center", "close", "middle", "RadialMenu invalid center", radial("center") },
				{ "RadialMenu completion", "stay", "exit", "RadialMenu invalid completion", radial("completion") },
				{
					"RadialMenu buttonSurface",
					"none",
					"glass",
					"RadialMenu invalid buttonSurface",
					radial("buttonSurface"),
				},
				{
					"VirtualList snap",
					"item",
					"row",
					"snap must be none or item",
					function(UI, Host, v)
						return UI.VirtualList({ from = {}, render = content(Host), snap = v })
					end,
				},
				{
					"VirtualGrid snap",
					"none",
					"page",
					"snap must be none or item",
					function(UI, Host, v)
						return UI.VirtualGrid({ from = {}, render = content(Host), snap = v })
					end,
				},
				{
					"Badge appearance",
					"utility",
					"loud",
					"Facet Badge invalid appearance",
					function(UI, _, v)
						return UI.Badge({ label = "New", appearance = v })
					end,
				},
				{
					"Badge status",
					"warning",
					"danger",
					"Facet: invalid status",
					function(UI, _, v)
						return UI.Badge({ label = "New", status = v })
					end,
				},
				{
					"Badge corners",
					"capsule",
					"round",
					"Facet Badge invalid corners",
					function(UI, _, v)
						return UI.Badge({ label = "New", corners = v })
					end,
				},
				{
					"Badge controlSize",
					"compact",
					"tiny",
					"compact, regular or large",
					function(UI, _, v)
						return UI.Badge({ label = "New", controlSize = v })
					end,
				},
				{
					"StatusIndicator status",
					"accent",
					"critical",
					"Facet: invalid status",
					function(UI, _, v)
						return UI.StatusIndicator({ status = v })
					end,
				},
				{
					"StatusIndicator form",
					"square",
					"star",
					"Facet StatusIndicator invalid form",
					function(UI, _, v)
						return UI.StatusIndicator({ status = "info", form = v })
					end,
				},
				{
					"StatusIndicator controlSize",
					"large",
					"tiny",
					"compact, regular or large",
					function(UI, _, v)
						return UI.StatusIndicator({ status = "info", controlSize = v })
					end,
				},
				{
					"ProgressView presentation",
					"spinner",
					"ring",
					"presentation must be bar, circular or spinner",
					function(UI, _, v)
						return UI.ProgressView({ value = 1, presentation = v })
					end,
				},
				{
					"ProgressView controlSize",
					"compact",
					"tiny",
					"compact, regular or large",
					function(UI, _, v)
						return UI.ProgressView({ value = 1, presentation = "circular", controlSize = v })
					end,
				},
				{
					"Skeleton form",
					"circle",
					"oval",
					"Facet Skeleton invalid form",
					function(UI, _, v)
						return UI.Skeleton({ form = v })
					end,
				},
				{
					"Skeleton corners",
					"pill",
					"round",
					"Facet Skeleton invalid corners",
					function(UI, _, v)
						return UI.Skeleton({ form = "box", corners = v })
					end,
				},
				{
					"Skeleton controlSize",
					"large",
					"tiny",
					"compact, regular or large",
					function(UI, _, v)
						return UI.Skeleton({ controlSize = v })
					end,
				},
				{
					"Avatar form",
					"icon",
					"photo",
					"Facet Avatar invalid form",
					function(UI, _, v)
						return UI.Avatar({ name = "Ada", form = v })
					end,
				},
				{
					"Avatar presence",
					"busy",
					"idle",
					"Facet Avatar invalid presence",
					function(UI, _, v)
						return UI.Avatar({ name = "Ada", presence = v })
					end,
				},
				{
					"Avatar controlSize",
					"compact",
					"tiny",
					"compact, regular or large",
					function(UI, _, v)
						return UI.Avatar({ name = "Ada", controlSize = v })
					end,
				},
				{
					"AvatarGroup layout",
					"spread",
					"grid",
					"Facet AvatarGroup invalid layout",
					function(UI, _, v)
						return UI.AvatarGroup({ items = { { id = "a", name = "Ada" } }, layout = v })
					end,
				},
				{
					"AvatarGroup overflow",
					"ellipsis",
					"hidden",
					"Facet AvatarGroup invalid overflow",
					function(UI, _, v)
						return UI.AvatarGroup({ items = { { id = "a", name = "Ada" } }, overflow = v })
					end,
				},
				{
					"AvatarGroup controlSize",
					"large",
					"tiny",
					"compact, regular or large",
					function(UI, _, v)
						return UI.AvatarGroup({ items = { { id = "a", name = "Ada" } }, controlSize = v })
					end,
				},
			}
			local failures = {}
			for _, case in cases do
				local name, good, bad, fragment, build = case[1], case[2], case[3], case[4], case[5]
				local accepted = refusal(function(UI, Host)
					return build(UI, Host, good)
				end)
				local refused = refusal(function(UI, Host)
					return build(UI, Host, bad)
				end)
				if accepted.message ~= nil then
					table.insert(failures, `{name} refused {good}: {accepted.message}`)
				elseif not refusedWith(refused, fragment) then
					table.insert(failures, `{name} did not refuse {bad} with {fragment}: {tostring(refused.message)}`)
				elseif refused.live ~= 0 or refused.connections ~= 0 or refused.heartbeat ~= 0 then
					table.insert(
						failures,
						`{name} leaked {refused.live} nodes, {refused.connections} connections, {refused.heartbeat} frames`
					)
				end
			end
			t.expect(table.concat(failures, "\n")).toBe("")
			t.expect(#cases).toBe(52)
		end)
	end)
end)
