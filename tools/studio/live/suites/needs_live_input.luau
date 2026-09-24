--!strict
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

local cases = {}

local function add(id: string, contracts: { string }, setup: (any) -> any, steps: { [string]: (any, any) -> () })
	table.insert(cases, { id = id, contracts = contracts, setup = setup, steps = steps })
end

local function watchSelection(value: any)
	value.visited = {}
	value.connection = GuiService:GetPropertyChangedSignal("SelectedObject"):Connect(function()
		local selected = GuiService.SelectedObject
		table.insert(value.visited, if selected then selected.Name else "nil")
	end)
end

local function selectedName(): string
	local selected = GuiService.SelectedObject
	return if selected then selected.Name else "nil"
end

local function rows(count: number): { any }
	local list = {}
	for index = 1, count do
		list[index] = { id = tostring(index) }
	end
	return list
end

add("list-keyboard-and-dpad", { "collections-262" }, function(t)
	local value = {}
	local stage = t.mount(function(UI, Host)
		return UI.VirtualList "List" {
			from = rows(100),
			key = function(item)
				return item.id
			end,
			itemSize = 40,
			Size = UDim2.fromOffset(300, 200),
			render = function(current)
				return UI.Button({
					Name = "Row" .. current:peek().id,
					label = "Row " .. current:peek().id,
					Size = UDim2.fromScale(1, 1),
				})
			end,
		}
	end, { frames = 12 })
	value.list = t.find(stage, "List")
	GuiService.SelectedObject = t.find(stage, "Row1")
	t.check("row 1 selected at the start", selectedName() == "Row1", selectedName())
	return value
end, {
	afterDown = function(t)
		t.check("keyboard Down selects row 2", selectedName() == "Row2", selectedName())
	end,
	afterDpad = function(t)
		t.check("a second Down selects row 3", selectedName() == "Row3", selectedName())
	end,
	afterPast = function(t, value)
		local name = selectedName()
		local row = tonumber(string.match(name, "%d+")) or 0
		t.note("selected after moving past the band", name)
		t.near("canvas shows the selected row at the band end", value.list.CanvasPosition.Y, row * 40 - 200, 1)
	end,
})

add("scroll-into-view-by-gamepad", { "mech3-31" }, function(t)
	local value = {}
	local stage = t.mount(function(UI, Host)
		local children = {
			Host.UIListLayout({ Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
		}
		for index = 1, 20 do
			table.insert(children, UI.Button({ Name = "Item" .. index, label = "Item " .. index, LayoutOrder = index }))
		end
		return Host.ScrollingFrame "Plain" {
			Size = UDim2.fromOffset(300, 200),
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			table.unpack(children),
		}
	end, { frames = 12 })
	value.frame = t.find(stage, "Plain")
	GuiService.SelectedObject = t.find(stage, "Item1")
	return value
end, {
	afterDpad = function(t, value)
		local selected = GuiService.SelectedObject
		if not selected then
			t.check("an item is selected", false)
			return
		end
		local s, f = t.rect(selected), t.rect(value.frame)
		t.note("selected", selected.Name)
		t.check(
			"selection moved below the first band",
			(tonumber(string.match(selected.Name, "%d+")) or 0) >= 5,
			selected.Name
		)
		t.check("canvas moved", value.frame.CanvasPosition.Y > 0, value.frame.CanvasPosition)
		t.check(
			"selected item is fully visible",
			s.y >= f.y - 0.5 and s.b <= f.b + 0.5,
			{ item = { s.y, s.b }, frame = { f.y, f.b } }
		)
	end,
})

add("sidebar-dpad-to-collections", { "apps-193" }, function(t)
	local api = workspace:WaitForChild("FacetShowcaseAPI") :: any
	api:Invoke("show", "all-controls")
	t.settle(10)
	local gui = Players.LocalPlayer.PlayerGui:WaitForChild("FacetGallery")
	local tabs = gui:FindFirstChild("Gallery")
		and gui.Gallery:FindFirstChild("Demos")
		and gui.Gallery.Demos:FindFirstChild("Tabs")
	local tab = tabs and tabs:FindFirstChild("all-controls", true)
	t.check("all-controls tab found", tab ~= nil)
	GuiService.SelectedObject = tab
	t.settle(2)
	t.check("all-controls tab selected", selectedName() == "all-controls", selectedName())
	return {}
end, {
	afterDown = function(t)
		t.check("one DPadDown selects the collections tab", selectedName() == "collections", selectedName())
		GuiService.SelectedObject = nil
	end,
})

add("power-off-traversal", { "mech2-25" }, function(t)
	local value = {}
	local stage = t.mount(function(UI, Host, Compose, env)
		value.built = t.scenario("inherited_subtree").build(t.context(UI, Host, Compose, env))
		return value.built.screen()
	end, { frames = 12 })
	value.stage = stage
	value.built.live:set(false)
	t.settle(6)
	GuiService.SelectedObject = t.find(stage, "PowerToggle")
	t.settle(2)
	watchSelection(value)
	return value
end, {
	afterDpad = function(t, value)
		local visited = table.clone(value.visited)
		t.note("DPadDown visits", visited)
		t.check(
			"DPadDown never selects Go or InnerGo",
			not table.find(visited, "Go") and not table.find(visited, "InnerGo"),
			visited
		)
		t.check("DPadDown reaches After", table.find(visited, "After") ~= nil, visited)
		table.clear(value.visited)
		GuiService.SelectedObject = t.find(value.stage, "PowerToggle")
		t.settle(2)
		table.clear(value.visited)
	end,
	afterTab = function(t, value)
		local visited = table.clone(value.visited)
		t.note("Tab visits", visited)
		t.check(
			"Tab never selects Go or InnerGo",
			not table.find(visited, "Go") and not table.find(visited, "InnerGo"),
			visited
		)
		t.note("Tab reaches After", table.find(visited, "After") ~= nil)
		value.connection:Disconnect()
		GuiService.SelectedObject = nil
	end,
})

add("touch-drag-scrolls-reorderable-list", { "collections-11" }, function(t)
	local value = { reorders = 0 }
	local stage = t.mount(function(UI)
		return UI.VirtualList "Sortable" {
			from = rows(50),
			key = function(item)
				return item.id
			end,
			itemSize = 44,
			reorderable = true,
			onReorder = function()
				value.reorders += 1
			end,
			Size = UDim2.fromOffset(320, 220),
			render = function(current)
				return UI.Label({
					Name = "Cell" .. current:peek().id,
					text = "Row " .. current:peek().id,
					Size = UDim2.fromScale(1, 1),
				})
			end,
		}
	end, { frames = 12 })
	value.list = t.find(stage, "Sortable")
	local cell = t.find(stage, "Cell3")
	t.note("drag start", cell and cell.AbsolutePosition + cell.AbsoluteSize / 2)
	t.note("touch", t.environment.touch)
	return value
end, {
	afterDrag = function(t, value)
		t.check("the list scrolled", value.list.CanvasPosition.Y > 0, value.list.CanvasPosition)
		t.check("no reorder request", value.reorders == 0, value.reorders)
	end,
})

add("mail-swipe-and-tap", { "collections-101" }, function(t)
	local value = {}
	local demo = t.scenario("collection_demo")
	local stage = t.mount(function(UI, Host, Compose, env)
		local seed = {}
		for index = 1, 6 do
			seed[index] = {
				id = "m" .. index,
				from = "Sender " .. index,
				subject = "Subject " .. index,
				preview = "Preview " .. index,
				read = false,
				flagged = false,
			}
		end
		value.built = demo(t.context(UI, Host, Compose, env), {
			name = "Mail_list",
			title = "Mail",
			rows = seed,
			count = 6,
			actions = true,
			mail = true,
			list = true,
		})
		return value.built.screen()
	end, { frames = 16 })
	value.stage = stage
	return value
end, {
	afterSwipe = function(t, value)
		local row = t.find(value.stage, "Row_m1")
		local tray = row and row:FindFirstChild("trailing")
		t.check("the trailing tray of m1 opened", tray ~= nil and tray.AbsoluteSize.X > 0, tray and tray.AbsoluteSize)
	end,
	afterTap = function(t, value)
		local read = value.built.report().read
		t.check("a tap on m5 marks it read", read.m5 == true, read)
	end,
})

add("tray-grows-with-text-size", { "collections-53" }, function(t)
	local value = {}
	local stage = t.mount(function(UI, _, Compose)
		return UI.RowActions "Row" {
			content = UI.Label({ text = "Message", Size = UDim2.fromScale(1, 1) }),
			open = Compose.cell("trailing"),
			trailing = { { id = "delete", label = "Delete", role = "destructive", onActivate = function() end } },
			Size = UDim2.fromOffset(360, 56),
		}
	end, { frames = 12 })
	value.tray = t.find(stage, "trailing")
	value.before = value.tray.AbsoluteSize.X
	value.size = t.environment.preferredTextSize
	t.note("tray width before", value.before)
	return value
end, {
	afterChange = function(t, value)
		local label
		for _, node in value.tray:GetDescendants() do
			if (node:IsA("TextLabel") or node:IsA("TextButton")) and node.Text ~= "" then
				label = node
			end
		end
		local width = value.tray.AbsoluteSize.X
		t.note("text size", { before = value.size, after = tostring(GuiService.PreferredTextSize) })
		t.note("tray width after", width)
		t.check("tray is at least the label width plus 32", label ~= nil and width >= label.TextBounds.X + 32 - 0.5, {
			width = width,
			label = label and label.TextBounds,
		})
		t.check("tray width followed the text size", width ~= value.before, { before = value.before, after = width })
	end,
})

return cases
