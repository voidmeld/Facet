--!strict
local t = require("./lib/testkit")
local Facet = require("../src")
local engineLib = require("./lib/native_engine")
local terminal = require("../examples/gallery/examples/outpost_terminal")
local Compose = Facet.Compose

local function world()
	local engine = engineLib.new({ cacheDefaults = true })
	local runtime = Facet.Roblox.createRuntime(engine)
	local root = engine.new("ScreenGui")
	local gui = engine.new("GuiService")
	local input = engine.new("UserInputService")
	input.GetFocusedTextBox = function()
		return nil
	end
	local UI = Facet.controls(runtime, {
		types = engine.types,
		services = { GuiService = gui, UserInputService = input },
		reducedMotion = true,
	})
	return engine, runtime, root, UI
end

local function sameCensus(engine, baseline, label)
	local now = engine.census()
	assert(now.live == baseline.live, `{label}: live instances {baseline.live} -> {now.live}`)
	assert(now.connections == baseline.connections, `{label}: connections {baseline.connections} -> {now.connections}`)
end

local function random(seed)
	return function(low, high)
		seed = (seed * 48271) % 2147483647
		return low + seed % (high - low + 1)
	end
end

t.describe("native stress invariants", function()
	t.it("detects detached instance and service connection leaks in the census", function()
		local engine = engineLib.new()
		local service = engine.new("GuiService")
		local baseline = engine.census()
		local orphan = engine.new("Frame")
		t.expect(pcall(sameCensus, engine, baseline, "orphan")).toBe(false)
		orphan:Destroy()
		local connection = service:GetPropertyChangedSignal("SelectedObject"):Connect(function() end)
		t.expect(pcall(sameCensus, engine, baseline, "connection")).toBe(false)
		connection:Disconnect()
		sameCensus(engine, baseline, "cleaned")
	end)

	t.it("returns all instances and connections to baseline through 200 modal cycles twice", function()
		for replay = 1, 2 do
			local engine, runtime, root, UI = world()
			local before = engine.census()
			local shown = Compose.cell(false)
			local stop = runtime.mount(function()
				return runtime.constructors.Frame({
					UI.Button({ Name = "Base", label = "Open" }),
					UI.Alert({ isPresented = shown, title = "Confirm", actions = { { id = "ok", label = "OK" } } }),
				})
			end, root)
			local baseline = engine.census()
			for cycle = 1, 200 do
				shown:set(true)
				assert(engine.census().live > baseline.live, "alert must actually mount")
				shown:set(false)
				sameCensus(engine, baseline, `modal replay {replay} cycle {cycle}`)
			end
			stop()
			runtime.dispose()
			sameCensus(engine, before, "modal teardown")
		end
	end)

	t.it("reclaims detached and pooled rows through 100 structural cycles twice", function()
		for replay = 1, 2 do
			local engine, runtime, root, UI = world()
			local before = engine.census()
			local initial = { { id = "a" }, { id = "b" }, { id = "c" } }
			local source = Compose.cell(initial)
			local stop, node = runtime.mount(function()
				return UI.VirtualList({
					from = source,
					key = function(item)
						return item.id
					end,
					itemSize = 20,
					overscan = 0,
					render = function(current)
						return UI.Button({
							label = function(use)
								return use(current).id
							end,
						})
					end,
				})
			end, root)
			node.AbsoluteWindowSize = engine.types.Vector2.new(300, 100)
			local baseline = engine.census()
			for cycle = 1, 100 do
				source:set({ initial[2], initial[3], { id = `new{cycle}` } })
				source:set(initial)
				sameCensus(engine, baseline, `collection replay {replay} cycle {cycle}`)
			end
			stop()
			runtime.dispose()
			sameCensus(engine, before, "collection teardown")
		end
	end)

	t.it("preserves keyed row content and bounded retention across 400 replayable mutation seeds", function()
		for seed = 1, 400 do
			local rng = random(260720 + seed)
			local engine, runtime, root, UI = world()
			local before = engine.census()
			local rows = {}
			for index = 1, 80 do
				rows[index] = { id = index, label = tostring(index) }
			end
			local nextId, source, status = 80, Compose.cell(rows), Compose.cell({ total = 0 })
			local stop, node = runtime.mount(function()
				return UI.VirtualList({
					from = source,
					key = function(item)
						return item.id
					end,
					itemSize = 20,
					overscan = 0,
					status = status,
					render = function(current)
						return UI.Button({
							Name = "Value",
							label = function(use)
								return use(current).label
							end,
						})
					end,
				})
			end, root)
			for step = 1, 40 do
				local operation = rng(1, 5)
				rows = table.clone(rows)
				if operation == 1 then
					nextId += 1
					table.insert(rows, rng(1, #rows + 1), { id = nextId, label = tostring(nextId) })
				elseif operation == 2 and #rows > 5 then
					table.remove(rows, rng(1, #rows))
				elseif operation == 3 then
					local index = rng(1, #rows)
					rows[index] = { id = rows[index].id, label = `seed{seed}step{step}` }
				elseif operation == 4 then
					local first, second = rng(1, #rows), rng(1, #rows)
					rows[first], rows[second] = rows[second], rows[first]
				end
				source:set(rows)
				local visible = rng(1, 12)
				node.AbsoluteWindowSize = engine.types.Vector2.new(300, visible * 20)
				node.CanvasPosition = engine.types.Vector2.new(0, rng(0, #rows - visible) * 20)
				local snapshot = status:peek()
				assert(snapshot.total == #rows, `seed={seed} step={step}: total`)
				assert(snapshot.retained <= visible + 1, `seed={seed} step={step}: unbounded retention`)
				for index = snapshot.first, snapshot.last do
					local item = rows[index]
					local row = node:FindFirstChild(tostring(item.id), true)
					assert(
						row and row:FindFirstChild("Value", true).Text == item.label,
						`seed={seed} step={step}: stale keyed row {item.id}`
					)
				end
			end
			stop()
			runtime.dispose()
			sameCensus(engine, before, `seed={seed} teardown`)
		end
	end)

	t.it("converges authoritative snapshots under 400 seeded delayed duplicated reordered deliveries", function()
		for seed = 1, 400 do
			local rng = random(471120 + seed)
			local engine, runtime, root, UI = world()
			local before = engine.census()
			local built
			local stop = runtime.mount(function()
				built = terminal.build({
					Facet = Facet,
					Compose = Compose,
					runtime = runtime,
					Host = runtime.constructors,
					UI = UI,
					types = engine.types,
				}, { send = function() end })
				return built.screen()
			end, root)
			built.steps.engage(terminal.rules.START, 0)
			local highest = 0
			for step = 1, 80 do
				local revision = rng(1, 100)
				local allocation = { door = revision % 3, beacon = revision % 2, workshop = revision % 4 }
				local accepted = built.steps.ingest(revision, allocation)
				assert(accepted == (revision > highest), `seed={seed} step={step}: revision acceptance`)
				highest = math.max(highest, revision)
				assert(built.model.revision:peek() == highest, `seed={seed} step={step}: revision regressed`)
				assert(built.model.confirmed:peek().door == highest % 3, `seed={seed} step={step}: authority diverged`)
			end
			built.steps.ingest(101, terminal.rules.START)
			assert(built.model.revision:peek() == 101, `seed={seed}: final snapshot did not converge`)
			for id, value in terminal.rules.START do
				assert(built.model.confirmed:peek()[id] == value)
			end
			stop()
			runtime.dispose()
			sameCensus(engine, before, `replication seed={seed} teardown`)
		end
	end)
	t.it("rejects stale async completions and cancels exactly once through 200 seeded fault storms", function()
		for seed = 1, 200 do
			local rng = random(611001 + seed)
			local engine, runtime, root, UI = world()
			local before = engine.census()
			local source, requests, changes = Compose.cell("initial"), {}, 0
			local stop, node = runtime.mount(function()
				return UI.AsyncImage({
					source = source,
					loader = function(content, resolve, reject)
						local request = { resolve = resolve, reject = reject, cancelled = 0 }
						table.insert(requests, request)
						return function()
							request.cancelled += 1
						end
					end,
					onStatus = function()
						changes += 1
					end,
				})
			end, root)
			for step = 1, rng(5, 25) do
				source:set(`seed{seed}step{step}`)
				local old = requests[rng(1, #requests - 1)]
				local image = node:FindFirstChild("Image")
				local prior, notifications = image.Image, changes
				old.resolve("stale")
				old.reject("stale failure")
				assert(
					image.Image == prior and changes == notifications,
					`seed={seed} step={step}: stale completion changed UI`
				)
				local current = requests[#requests]
				if rng(1, 2) == 1 then
					current.resolve(source:peek())
					assert(image.Visible and image.Image == source:peek(), `seed={seed}: latest result missing`)
				else
					current.reject("injected failure")
					assert(not image.Visible, `seed={seed}: failure still paints image`)
				end
			end
			stop()
			local notifications = changes
			for _, request in requests do
				request.resolve("after teardown")
				request.reject("after teardown")
				assert(request.cancelled == 1, `seed={seed}: cancellation count {request.cancelled}`)
			end
			assert(changes == notifications, `seed={seed}: late callback survived owner`)
			runtime.dispose()
			sameCensus(engine, before, `async seed={seed} teardown`)
		end
	end)

	t.it("preserves UTF8 edit state and gates actions through 200 seeded preference and visibility storms", function()
		local labels = { "保存", "مرحبا", "Café", "👩‍🚀", "é", "Long translated label with spaces" }
		for seed = 1, 200 do
			local rng = random(845101 + seed)
			local engine, runtime, root, UI = world()
			local before = engine.census()
			local text, size, enabled = Compose.cell("Initial"), Compose.cell(16), Compose.cell(true)
			local activations, field, button = 0, nil, nil
			local stop, panel = runtime.mount(function()
				field = UI.TextInput({ value = text, TextSize = size })
				button = UI.Button({
					label = text,
					TextSize = size,
					enabled = enabled,
					onActivate = function()
						activations += 1
					end,
				})
				return runtime.constructors.Frame({ field, button })
			end, root)
			field:CaptureFocus()
			for step = 1, 40 do
				panel.Visible = true
				root.Enabled = true
				field:CaptureFocus()
				local value = labels[rng(1, #labels)]
				field.Text = value
				size:set(rng(12, 48))
				assert(
					text:peek() == value and field.Text == value and button.Text == value,
					`seed={seed} step={step}: expected={value} model={text:peek()} editor={field.Text} button={button.Text}`
				)
				assert(field:IsFocused(), `seed={seed} step={step}: preference lost editing focus`)
				assert(field.TextSize == size:peek() and button.TextSize == size:peek(), `seed={seed}: stale text size`)
				enabled:set(rng(0, 1) == 1)
				panel.Visible = rng(0, 1) == 1
				root.Enabled = rng(0, 1) == 1
				local prior = activations
				button.Activated.fire()
				local expected = if enabled:peek() and panel.Visible and root.Enabled then 1 else 0
				assert(activations == prior + expected, `seed={seed} step={step}: action eligibility stale`)
			end
			stop()
			runtime.dispose()
			sameCensus(engine, before, `preference seed={seed} teardown`)
		end
	end)
end)
