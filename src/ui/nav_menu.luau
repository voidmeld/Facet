--!strict
local Types = require("./types")
local Nav = require("./navigation_types")
local Inputs = require("./input_types")
local Media = require("./media_types")
local ComposeTypes = require("../vendor/compose/core")

type MenuEntry<V> = { key: string, heading: string?, item: Nav.MenuItem<V>? }

return function(
	ctx: Types.Context,
	UI: {
		Menu: Nav.MenuConstructor,
		Picker: Nav.PickerConstructor,
		SplitButton: Nav.SplitButtonConstructor,
		ComboBox: Types.Constructor<Nav.ComboBoxSpec, Frame>,
		Button: Types.Constructor<Inputs.ButtonProps, TextButton>,
		TextInput: Types.Constructor<Inputs.TextInputProps, TextBox>,
		Badge: Types.Constructor<Media.BadgeProps, GuiObject>,
		Avatar: Types.Constructor<Media.AvatarProps, TextButton>,
	},
	surfaces: Nav.Surfaces
): ()
	local Host, Compose, runtime, read = ctx.Host, ctx.Compose, ctx.runtime, ctx.read
	local POPOVER: Nav.MotionTiming = { enter = 0.15, exit = 0.1 }
	local E, D2, V2, D = ctx.types.Enum, ctx.types.UDim2, ctx.types.Vector2, ctx.types.UDim
	local function writable(cell: { set: unknown }, name: string)
		assert(type(cell) == "table" and type(cell.set) == "function", name .. " requires a writable Compose cell")
	end
	local function actionItem<V>(item: Nav.MenuItem<V>): Nav.MenuAction<V>
		assert(item.divider ~= true, "Menu action cannot be a divider")
		return item
	end
	local function commitItem<V>(item: Nav.MenuAction<V>): boolean
		if read(item.enabled) == false then
			return false
		end
		if item.checked then
			item.checked:set(not item.checked:peek())
			if item.onChange then
				item.onChange(item.checked:peek())
			end
		elseif item.selected then
			item.selected:set(item.value)
			if item.onChange then
				item.onChange(item.value)
			end
		end
		local onSelect: (() -> ())? = item.onSelect
		if onSelect then
			onSelect()
		end
		return true
	end
	local function menuItems<V>(items: { Nav.MenuItem<V> }, use: ComposeTypes.Use?): { Nav.MenuItem<V> }
		assert(type(items) == "table", "Menu.items must be an array")
		local result: { Nav.MenuItem<V> } = {}
		local identifiers: { [string]: boolean } = {}
		for index = 1, #items do
			local source = items[index]
			local copy = table.clone(source)
			local id = copy.id or tostring(index)
			copy.id = id
			local item: Nav.MenuItem<V> = copy
			assert(not identifiers[id], `Facet UI.Menu: two items at one level share the id '{id}'`)
			identifiers[id] = true
			if not item.divider then
				assert(
					type(read(item.label, use)) == "string" and string.find(read(item.label, use), "%S") ~= nil,
					"Menu items require nonempty labels"
				)
				assert(not (item.children and item.onSelect), "A menu item cannot have both children and onSelect")
				assert(
					item.children or item.onSelect or item.checked or item.selected,
					"Menu items require an action, submenu, or selection state"
				)
				assert(not (item.checked and item.selected), "A menu item cannot be both checked and selected")
				if item.children then
					item.children = menuItems(read(item.children, use), use)
				end
			end
			table.insert(result, item)
		end
		return result
	end
	local function menuPanel<V>(
		spec: Nav.MenuSpec<V>,
		close: () -> (),
		anchor: GuiObject,
		nonmodal: boolean?,
		phase: Nav.PresencePhase?
	): Frame
		local shown = if phase then surfaces.appearance(phase, POPOVER) else nil
		local path = Compose.cell({} :: { string })
		local pendingFocus: string?
		local rootItems = Compose.formula(function(use: ComposeTypes.Use)
			return menuItems(read(spec.items, use), use)
		end)
		local current = Compose.formula(function(use: ComposeTypes.Use)
			local items = use(rootItems)
			for _, id in use(path) do
				local found: Nav.MenuAction<V>?
				for _, item in items do
					if item.divider ~= true and item.id == id then
						found = item
						break
					end
				end
				if not found or not found.children then
					break
				end
				items = read(found.children, use)
			end
			return items
		end)
		Compose.watch(function(use: ComposeTypes.Use)
			local items, valid = use(rootItems), {}
			for _, id in path:peek() do
				local found: Nav.MenuAction<V>?
				for _, item in items do
					if item.divider ~= true and item.id == id then
						found = item
						break
					end
				end
				if not found or not found.children then
					break
				end
				table.insert(valid, id)
				items = read(found.children, use)
			end
			if #valid ~= #path:peek() then
				path:set(valid)
			end
		end)
		local function back()
			local previous = table.clone(path:peek())
			if #previous == 0 then
				close()
			else
				pendingFocus = table.remove(previous)
				path:set(previous)
			end
		end
		local widths = Compose.cell({} :: { [string]: number })
		local function landing(items: { Nav.MenuItem<V> }): string?
			for _, item in items do
				if item.divider ~= true then
					local action = actionItem(item)
					if
						action.selected ~= nil
						and read(action.selected) == action.value
						and read(action.enabled) ~= false
					then
						return tostring(item.id)
					end
				end
			end
			return nil
		end
		local entries = Compose.formula(function(use: ComposeTypes.Use): { MenuEntry<V> }
			local out: { MenuEntry<V> } = {}
			for index, item in use(current) do
				local key = tostring(item.id or index)
				if item.divider ~= true then
					local heading = read(actionItem(item).sectionTitle, use)
					if heading ~= nil and heading ~= "" then
						table.insert(out, { key = "Section:" .. key, heading = heading })
					end
				end
				table.insert(out, { key = key, item = item })
			end
			return out
		end)
		local rows = Host.Frame({
			Name = "MenuRows",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = D2.new(1, 0, 0, 0),
			AutomaticSize = E.AutomaticSize.Y,
			Host.UIListLayout({
				FillDirection = E.FillDirection.Vertical,
				SortOrder = E.SortOrder.LayoutOrder,
				Padding = D.new(0, 8),
			}) :: Types.Child,
			Compose.show(function()
				return spec.query ~= nil
			end, function()
				return UI.TextInput "Search" {
					value = assert(spec.query),
					placeholder = "Search",
					LayoutOrder = -2,
				}
			end),
			Compose.show(function(use: ComposeTypes.Use)
				return #use(path) > 0
			end, function()
				return UI.Button "Back" {
					label = spec.backLabel or "Back",
					onActivate = back,
					LayoutOrder = -1,
					Size = D2.new(1, 0, 0, 44),
				}
			end),
			Compose.keyed({
				from = entries,
				key = function(entry: MenuEntry<V>)
					return entry.key
				end,
				render = function(
					entrySource: ComposeTypes.Readable<MenuEntry<V>>,
					index: ComposeTypes.Readable<number>
				)
					local entry = entrySource:peek()
					if entry.heading then
						local title = ctx.text({
							Name = "SectionTitle",
							Text = function(use: ComposeTypes.Use): string
								return use(entrySource).heading or ""
							end,
						})
						title:AddTag("facet-type-caption")
						title:AddTag("facet-secondary")
						return Host.Frame({
							Name = entry.key,
							LayoutOrder = index,
							BackgroundTransparency = 1,
							Size = D2.new(1, 0, 0, 0),
							AutomaticSize = E.AutomaticSize.Y,
							ctx.padding(12, 4) :: Types.Child,
							title :: Types.Child,
						})
					end
					local source = Compose.formula(function(use: ComposeTypes.Use): Nav.MenuItem<V>
						return assert(use(entrySource).item)
					end)
					local item = source:peek()
					if item.divider then
						return ctx.styled(
							Host.Frame "Divider" { Size = D2.new(1, 0, 0, 1), LayoutOrder = index },
							"divider"
						)
					end
					local rowKey = tostring(item.id or index:peek())
					local row = UI.Button({
						Name = rowKey,
						LayoutOrder = index,
						Size = D2.new(1, 0, 0, 44),
						label = function(use: ComposeTypes.Use)
							return read(actionItem(use(source)).label, use)
						end,
						icon = item.icon,
						role = item.role,
						trailingIcon = if item.children
							then "chevron.trailing"
							elseif item.checked ~= nil or item.selected ~= nil or item.marked ~= nil then "checkmark"
							else nil,
						subtitle = function(use: ComposeTypes.Use)
							return read(actionItem(use(source)).description, use) or ""
						end,
						enabled = function(use: ComposeTypes.Use)
							return read(actionItem(use(source)).enabled, use) ~= false
						end,
						selected = function(use: ComposeTypes.Use)
							local live = actionItem(use(source))
							return if live.checked
								then use(live.checked)
								elseif live.selected then use(live.selected) == live.value
								else read(live.marked, use) == true
						end,
						onActivate = function()
							local live = actionItem(source:peek())
							if read(live.enabled) == false then
								return
							end
							if live.children then
								local nextPath = table.clone(path:peek())
								table.insert(nextPath, assert(live.id))
								pendingFocus = nil
								path:set(nextPath)
							elseif
								commitItem(live)
								and (
									live.dismiss == true
									or (live.dismiss ~= false and not live.checked and not live.selected)
								)
							then
								close()
							end
						end,
					})
					row:AddTag("facet-menu-item")
					local accessories: { Types.Child } = {
						Host.UIListLayout({
							FillDirection = E.FillDirection.Horizontal,
							SortOrder = E.SortOrder.LayoutOrder,
							VerticalAlignment = E.VerticalAlignment.Center,
							Padding = D.new(0, 8),
						}) :: Types.Child,
					}
					if item.badge ~= nil then
						table.insert(
							accessories,
							UI.Badge({
								Name = "Count",
								LayoutOrder = 1,
								label = function(use: ComposeTypes.Use): string
									local badge = read(actionItem(use(source)).badge, use)
									return if badge == nil then "" else tostring(badge)
								end,
							}) :: Types.Child
						)
					end
					if item.shortcutLabel ~= nil then
						local shortcut = ctx.text({
							Name = "Shortcut",
							LayoutOrder = 2,
							Text = function(use: ComposeTypes.Use): string
								return read(actionItem(use(source)).shortcutLabel, use) or ""
							end,
						})
						shortcut:AddTag("facet-secondary")
						table.insert(accessories, shortcut :: Types.Child)
					end
					if #accessories > 1 then
						surfaces.attach(row, {
							Host.Frame({
								Name = "Accessories",
								BackgroundTransparency = 1,
								AnchorPoint = V2.new(1, 0.5),
								Position = D2.new(
									1,
									if item.checked or item.selected or item.marked then -32 else 0,
									0.5,
									0
								),
								Size = D2.fromOffset(0, 0),
								AutomaticSize = E.AutomaticSize.XY,
								ZIndex = 2,
								table.unpack(accessories),
							}) :: Types.Child,
						})
					end
					local avatar = item.avatar
					local rowContent = row:FindFirstChild("Content")
					if avatar and rowContent then
						runtime.mount(function()
							return UI.Avatar({
								Name = "Avatar",
								LayoutOrder = 0,
								name = avatar.name,
								image = avatar.image,
								userId = avatar.userId,
								controlSize = "compact" :: Types.ControlSize,
								Selectable = false,
							})
						end, rowContent)
					end
					local check = if item.children then nil else row:FindFirstChild("TrailingIcon", true)
					if check and check:IsA("GuiObject") then
						Compose.watch(function(use: ComposeTypes.Use)
							local live = actionItem(use(source))
							check.Visible = if live.checked
								then use(live.checked) == true
								elseif live.selected then use(live.selected) == live.value
								else read(live.marked, use) == true
						end)
					end
					if item.role == "destructive" then
						row:AddTag("facet-menu-destructive")
					end
					local content = row:FindFirstChild("Content")
					if content and content:IsA("GuiObject") then
						local layout = content:FindFirstChildWhichIsA("UIListLayout")
						if layout then
							layout.HorizontalAlignment = E.HorizontalAlignment.Left
						end
						local natural = ctx.observe(content, "AbsoluteSize")
						Compose.watch(function(use: ComposeTypes.Use)
							local next = table.clone(widths:peek())
							next[rowKey] = use(natural).X
							widths:set(next)
						end)
						Compose.cleanup(function()
							local next = table.clone(widths:peek())
							next[rowKey] = nil
							widths:set(next)
						end)
					end
					return row
				end,
			}),
			ctx.padding(8, 8) :: Types.Child,
			ctx.corner() :: Types.Child,
		})
		local rowSize = ctx.observe(rows, "AbsoluteSize")
		local function panelWidth(use: ComposeTypes.Use): number
			local authored = read(spec.width, use)
			if authored ~= nil then
				return authored
			end
			local widest = 0
			for _, width in use(widths) do
				widest = math.max(widest, width)
			end
			return math.clamp(widest + 48, 220, 400)
		end
		local panel = Host.ScrollingFrame "MenuPanel" {
			Selectable = false,
			Size = D2.fromOffset(280, 0),
			BorderSizePixel = 0,
			AutomaticCanvasSize = E.AutomaticSize.Y,
			CanvasSize = D2.fromOffset(0, 0),
			ScrollingDirection = E.ScrollingDirection.Y,
			ScrollBarThickness = 4,
			if shown
				then Host.CanvasGroup "MenuGroup" {
					BackgroundTransparency = 1,
					Size = D2.new(1, 0, 0, 0),
					AutomaticSize = E.AutomaticSize.Y,
					GroupTransparency = function(use: ComposeTypes.Use)
						return 1 - shown(use)
					end,
					rows,
				}
				else rows,
		}
		if shown then
			surfaces.attach(panel, {
				Host.UIGradient "PresentationFade" {
					Transparency = function(use: ComposeTypes.Use)
						return ctx.types.NumberSequence.new(1 - shown(use))
					end,
				},
			})
		end
		ctx.styled(panel, "menu")
		surfaces.skin(panel)
		local position = ctx.observe(anchor, "AbsolutePosition")
		local size = ctx.observe(anchor, "AbsoluteSize")
		local modal = if nonmodal
			then Host.Frame "SuggestionsOverlay" {
				BackgroundTransparency = 1,
				Size = D2.fromScale(1, 1),
				ZIndex = 100,
				panel,
			}
			else surfaces.modal(
				function()
					return panel
				end,
				back,
				{
					backgroundTransparency = 1,
					onOutside = close,
					exiting = if phase then phase.exiting else nil,
					initialFocus = landing(current:peek()),
				}
			)
		if nonmodal then
			ctx.modalPortal(modal, anchor)
			runtime.decorate(panel, { ZIndex = 101 })
		end
		local extent = ctx.observe(modal, "AbsoluteSize")
		local origin = ctx.observe(modal, "AbsolutePosition")
		local measured = ctx.observe(panel, "AbsoluteSize")
		local input = surfaces.service("UserInputService")
		local preferred = if input then ctx.observe(input, "PreferredInput") else Compose.cell(nil)
		local asSheet = Compose.formula(function(use: ComposeTypes.Use)
			local presentation = read(spec.presentation, use)
			if presentation and presentation ~= "automatic" then
				return presentation == "sheet"
			end
			return (use(extent).X > 0 and use(extent).X < math.max(600, (#use(path) + 1) * 288 + 16))
				or use(preferred) == E.PreferredInput.Touch
		end)
		local function place(use: ComposeTypes.Use): (Vector2, Vector2)
			local at, bounds, offer, panelSize, offset =
				use(position), use(size), use(extent), use(measured), use(origin)
			if use(asSheet) then
				return V2.new(12, math.max(12, offer.Y - panelSize.Y - 12)), V2.new(panelSize.X / 2, panelSize.Y)
			end
			local left, top = at.X - offset.X + #use(path) * 288, at.Y - offset.Y + bounds.Y + 4
			local above = false
			local edge, align = spec.edge or "bottom", spec.align or "start"
			if #use(path) > 0 or (edge == "bottom" and align == "start") then
				if offer.Y > 0 and top + panelSize.Y > offer.Y - 8 then
					top = at.Y - offset.Y - panelSize.Y - 4
					above = true
				end
			else
				local x, y = at.X - offset.X, at.Y - offset.Y
				local function along(start: number, length: number, extentAlong: number): number
					return if align == "center"
						then start + (length - extentAlong) / 2
						elseif align == "end" then start + length - extentAlong
						else start
				end
				if edge == "top" or edge == "bottom" then
					left = along(x, bounds.X, panelSize.X)
					local below, over = y + bounds.Y + 4, y - panelSize.Y - 4
					above = edge == "top"
					if edge == "bottom" and offer.Y > 0 and below + panelSize.Y > offer.Y - 8 and over >= 8 then
						above = true
					elseif edge == "top" and over < 8 and (offer.Y <= 0 or below + panelSize.Y <= offer.Y - 8) then
						above = false
					end
					top = if above then over else below
				else
					top = along(y, bounds.Y, panelSize.Y)
					local after, before = x + bounds.X + 4, x - panelSize.X - 4
					left = if edge == "trailing" then after else before
					if edge == "trailing" and offer.X > 0 and after + panelSize.X > offer.X - 8 and before >= 8 then
						left = before
					elseif
						edge == "leading"
						and before < 8
						and (offer.X <= 0 or after + panelSize.X <= offer.X - 8)
					then
						left = after
					end
					if offer.Y > 0 then
						top = math.clamp(top, 8, math.max(8, offer.Y - panelSize.Y - 8))
					end
				end
			end
			if offer.X > 0 then
				left = math.clamp(left, 8, math.max(8, offer.X - panelSize.X - 8))
			end
			local center = math.clamp(at.X - offset.X + bounds.X / 2 - left, 0, panelSize.X)
			return V2.new(left, math.max(8, top)), V2.new(center, if above then panelSize.Y else 0)
		end
		runtime.decorate(panel, {
			Size = function(use: ComposeTypes.Use)
				local height = math.min(use(rowSize).Y, math.max(44, use(extent).Y - 24), spec.maxHeight or math.huge)
				return if use(asSheet) then D2.new(1, -24, 0, height) else D2.fromOffset(panelWidth(use), height)
			end,
		})
		if shown then
			surfaces.popover(panel, shown, place)
		else
			runtime.decorate(panel, {
				Position = function(use: ComposeTypes.Use)
					local at = place(use)
					return D2.fromOffset(at.X, at.Y)
				end,
			})
		end
		local gui = surfaces.service("GuiService")
		local selected = if gui then ctx.observe(gui, "SelectedObject") else Compose.cell(nil)
		local function selectedBranch(use: ComposeTypes.Use?): Nav.MenuAction<V>?
			local node = read(selected, use)
			for _, item in read(current, use) do
				if
					item.divider ~= true
					and node
					and item.id == node.Name
					and item.children
					and read(item.enabled, use) ~= false
				then
					return item
				end
			end
			return nil
		end
		ctx.action(modal, "MenuRight", { E.KeyCode.Right, E.KeyCode.DPadRight }, function(use: ComposeTypes.Use)
			return selectedBranch(use) ~= nil
		end, function()
			local item = selectedBranch()
			if item then
				local nextPath = table.clone(path:peek())
				table.insert(nextPath, assert(item.id))
				path:set(nextPath)
			end
		end, { priority = 2100 })
		ctx.action(modal, "MenuLeft", { E.KeyCode.Left, E.KeyCode.DPadLeft }, function(use: ComposeTypes.Use)
			return #use(path) > 0
		end, back, { priority = 2100 })
		local focusIn = surfaces.selecting()
		Compose.watch(function(use: ComposeTypes.Use)
			local rows = use(current)
			if gui and not nonmodal and focusIn(use) then
				local target = if pendingFocus then surfaces.firstSelectable(panel, pendingFocus) else nil
				if not target then
					local chosen = landing(rows)
					target = if chosen then surfaces.firstSelectable(panel, chosen) else nil
				end
				if not target then
					for _, item in rows do
						if not item.divider and read(item.enabled, use) ~= false then
							target = surfaces.firstSelectable(panel, tostring(item.id))
							if target then
								break
							end
						end
					end
				end
				if target and modal.Parent then
					gui.SelectedObject = target
				end
			end
		end)
		local centered: string? = nil
		Compose.watch(function(use: ComposeTypes.Use)
			local level = table.concat(use(path), "/")
			if centered == level then
				return
			end
			local chosen = landing(use(current))
			if chosen == nil then
				centered = level
				return
			end
			local window, canvas = use(measured).Y, use(rowSize).Y
			local row = rows:FindFirstChild(chosen)
			if row == nil or not row:IsA("GuiObject") or window <= 0 or canvas <= 0 then
				return
			end
			local offset = row.AbsolutePosition.Y - rows.AbsolutePosition.Y
			local target = math.clamp(offset + row.AbsoluteSize.Y / 2 - window / 2, 0, math.max(0, canvas - window))
			panel.CanvasPosition = V2.new(panel.CanvasPosition.X, target)
			centered = level
		end)
		surfaces.attach(modal, {
			Compose.keyed({
				from = function(use: ComposeTypes.Use)
					if use(asSheet) then
						return {}
					end
					local levels: { { id: string, items: { Nav.MenuItem<V> }, prefix: { string }, depth: number } } = {}
					local items = use(rootItems)
					local prefix: { string } = {}
					for depth, selectedId in use(path) do
						table.insert(levels, {
							id = table.concat(prefix, "/"),
							items = items,
							prefix = table.clone(prefix),
							depth = depth,
						})
						local found: Nav.MenuAction<V>?
						for _, item in items do
							if item.divider ~= true and item.id == selectedId then
								found = item
								break
							end
						end
						if not found or not found.children then
							break
						end
						items = read(found.children, use)
						table.insert(prefix, selectedId)
					end
					return levels
				end,
				key = function(level: { id: string, items: { Nav.MenuItem<V> }, prefix: { string }, depth: number })
					return level.id
				end,
				render = function(
					source: ComposeTypes.Readable<{ id: string, items: { Nav.MenuItem<V> }, prefix: { string }, depth: number }>
				)
					return ctx.styled(
						ctx.column({
							Compose.keyed({
								from = function(use: ComposeTypes.Use)
									return use(source).items
								end,
								key = function(item: Nav.MenuItem<V>, index: number)
									return item.id or index
								end,
								render = function(
									row: ComposeTypes.Readable<Nav.MenuItem<V>>,
									index: ComposeTypes.Readable<number>
								)
									local item = row:peek()
									if item.divider then
										return ctx.styled(
											Host.Frame({ Size = D2.new(1, 0, 0, 1), LayoutOrder = index }),
											"divider"
										)
									end
									return UI.Button({
										Name = item.id,
										label = item.label,
										enabled = item.enabled,
										icon = item.icon,
										subtitle = item.description,
										LayoutOrder = index,
										Size = D2.new(1, 0, 0, 44),
										onActivate = function()
											if item.children then
												local next = table.clone(source:peek().prefix)
												table.insert(next, assert(item.id))
												path:set(next)
											elseif
												commitItem(item)
												and (
													item.dismiss == true
													or (
														item.dismiss ~= false
														and not item.checked
														and not item.selected
													)
												)
											then
												close()
											end
										end,
									})
								end,
							}),
							ctx.padding(8, 8),
							ctx.corner(),
						}, {
							Name = "AncestorMenu",
							ZIndex = 103,
							Size = D2.fromOffset(280, 0),
							AutomaticSize = E.AutomaticSize.Y,
							Position = function(use: ComposeTypes.Use)
								local at, bounds, offset = use(position), use(size), use(origin)
								return D2.fromOffset(
									math.max(8, at.X - offset.X + (use(source).depth - 1) * 288),
									math.max(8, at.Y - offset.Y + bounds.Y + 4)
								)
							end,
						}),
						"menu"
					)
				end,
			}),
		})
		return modal
	end

	UI.Menu = ctx.construct("Menu", function<V>(spec: Nav.MenuSpec<V>): Frame
		assert(spec.items ~= nil, "Menu requires items")
		menuItems(read(spec.items))
		assert(
			spec.edge == nil or table.find({ "top", "bottom", "leading", "trailing" }, spec.edge),
			"Facet UI.Menu: edge must be top, bottom, leading or trailing"
		)
		assert(
			spec.align == nil or table.find({ "start", "center", "end" }, spec.align),
			"Facet UI.Menu: align must be start, center or end"
		)
		assert(
			spec.maxHeight == nil
				or (type(spec.maxHeight) == "number" and spec.maxHeight > 0 and spec.maxHeight < math.huge),
			"Facet UI.Menu: maxHeight must be a finite number of pixels above 0"
		)
		local width = read(spec.width)
		assert(
			width == nil or (type(width) == "number" and width > 0 and width < math.huge),
			"Facet UI.Menu: width must be a finite number of pixels above 0, or a readable of one"
		)
		local opened = spec.isPresented or Compose.cell(false)
		local function close()
			if opened:peek() then
				opened:set(false)
				if spec.onClose then
					spec.onClose()
				end
			end
		end
		local function open()
			if read(spec.enabled) == false or opened:peek() then
				return
			end
			opened:set(true)
			if spec.onOpen then
				spec.onOpen()
			end
		end
		local allowed = spec.triggers or { "activate", "secondary", "longPress", "keyboard", "gamepad" }
		local trigger = if type(spec.trigger) == "function" then spec.trigger() else spec.trigger
		local automatic = spec.AutomaticSize or (if spec.Size ~= nil then E.AutomaticSize.None else E.AutomaticSize.XY)
		if trigger == nil then
			local triggerProps: Inputs.ButtonProps = {
				Name = "Trigger",
				label = spec.label or "Menu",
				enabled = spec.enabled,
				onActivate = if table.find(allowed, "activate") then open else nil,
			}
			if spec.Size ~= nil then
				triggerProps.AutomaticSize = automatic
				triggerProps.Size = function(use: ComposeTypes.Use)
					local sizing = read(automatic, use)
					local width = sizing == E.AutomaticSize.X or sizing == E.AutomaticSize.XY
					local height = sizing == E.AutomaticSize.Y or sizing == E.AutomaticSize.XY
					return D2.new(
						if width then 0 else 1,
						0,
						if height then 0 else 1,
						if height then ctx.controlSize(nil, "height", use) else 0
					)
				end
				triggerProps.TextTruncate = E.TextTruncate.AtEnd
				triggerProps.TextWrapped = false
				triggerProps.ClipsDescendants = true
				local attributes: Types.Attributes = {
					FacetLabel = function(use: ComposeTypes.Use)
						return read(triggerProps.label, use)
					end,
				}
				triggerProps.Attributes = attributes
			end
			if spec.disclosure then
				table.insert(
					triggerProps,
					ctx.icon("chevron.up.chevron.down", {
						Name = "Disclosure",
						Size = D2.fromOffset(12, 12),
						AnchorPoint = V2.new(1, 0.5),
						Position = D2.new(1, 20, 0.5, 0),
						BackgroundTransparency = 1,
					}) :: Types.Child
				)
			end
			local button = UI.Button(triggerProps)
			if spec.disclosure then
				button:AddTag("facet-disclosure")
			end
			trigger = button
		else
			if table.find(allowed, "activate") then
				runtime.connect(trigger, "Activated", open)
			end
		end
		local root = Host.Frame(ctx.props(spec, {
			"items",
			"query",
			"label",
			"disclosure",
			"trigger",
			"triggers",
			"presentation",
			"backLabel",
			"onOpen",
			"onClose",
			"enabled",
			"isPresented",
			"edge",
			"align",
			"width",
			"maxHeight",
		}, {
			Name = "Menu",
			BackgroundTransparency = 1,
			Size = D2.fromOffset(0, 0),
			AutomaticSize = automatic,
			trigger,
		}))
		local available = surfaces.available(root)
		local mounted = false
		Compose.watch(function(use: ComposeTypes.Use)
			local active = use(available)
			if active then
				mounted = true
			end
			if mounted and (not active or read(spec.enabled, use) == false) then
				close()
			end
		end)
		if table.find(allowed, "secondary") then
			runtime.connect(trigger, "InputBegan", function(input: InputObject)
				if input.UserInputType == E.UserInputType.MouseButton2 then
					open()
				end
			end)
		end
		if table.find(allowed, "longPress") then
			runtime.connect(trigger, "TouchLongPress", function(_: { Vector2 }, state: Enum.UserInputState)
				if state == E.UserInputState.Begin then
					open()
				end
			end)
		end
		local gui = surfaces.service("GuiService")
		local selected = if gui then ctx.observe(gui, "SelectedObject") else Compose.cell(nil)
		local bindings: { Types.ActionBinding } = {}
		if table.find(allowed, "keyboard") then
			table.insert(bindings, E.KeyCode.Menu)
			table.insert(bindings, { KeyCode = E.KeyCode.F10, PrimaryModifier = E.KeyCode.LeftShift })
			table.insert(bindings, { KeyCode = E.KeyCode.F10, PrimaryModifier = E.KeyCode.RightShift })
		end
		if table.find(allowed, "gamepad") then
			table.insert(bindings, E.KeyCode.ButtonY)
		end
		if #bindings > 0 then
			ctx.action(root, "Menu", bindings, function(use: ComposeTypes.Use)
				return surfaces.within(use(selected), root)
			end, open, { priority = 1200 })
		end
		surfaces.attach(root, {
			surfaces.overlay(root, opened, function(phase: Nav.PresencePhase?)
				return menuPanel(spec, close, assert(trigger), nil, phase)
			end, { motion = POPOVER }),
		})
		return root
	end)

	local pickerKeys = {
		"selected",
		"options",
		"style",
		"query",
		"placeholder",
		"label",
		"required",
		"multiple",
		"onChanging",
		"onChange",
		"enabled",
		"indicator",
		"axis",
		"sizing",
		"iconOnly",
		"textSize",
		"isPresented",
	}
	local optionFields: { [string]: boolean } = {
		id = true,
		value = true,
		label = true,
		description = true,
		icon = true,
		badge = true,
		enabled = true,
	}
	UI.Picker = ctx.construct("Picker", function<V>(spec: Nav.PickerSpec<V>): GuiObject
		writable(spec.selected, "Picker.selected")
		assert(spec.onChange == nil or type(spec.onChange) == "function", "Picker.onChange must be a function")
		assert(spec.onChanging == nil or type(spec.onChanging) == "function", "Picker.onChanging must be a function")
		assert(spec.required == nil or type(spec.required) == "boolean", "Picker.required must be a boolean")
		assert(
			spec.enabled == nil or type(read(spec.enabled)) == "boolean",
			"Picker.enabled must be a boolean or a readable boolean"
		)
		assert(
			type(spec.options) == "table" or type(spec.options) == "function",
			"Facet UI.Picker: options must be an array of { value, label } entries, a Compose readable, or a function(use) that returns one"
		)
		local function isSelected(value: V, use: ComposeTypes.Use?): boolean
			if spec.multiple then
				return read(spec.selected, use)[value] == true
			else
				return read(spec.selected, use) == value
			end
		end
		local function commitSelection<T>(
			selected: ComposeTypes.Cell<T>,
			value: T,
			onChanging: ((T, T) -> boolean?)?,
			onChange: ((T) -> ())?
		)
			local previous = selected:peek()
			if onChanging and onChanging(value, previous) == false then
				return
			end
			runtime:batch(function()
				selected:set(value)
				if onChange then
					onChange(value)
				end
			end)
		end
		local function select(value: V)
			if read(spec.enabled) == false then
				return
			end
			if spec.multiple then
				local previous = spec.selected:peek()
				local nextValue: { [V]: boolean } = {}
				for key, flag in previous do
					if key ~= value then
						nextValue[key] = flag
					end
				end
				if not previous[value] then
					nextValue[value] = true
				end
				if spec.required and next(nextValue) == nil then
					return
				end
				commitSelection(spec.selected, nextValue, spec.onChanging, spec.onChange)
			else
				if value ~= spec.selected:peek() then
					commitSelection(spec.selected, value, spec.onChanging, spec.onChange)
				end
			end
		end
		local options = Compose.formula(function(use: ComposeTypes.Use)
			local query = string.lower(tostring(read(spec.query, use) or ""))
			local result: { Nav.PickerOption<V> } = {}
			local seen: { [V | string]: boolean } = {}
			local list: { Nav.PickerOption<V> } = read(spec.options, use)
			for key in list do
				assert(
					type(key) == "number" and key >= 1 and key <= #list and key % 1 == 0,
					"Picker options require a dense array"
				)
			end
			for _, option in list do
				for field in (option :: unknown) :: { [unknown]: unknown } do
					assert(
						type(field) == "string" and optionFields[field] == true,
						`Unknown Picker option field {tostring(field)}`
					)
				end
				assert(
					option.description == nil or type(read(option.description, use)) == "string",
					"Picker description must be text"
				)
				assert(
					option.enabled == nil or type(read(option.enabled, use)) == "boolean",
					"Picker option enabled must be a boolean"
				)
				assert(
					option.icon == nil or type(read(option.icon, use)) == "string",
					"Picker option icon must be an icon name"
				)
				local badge = read(option.badge, use)
				assert(
					badge == nil or type(badge) == "string" or type(badge) == "number",
					"Picker option badge must be text or a number"
				)
				local key = option.id or option.value
				assert(key ~= nil and not seen[key], "Picker options require unique values or ids")
				seen[key] = true
				assert(
					type(read(option.label, use)) == "string" and string.find(read(option.label, use), "%S") ~= nil,
					"Picker options require nonempty labels"
				)
				assert(
					read(spec.iconOnly) ~= true or option.icon ~= nil,
					"Picker.iconOnly requires an icon on each option"
				)
				local label = tostring(read(option.label, use) or "")
				if query == "" or string.find(string.lower(label), query, 1, true) then
					table.insert(result, option)
				end
			end
			return result
		end)
		local declaredIndicator, declaredAxis, declaredSizing = read(spec.indicator), read(spec.axis), read(spec.sizing)
		assert(
			declaredIndicator == nil or table.find({ "automatic", "pill", "underline", "none" }, declaredIndicator),
			"Invalid Picker.indicator"
		)
		assert(declaredAxis == nil or table.find({ "x", "y" }, declaredAxis), "Picker.axis must be x or y")
		assert(
			declaredSizing == nil or table.find({ "fill", "hug" }, declaredSizing),
			"Picker.sizing must be fill or hug"
		)
		local style = spec.style or "automatic"
		if style == "automatic" then
			local input = surfaces.service("UserInputService")
			local preferred = if input then ctx.observe(input, "PreferredInput") else Compose.cell(nil)
			local opened = spec.isPresented or Compose.cell(false)
			local width = Compose.cell(0)

			local resolved = Compose.formula(function(use: ComposeTypes.Use): Nav.PickerStyle
				if spec.query then
					return "navigationLink"
				end
				local list: { Nav.PickerOption<V> } = read(spec.options, use)
				local count = #list
				local available = use(width)
				local described = false
				for _, option in list do
					if option.description ~= nil then
						described = true
					end
				end
				if count <= 4 and not described and (available == 0 or available >= 360) then
					return "segmented"
				end
				local kind = use(preferred)
				if kind == E.PreferredInput.KeyboardAndMouse or kind == E.PreferredInput.Touch then
					return "menu"
				end
				return if count <= 6 then "inline" else "menu"
			end)
			local props = ctx.props(spec, pickerKeys, {
				Name = "Picker",
				BackgroundTransparency = 1,
				Size = D2.new(1, 0, 0, 0),
				AutomaticSize = E.AutomaticSize.Y,
			})
			table.insert(
				props,
				Compose.keyed({
					from = function(use: ComposeTypes.Use)
						return { use(resolved) }
					end,
					render = function(current: ComposeTypes.Readable<Nav.PickerStyle>)
						local presentation: Nav.PickerStyle = current:peek()
						local automatic = props.AutomaticSize
						local size = function(use: ComposeTypes.Use)
							local sizing = read(automatic, use)
							return D2.fromScale(
								if sizing == E.AutomaticSize.X or sizing == E.AutomaticSize.XY then 0 else 1,
								if sizing == E.AutomaticSize.Y or sizing == E.AutomaticSize.XY then 0 else 1
							)
						end
						if spec.multiple then
							local child: Nav.MultiplePickerSpec<V> = {
								options = spec.options,
								query = spec.query,
								placeholder = spec.placeholder,
								label = spec.label,
								required = spec.required,
								enabled = spec.enabled,
								indicator = spec.indicator,
								axis = spec.axis,
								sizing = spec.sizing,
								iconOnly = spec.iconOnly,
								textSize = spec.textSize,
								Name = "Presentation",
								style = presentation,
								isPresented = opened,
								AutomaticSize = automatic,
								Size = size,
								multiple = true :: true,
								selected = spec.selected,
								onChanging = spec.onChanging,
								onChange = spec.onChange,
							}
							return UI.Picker(child)
						else
							local child: Nav.SinglePickerSpec<V> = {
								options = spec.options,
								query = spec.query,
								placeholder = spec.placeholder,
								label = spec.label,
								required = spec.required,
								enabled = spec.enabled,
								indicator = spec.indicator,
								axis = spec.axis,
								sizing = spec.sizing,
								iconOnly = spec.iconOnly,
								textSize = spec.textSize,
								Name = "Presentation",
								style = presentation,
								isPresented = opened,
								AutomaticSize = automatic,
								Size = size,
								multiple = false :: false,
								selected = spec.selected,
								onChanging = spec.onChanging,
								onChange = spec.onChange,
							}
							return UI.Picker(child)
						end
					end,
				})
			)
			local container = Host.Frame(props)
			local measured = ctx.observe(container, "AbsoluteSize")
			Compose.watch(function(use: ComposeTypes.Use)
				width:set(use(measured).X)
			end)
			return container
		end
		if style == "menu" then
			local native: Types.FrameNativeProps = ctx.props(spec, pickerKeys)
			local menuSpec: Nav.MenuSpec<V> = { items = {} }
			for key, value in pairs(native) do
				menuSpec[key] = value
			end
			menuSpec.enabled = spec.enabled
			menuSpec.isPresented = spec.isPresented
			menuSpec.query = spec.query
			menuSpec.label = function(use: ComposeTypes.Use)
				local labels = {}
				for _, option in read(spec.options, use) do
					if isSelected(option.value, use) then
						table.insert(labels, read(option.label, use))
					end
				end
				return if #labels > 0
					then table.concat(labels, ", ")
					else read(spec.placeholder, use) or read(spec.label, use) or "Choose"
			end
			menuSpec.disclosure = true
			menuSpec.items = function(use: ComposeTypes.Use)
				local items = {}
				for _, option in use(options) do
					table.insert(items, {
						id = option.id or tostring(option.value),
						label = option.label,
						icon = option.icon,
						description = option.description,
						badge = option.badge,
						dismiss = not spec.multiple,
						marked = function(use: ComposeTypes.Use)
							return isSelected(option.value, use)
						end,
						enabled = option.enabled,
						onSelect = function()
							select(option.value)
						end,
					})
				end
				return items
			end
			if spec.label == nil then
				return UI.Menu(menuSpec)
			end

			menuSpec.Name = "Value"
			menuSpec.Size = nil
			menuSpec.AutomaticSize = E.AutomaticSize.XY
			menuSpec.AnchorPoint = V2.new(1, 0.5)
			menuSpec.Position = D2.fromScale(1, 0.5)
			local row = ctx.props(spec, pickerKeys, {
				Name = spec.Name or "Picker",
				BackgroundTransparency = 1,
				Size = D2.new(1, 0, 0, 0),
				AutomaticSize = E.AutomaticSize.Y,
			})
			table.insert(
				row,
				ctx.text({
					Name = "Label",
					Text = function(use: ComposeTypes.Use)
						return read(spec.label, use) or ""
					end,
					Size = D2.new(1, -8, 0, 0),
					AutomaticSize = E.AutomaticSize.Y,
					TextXAlignment = E.TextXAlignment.Left,
					AnchorPoint = V2.new(0, 0.5),
					Position = D2.fromScale(0, 0.5),
				})
			)
			table.insert(row, Host.UISizeConstraint({ MinSize = V2.new(0, 44) }))
			table.insert(row, UI.Menu(menuSpec))
			return Host.Frame(row)
		end
		if style == "navigationLink" then
			local opened = spec.isPresented or Compose.cell(false)
			local native: Types.FrameNativeProps = ctx.props(spec, pickerKeys)
			local triggerProps = (native :: unknown) :: Inputs.ButtonProps
			triggerProps.Name = spec.Name or "Picker"
			triggerProps.enabled = spec.enabled
			triggerProps.label = spec.label
				or function(use: ComposeTypes.Use)
					for _, option in read(spec.options, use) do
						if isSelected(option.value, use) then
							local label: string = read(option.label, use)
							return label
						end
					end
					return read(spec.placeholder, use) or "Choose"
				end
			triggerProps.onActivate = function()
				opened:set(true)
			end
			local trigger = UI.Button(triggerProps)
			surfaces.attach(trigger, {
				surfaces.overlay(trigger, opened, function()
					local choices: Nav.PickerSpec<V>
					if spec.multiple then
						local source: Nav.MultiplePickerSpec<V> = spec
						local child = table.clone(source)
						child.Name, child.style, child.isPresented = "Choices", "inline", nil
						child.Size = D2.new(1, 0, 0, 0)
						child.onChange = function(value: { [V]: boolean })
							if source.onChange then
								source.onChange(value)
							end
						end
						choices = child
					else
						local source: Nav.SinglePickerSpec<V> = spec
						local child = table.clone(source)
						child.Name, child.style, child.isPresented = "Choices", "inline", nil
						child.Size = D2.new(1, 0, 0, 0)
						child.onChange = function(value: V)
							opened:set(false)
							if source.onChange then
								source.onChange(value)
							end
						end
						choices = child
					end
					return surfaces.modal(function()
						return surfaces.centered(
							ctx.column({
								UI.Picker(choices),
								UI.Button "Close" {
									label = "Close",
									onActivate = function()
										opened:set(false)
									end,
								},
								ctx.padding(16, 16),
								ctx.corner(),
							}, { Name = "PickerSearch" }),
							560
						)
					end, function()
						opened:set(false)
					end)
				end),
			})
			return trigger
		end
		assert(table.find({ "segmented", "inline", "radioGroup", "navigationLink" }, style), "Unknown Picker style")
		local vertical = style ~= "segmented" or read(spec.axis) == "y"
		local children: { ComposeTypes.Child } = {
			Host.UIListLayout({
				FillDirection = function(use: ComposeTypes.Use)
					return if style ~= "segmented" or read(spec.axis, use) == "y"
						then E.FillDirection.Vertical
						else E.FillDirection.Horizontal
				end,
				SortOrder = E.SortOrder.LayoutOrder,
				Padding = D.new(0, 4),
				HorizontalFlex = function(use: ComposeTypes.Use)
					return if style == "segmented"
							and read(spec.axis, use) ~= "y"
							and read(spec.sizing, use) ~= "hug"
						then E.UIFlexAlignment.Fill
						else E.UIFlexAlignment.None
				end,
			}),
		}
		if spec.query then
			table.insert(children, UI.TextInput "Search" { value = spec.query, placeholder = "Search" })
		end
		table.insert(
			children,
			Compose.keyed({
				from = options,
				key = function(option: Nav.PickerOption<V>)
					return option.id or option.value
				end,
				render = function(
					source: ComposeTypes.Readable<Nav.PickerOption<V>>,
					index: ComposeTypes.Readable<number>
				)
					local selected = function(use: ComposeTypes.Use)
						return isSelected(use(source).value, use)
					end
					local button = UI.Button({
						Name = tostring(source:peek().id or source:peek().value),
						LayoutOrder = index,
						Size = function(use: ComposeTypes.Use)
							return if style ~= "segmented" or read(spec.axis, use) == "y"
								then D2.new(1, 0, 0, 44)
								else D2.fromOffset(0, 44)
						end,
						AutomaticSize = if style ~= "segmented" then E.AutomaticSize.Y else nil,
						label = function(use: ComposeTypes.Use)
							if read(spec.iconOnly, use) then
								return ""
							end
							local option = use(source)
							local badge = read(option.badge, use)
							local label: string = read(option.label, use)
							return label
								.. (if badge ~= nil and badge ~= "" then " (" .. tostring(badge) .. ")" else "")
						end,
						subtitle = if source:peek().description ~= nil
								or Compose.isReadable(spec.options)
								or type(spec.options) == "function"
							then function(use: ComposeTypes.Use)
								return read(use(source).description, use) or ""
							end
							else nil,
						icon = source:peek().icon,
						TextSize = spec.textSize,
						selected = function(use: ComposeTypes.Use)
							return selected(use) and read(spec.indicator, use) ~= "underline"
						end,
						enabled = function(use: ComposeTypes.Use)
							return read(spec.enabled, use) ~= false and read(use(source).enabled, use) ~= false
						end,
						haptic = function(use: ComposeTypes.Use)
							return spec.multiple == true or not selected(use)
						end,
						onActivate = function()
							select(source:peek().value)
						end,
					})
					surfaces.attach(button, {
						Host.UISizeConstraint({ MinSize = V2.new(44, 44) }),
						Compose.show(function(use: ComposeTypes.Use)
							return read(spec.indicator, use) == "underline" and selected(use)
						end, function()
							return ctx.styled(
								Host.Frame "SelectionIndicator" {
									BorderSizePixel = 0,
									Size = D2.new(1, 0, 0, 2),
									Position = D2.new(0, 0, 1, -2),
									Selectable = false,
								},
								"selection-indicator"
							)
						end),
					})
					Compose.watch(function(use: ComposeTypes.Use)
						button:SetAttribute("FacetLabel", read(use(source).label, use))
					end)
					local family = if style == "segmented" then "facet-segment" else "facet-choice"
					button:AddTag(family)
					local content = button:FindFirstChild("Content")
					local layout = if content then content:FindFirstChildWhichIsA("UIListLayout") else nil
					if style ~= "segmented" and layout then
						layout.HorizontalAlignment = E.HorizontalAlignment.Left
					end
					Compose.watch(function(use: ComposeTypes.Use)
						local current = selected(use) and read(spec.indicator, use) ~= "underline"
						if current then
							button:AddTag(family .. "-current")
						elseif button:HasTag(family .. "-current") then
							button:RemoveTag(family .. "-current")
						end
					end)
					return button
				end,
			})
		)
		local defaults: Types.FrameNativeProps = {
			Name = "Picker",
			BackgroundTransparency = if style == "segmented" then nil else 1,
			Size = D2.new(1, 0, 0, 0),
			AutomaticSize = E.AutomaticSize.Y,
		}
		local p = if spec.label == nil then ctx.props(spec, pickerKeys, defaults) else defaults
		for _, child in children do
			table.insert(p, child)
		end
		local picker = Host.Frame(p)
		if style == "segmented" then
			picker:AddTag("facet-segmented")
		end
		if spec.label == nil then
			return picker
		end
		picker.Name = "Options"
		local label = ctx.text({
			Name = "Label",
			Text = function(use: ComposeTypes.Use)
				return read(spec.label, use) or ""
			end,
			Size = D2.new(if vertical then 1 else 0, 0, 0, 0),
			AutomaticSize = if vertical then E.AutomaticSize.Y else E.AutomaticSize.XY,
			TextWrapped = vertical,
			TextXAlignment = E.TextXAlignment.Left,
		})
		local outer = ctx.props(spec, pickerKeys, {
			Name = "Picker",
			BackgroundTransparency = 1,
			Size = D2.new(1, 0, 0, 0),
			AutomaticSize = E.AutomaticSize.Y,
		})
		if vertical then
			return ctx.column({ label, picker }, outer)
		end
		runtime.mount(function()
			return Host.UIFlexItem({ FlexMode = E.UIFlexMode.Grow })
		end, label)
		picker.Size = D2.new(0, 0, 0, 0)
		picker.AutomaticSize = E.AutomaticSize.XY
		local row = ctx.row({ label, picker }, outer)
		local layout = assert(row:FindFirstChildWhichIsA("UIListLayout"))
		layout.VerticalAlignment = E.VerticalAlignment.Center
		layout.Padding = D.new(0, 16)
		layout.Wraps = true
		return row
	end)

	UI.SplitButton = ctx.construct("SplitButton", function<V>(spec: Nav.SplitButtonSpec<V>): Frame
		local input = surfaces.service("UserInputService")
		local preferred = if input then ctx.observe(input, "PreferredInput") else Compose.cell(nil)
		local touch = Compose.formula(function(use: ComposeTypes.Use)
			return use(preferred) == E.PreferredInput.Touch
		end)
		local opened = Compose.cell(false)
		local enabled = function(use: ComposeTypes.Use)
			return read(spec.enabled, use) ~= false and read(spec.busy, use) ~= true
		end
		local function primary()
			return UI.Button "Primary" {
				label = spec.label,
				onActivate = spec.onActivate,
				enabled = spec.enabled,
				busy = spec.busy,
				shortcut = spec.shortcut,
			}
		end
		return Host.Frame(
			ctx.props(spec, { "label", "onActivate", "items", "enabled", "busy", "shortcut", "menuLabel" }, {
				Name = "SplitButton",
				BackgroundTransparency = 1,
				Size = D2.fromOffset(0, 0),
				AutomaticSize = E.AutomaticSize.XY,
				Compose.show(touch, function()
					local suppressEcho = false
					local trigger = UI.Button "Primary" {
						Size = if spec.Size then D2.fromScale(1, 1) else nil,
						AutomaticSize = if spec.Size then E.AutomaticSize.None else nil,
						label = spec.label,
						enabled = spec.enabled,
						busy = spec.busy,
						onActivate = function()
							if suppressEcho then
								suppressEcho = false
								return
							end
							if spec.onActivate then
								spec.onActivate()
							end
						end,
					}
					return UI.Menu "TouchAlternatives" {
						Size = if spec.Size then D2.fromScale(1, 1) else nil,
						AutomaticSize = if spec.Size then E.AutomaticSize.None else nil,
						trigger = function(): GuiObject
							return trigger
						end,
						items = spec.items,
						enabled = enabled,
						isPresented = opened,
						triggers = { "longPress", "secondary", "keyboard", "gamepad" } :: { Nav.MenuTrigger },
						onOpen = function()
							suppressEcho = true
						end,
						onClose = function()
							suppressEcho = false
						end,
					}
				end, function()
					return ctx.row({
						primary(),
						UI.Menu "Alternatives" {
							label = spec.menuLabel or "More options",
							items = spec.items,
							enabled = enabled,
							isPresented = opened,
						},
					})
				end),
			})
		)
	end)

	UI.ComboBox = ctx.construct("ComboBox", function(spec: Nav.ComboBoxSpec): Frame
		writable(spec.value, "ComboBox.value")
		writable(spec.text, "ComboBox.text")
		assert(type(spec.value:peek()) == "string", "ComboBox.value must be a string")
		assert(type(read(spec.options)) == "table", "ComboBox requires options")
		assert(type(spec.acceptCustom) == "function", "ComboBox requires acceptCustom")
		local errorText = Compose.cell("")
		local alive = true
		Compose.cleanup(function()
			alive = false
		end)
		local opened, editing = Compose.cell(false), Compose.cell(false)
		local navigating = false
		local popup: Frame?
		local gui = surfaces.service("GuiService")
		local function close()
			opened:set(false)
		end
		local function label(value: string): string
			for _, option in read(spec.options) do
				if (option.value or option.id) == value then
					return read(option.label)
				end
			end
			return value
		end
		local function update(value: string)
			close()
			errorText:set("")
			spec.text:set(label(value))
			if value ~= spec.value:peek() then
				spec.value:set(value)
				if spec.onChange then
					spec.onChange(value)
				end
			end
		end
		local function commit(text: string, reason: Inputs.CommitReason)
			if
				navigating
				or read(spec.enabled) == false
				or (reason == "focusLost" and spec.commitOnFocusLost ~= true)
			then
				return
			end
			for _, option in read(spec.options) do
				if read(option.label) == text then
					if read(option.enabled) == false then
						errorText:set("This option is unavailable.")
					else
						update(option.value or option.id)
					end
					return
				end
			end
			local ok, accepted, message = pcall(spec.acceptCustom, text)
			if not alive or read(spec.enabled) == false then
				return
			end
			if ok and accepted == true then
				update(text)
			else
				errorText:set(message or "This value is not accepted.")
			end
		end
		local function cancel()
			close()
			spec.text:set(label(spec.value:peek()))
			errorText:set("")
		end
		local editor = UI.TextInput "Editor" {
			value = spec.text,
			placeholder = spec.placeholder,
			enabled = spec.enabled,
			Size = D2.new(1, -60, 1, 0),
			AutomaticSize = E.AutomaticSize.None,
			onCommit = function(value, reason)
				commit(value, reason)
				if reason == "submit" then
					close()
				end
			end,
			onCancel = cancel,
			onChange = function(value)
				spec.text:set(value)
				opened:set(true)
			end,
			Focused = function()
				editing:set(true)
			end,
			FocusLost = function()
				editing:set(false)
			end,
		}
		local function open()
			if read(spec.enabled) ~= false then
				opened:set(true)
			end
		end
		local triggerAttributes: Types.Attributes = { FacetLabel = "Suggestions" }
		local suggestions = Host.Frame "Suggestions" {
			BackgroundTransparency = 1,
			Position = D2.new(1, -56, 0, 0),
			Size = D2.new(0, 56, 1, 0),
			UI.Button "Trigger" {
				label = "",
				icon = "chevron.down",
				enabled = spec.enabled,
				Size = D2.fromScale(1, 1),
				AutomaticSize = E.AutomaticSize.None,
				Attributes = triggerAttributes,
				onActivate = function()
					if opened:peek() then
						close()
					else
						open()
					end
				end,
			},
		}
		local row = Host.Frame "Row" {
			BackgroundTransparency = 1,
			Size = D2.new(1, 0, 0, 44),
			editor :: Instance,
			suggestions,
		}
		local root = ctx.column(
			{
				row,
				Compose.show(function(use: ComposeTypes.Use)
					return use(errorText) ~= ""
				end, function()
					return ctx.text({ Name = "Validation", Text = errorText, TextWrapped = true, LayoutOrder = 2 })
				end),
			},
			ctx.props(spec, {
				"value",
				"text",
				"options",
				"enabled",
				"acceptCustom",
				"onChange",
				"commitOnFocusLost",
				"placeholder",
			}, {
				Name = "ComboBox",
				Size = D2.new(1, 0, 0, 44),
				AutomaticSize = E.AutomaticSize.Y,
			})
		)
		local available = surfaces.available(root)
		Compose.watch(function(use: ComposeTypes.Use)
			if not use(available) or read(spec.enabled, use) == false then
				close()
			end
		end)
		local choices = function(use: ComposeTypes.Use): { Nav.MenuItem<string> }
			local result: { Nav.MenuItem<string> } = {}
			local query = string.lower(use(spec.text))
			for _, option in read(spec.options, use) do
				if string.find(string.lower(read(option.label, use)), query, 1, true) then
					table.insert(result, {
						id = option.id or tostring(option.value),
						label = option.label,
						enabled = option.enabled,
						onSelect = function()
							update(option.value or option.id)
						end,
					})
				end
			end
			return result
		end
		surfaces.attach(root, {
			surfaces.overlay(row, opened, function()
				local panel = menuPanel({ items = choices, presentation = "menu" :: "menu" }, close, row, true)
				popup = panel
				Compose.cleanup(function()
					if gui and surfaces.within(gui.SelectedObject, panel) then
						gui.SelectedObject = if ctx.available(root) then editor else nil
					end
					popup = nil
				end)
				local input = surfaces.service("UserInputService")
				if input then
					runtime.connect(input, "InputBegan", function(event: InputObject)
						if
							event.UserInputType ~= E.UserInputType.MouseButton1
							and event.UserInputType ~= E.UserInputType.Touch
						then
							return
						end
						local function hit(node: GuiObject): boolean
							local at, size, point = node.AbsolutePosition, node.AbsoluteSize, event.Position
							return point.X >= at.X
								and point.Y >= at.Y
								and point.X <= at.X + size.X
								and point.Y <= at.Y + size.Y
						end
						local menu = panel:FindFirstChild("MenuPanel")
						if not hit(row) and menu and menu:IsA("GuiObject") and not hit(menu) then
							close()
						end
					end)
				end
				return panel
			end),
			Compose.show(function(use: ComposeTypes.Use)
				return use(editing) or use(opened)
			end, function()
				ctx.action(root, "ComboSuggestions", { E.KeyCode.Down, E.KeyCode.DPadDown }, editing, function()
					open()
					local panel = popup
					local target: GuiObject?
					if panel then
						for _, item in read(choices) do
							if item.divider ~= true and read(item.enabled) ~= false then
								target = surfaces.firstSelectable(panel, item.id)
								if target then
									break
								end
							end
						end
					end
					if target and gui then
						navigating = true
						editor:ReleaseFocus(false)
						navigating = false
						gui.SelectedObject = target
					end
				end, { priority = 11000 })
				ctx.action(root, "ComboCancel", { E.KeyCode.Escape, E.KeyCode.ButtonB }, opened, function()
					cancel()
					if ctx.available(root) then
						editor:CaptureFocus()
					end
				end, { priority = 11000 })
				return Host.Folder({})
			end),
		})
		return root
	end)
end
