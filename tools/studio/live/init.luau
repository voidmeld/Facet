--!strict
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local storage = game:GetService("ReplicatedStorage")

local live = {}

local function round(value: number): number
	return math.floor(value * 100 + 0.5) / 100
end

local function encode(value: any): any
	local kind = typeof(value)
	if kind == "Vector2" then
		return { round(value.X), round(value.Y) }
	elseif kind == "UDim2" then
		return { value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset }
	elseif kind == "UDim" then
		return { value.Scale, value.Offset }
	elseif kind == "EnumItem" then
		return tostring(value)
	elseif kind == "number" then
		return round(value)
	elseif kind == "table" then
		local out = {}
		for key, item in value do
			out[key] = encode(item)
		end
		return out
	elseif kind == "Instance" then
		return value:GetFullName()
	end
	return value
end

local function themeModules(Facet: any): { { name: string, package: any } }
	local list = { { name = "Neutral", package = assert(Facet.themes.define(Facet.themes.neutralPackage())) } }
	local folder = storage:FindFirstChild("FacetThemes")
	local found = {}
	if folder then
		for _, module in folder:GetChildren() do
			if module:IsA("ModuleScript") then
				local ok, definition = pcall(require, module)
				if
					ok
					and type(definition) == "table"
					and not definition.testOnly
					and type(definition.build) == "function"
				then
					local built, package = pcall(definition.build, Facet.themes)
					if built and package then
						table.insert(found, { name = module.Name, package = package })
					end
				end
			end
		end
	end
	table.sort(found, function(a, b)
		return a.name < b.name
	end)
	for _, entry in found do
		table.insert(list, entry)
	end
	return list
end

local function environment(): { [string]: any }
	local camera = workspace.CurrentCamera
	local inset = GuiService:GetGuiInset()
	return {
		viewport = encode(camera.ViewportSize),
		guiInset = encode(inset),
		preferredTextSize = tostring(GuiService.PreferredTextSize),
		preferredTransparency = GuiService.PreferredTransparency,
		reducedMotion = GuiService.ReducedMotionEnabled,
		touch = game:GetService("UserInputService").TouchEnabled,
		studio = RunService:IsStudio(),
		version = version(),
		stamp = workspace:GetAttribute("Facet_SourceStamp"),
	}
end

local function newCase(Facet: any, themes: { any }, record: { [string]: any })
	local t = {}
	local cleanups: { () -> () } = {}
	t.Facet = Facet
	t.themes = themes
	t.environment = environment()
	function t.check(name: string, ok: boolean, detail: any?)
		table.insert(record.checks, { name = name, ok = ok == true, detail = encode(detail) })
	end
	function t.near(name: string, actual: number, expected: number, tolerance: number?)
		local margin = tolerance or 1
		t.check(
			name,
			math.abs(actual - expected) <= margin,
			{ actual = actual, expected = expected, tolerance = margin }
		)
	end
	function t.note(name: string, value: any)
		record.notes[name] = encode(value)
	end
	function t.settle(frames: number?)
		for _ = 1, frames or 6 do
			RunService.RenderStepped:Wait()
		end
	end
	function t.find(root: Instance, name: string): any
		if root.Name == name then
			return root
		end
		return root:FindFirstChild(name, true)
	end
	function t.all(root: Instance, name: string): { any }
		local out = {}
		for _, node in root:GetDescendants() do
			if node.Name == name then
				table.insert(out, node)
			end
		end
		return out
	end
	function t.rect(node: any): { x: number, y: number, w: number, h: number, r: number, b: number }
		local at, size = node.AbsolutePosition, node.AbsoluteSize
		return { x = at.X, y = at.Y, w = size.X, h = size.Y, r = at.X + size.X, b = at.Y + size.Y }
	end
	function t.inside(name: string, inner: any, outer: any, tolerance: number?)
		local a = if typeof(inner) == "Instance" then t.rect(inner) else inner
		local b = if typeof(outer) == "Instance" then t.rect(outer) else outer
		local margin = tolerance or 0.5
		t.check(
			name,
			a.x >= b.x - margin and a.y >= b.y - margin and a.r <= b.r + margin and a.b <= b.b + margin,
			{ inner = { a.x, a.y, a.w, a.h }, outer = { b.x, b.y, b.w, b.h } }
		)
	end
	function t.fits(label: any): boolean
		local bounds, size = label.TextBounds, label.AbsoluteSize
		return label.ContentText ~= "" and bounds.X <= size.X + 0.5 and bounds.Y <= size.Y + 0.5
	end
	function t.visible(node: Instance): boolean
		local current: Instance? = node
		while current and current:IsA("GuiObject") do
			if not current.Visible then
				return false
			end
			current = current.Parent
		end
		if current and current:IsA("LayerCollector") then
			return current.Enabled
		end
		return current ~= nil
	end
	function t.mount(build: (any, any, any, any) -> any, options: { [string]: any }?): any
		local config = options or {}
		local Compose = Facet.Compose
		local runtime = Facet.Roblox.createRuntime()
		local Host = runtime.constructors
		local package = config.theme or themes[1].package
		local root
		local stop = runtime.mount(function()
			local theme = Compose.cell(package)
			local palette = Compose.cell(config.palette or package.style.defaultTheme)
			local viewport = Facet.Roblox.createViewport(workspace.CurrentCamera)
			local UI = Facet.controls(runtime, {
				viewport = viewport,
				theme = theme,
				reducedMotion = config.reducedMotion ~= false,
			})
			local sheet = Facet.themes.createStyleSheet(runtime, theme, { theme = palette, transition = false })
			local stage = Host.Frame "Stage" {
				Size = function(use)
					local size = config.size
					if size == nil then
						return UDim2.fromScale(1, 1)
					end
					local value = if Compose.isReadable(size) then use(size) else size
					return UDim2.fromOffset(value.X, value.Y)
				end,
				BackgroundTransparency = 1,
				build(UI, Host, Compose, {
					runtime = runtime,
					viewport = viewport,
					theme = theme,
					types = {
						UDim = UDim,
						UDim2 = UDim2,
						Vector2 = Vector2,
						Vector3 = Vector3,
						Color3 = Color3,
						CFrame = CFrame,
						Rect = Rect,
						Enum = Enum,
						Path2DControlPoint = Path2DControlPoint,
						NumberSequence = NumberSequence,
						NumberSequenceKeypoint = NumberSequenceKeypoint,
						ColorSequence = ColorSequence,
						ColorSequenceKeypoint = ColorSequenceKeypoint,
						FloatCurveKey = FloatCurveKey,
					},
				}),
			}
			root = stage
			return Host.ScreenGui "FacetLive" {
				ResetOnSpawn = false,
				DisplayOrder = 50,
				ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
				sheet,
				Host.StyleLink({ StyleSheet = Compose.static(sheet) }),
				Host.Frame "Backdrop" {
					Size = UDim2.fromScale(1, 1),
					BorderSizePixel = 0,
					ZIndex = 0,
				},
				stage,
			}
		end, Players.LocalPlayer:WaitForChild("PlayerGui"))
		table.insert(cleanups, function()
			stop()
			runtime:dispose()
		end)
		t.settle(config.frames or 8)
		return root
	end
	function t.context(UI: any, Host: any, Compose: any, env: any): { [string]: any }
		return {
			Facet = Facet,
			Compose = Compose,
			runtime = env.runtime,
			Host = Host,
			UI = UI,
			viewport = env.viewport,
			types = env.types,
			guiService = GuiService,
			runService = RunService,
			inputTarget = Players.LocalPlayer:WaitForChild("PlayerGui"),
			worldTarget = workspace,
		}
	end
	function t.scenario(name: string): any
		return (require :: any)(storage:WaitForChild("FacetScenarios"):WaitForChild(name))
	end
	function t.hold(value: any)
		shared.FacetLiveHold = { cleanup = t.cleanup, value = value }
		record.held = true
	end
	function t.held(): any
		local hold = shared.FacetLiveHold
		return hold and hold.value
	end
	function t.cleanup()
		for index = #cleanups, 1, -1 do
			pcall(cleanups[index])
		end
		table.clear(cleanups)
	end
	return t
end

function live.cases(suite: string): { any }
	local module = script:WaitForChild("suites"):FindFirstChild(suite)
	assert(module and module:IsA("ModuleScript"), "unknown live suite " .. suite)
	return (require :: any)(module)
end

function live.run(suite: string, options: { [string]: any }?): string
	local config = options or {}
	local Facet = (require :: any)(storage:WaitForChild("Facet"))
	local themes = themeModules(Facet)
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local hidden = {}
	for _, gui in playerGui:GetChildren() do
		if gui:IsA("ScreenGui") and string.sub(gui.Name, 1, 12) == "FacetGallery" and gui.Enabled then
			if not config.keepGallery then
				gui.Enabled = false
				table.insert(hidden, gui)
			end
		end
	end
	local results = {}
	local passed, failed = 0, 0
	for _, case in live.cases(suite) do
		if config.only and not string.find(case.id, config.only, 1, true) then
			continue
		end
		local record = { id = case.id, contracts = case.contracts or {}, checks = {}, notes = {} }
		local t = newCase(Facet, themes, record)
		local ok, problem = xpcall(case.run, debug.traceback, t)
		if not record.held then
			t.cleanup()
		end
		if not ok then
			record.error = tostring(problem)
		end
		local good = ok and #record.checks > 0
		for _, check in record.checks do
			good = good and check.ok
		end
		record.ok = good
		if good then
			passed += 1
		else
			failed += 1
		end
		table.insert(results, record)
	end
	for _, gui in hidden do
		gui.Enabled = true
	end
	return HttpService:JSONEncode({
		schema = "facet-live-assertions/1",
		suite = suite,
		environment = environment(),
		themes = (function()
			local names = {}
			for _, entry in themes do
				table.insert(names, entry.name)
			end
			return names
		end)(),
		passed = passed,
		failed = failed,
		cases = results,
	})
end

function live.begin(suite: string, id: string): string
	live.release()
	local Facet = (require :: any)(storage:WaitForChild("Facet"))
	local chosen
	for _, case in live.cases(suite) do
		if case.id == id then
			chosen = case
		end
	end
	assert(chosen and chosen.setup, "no interactive case " .. id)
	local record = { id = chosen.id, contracts = chosen.contracts or {}, checks = {}, notes = {}, steps = {} }
	local t = newCase(Facet, themeModules(Facet), record)
	local value = chosen.setup(t)
	shared.FacetLiveHold = { cleanup = t.cleanup, value = value }
	shared.FacetLiveSession = { suite = suite, case = chosen, record = record, t = t, value = value }
	return HttpService:JSONEncode(record)
end

function live.step(name: string): string
	local session = assert(shared.FacetLiveSession, "call live.begin first")
	local before = #session.record.checks
	table.insert(session.record.steps, name)
	local ok, problem = xpcall(session.case.steps[name], debug.traceback, session.t, session.value)
	if not ok then
		session.t.check(name .. " ran", false, tostring(problem))
	end
	local lines = {}
	for index = before + 1, #session.record.checks do
		local check = session.record.checks[index]
		table.insert(lines, `{if check.ok then "ok  " else "FAIL"} {check.name} {HttpService:JSONEncode(check.detail)}`)
	end
	return table.concat(lines, "\n")
end

function live.finish(tag: string): string
	local session = assert(shared.FacetLiveSession, "call live.begin first")
	shared.FacetLiveSession = nil
	live.release()
	local record = session.record
	local good = #record.checks > 0
	for _, check in record.checks do
		good = good and check.ok
	end
	record.ok = good
	local json = HttpService:JSONEncode({
		schema = "facet-live-assertions/1",
		suite = session.suite,
		environment = environment(),
		passed = if good then 1 else 0,
		failed = if good then 0 else 1,
		cases = { record },
	})
	live.save(`{session.suite}-{record.id}-{tag}`, json)
	return live.summary(json)
end

function live.release()
	local hold = shared.FacetLiveHold
	shared.FacetLiveHold = nil
	if hold then
		hold.cleanup()
	end
end

function live.save(name: string, json: string): number
	local event = storage:WaitForChild("FacetLiveRelay", 10) :: RemoteEvent?
	assert(event, "start the relay in the Server datamodel first")
	local size = 30000
	local count = math.max(1, math.ceil(#json / size))
	for index = 1, count do
		event:FireServer(name, index, count, string.sub(json, (index - 1) * size + 1, index * size))
	end
	return #json
end

function live.record(tag: string, suites: { string }?): string
	local lines = {}
	for _, suite in suites or { "layout_geometry", "gallery", "needs_live" } do
		local json = live.run(suite, { keepGallery = suite ~= "layout_geometry" })
		live.save(`{suite}-{tag}`, json)
		table.insert(lines, live.summary(json))
	end
	return table.concat(lines, "\n")
end

function live.summary(json: string, limit: number?): string
	local result = HttpService:JSONDecode(json)
	local lines = {
		`{result.suite}: {result.passed} passed, {result.failed} failed at {table.concat(
			result.environment.viewport,
			"x"
		)} {result.environment.preferredTextSize}`,
	}
	for _, case in result.cases do
		local bad = 0
		for _, check in case.checks do
			if not check.ok then
				bad += 1
				if bad <= (limit or 4) then
					table.insert(lines, `  FAIL {case.id} :: {check.name} {HttpService:JSONEncode(check.detail)}`)
				end
			end
		end
		table.insert(
			lines,
			`{if case.ok then "ok  " else "FAIL"} {case.id} ({#case.checks} checks, {bad} failed){if case.error
				then " error " .. string.sub(case.error, 1, 300)
				else ""}`
		)
	end
	return table.concat(lines, "\n")
end

return live
