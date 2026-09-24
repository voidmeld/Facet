--!strict
local ComposeTypes = require("../vendor/compose/core")
local Types = require("./types")
local Engine = require("./engine_types")
local Layout = require("./layout_types")
local layoutKit = require("./layout_kit")
export type LayoutControls = Layout.LayoutControls

return function(ctx: Types.Context, controls: Layout.LayoutControls?): Layout.LayoutControls
	local Host, read, Compose = ctx.Host, ctx.read, ctx.Compose
	local kit = layoutKit.of(ctx)
	local E, D2, V2 = ctx.types.Enum, ctx.types.UDim2, ctx.types.Vector2
	local UI: Layout.LayoutControls = controls or ({} :: Layout.LayoutControls)
	local flowKeys = { "gap", "padding", "align", "distribute", "wrap", "width", "height" }
	local function split(spec: unknown, keys: { string }): ({ [unknown]: unknown }, { ComposeTypes.Child })
		local fields = spec :: { [unknown]: unknown }
		local named: { [unknown]: unknown } = {}
		local children: { ComposeTypes.Child } = {}
		for key, value in fields do
			if type(key) ~= "number" then
				named[key] = value
			end
		end
		for index = 1, #fields do
			children[index] = fields[index] :: ComposeTypes.Child
		end
		return ctx.props(named, keys), children
	end
	local function stack(spec: Layout.StackProps, vertical: boolean): Frame
		local properties, children = split(spec, flowKeys)
		return kit.stack(children, (properties :: unknown) :: Engine.FrameNativeProps, spec, vertical)
	end

	UI.VStack = ctx.construct("VStack", function(spec: Layout.StackProps): Frame
		return stack(spec, true)
	end)

	UI.HStack = ctx.construct("HStack", function(spec: Layout.StackProps): Frame
		return stack(spec, false)
	end)

	UI.Screen = ctx.construct("Screen", function(spec: Layout.ScreenProps): Frame
		local properties, children = split(spec, { "gap", "padding", "align", "distribute", "width", "height" })
		local flow: Types.Flow = {
			gap = spec.gap,
			align = spec.align,
			distribute = spec.distribute,
			padding = if spec.padding == nil then "m" else spec.padding,
			width = spec.width,
			height = spec.height,
		}
		return kit.stack(children, (properties :: unknown) :: Engine.FrameNativeProps, flow, true, "fill", "fill")
	end)

	UI.ZStack = ctx.construct("ZStack", function(spec: Layout.ZStackProps): Frame
		local properties, children = split(spec, { "padding", "width", "height", "alignH", "alignV" })
		local size, automatic = kit.extent(spec, "hug", "hug")
		local aligned = spec.alignH ~= nil or spec.alignV ~= nil
		local function fraction(value: Layout.Edge?): number
			assert(
				value == nil or value == "start" or value == "center" or value == "end",
				"Facet ZStack alignH and alignV must be start, center or end"
			)
			return if value == "center" then 0.5 elseif value == "end" then 1 else 0
		end
		local placed = (setmetatable({}, { __mode = "k" }) :: unknown) :: { [GuiObject]: boolean }
		local function align(node: GuiObject, use: ComposeTypes.Use?)
			local x, y = fraction(read(spec.alignH, use)), fraction(read(spec.alignV, use))
			node.AnchorPoint = V2.new(x, y)
			node.Position = D2.fromScale(x, y)
		end
		if aligned then
			Compose.watch(function(use: ComposeTypes.Use)
				local x, y = read(spec.alignH, use), read(spec.alignV, use)
				if x == nil and y == nil then
					return
				end
				for node in placed do
					align(node, use)
				end
			end)
		end
		local native: Engine.FrameNativeProps = {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = size,
			AutomaticSize = automatic,
		}
		return Host.Frame(kit.assemble(native, properties, { kit.insets(spec.padding) }, children, function(node, index)
			if node.ZIndex == 1 then
				node.ZIndex = index
			end
			if aligned then
				placed[node] = true
				align(node)
			end
		end))
	end)

	UI.ScrollView = ctx.construct("ScrollView", function(spec: Layout.ScrollViewProps): ScrollingFrame
		local properties, children = split(spec, { "axis", "gap", "padding", "align", "distribute", "width", "height" })
		local axis = spec.axis or "y"
		assert(axis == "x" or axis == "y" or axis == "xy", "Facet ScrollView axis must be x, y or xy")
		local size, automatic = kit.extent(spec, "fill", "fill")
		local native: Engine.ScrollingFrameNativeProps = {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = size,
			AutomaticSize = automatic,
			CanvasSize = D2.new(),
			AutomaticCanvasSize = if axis == "x"
				then E.AutomaticSize.X
				elseif axis == "y" then E.AutomaticSize.Y
				else E.AutomaticSize.XY,
			ScrollingDirection = if axis == "x"
				then E.ScrollingDirection.X
				elseif axis == "y" then E.ScrollingDirection.Y
				else E.ScrollingDirection.XY,
		}
		if axis ~= "x" then
			native.VerticalScrollBarInset = E.ScrollBarInset.ScrollBar
		end
		if axis ~= "y" then
			native.HorizontalScrollBarInset = E.ScrollBarInset.ScrollBar
		end
		local flow: Types.Flow = { gap = spec.gap, align = spec.align, distribute = spec.distribute }
		return Host.ScrollingFrame(
			kit.assemble(native, properties, { kit.list(flow, axis ~= "x"), kit.insets(spec.padding) }, children)
		)
	end)

	UI.Grid = ctx.construct("Grid", function(spec: Layout.GridProps): Frame
		local properties, children = split(
			spec,
			{ "columns", "gap", "rowGap", "cellHeight", "aspectRatio", "align", "padding", "width", "height" }
		)
		local size, automatic = kit.extent(spec, "fill", "hug")
		local function columns(use: ComposeTypes.Use?): number
			local count = read(spec.columns, use)
			assert(
				type(count) == "number" and count >= 1 and count % 1 == 0,
				"Facet Grid columns must be a whole number, 1 or more"
			)
			return count
		end
		local layout: Engine.UIGridLayoutNativeProps = {
			SortOrder = E.SortOrder.LayoutOrder,
			FillDirection = E.FillDirection.Horizontal,
			FillDirectionMaxCells = function(use: ComposeTypes.Use): number
				return columns(use)
			end,
			CellPadding = function(use: ComposeTypes.Use): UDim2
				local gap = kit.spacing(spec.gap, use)
				return D2.fromOffset(gap, if spec.rowGap == nil then gap else kit.spacing(spec.rowGap, use))
			end,
			CellSize = function(use: ComposeTypes.Use): UDim2
				local count = columns(use)
				local gap = kit.spacing(spec.gap, use)
				local height = read(spec.cellHeight, use)
				return D2.new(
					1 / count,
					-math.ceil(gap * (count - 1) / count),
					0,
					if height == nil then ctx.controlSize(ctx.config.controlSize, "height", use) else height
				)
			end,
		}
		if spec.align ~= nil then
			layout.HorizontalAlignment = function(use: ComposeTypes.Use): Enum.HorizontalAlignment
				local value = read(spec.align, use)
				assert(
					value == "start" or value == "center" or value == "end",
					"Facet Grid align must be start, center or end"
				)
				return if value == "center"
					then E.HorizontalAlignment.Center
					elseif value == "end" then E.HorizontalAlignment.Right
					else E.HorizontalAlignment.Left
			end
		end
		if spec.aspectRatio ~= nil then
			layout[1] = Host.UIAspectRatioConstraint({ AspectRatio = spec.aspectRatio })
		end
		local native: Engine.FrameNativeProps = {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = size,
			AutomaticSize = automatic,
		}
		return Host.Frame(
			kit.assemble(native, properties, { Host.UIGridLayout(layout), kit.insets(spec.padding) }, children)
		)
	end)

	UI.fill = function(weight: number?): UIFlexItem
		if weight == nil then
			return Host.UIFlexItem({ FlexMode = E.UIFlexMode.Fill })
		end
		assert(type(weight) == "number" and weight > 0, "Facet fill weight must be a positive number")
		return Host.UIFlexItem({ FlexMode = E.UIFlexMode.Custom, GrowRatio = weight, ShrinkRatio = weight })
	end

	return UI
end
