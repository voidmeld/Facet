--!strict
local t = require("./lib/testkit")
local Facet = require("../src")
local engineLib = require("./lib/native_engine")
local glade = require("../examples/reference/p1_glade")
local gladeSeed = require("../examples/reference/p1_glade/content/seed")
local gladeStrings = require("../examples/reference/p1_glade/content/strings")
local cartwheel = require("../examples/reference/p2_cartwheel")
local cartData = require("../examples/reference/p2_cartwheel/content/data")
local cartArt = require("../examples/reference/p2_cartwheel/content/art")
local cartStrings = require("../examples/reference/p2_cartwheel/content/strings")
local cartOrders = require("../examples/reference/p2_cartwheel/services/order_service")
local cartClock = require("../examples/reference/p2_cartwheel/services/clock")
local cartAmbient = require("../examples/reference/p2_cartwheel/services/ambient_service")
local sipworks = require("../examples/reference/p3_sipworks")
local sipStrings = require("../examples/reference/p3_sipworks/content/strings")
local sipArt = require("../examples/reference/p3_sipworks/content/art")
local sipBlends = require("../examples/reference/p3_sipworks/content/blends")
local sipFavorites = require("../examples/reference/p3_sipworks/services/favorites")
local sipTask = require("../examples/reference/p3_sipworks/services/task")
local foyer = require("../examples/reference/p4_foyer")
local foyerSeed = require("../examples/reference/p4_foyer/content/seed")
local foyerStrings = require("../examples/reference/p4_foyer/content/strings")
local Compose = Facet.Compose

type World = {
	built: any,
	root: any,
	screen: any,
	engine: any,
	gui: any,
	runtime: any,
	stop: () -> (),
}

type Options = {
	reducedMotion: boolean?,
	heartbeat: boolean?,
	guiService: boolean?,
	viewport: any?,
	seed: number?,
}

local function world(module: any, options: Options?): World
	local settings: Options = options or {}
	local engine: any = engineLib.new()
	local runtime = Facet.Roblox.createRuntime(engine)
	local gui = engine.new("GuiService")
	gui.ReducedMotionEnabled = settings.reducedMotion == true
	local input = engine.new("UserInputService")
	input.GetFocusedTextBox = function()
		return nil
	end
	local screen = engine.new("ScreenGui")
	local built
	local stop, root = runtime.mount(function()
		built = module.build({
			Facet = Facet,
			Compose = Compose,
			runtime = runtime,
			Host = runtime.constructors,
			UI = Facet.controls(
				runtime,
				{
					types = engine.types,
					guiService = gui,
					services = { GuiService = gui, UserInputService = input },
				} :: any
			),
			types = engine.types,
			viewport = settings.viewport or Compose.cell({ width = 1000, height = 720 }),
			guiService = if settings.guiService or settings.reducedMotion ~= nil then gui else nil,
			heartbeat = if settings.heartbeat then engine.heartbeat else nil,
		})
		return built.screen()
	end, screen)
	return {
		built = built,
		root = root,
		screen = screen,
		engine = engine,
		gui = gui,
		runtime = runtime,
		stop = function()
			stop()
			runtime:dispose()
		end,
	}
end

local function find(node: any, name: string): any
	if node.Name == name then
		return node
	end
	for _, child in node:GetChildren() do
		local found = find(child, name)
		if found then
			return found
		end
	end
	return nil
end

local function within(node: any, ...: string): any
	local at = node
	for _, name in { ... } do
		at = find(at, name)
		if at == nil then
			return nil
		end
	end
	return at
end

local function texts(node: any): { string }
	local out = {}
	for _, child in node:GetDescendants() do
		if child.ClassName == "TextLabel" or child.ClassName == "TextButton" or child.ClassName == "TextBox" then
			if child.Text ~= "" then
				table.insert(out, child.Text)
			end
		end
	end
	return out
end

local function hasText(node: any, text: string): boolean
	return table.find(texts(node), text) ~= nil
end

local function containsText(node: any, fragment: string): boolean
	for _, value in texts(node) do
		if string.find(value, fragment, 1, true) then
			return true
		end
	end
	return false
end

local function modal(screen: any): any
	for _, child in screen:GetDescendants() do
		if child.Name == "SheetPanel" or child.Name == "AlertPanel" then
			return child
		end
	end
	return nil
end

local function press(node: any, ...: string)
	local target = assert(within(node, ...), `no {table.concat({ ... }, "/")}`)
	target.Activated.fire()
end

local function type_(node: any, name: string, value: string)
	local box = assert(find(node, name), `no text input {name}`)
	box:CaptureFocus()
	box.Text = value
	box:ReleaseFocus(true)
end

local function same(a: any, b: any): boolean
	if type(a) ~= "table" or type(b) ~= "table" then
		return a == b
	end
	for key, value in a do
		if not same(value, b[key]) then
			return false
		end
	end
	for key in b do
		if a[key] == nil then
			return false
		end
	end
	return true
end

local function placeholders(text: string): { string }
	local out = {}
	for name in string.gmatch(text, "{(%w+)}") do
		table.insert(out, name)
	end
	table.sort(out)
	return out
end

local JARGON = { "proof", "stage", "gate", "ledger", "spec", "clean%-room", "ra%-p" }

local function jargon(value: string): string?
	local lowered = string.lower(value)
	for _, pattern in JARGON do
		if string.find(lowered, pattern) then
			return pattern
		end
	end
	return nil
end

t.describe("native parity reference applications", function()
	t.describe("Glade", function()
		t.it(
			"opens the shop for an empty premium satchel and presents the wisp only when the glade is ready",
			function()
				local w = world(glade)
				local steps, model = w.built.steps, w.built.model
				local held = model.commerce.satchelOf("starlight")
				t.expect(held:peek()).toBe(gladeSeed.SATCHEL.starlight)
				for _ = 1, gladeSeed.SATCHEL.starlight do
					t.expect(steps.choose("mossholm", "starlight")).toBe(true)
				end
				t.expect(held:peek()).toBe(0)
				t.expect(modal(w.screen)).toBeNil()
				t.expect(steps.choose("mossholm", "starlight")).toBe(false)
				t.expect(held:peek()).toBe(0)
				t.expect(model.supply.nectarOf("mossholm"):peek()).toBe("starlight")
				t.expect(hasText(modal(w.screen), "Provisions")).toBe(true)
				w.stop()

				local fresh = world(glade)
				local report = fresh.built.report
				t.expect(fresh.built.model.visits.current("mossholm"):peek().wisp).toBe(gladeSeed.TASK.wisp)
				fresh.built.steps.open("mossholm")
				t.expect(#report().visits.presented).toBe(0)
				fresh.built.steps.refill("mossholm")
				t.expect(#report().visits.presented).toBe(0)
				t.expect(fresh.built.model.complete:peek()).toBe(false)
				t.expect(fresh.built.steps.choose("mossholm", gladeSeed.TASK_NECTAR)).toBe(true)
				t.expect(fresh.built.model.complete:peek()).toBe(true)
				t.expect(same(report().visits.presented, { "v2" })).toBe(true)
				t.expect(hasText(fresh.root, "Mossholm is ready. Your visiting wisp has a home.")).toBe(true)
				fresh.stop()
			end
		)

		t.it("drains nectar and dew on their own clock thresholds and restamps on refill", function()
			local w = world(glade)
			local steps, supply = w.built.steps, w.built.model.supply
			local nectar, dew = supply.state("mossholm", "nectar"), supply.state("lanternDell", "dew")
			t.expect(gladeSeed.DRAIN.nectar.low).toBe(7.5 * 60)
			t.expect(gladeSeed.DRAIN.nectar.empty).toBe(9 * 60)
			t.expect(gladeSeed.DRAIN.dew.low ~= gladeSeed.DRAIN.nectar.low).toBe(true)
			t.expect(gladeSeed.DRAIN.dew.empty ~= gladeSeed.DRAIN.nectar.empty).toBe(true)
			t.expect(nectar:peek()).toBe("full")
			steps.advance(449)
			t.expect(nectar:peek()).toBe("full")
			steps.advance(1)
			t.expect(nectar:peek()).toBe("low")
			steps.advance(89)
			t.expect(nectar:peek()).toBe("low")
			steps.advance(1)
			t.expect(nectar:peek()).toBe("empty")
			t.expect(supply.level("mossholm", "nectar"):peek()).toBe(0)
			steps.refill("lanternDell")
			t.expect(dew:peek()).toBe("full")
			t.expect(supply.level("lanternDell", "dew"):peek()).toBe(1)
			steps.advance(gladeSeed.DRAIN.dew.low - 1)
			t.expect(dew:peek()).toBe("full")
			t.expect(supply.level("lanternDell", "dew"):peek() < 1).toBe(true)
			steps.advance(1)
			t.expect(dew:peek()).toBe("low")
			steps.advance(gladeSeed.DRAIN.dew.empty - gladeSeed.DRAIN.dew.low - 1)
			t.expect(dew:peek()).toBe("low")
			steps.advance(1)
			t.expect(dew:peek()).toBe("empty")
			steps.refill("lanternDell")
			t.expect(dew:peek()).toBe("full")
			steps.advance(gladeSeed.DRAIN.dew.low)
			t.expect(dew:peek()).toBe("low")
			t.expect(steps.choose("mossholm", "clover")).toBe(true)
			t.expect(nectar:peek()).toBe("full")
			w.stop()
		end)

		t.it(
			"runs a provision purchase through pending, confirmed and the scripted decline on its Buy button",
			function()
				local w = world(glade)
				local steps, commerce = w.built.steps, w.built.model.commerce
				w.built.model.section:set("keeper")
				press(w.root, "Keeper", "Shop")
				local shop = assert(find(modal(w.screen), "Shop"))
				local row = assert(find(shop, "starlightSingle"))
				local buy = assert(find(row, "Buy"))
				t.expect(buy.Text).toBe(commerce.priceOf("starlightSingle"))
				t.expect(buy.Text).toBe(`{gladeStrings.PRICE_MARK} 79`)
				t.expect(find(find(shop, "moonpetalBundle"), "Buy").Text).toBe(commerce.priceOf("moonpetalBundle"))
				local before = commerce.satchelOf("starlight"):peek()
				buy.Activated.fire()
				t.expect(commerce.status("starlightSingle"):peek()).toBe("pending")
				t.expect(buy.Text).toBe("Confirming…")
				t.expect(buy.Interactable).toBe(false)
				t.expect(hasText(row, "pending")).toBe(true)
				buy.Activated.fire()
				t.expect(w.built.report().commerce.attempts.pack).toBe(1)
				steps.advance(gladeSeed.COMMAND_SECONDS - 0.01)
				t.expect(commerce.status("starlightSingle"):peek()).toBe("pending")
				steps.advance(0.01)
				t.expect(commerce.status("starlightSingle"):peek()).toBe("confirmed")
				t.expect(commerce.satchelOf("starlight"):peek()).toBe(before + 1)
				t.expect(buy.Interactable).toBe(true)
				t.expect(buy.Text).toBe(commerce.priceOf("starlightSingle"))
				buy.Activated.fire()
				steps.advance(gladeSeed.COMMAND_SECONDS)
				t.expect(commerce.status("starlightSingle"):peek()).toBe("rejected")
				t.expect(commerce.reason("starlightSingle"):peek()).toBe("declined")
				t.expect(commerce.satchelOf("starlight"):peek()).toBe(before + 1)
				t.expect(hasText(row, "rejected: declined")).toBe(true)
				w.stop()
			end
		)

		t.it(
			"refuses to resell an owned charm, confirms a retry and opens the Frostwisp early window with Lumen",
			function()
				local w = world(glade)
				local steps, commerce, visits = w.built.steps, w.built.model.commerce, w.built.model.visits
				steps.advance(60)
				t.expect(visits.current("lanternDell"):peek()).toBeNil()
				steps.charm("grove")
				steps.advance(gladeSeed.COMMAND_SECONDS)
				t.expect(commerce.charmTier():peek()).toBe("grove")
				for _, lower in { "ember", "grove" } do
					steps.charm(lower)
					steps.advance(gladeSeed.COMMAND_SECONDS)
					t.expect(commerce.status(lower):peek()).toBe("rejected")
					t.expect(commerce.reason(lower):peek()).toBe("owned")
					t.expect(commerce.charmTier():peek()).toBe("grove")
				end
				steps.charm("lumen")
				steps.advance(gladeSeed.COMMAND_SECONDS)
				t.expect(commerce.status("lumen"):peek()).toBe("rejected")
				t.expect(commerce.reason("lumen"):peek()).toBe("owned")
				t.expect(commerce.charmTier():peek()).toBe("grove")
				t.expect(visits.current("lanternDell"):peek()).toBeNil()
				steps.charm("lumen")
				steps.advance(gladeSeed.COMMAND_SECONDS)
				t.expect(commerce.status("lumen"):peek()).toBe("confirmed")
				t.expect(commerce.charmTier():peek()).toBe("lumen")
				local early = visits.current("lanternDell"):peek()
				t.expect(early.wisp).toBe("frostwisp")
				t.expect(early.start).toBe(60)
				steps.charm("ember")
				steps.advance(gladeSeed.COMMAND_SECONDS)
				t.expect(commerce.reason("ember"):peek()).toBe("owned")
				t.expect(commerce.charmTier():peek()).toBe("lumen")
				w.built.model.section:set("keeper")
				press(w.root, "Keeper", "Restore")
				t.expect(commerce.status("restore"):peek()).toBe("pending")
				steps.advance(gladeSeed.COMMAND_SECONDS)
				t.expect(commerce.status("restore"):peek()).toBe("confirmed")
				press(w.root, "Keeper", "Restore")
				steps.advance(gladeSeed.COMMAND_SECONDS)
				t.expect(commerce.status("restore"):peek()).toBe("rejected")
				t.expect(commerce.reason("restore"):peek()).toBe("offline")
				w.stop()
			end
		)

		t.it("states where a wisp was last seen and when it has not been seen", function()
			local w = world(glade)
			w.built.model.section:set("wisps")
			press(w.root, "Wisps", "emberwisp", "Open")
			local sheet = assert(modal(w.screen))
			t.expect(hasText(sheet, "Last seen in Mossholm")).toBe(true)
			press(sheet, "Close")
			t.expect(modal(w.screen)).toBeNil()
			press(w.root, "Wisps", "frostwisp", "Open")
			t.expect(hasText(assert(modal(w.screen)), "Not seen yet")).toBe(true)
			w.stop()
		end)

		t.it("commits a keeper edit on Save and discards it on Cancel", function()
			local w = world(glade)
			local model = w.built.model
			local name = gladeSeed.KEEPER.displayName
			model.section:set("keeper")
			press(w.root, "Keeper", "EditKeeper")
			local sheet = assert(modal(w.screen))
			type_(sheet, "DisplayName", "Rowan")
			t.expect(model.draftName:peek()).toBe("Rowan")
			press(sheet, "CancelKeeper")
			t.expect(modal(w.screen)).toBeNil()
			t.expect(model.keeperName:peek()).toBe(name)
			t.expect(hasText(w.root, name)).toBe(true)
			press(w.root, "Keeper", "EditKeeper")
			sheet = assert(modal(w.screen))
			t.expect(find(sheet, "DisplayName").Text).toBe(name)
			type_(sheet, "DisplayName", "Rowan")
			type_(sheet, "Contact", "rowan@glade")
			press(sheet, "SaveKeeper")
			t.expect(modal(w.screen)).toBeNil()
			t.expect(model.keeperName:peek()).toBe("Rowan")
			t.expect(model.keeperContact:peek()).toBe("rowan@glade")
			t.expect(hasText(w.root, "Rowan")).toBe(true)
			w.stop()
		end)

		t.it("asks before Fresh Start, keeps the world on Keep and reseeds it on Start over", function()
			local pristine = world(glade)
			local fresh = pristine.built.report()
			pristine.stop()
			local w = world(glade)
			local steps, model = w.built.steps, w.built.model
			steps.refill("fernhollow")
			steps.choose("mossholm", "starlight")
			steps.buy("starlightBundle")
			steps.charm("ember")
			steps.advance(30)
			type_(w.root, "Search", "moss")
			model.keeperName:set("Rowan")
			model.section:set("keeper")
			local changed = w.built.report()
			t.expect(same(changed, fresh)).toBe(false)
			press(w.root, "Keeper", "FreshStart")
			local alert = assert(modal(w.screen))
			t.expect(hasText(alert, gladeStrings.get("en", "keeper.confirmTitle"))).toBe(true)
			press(alert, "cancel")
			t.expect(modal(w.screen)).toBeNil()
			t.expect(same(w.built.report(), changed)).toBe(true)
			t.expect(model.keeperName:peek()).toBe("Rowan")
			press(w.root, "Keeper", "FreshStart")
			press(assert(modal(w.screen)), "reset")
			t.expect(modal(w.screen)).toBeNil()
			t.expect(same(w.built.report(), fresh)).toBe(true)
			t.expect(model.section:peek()).toBe("glades")
			t.expect(find(w.root, "Search").Text).toBe("")
			local cards = 0
			for _, child in within(w.root, "Glades", "Content", "Glades"):GetChildren() do
				if child.ClassName == "Frame" then
					cards += 1
				end
			end
			t.expect(cards).toBe(#gladeSeed.GLADES)
			t.expect(model.keeperName:peek()).toBe(gladeSeed.KEEPER.displayName)
			w.stop()
		end)

		t.it(
			"gives identical reports for identical worlds, keeps a report stable and makes every step callable",
			function()
				local function drive(target: World)
					local steps = target.built.steps
					steps.open("fernhollow")
					steps.refill("fernhollow")
					steps.choose("fernhollow", "meadow")
					steps.buy("gildedSingle")
					steps.charm("grove")
					steps.restore()
					steps.advance(120)
					steps.choose("mossholm", "starlight")
					steps.advance(400)
				end
				local a, b = world(glade), world(glade)
				drive(a)
				drive(b)
				local first = a.built.report()
				t.expect(same(first, b.built.report())).toBe(true)
				t.expect(same(first, a.built.report())).toBe(true)
				t.expect(first.commerce.charm).toBe("grove")
				local calls = {
					advance = { 1 },
					open = { "mossholm" },
					refill = { "mossholm" },
					choose = { "mossholm", "clover" },
					buy = { "moonpetalSingle" },
					charm = { "lumen" },
					restore = {},
					reset = {},
					saveKeeper = {},
				}
				for name, step in a.built.steps do
					local args = assert(calls[name], `unexpected step {name}`)
					t.expect(type(step)).toBe("function")
					step(table.unpack(args))
				end
				for name in calls do
					t.expect(type(a.built.steps[name])).toBe("function")
				end
				a.stop()
				b.stop()
			end
		)

		t.it("lists one overview entry per seeded glade in order with supply states and filters by search", function()
			local w = world(glade)
			local list = assert(within(w.root, "Glades", "Content", "Glades"))
			local function ids(): { string }
				local out = {}
				local children = {}
				for _, child in list:GetChildren() do
					if child.ClassName == "Frame" then
						table.insert(children, child)
					end
				end
				table.sort(children, function(x, y)
					return x.LayoutOrder < y.LayoutOrder
				end)
				for _, child in children do
					table.insert(out, child.Name)
				end
				return out
			end
			local seeded = {}
			for _, item in gladeSeed.GLADES do
				table.insert(seeded, item.id)
			end
			t.expect(table.concat(ids(), ",")).toBe(table.concat(seeded, ","))
			t.expect(hasText(find(list, "mossholm"), "Dew low · Nectar full")).toBe(true)
			t.expect(hasText(find(list, "lanternDell"), "Dew full · Nectar empty")).toBe(true)
			t.expect(hasText(find(list, "fernhollow"), "Dew low · Nectar low")).toBe(true)
			type_(w.root, "Search", "MOSS")
			t.expect(table.concat(ids(), ",")).toBe("mossholm")
			type_(w.root, "Search", "zzz")
			t.expect(#ids()).toBe(0)
			type_(w.root, "Search", "")
			t.expect(#ids()).toBe(#gladeSeed.GLADES)
			w.built.model.section:set("favorites")
			local favorites =
				assert(within(w.root, "Destinations", "Content", "favorites", "Glades", "Content", "Glades"))
			local shown = 0
			for _, child in favorites:GetChildren() do
				if child.ClassName == "Frame" then
					shown += 1
					t.expect(gladeSeed.GLADE_BY_ID[child.Name].favourite).toBe(true)
				end
			end
			t.expect(shown).toBe(1)
			w.stop()
		end)

		t.it("refills dew instantly from the detail with no confirmation and a toast", function()
			local w = world(glade)
			local supply = w.built.model.supply
			press(w.root, "Task")
			local sheet = assert(modal(w.screen))
			t.expect(supply.state("mossholm", "dew"):peek()).toBe("low")
			press(sheet, "GladeDetail", "Refill")
			t.expect(supply.state("mossholm", "dew"):peek()).toBe("full")
			t.expect(supply.level("mossholm", "dew"):peek()).toBe(1)
			t.expect(modal(w.screen)).toBe(sheet)
			t.expect(find(w.screen, "AlertPanel")).toBeNil()
			t.expect(hasText(w.root, gladeStrings.get("en", "toast.refill", { glade = "Mossholm" }))).toBe(true)
			t.expect(hasText(sheet, "Dew: full")).toBe(true)
			w.stop()
		end)

		t.it("moves its navigation between homes on a live resize and keeps the world and every section", function()
			local w = world(glade)
			local model = w.built.model
			local destinations = assert(find(w.root, "Destinations"))
			local V2 = w.engine.types.Vector2
			local E = w.engine.types.Enum
			model.supply.refill("fernhollow", "dew")
			type_(w.root, "Search", "fern")
			local report = w.built.report()
			local tabs = assert(find(destinations, "Tabs"))
			destinations.AbsoluteSize = V2.new(1000, 700)
			t.expect(tabs.ScrollingDirection).toBe(E.ScrollingDirection.Y)
			destinations.AbsoluteSize = V2.new(390, 800)
			t.expect(tabs.ScrollingDirection).toBe(E.ScrollingDirection.X)
			t.expect(tabs.Position.Y.Scale).toBe(1)
			destinations.AbsoluteSize = V2.new(1000, 700)
			t.expect(tabs.ScrollingDirection).toBe(E.ScrollingDirection.Y)
			t.expect(find(w.root, "Destinations")).toBe(destinations)
			t.expect(find(destinations, "Tabs")).toBe(tabs)
			t.expect(same(w.built.report(), report)).toBe(true)
			t.expect(find(w.root, "Search").Text).toBe("fern")
			for _, size in { V2.new(1000, 700), V2.new(390, 800), V2.new(800, 360) } do
				destinations.AbsoluteSize = size
				for _, id in { "glades", "favorites", "wisps", "flora", "keeper" } do
					find(tabs, id).Activated.fire()
					t.expect(model.section:peek()).toBe(id)
				end
			end
			w.stop()
		end)

		t.it(
			"keeps locale key parity, expands by 1.4 times, keeps placeholders, falls back and relabels live",
			function()
				local keys = gladeStrings.keys()
				t.expect(#keys > 80).toBe(true)
				for _, key in keys do
					local en, xa = gladeStrings.TABLES.en[key], gladeStrings.TABLES.xa[key]
					t.expect(type(xa)).toBe("string")
					t.expect(#xa).toBe(#en + math.max(1, math.ceil(#en * 0.4)))
					t.expect(table.concat(placeholders(xa), ",")).toBe(table.concat(placeholders(en), ","))
				end
				local filled = gladeStrings.get("xa", "toast.refill", { glade = "Mossholm" })
				t.expect(string.find(filled, "Mossholm", 1, true) ~= nil).toBe(true)
				t.expect(string.find(filled, "{glade}", 1, true)).toBeNil()
				t.expect(gladeStrings.get("qq", "keeper.cancel")).toBe("Cancel")
				t.expect(gladeStrings.get("qq", "task.open", { glade = "Mossholm" })).toBe("Open Mossholm")
				local w = world(glade)
				local task = assert(find(w.root, "Task"))
				local open = assert(within(w.root, "Glades", "mossholm", "Open"))
				t.expect(open.Text).toBe("Mossholm")
				w.built.model.section:set("keeper")
				press(w.root, "Keeper", "Locale", "xa")
				w.built.model.section:set("glades")
				t.expect(open.Text).toBe(gladeStrings.TABLES.xa["glade.mossholm"])
				t.expect(find(w.root, "Task")).toBe(task)
				t.expect(within(w.root, "Glades", "mossholm", "Open")).toBe(open)
				w.stop()
			end
		)

		t.it("keeps the same states and events under reduced motion and holds the wisp still", function()
			local function drive(target: World)
				local steps = target.built.steps
				steps.refill("mossholm")
				steps.choose("mossholm", gladeSeed.TASK_NECTAR)
				steps.buy("gildedSingle")
				steps.advance(3)
			end
			local moving = world(glade, { reducedMotion = false })
			local still = world(glade, { reducedMotion = true })
			local function wisp(target: World): any
				return assert(within(target.root, "Glades", "mossholm", "LivingGlade", gladeSeed.TASK.wisp))
			end
			local movingStart, stillStart = wisp(moving).Position, wisp(still).Position
			drive(moving)
			drive(still)
			t.expect(wisp(still).Position).toBe(stillStart)
			t.expect(wisp(moving).Position ~= movingStart).toBe(true)
			t.expect(same(moving.built.report(), still.built.report())).toBe(true)
			still.gui.ReducedMotionEnabled = false
			still.built.steps.advance(1)
			t.expect(wisp(still).Position ~= stillStart).toBe(true)
			moving.stop()
			still.stop()
		end)

		t.it("browses flora by name and species with no presented surface", function()
			local w = world(glade)
			w.built.model.section:set("flora")
			local page = assert(find(w.root, "Flora"))
			for _, item in gladeSeed.FLORA do
				local column = assert(find(page, item.id), item.id)
				t.expect(hasText(column, gladeStrings.get("en", "flora." .. item.id))).toBe(true)
				t.expect(hasText(column, gladeStrings.get("en", "flora.species." .. item.id))).toBe(true)
				for _, node in column:GetDescendants() do
					t.expect(node.ClassName ~= "TextButton").toBe(true)
				end
			end
			t.expect(modal(w.screen)).toBeNil()
			w.stop()
		end)

		t.it("keeps test vocabulary out of every string a player can read", function()
			local offenders = {}
			for _, locale in gladeStrings.LOCALES do
				for key, value in gladeStrings.TABLES[locale] do
					if jargon(value) then
						table.insert(offenders, `{locale}:{key}`)
					end
				end
			end
			local w = world(glade)
			for _, id in { "glades", "favorites", "wisps", "flora", "keeper" } do
				w.built.model.section:set(id)
				for _, value in texts(w.root) do
					if jargon(value) then
						table.insert(offenders, value)
					end
				end
			end
			t.expect(table.concat(offenders, "; ")).toBe("")
			t.expect(glade.title).toBe("Glade")
			w.stop()
		end)
	end)

	t.describe("Cartwheel", function()
		local LATENCY = 0.25

		local function pages(w: World): any
			return assert(within(w.root, "Destinations", "Content"))
		end

		local function brewList(w: World): any
			w.built.model.section:set("brews")
			local list = assert(find(pages(w), "BrewList"))
			list.AbsoluteSize = w.engine.types.Vector2.new(600, 4000)
			list.AbsoluteWindowSize = w.engine.types.Vector2.new(600, 4000)
			return list
		end

		local function rowKeys(list: any): { number }
			local out = {}
			for _, row in assert(find(list, "Items")):GetChildren() do
				local key = tonumber(row.Name)
				if key then
					table.insert(out, key)
				end
			end
			table.sort(out, function(a, b)
				return a > b
			end)
			return out
		end

		t.it("borrows only shipped framework art for its potion marks", function()
			local neutral = Facet.themes.neutralPackage()
			local count = 0
			for name, mark in cartArt.marks do
				count += 1
				t.expect(Facet.themes.resolveIcon(neutral, mark.iconName)).toBe(mark.image)
				t.expect(table.find(cartArt.cycle, name) ~= nil).toBe(true)
			end
			t.expect(count).toBe(#cartArt.cycle)
			for _, potion in cartData.potions do
				t.expect(Facet.themes.resolveIcon(neutral, potion.mark.iconName)).toBe(potion.mark.image)
			end
			local w = world(cartwheel)
			w.built.model.section:set("workbench")
			for _, potion in cartData.potions do
				t.expect(within(pages(w), "Potions", potion.id, "Potion").Image).toBe(potion.mark.image)
			end
			w.stop()
		end)

		t.it("selects each section through its tab button", function()
			local w = world(cartwheel)
			local tabs = assert(within(w.root, "Destinations", "Tabs"))
			for _, id in { "brews", "workbench", "ledger", "chatter", "plazas", "dashboard" } do
				press(tabs, id)
				t.expect(w.built.model.section:peek()).toBe(id)
			end
			press(tabs, "workbench")
			t.expect(find(pages(w), "Workbench") ~= nil).toBe(true)
			t.expect(find(pages(w), "PotionName") ~= nil).toBe(true)
			w.stop()
		end)

		t.it("matches a brew search on its number, its potions and their ingredients", function()
			local w = world(cartwheel)
			local list = brewList(w)
			local brews = w.built.model.orders.brews:peek()
			t.expect(#rowKeys(list)).toBe(#brews)
			local function expected(query: string): { number }
				local out = {}
				for _, brew in brews do
					if string.find(w.built.model.orders.searchText(brew), string.lower(query), 1, true) then
						table.insert(out, brew.id)
					end
				end
				table.sort(out, function(a, b)
					return a > b
				end)
				return out
			end
			type_(pages(w), "Search", "117")
			t.expect(table.concat(rowKeys(list), ",")).toBe("117")
			local sample = brews[1]
			local potion = assert(cartData.potionById(sample.items[1].potion))
			type_(pages(w), "Search", string.upper(potion.name))
			local byPotion = rowKeys(list)
			t.expect(table.find(byPotion, sample.id) ~= nil).toBe(true)
			t.expect(table.concat(byPotion, ",")).toBe(table.concat(expected(potion.name), ","))
			local base = assert(cartData.ingredientById(potion.base))
			type_(pages(w), "Search", base.name)
			local byIngredient = rowKeys(list)
			t.expect(table.find(byIngredient, sample.id) ~= nil).toBe(true)
			t.expect(table.concat(byIngredient, ",")).toBe(table.concat(expected(base.name), ","))
			type_(pages(w), "Search", "no such brew")
			t.expect(#rowKeys(list)).toBe(0)
			w.stop()
		end)

		t.it(
			"moves a brew through start, brewing and done, disables pending commands and rejects a second collect",
			function()
				local w = world(cartwheel)
				local model, steps = w.built.model, w.built.steps
				local orders, commands = model.orders, model.commands
				local list = brewList(w)
				local row = assert(within(list, "Items", "101"))
				local advance = assert(find(row, "Advance"))
				t.expect(orders.statusOf(101)).toBe("new")
				t.expect(advance.Text).toBe("Start brewing")
				advance.Activated.fire()
				t.expect(commands.status("start:101"):peek()).toBe("pending")
				t.expect(advance.Interactable).toBe(false)
				advance.Activated.fire()
				steps.advance(LATENCY)
				t.expect(#commands.dump()).toBe(1)
				t.expect(orders.statusOf(101)).toBe("brewing")
				t.expect(orders.remaining(101)).toBe(orders.brewSeconds())
				t.expect(advance.Interactable).toBe(false)
				steps.openBrew(101)
				local sheet = assert(modal(w.screen))
				t.expect(hasText(sheet, `Status: brewing · {orders.brewSeconds()} s`)).toBe(true)
				t.expect(find(sheet, "Start").Interactable).toBe(false)
				t.expect(find(sheet, "Collect").Interactable).toBe(false)
				steps.advance(orders.brewSeconds() / 2)
				t.expect(orders.remaining(101)).toBe(orders.brewSeconds() / 2)
				t.expect(hasText(sheet, `Status: brewing · {math.ceil(orders.brewSeconds() / 2)} s`)).toBe(true)
				steps.advance(orders.brewSeconds())
				t.expect(orders.remaining(101)).toBe(0)
				t.expect(orders.statusOf(101)).toBe("brewing")
				press(sheet, "Close")
				steps.collect(101)
				t.expect(commands.status("finish:101"):peek()).toBe("pending")
				steps.advance(LATENCY)
				t.expect(orders.statusOf(101)).toBe("done")
				t.expect(orders.remaining(101)).toBeNil()
				t.expect(commands.status("finish:101"):peek()).toBe("confirmed")
				press(assert(modal(w.screen)), "done")
				local ready = assert(within(list, "Items", "124", "Advance"))
				t.expect(ready.Text).toBe("Collect brew")
				ready.Activated.fire()
				t.expect(ready.Interactable).toBe(false)
				steps.advance(LATENCY)
				t.expect(orders.statusOf(124)).toBe("done")
				press(assert(modal(w.screen)), "done")
				t.expect(steps.collect(124)).toBe(true)
				steps.advance(LATENCY)
				t.expect(commands.status("finish:124"):peek()).toBe("rejected")
				t.expect(commands.reason("finish:124"):peek()).toBe("Brew already collected")
				t.expect(hasText(w.root, "Brew already collected")).toBe(true)
				t.expect(steps.start(124)).toBe(true)
				steps.advance(LATENCY)
				t.expect(commands.reason("start:124"):peek()).toBe("Brew already collected")
				t.expect(orders.statusOf(124)).toBe("done")
				w.stop()
			end
		)

		t.it("opens the completion celebration on a collected brew and closes it on its action", function()
			local w = world(cartwheel)
			local steps = w.built.steps
			t.expect(modal(w.screen)).toBeNil()
			steps.collect(120)
			t.expect(modal(w.screen)).toBeNil()
			steps.advance(LATENCY)
			local alert = assert(modal(w.screen))
			t.expect(alert.Name).toBe("AlertPanel")
			t.expect(hasText(alert, "Brew collected!")).toBe(true)
			local brew = w.built.model.orders.byId(120)
			t.expect(hasText(alert, `Brew #120 collected · {brew.bottles} bottles`)).toBe(true)
			press(alert, "done")
			t.expect(modal(w.screen)).toBeNil()
			t.expect(w.built.model.stats.collectedBottles() >= brew.bottles).toBe(true)
			w.stop()
		end)

		t.it(
			"delivers scripted arrivals in id order at seeded three to eight second gaps and re-keys the newest row",
			function()
				local w = world(cartwheel)
				local model, steps = w.built.model, w.built.steps
				local times = model.orders.arrivalTimes
				t.expect(#times).toBe(20)
				local previous = 0
				for _, at in times do
					t.expect(at - previous >= 3 and at - previous <= 8).toBe(true)
					previous = at
				end
				local list = brewList(w)
				t.expect(rowKeys(list)[1]).toBe(124)
				steps.advance(times[1] - 0.01)
				t.expect(#model.orders.arrivalLog()).toBe(0)
				steps.advance(0.01)
				t.expect(table.concat(model.orders.arrivalLog(), ",")).toBe("125")
				t.expect(model.orders.brews:peek()[1].id).toBe(125)
				t.expect(rowKeys(list)[1]).toBe(125)
				for _ = 1, 200 do
					steps.advance(1)
				end
				local report = w.built.report().orders
				t.expect(#report.arrivals).toBe(20)
				for index, id in report.arrivals do
					t.expect(id).toBe(124 + index)
				end
				t.expect(report.arrivalsRemaining).toBe(0)
				t.expect(report.first).toBe(144)
				list.CanvasPosition = w.engine.types.Vector2.zero
				t.expect(rowKeys(list)[1]).toBe(144)
				t.expect(model.orders.statusOf(144)).toBe("new")
				model.section:set("dashboard")
				t.expect(hasText(pages(w), `{#model.orders.brews:peek()} brews · 0 bottles collected`)).toBe(true)
				w.stop()
			end
		)

		t.it("opens the workbench on a potion, applies edits at once and keeps each draft after leaving", function()
			local w = world(cartwheel)
			local model, steps = w.built.model, w.built.steps
			model.section:set("workbench")
			press(pages(w), "Potions", "moonwell", "Mix")
			t.expect(model.selectedPotion:peek()).toBe("moonwell")
			t.expect(model.draftName:peek()).toBe("Moonwell")
			t.expect(model.base:peek()).toBe("springwater")
			t.expect(find(pages(w), "PotionName").Text).toBe("Moonwell")
			type_(pages(w), "PotionName", "Moonwell Reserve")
			t.expect(model.draftName:peek()).toBe("Moonwell Reserve")
			press(pages(w), "Base", "Trigger")
			local option = assert(find(w.screen, "hearthmilk"))
			option.Activated.fire()
			t.expect(model.base:peek()).toBe("hearthmilk")
			local attributes = cartData.attributesOf("hearthmilk", "skyveil", "swirl-skyveil")
			local summary = {}
			for index, name in cartData.ATTRIBUTES do
				table.insert(summary, name .. " " .. tostring(attributes[index]))
			end
			t.expect(hasText(pages(w), table.concat(summary, " · "))).toBe(true)
			model.section:set("ledger")
			model.section:set("workbench")
			t.expect(model.draftName:peek()).toBe("Moonwell Reserve")
			t.expect(find(pages(w), "PotionName").Text).toBe("Moonwell Reserve")
			steps.selectPotion("ashroot")
			t.expect(model.draftName:peek()).toBe("Ashroot")
			t.expect(model.base:peek()).toBe("emberoil")
			steps.selectPotion("moonwell")
			t.expect(model.draftName:peek()).toBe("Moonwell Reserve")
			t.expect(model.base:peek()).toBe("hearthmilk")
			press(pages(w), "NewPotion")
			t.expect(model.selectedPotion:peek()).toBe("scratch")
			t.expect(model.draftName:peek()).toBe("New potion")
			w.stop()
		end)

		t.it("locks the longer ledger and the chatter bonus until the second purchase is granted", function()
			local w = world(cartwheel)
			local model, steps = w.built.model, w.built.steps
			model.section:set("ledger")
			t.expect(find(pages(w), "Trading") ~= nil).toBe(true)
			press(pages(w), "LedgerTimeframe", "month")
			t.expect(model.ledgerTimeframe:peek()).toBe("month")
			t.expect(find(pages(w), "Trading")).toBeNil()
			local buy = assert(within(pages(w), "Unlock", "Buy"))
			buy.Activated.fire()
			t.expect(buy.Interactable).toBe(false)
			steps.advance(LATENCY)
			t.expect(model.entitlement.fullLedger:peek()).toBe(false)
			t.expect(hasText(w.root, "Purchase declined — nothing was charged")).toBe(true)
			t.expect(find(pages(w), "Trading")).toBeNil()
			press(pages(w), "Unlock", "Buy")
			steps.advance(LATENCY)
			t.expect(model.entitlement.fullLedger:peek()).toBe(true)
			t.expect(find(pages(w), "Unlock")).toBeNil()
			t.expect(within(pages(w), "Trading", "Markets", "gullsgate") ~= nil).toBe(true)
			model.section:set("chatter")
			local function posts(): number
				local count = 0
				for _, child in assert(find(pages(w), "Posts")):GetChildren() do
					if child.ClassName == "Frame" then
						count += 1
					end
				end
				return count
			end
			t.expect(posts()).toBe(#cartData.chatterPosts)
			press(pages(w), "Subscribe")
			steps.advance(LATENCY)
			t.expect(model.entitlement.chatterPlus:peek()).toBe(false)
			t.expect(posts()).toBe(#cartData.chatterPosts)
			press(pages(w), "Subscribe")
			steps.advance(LATENCY)
			t.expect(model.entitlement.chatterPlus:peek()).toBe(true)
			t.expect(posts()).toBe(#cartData.chatterPosts + #cartData.chatterBonusPosts)
			t.expect(find(pages(w), "Subscribe").Interactable).toBe(false)
			w.stop()
		end)

		t.it("rejects a taken guild name with its reason and signs in an accepted name", function()
			local w = world(cartwheel)
			local model, steps = w.built.model, w.built.steps
			press(w.root, "Guild")
			local sheet = assert(modal(w.screen))
			t.expect(find(sheet, "Submit").Interactable).toBe(false)
			type_(sheet, "GuildName", "  Cartwheel ")
			t.expect(find(sheet, "GuildName").Text).toBe("cartwheel")
			type_(sheet, "Watchword", "secret")
			local submit = assert(find(sheet, "Submit"))
			t.expect(submit.Interactable).toBe(true)
			submit.Activated.fire()
			t.expect(submit.Interactable).toBe(false)
			steps.advance(LATENCY)
			t.expect(model.identity.signedIn:peek()).toBe(false)
			t.expect(model.commands.status("signup"):peek()).toBe("rejected")
			t.expect(hasText(sheet, "That guild name is taken")).toBe(true)
			t.expect(modal(w.screen)).toBe(sheet)
			type_(sheet, "GuildName", "NewKeepers")
			press(sheet, "Submit")
			steps.advance(LATENCY)
			t.expect(model.identity.signedIn:peek()).toBe(true)
			t.expect(model.identity.guildName:peek()).toBe("newkeepers")
			t.expect(modal(w.screen)).toBeNil()
			t.expect(find(w.root, "Guild").Text).toBe("Sign out of newkeepers")
			w.stop()
		end)

		t.it("recommends the first plaza without a damp spell and mounts the market Stage", function()
			local ambient = cartAmbient.new({ seed = 1 })
			local recommended = ambient.recommendedPlaza()
			for _, plaza in cartData.plazas do
				if plaza == recommended then
					break
				end
				t.expect(ambient.hasDampSpell(plaza.id)).toBe(true)
			end
			t.expect(ambient.hasDampSpell(recommended.id)).toBe(false)
			local w = world(cartwheel)
			t.expect(hasText(pages(w), "Recommended pitch: " .. recommended.name)).toBe(true)
			w.built.model.section:set("plazas")
			local stage = assert(find(pages(w), "MarketScene"))
			t.expect(stage.ClassName).toBe("ViewportFrame")
			t.expect(stage.CurrentCamera ~= nil).toBe(true)
			local scene = assert(find(stage, cartData.plazas[1].name))
			t.expect(scene.ClassName).toBe("Model")
			t.expect(find(scene, "Cart").ClassName).toBe("Part")
			t.expect(find(scene, "Potion5") ~= nil).toBe(true)
			local weather = ambient.forPlaza(cartData.plazas[1].id)
			t.expect(hasText(pages(w), `Cloud cover {weather.cloud}%`)).toBe(true)
			w.stop()
		end)

		t.it("reports identically for one seed, differs for another and leaves nothing behind on dispose", function()
			local function drive(target: World)
				local steps = target.built.steps
				steps.start(101)
				steps.collect(115)
				steps.purchase("ledger")
				steps.advance(0.3)
				steps.purchase("ledger")
				steps.signup("cartwheel", "x")
				steps.advance(30)
			end
			local a, b = world(cartwheel), world(cartwheel)
			drive(a)
			drive(b)
			t.expect(same(a.built.report(), b.built.report())).toBe(true)
			t.expect(same(a.built.report(), a.built.report())).toBe(true)
			local function dump(seed: number): any
				local clock = cartClock.new(Compose, { start = 0 })
				local orders = cartOrders.new({ Compose = Compose, clock = clock, seed = seed })
				clock.advance(30)
				return orders.dump()
			end
			t.expect(same(dump(1), dump(1))).toBe(true)
			t.expect(same(dump(1).arrivals, a.built.report().orders.arrivals)).toBe(true)
			t.expect(same(dump(1), dump(2))).toBe(false)
			a.stop()
			b.stop()
			local engine: any = engineLib.new()
			local runtime = Facet.Roblox.createRuntime(engine)
			local host = engine.new("ScreenGui")
			local baseline = engine.census()
			local stop, root = runtime.mount(function()
				return cartwheel
					.build({
						Facet = Facet,
						Compose = Compose,
						runtime = runtime,
						Host = runtime.constructors,
						UI = Facet.controls(runtime, { types = engine.types } :: any),
						types = engine.types,
						viewport = Compose.cell({ width = 1000, height = 720 }),
						heartbeat = engine.heartbeat,
					})
					.screen()
			end, host)
			t.expect(engine.heartbeat.count()).toBe(1)
			engine.heartbeat.fire(LATENCY)
			stop()
			runtime:dispose()
			t.expect(root.isDestroyed()).toBe(true)
			t.expect(engine.heartbeat.count()).toBe(0)
			t.expect(engine.census().live).toBe(baseline.live)
			t.expect(engine.census().connections).toBe(baseline.connections)
		end)

		t.it("expands the pseudo-locale by at least 1.4 times and keeps every placeholder", function()
			t.expect(cartStrings.EXPANSION).toBe(1.4)
			local count = 0
			for key, en in cartStrings.locales.en do
				count += 1
				local xa = assert(cartStrings.locales.xa[key])
				t.expect(#xa >= math.ceil(#en * 1.4)).toBe(true)
				t.expect(string.sub(xa, 2, #en + 1)).toBe(en)
				t.expect(table.concat(placeholders(xa), ",")).toBe(table.concat(placeholders(en), ","))
			end
			for key in cartStrings.locales.xa do
				t.expect(cartStrings.locales.en[key] ~= nil).toBe(true)
			end
			t.expect(count > 40).toBe(true)
			local welcome = cartStrings.new("xa").t("guild.welcome", { name = "Ash" })
			t.expect(string.find(welcome, "Ash", 1, true) ~= nil).toBe(true)
			t.expect(string.find(welcome, "{name}", 1, true)).toBeNil()
			t.expect(cartStrings.new("zz").locale).toBe("en")
		end)

		t.it("mounts and drives identically with reduced motion", function()
			local function drive(target: World): any
				local steps = target.built.steps
				steps.start(102)
				steps.collect(111)
				steps.advance(0.3)
				steps.purchase("chatter")
				steps.advance(12)
				steps.openBrew(102)
				return target.built.report()
			end
			local moving = world(cartwheel, { reducedMotion = false })
			local still = world(cartwheel, { reducedMotion = true })
			t.expect(same(drive(moving), drive(still))).toBe(true)
			t.expect(modal(still.screen) ~= nil).toBe(true)
			moving.stop()
			still.stop()
		end)
	end)

	t.describe("Sipworks", function()
		local function pages(w: World): any
			return assert(within(w.root, "Destinations", "Content"))
		end

		local function blendRows(w: World, tab: string?): { string }
			local list = assert(within(pages(w), tab or "menu", "Blends"))
			local rows = {}
			for _, child in list:GetChildren() do
				if child.ClassName == "Frame" then
					table.insert(rows, child)
				end
			end
			table.sort(rows, function(a, b)
				return a.LayoutOrder < b.LayoutOrder
			end)
			local out = {}
			for _, row in rows do
				table.insert(out, row.Name)
			end
			return out
		end

		t.it("keeps search text, the open blend and the section across a shell flip", function()
			local w = world(sipworks)
			local model = w.built.model
			local destinations = assert(find(w.root, "Destinations"))
			local tabs = assert(find(destinations, "Tabs"))
			local V2, E = w.engine.types.Vector2, w.engine.types.Enum
			destinations.AbsoluteSize = V2.new(390, 800)
			type_(pages(w), "Search", "mint")
			press(tabs, "favorites")
			press(pages(w), "favorites", "Blends", "mistral-mint", "Open")
			local sheet = assert(modal(w.screen))
			local root = w.root
			t.expect(tabs.ScrollingDirection).toBe(E.ScrollingDirection.X)
			destinations.AbsoluteSize = V2.new(1100, 800)
			t.expect(tabs.ScrollingDirection).toBe(E.ScrollingDirection.Y)
			t.expect(model.search:peek()).toBe("mint")
			t.expect(within(pages(w), "favorites", "Search").Text).toBe("mint")
			t.expect(model.section:peek()).toBe("favorites")
			t.expect(model.selected:peek()).toBe("mistral-mint")
			t.expect(modal(w.screen)).toBe(sheet)
			t.expect(find(w.root, "Destinations")).toBe(destinations)
			t.expect(w.root).toBe(root)
			destinations.AbsoluteSize = V2.new(390, 800)
			t.expect(model.search:peek()).toBe("mint")
			t.expect(model.section:peek()).toBe("favorites")
			w.stop()
		end)

		t.it(
			"matches a title or a botanical, shares the query across sections and toggles a shared favorite",
			function()
				local w = world(sipworks)
				local model = w.built.model
				type_(pages(w), "Search", "lavender")
				t.expect(table.concat(blendRows(w), ",")).toBe("moonpetal,nightporch")
				type_(pages(w), "Search", "MOON")
				t.expect(table.concat(blendRows(w), ",")).toBe("moonpetal")
				type_(pages(w), "Search", "lavender")
				t.expect(model.favorites.isFavorite("moonpetal")).toBe(false)
				local favorite = assert(within(pages(w), "Blends", "moonpetal", "Favorite"))
				t.expect(favorite.Text).toBe("Save favorite")
				favorite.Activated.fire()
				t.expect(model.favorites.isFavorite("moonpetal")).toBe(true)
				t.expect(favorite.Text).toBe("Remove favorite")
				press(assert(within(w.root, "Destinations", "Tabs")), "favorites")
				t.expect(model.search:peek()).toBe("lavender")
				t.expect(find(pages(w), "Search").Text).toBe("lavender")
				t.expect(table.concat(blendRows(w, "favorites"), ",")).toBe("moonpetal")
				press(pages(w), "favorites", "Blends", "moonpetal", "Favorite")
				t.expect(model.favorites.isFavorite("moonpetal")).toBe(false)
				t.expect(#blendRows(w, "favorites")).toBe(0)
				type_(within(pages(w), "favorites"), "Search", "")
				local expected = {}
				for _, id in model.favorites.ids() do
					table.insert(expected, id)
				end
				local shown = blendRows(w, "favorites")
				table.sort(shown)
				t.expect(table.concat(shown, ",")).toBe(table.concat(expected, ","))
				w.stop()
			end
		)

		t.it("opens the botanical card from a tile with the facts for this blend", function()
			local w = world(sipworks)
			local catalog = w.built.model.catalog
			w.built.steps.open("lantern-oolong")
			press(assert(modal(w.screen)), "BlendDetail", "jasmine")
			local card = assert(find(w.screen, "BotanicalCard"))
			t.expect(hasText(card, "Jasmine")).toBe(true)
			t.expect(hasText(card, sipArt.of("botanical", "jasmine").mark)).toBe(true)
			t.expect(find(card, "MeasuredFacts")).toBeNil()
			press(card, "Flip")
			local facts = assert(find(card, "MeasuredFacts"))
			local i18n = w.built.model.i18n
			for _, fact in catalog.factsFor("lantern-oolong", "jasmine") do
				local line = i18n.t(fact.key) .. ": " .. i18n.t("facts." .. fact.kind, { value = fact.value })
				t.expect(hasText(facts, line)).toBe(true)
			end
			t.expect(#catalog.factsFor("lantern-oolong", "jasmine")).toBe(4)
			t.expect(#texts(facts)).toBe(4)
			w.stop()
		end)

		t.it("shows the guard reason and never starts an order when ordering is off", function()
			local w = world(sipworks)
			local model = w.built.model
			model.order.setPaymentsEnabled(false)
			w.built.steps.open("amber-harvest")
			press(assert(modal(w.screen)), "BlendDetail", "Order")
			t.expect(model.order.status:peek()).toBe("idle")
			t.expect(hasText(w.root, sipStrings.byLocale.en["guard.paymentsDisabled"])).toBe(true)
			t.expect(model.task.phase:peek()).toBe("order")
			w.built.steps.advance(5)
			t.expect(model.order.attempts()).toBe(0)
			t.expect(model.rewards.unspent()).toBe(9)
			w.stop()
		end)

		t.it("refuses the Blend Book while its price loads and rescales recipe measures with the batch", function()
			local w = world(sipworks)
			local model, steps = w.built.model, w.built.steps
			steps.open("lantern-oolong")
			local sheet = assert(modal(w.screen))
			press(sheet, "BlendDetail", "Recipe")
			local buy = assert(within(sheet, "Unlock", "Buy"))
			t.expect(model.unlock.availability:peek()).toBe("pending")
			t.expect(buy.Interactable).toBe(false)
			t.expect(steps.buyBook()).toBe(false)
			steps.advance(0.99)
			t.expect(buy.Interactable).toBe(false)
			steps.advance(0.01)
			t.expect(buy.Interactable).toBe(true)
			press(sheet, "Close")
			steps.open("amber-harvest")
			sheet = assert(modal(w.screen))
			press(sheet, "BlendDetail", "Recipe")
			local recipe
			for _, node in sheet:GetDescendants() do
				if node.Name == "Recipe" and node.ClassName == "Frame" then
					recipe = node
				end
			end
			assert(recipe, "no recipe column")
			t.expect(find(recipe, "Unlock")).toBeNil()
			local assam = assert(find(recipe, "assam"))
			local function label(node: any): string
				return node.Text
			end
			t.expect(label(assam)).toBe("Assam · 2 tsp")
			t.expect(label(find(recipe, "cinnamon"))).toBe("Cinnamon · 0.5 tsp")
			local increase = assert(within(recipe, "Batch", "Increase"))
			increase.Activated.fire()
			increase.Activated.fire()
			t.expect(model.batch:peek()).toBe(3)
			t.expect(label(assam)).toBe("Assam · 6 tsp")
			t.expect(label(find(recipe, "cinnamon"))).toBe("Cinnamon · 1.5 tsp")
			model.i18n.setLocale("xa")
			t.expect(label(find(recipe, "cinnamon"))).toBe("Cinnamon · " .. model.i18n.measureAt("xa", 1.5, "tsp"))
			t.expect(string.find(label(find(recipe, "cinnamon")), "1,5", 1, true) ~= nil).toBe(true)
			w.stop()
		end)

		t.it(
			"keeps locale keys, expansion, placeholders, plurals and separators and relabels without a remount",
			function()
				local en, xa = sipStrings.byLocale.en, sipStrings.byLocale.xa
				local worst, measured = math.huge, 0
				for key, entry in en do
					local forms = if type(entry) == "table" then entry else { other = entry }
					for form, template in forms do
						local expanded = assert(xa[key])
						local text = if type(expanded) == "table" then expanded[form] else expanded
						t.expect(type(text)).toBe("string")
						local source = string.gsub(template, "{[%w_]+}", "")
						local target = string.gsub(text, "{[%w_]+}", "")
						if #string.gsub(source, "%s", "") >= 4 then
							measured += 1
							worst = math.min(worst, #target / #source)
						end
						t.expect(table.concat(placeholders(text), ",")).toBe(table.concat(placeholders(template), ","))
					end
				end
				t.expect(measured > 30).toBe(true)
				t.expect(worst >= sipStrings.EXPANSION).toBe(true)
				for key in xa do
					t.expect(en[key] ~= nil).toBe(true)
				end
				local w = world(sipworks)
				local i18n = w.built.model.i18n
				t.expect(i18n.at("en", "rewards.away", { n = 0 })).toBe("Your next pour is on the house!")
				t.expect(i18n.at("en", "rewards.away", { n = 1 })).toBe("You are 1 stamp from a free pour!")
				t.expect(i18n.at("en", "rewards.away", { n = 4 })).toBe("You are 4 stamps from a free pour!")
				t.expect(i18n.at("xa", "recipe.batches", { n = 1 })).toBe(xa["recipe.batches"].one)
				t.expect(i18n.at("xa", "recipe.batches", { n = 3 }))
					.toBe(string.gsub(xa["recipe.batches"].other, "{n}", "3"))
				t.expect(i18n.listAt("en", { "a", "b" })).toBe("a and b")
				t.expect(i18n.listAt("en", { "a", "b", "c" })).toBe("a, b, and c")
				t.expect(i18n.listAt("xa", { "a", "b" }) ~= "a and b").toBe(true)
				t.expect(i18n.measureAt("en", 1.5, "tsp")).toBe("1.5 tsp")
				t.expect(string.find(i18n.measureAt("xa", 1.5, "tsp"), "1,5", 1, true) ~= nil).toBe(true)
				t.expect(i18n.setLocale("zz")).toBe(false)
				t.expect(i18n.locale:peek()).toBe("en")
				local open = assert(within(pages(w), "Blends", "amber-harvest", "Open"))
				t.expect(open.Text).toBe("Amber Harvest")
				local root = w.root
				w.built.model.section:set("rewards")
				press(pages(w), "Locale", "xa")
				t.expect(i18n.locale:peek()).toBe("xa")
				w.built.model.section:set("menu")
				open = assert(within(pages(w), "Blends", "amber-harvest", "Open"))
				t.expect(open.Text).toBe(sipStrings.expand("Amber Harvest"))
				t.expect(w.root).toBe(root)
				w.stop()
			end
		)

		t.it("reports identically for identical worlds and seeds favorites deterministically", function()
			local function drive(target: World)
				local steps = target.built.steps
				steps.favorite("tidepool")
				steps.order("amber-harvest", "paid")
				steps.advance(0.7)
				steps.order("amber-harvest", "paid")
				steps.advance(5)
				steps.buyBook()
				steps.advance(2)
			end
			local a, b = world(sipworks), world(sipworks)
			drive(a)
			drive(b)
			t.expect(same(a.built.report(), b.built.report())).toBe(true)
			t.expect(same(a.built.report(), a.built.report())).toBe(true)
			t.expect(a.built.report().task).toBe("redeem/10/true/false/false")
			local function seeded(seed: number): { string }
				local ids = {}
				for _, blend in sipBlends.list do
					table.insert(ids, blend.id)
				end
				return sipFavorites.new({ Compose = Compose, seed = seed, ids = ids }).ids()
			end
			t.expect(same(seeded(1), seeded(1))).toBe(true)
			t.expect(same(seeded(1), seeded(2))).toBe(false)
			a.stop()
			b.stop()
		end)

		t.it("fires the same events under reduced motion and leaves nothing behind on dispose", function()
			local function drive(target: World): any
				local steps = target.built.steps
				steps.order("amber-harvest", "paid")
				steps.advance(0.7)
				steps.order("amber-harvest", "paid")
				steps.advance(0.7)
				steps.redeem()
				steps.advance(5)
				return target.built.report()
			end
			local moving = world(sipworks, { reducedMotion = false })
			local still = world(sipworks, { reducedMotion = true })
			t.expect(same(drive(moving), drive(still))).toBe(true)
			t.expect(still.built.report().task).toBe("done/0/true/true/false")
			moving.stop()
			still.stop()
			local engine: any = engineLib.new()
			local runtime = Facet.Roblox.createRuntime(engine)
			local host = engine.new("ScreenGui")
			local baseline = engine.census()
			local built
			local stop, root = runtime.mount(function()
				built = sipworks.build({
					Facet = Facet,
					Compose = Compose,
					runtime = runtime,
					Host = runtime.constructors,
					UI = Facet.controls(runtime, { types = engine.types } :: any),
					types = engine.types,
					viewport = Compose.cell({ width = 1000, height = 720 }),
					heartbeat = engine.heartbeat,
				})
				return built.screen()
			end, host)
			built.steps.order("amber-harvest", "paid")
			engine.heartbeat.fire(0.7)
			t.expect(built.model.order.status:peek()).toBe("rejected")
			stop()
			runtime:dispose()
			t.expect(root.isDestroyed()).toBe(true)
			t.expect(engine.heartbeat.count()).toBe(0)
			t.expect(engine.census().live).toBe(baseline.live)
			t.expect(engine.census().connections).toBe(baseline.connections)
		end)

		t.it("names the task blend on its action, orders that blend and ends the task after the free pour", function()
			local w = world(sipworks)
			local model, steps = w.built.model, w.built.steps
			local task = assert(within(pages(w), "Menu", "Task"))
			t.expect(task.Text).toBe("Order " .. model.catalog.blend(sipTask.FIRST_BLEND).title)
			t.expect(within(pages(w), "Blends", sipTask.FIRST_BLEND, "Open").Text).toBe("Amber Harvest")
			task.Activated.fire()
			t.expect(model.order.blendId:peek()).toBe(sipTask.FIRST_BLEND)
			t.expect(model.order.mode:peek()).toBe("paid")
			t.expect(task.Interactable).toBe(false)
			steps.advance(0.7)
			t.expect(model.task.phase:peek()).toBe("rejected")
			task.Activated.fire()
			steps.advance(0.7)
			t.expect(model.task.phase:peek()).toBe("redeem")
			t.expect(task.Text).toBe("Redeem a " .. model.catalog.blend(sipTask.FREE_POUR_BLEND).title)
			task.Activated.fire()
			t.expect(model.order.blendId:peek()).toBe(sipTask.FREE_POUR_BLEND)
			t.expect(model.order.mode:peek()).toBe("redeem")
			steps.advance(0.7)
			t.expect(model.task.phase:peek()).toBe("done")
			t.expect(model.rewards.unspent()).toBe(0)
			t.expect(task.Interactable).toBe(false)
			t.expect(hasText(w.root, sipStrings.byLocale.en["order.redeemed"])).toBe(true)
			w.stop()
		end)

		t.it("titles the module Sipworks and keeps test vocabulary out of player strings", function()
			t.expect(sipworks.title).toBe("Sipworks")
			local offenders = {}
			for key, value in sipStrings.byLocale.en do
				local forms = if type(value) == "string" then { value } else value
				for _, text in forms do
					if jargon(text) then
						table.insert(offenders, key)
					end
				end
			end
			local w = world(sipworks)
			for _, id in { "menu", "favorites", "rewards", "book" } do
				w.built.model.section:set(id)
				for _, value in texts(w.root) do
					if jargon(value) then
						table.insert(offenders, value)
					end
				end
			end
			t.expect(table.concat(offenders, "; ")).toBe("")
			w.stop()
		end)
	end)

	t.describe("Foyer", function()
		local function pages(w: World): any
			return assert(within(w.root, "Destinations", "Content"))
		end

		local function sectionIds(w: World): { string }
			local out = {}
			local list = assert(within(pages(w), "home", "Sections"))
			local children = {}
			for _, child in list:GetChildren() do
				if child.ClassName == "Frame" then
					table.insert(children, child)
				end
			end
			table.sort(children, function(a, b)
				return a.LayoutOrder < b.LayoutOrder
			end)
			for _, child in children do
				table.insert(out, child.Name)
			end
			return out
		end

		t.it("docks a wide rail or a compact bottom bar and never remounts the home body", function()
			local w = world(foyer)
			local destinations = assert(find(w.root, "Destinations"))
			local tabs = assert(find(destinations, "Tabs"))
			local V2, E = w.engine.types.Vector2, w.engine.types.Enum
			destinations.AbsoluteSize = V2.new(1200, 800)
			t.expect(tabs.ScrollingDirection).toBe(E.ScrollingDirection.Y)
			t.expect(tabs.Position.Y.Scale).toBe(0)
			local feed = assert(within(pages(w), "home", "Feed"))
			local search = assert(find(feed, "Search"))
			destinations.AbsoluteSize = V2.new(390, 800)
			t.expect(tabs.ScrollingDirection).toBe(E.ScrollingDirection.X)
			t.expect(tabs.Position.Y.Scale).toBe(1)
			t.expect(within(pages(w), "home", "Feed")).toBe(feed)
			t.expect(find(feed, "Search")).toBe(search)
			destinations.AbsoluteSize = V2.new(1200, 800)
			t.expect(within(pages(w), "home", "Feed")).toBe(feed)
			w.stop()
		end)

		t.it("swaps the feed for the charts and shows unopened destinations honestly", function()
			local w = world(foyer)
			local services = w.built.model.services
			local picked = {}
			for _, section in services.sections:peek() do
				table.insert(picked, section.id)
			end
			t.expect(table.concat(sectionIds(w), ",")).toBe(table.concat(picked, ","))
			press(pages(w), "home", "FeedSelection", "charts")
			t.expect(w.built.model.tab:peek()).toBe("charts")
			local charted = {}
			for _, section in services.charted do
				table.insert(charted, section.id)
			end
			t.expect(table.concat(sectionIds(w), ",")).toBe(table.concat(charted, ","))
			local first = services.charted[1]
			local tiles = assert(within(pages(w), "home", "Sections", first.id, "Tiles"))
			local shown = {}
			for _, child in tiles:GetChildren() do
				if child.ClassName == "Frame" then
					table.insert(shown, child)
				end
			end
			table.sort(shown, function(a, b)
				return a.LayoutOrder < b.LayoutOrder
			end)
			for index, tile in first.tiles do
				t.expect(shown[index].Name).toBe(tile.id)
			end
			press(pages(w), "home", "FeedSelection", "forYou")
			t.expect(table.concat(sectionIds(w), ",")).toBe(table.concat(picked, ","))
			press(assert(within(w.root, "Destinations", "Tabs")), "forge")
			t.expect(w.built.model.destination:peek()).toBe("forge")
			local forge = assert(within(pages(w), "forge", "Forge"))
			t.expect(hasText(forge, foyerStrings.get("en", "stub.honest"))).toBe(true)
			t.expect(find(forge, "Worlds")).toBeNil()
			t.expect(find(forge, "Artwork")).toBeNil()
			for _, node in forge:GetDescendants() do
				t.expect(node.ClassName ~= "TextButton").toBe(true)
			end
			w.stop()
		end)

		t.it("leaves Keep playing untouched and the world open after a rejected visit", function()
			local w = world(foyer)
			local steps, services = w.built.steps, w.built.model.services
			press(pages(w), "home", "Sections", "moss-kingdom", "Open")
			local sheet = assert(modal(w.screen))
			t.expect(hasText(sheet, "Moss Kingdom")).toBe(true)
			local visit = assert(within(sheet, "World", "Visit"))
			t.expect(visit.Text).toBe(foyerStrings.get("en", "detail.visit"))
			steps.reject("visit", "err.generic")
			visit.Activated.fire()
			t.expect(services.visitStatus:peek()).toBe("pending")
			t.expect(visit.Text).toBe(foyerStrings.get("en", "detail.visiting"))
			t.expect(visit.Interactable).toBe(false)
			steps.settle()
			t.expect(services.visitStatus:peek()).toBe("rejected")
			t.expect(next(w.built.report().continued)).toBeNil()
			t.expect(modal(w.screen)).toBe(sheet)
			t.expect(visit.Interactable).toBe(true)
			t.expect(visit.Text).toBe(foyerStrings.get("en", "detail.visit"))
			t.expect(hasText(w.root, foyerStrings.get("en", "err.generic"))).toBe(true)
			visit.Activated.fire()
			steps.settle()
			t.expect(w.built.report().continued["moss-kingdom"]).toBe(true)
			t.expect(hasText(w.root, foyerStrings.get("en", "toast.visited"))).toBe(true)
			w.stop()
		end)

		t.it(
			"clears the bell count, relabels on a locale swap, scripts image transport and stays deterministic",
			function()
				local w = world(foyer)
				local services = w.built.model.services
				local bell = assert(within(pages(w), "home", "Notifications"))
				t.expect(bell.Text).toBe(`{foyerStrings.get("en", "bell.label")} · {#foyerSeed.notices}`)
				t.expect(w.built.report().notices).toBe(#foyerSeed.notices)
				bell.Activated.fire()
				t.expect(services.noticeCount:peek()).toBe(0)
				t.expect(bell.Text).toBe(`{foyerStrings.get("en", "bell.label")} · 0`)
				local sheet = assert(modal(w.screen))
				for _, notice in foyerSeed.notices do
					t.expect(hasText(sheet, notice.bodyKeyless)).toBe(true)
				end
				press(sheet, "Close")
				t.expect(modal(w.screen)).toBeNil()

				local tiles = assert(within(pages(w), "home", "Sections", "picked", "Tiles"))
				local ready = assert(within(tiles, "moss-kingdom", "Artwork"))
				local _, asset = foyerSeed.assetFor("thumb:moss-kingdom")
				t.expect(find(ready, "Image").Visible).toBe(true)
				t.expect(find(ready, "Image").Image).toBe(asset)
				t.expect(find(ready, "Placeholder").Visible).toBe(false)
				local failed = assert(within(tiles, "signal-lost", "Artwork"))
				t.expect(foyerSeed.assetFor("thumb:signal-lost")).toBe(false)
				t.expect(find(failed, "Image").Visible).toBe(false)
				t.expect(find(failed, "Placeholder").Visible).toBe(true)
				t.expect(hasText(failed, "Artwork unavailable")).toBe(true)
				w.built.model.destination:set("crews")
				local friends = assert(within(pages(w), "crews", "Friends"))
				for _, friend in foyerSeed.friends do
					local portrait = assert(within(friends, friend.id, "Artwork"))
					t.expect(find(portrait, "Image").Visible).toBe(foyerSeed.assetFor(friend.portraitKey))
				end
				press(pages(w), "crews", "Invite")
				local invite = assert(modal(w.screen))
				t.expect(invite.Name).toBe("AlertPanel")
				t.expect(hasText(invite, foyerStrings.get("en", "invite.label"))).toBe(true)
				t.expect(hasText(invite, foyerStrings.get("en", "invite.stub"))).toBe(true)
				press(invite, "close")
				t.expect(modal(w.screen)).toBeNil()

				local root = w.root
				local homeTab = assert(within(w.root, "Destinations", "Tabs", "home"))
				local refresh = assert(within(pages(w), "home", "Refresh"))
				t.expect(refresh.Text).toBe(foyerStrings.get("en", "refresh.label"))
				w.built.model.destination:set("you")
				press(pages(w), "you", "Locale", "xa")
				t.expect(w.built.model.locale:peek()).toBe("xa")
				t.expect(refresh.Text).toBe(foyerStrings.get("xa", "refresh.label"))
				t.expect(within(pages(w), "home", "Refresh")).toBe(refresh)
				t.expect(homeTab:GetAttribute("FacetLabel")).toBe(foyerStrings.get("xa", "nav.home"))
				t.expect(w.root).toBe(root)
				t.expect(foyerStrings.get("qq", "nav.home")).toBe("Home")

				local function drive(target: World): any
					local steps = target.built.steps
					steps.search("moss")
					steps.refresh()
					steps.settle()
					steps.open("gloamwood")
					steps.visit("gloamwood")
					steps.settle()
					return target.built.report()
				end
				local a, b = world(foyer), world(foyer)
				t.expect(same(drive(a), drive(b))).toBe(true)
				t.expect(same(a.built.report(), a.built.report())).toBe(true)
				a.stop()
				b.stop()
				w.stop()
				t.expect(root.isDestroyed()).toBe(true)
				t.expect(refresh.isDestroyed()).toBe(true)
			end
		)
	end)
end)
