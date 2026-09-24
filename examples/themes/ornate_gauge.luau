--!strict

local ornate_gauge = {}

ornate_gauge.namespace = "gauge"
ornate_gauge.control = "OrnateGauge"

ornate_gauge.ART = table.freeze({
	face = "rbxassetid://117569461983627",
	needle = "rbxassetid://88340591181438",
	endcap = "rbxassetid://80585948903459",
})

ornate_gauge.CAP_PX = 28
ornate_gauge.NEEDLE_PX = 24

ornate_gauge.needs = table.freeze({
	table.freeze({
		name = "gauge:dial",
		kind = "controlSize",
		section = "metrics.controlSizes",
		fields = table.freeze({ "height", "paddingX", "iconSize" }),
		authority = "layout",
		capability = "none",
		fallback = table.freeze({ height = 44, paddingX = 12, iconSize = 18 }),
	}),
	table.freeze({
		name = "gauge:needle",
		kind = "color",
		section = "style.themes[].extra",
		authority = "paint",
		capability = "none",

		fallback = table.freeze({ r = 0.75, g = 0.58, b = 0.23 }),
	}),
	table.freeze({
		name = "gauge:ring",
		kind = "number",
		section = "metrics.radii",
		authority = "paint",
		capability = "none",
		fallback = 6,
	}),
})

local function needByName(name: string): any
	for _, need in ornate_gauge.needs do
		if need.name == name then
			return need
		end
	end
	return nil
end

function ornate_gauge.check(themes: any, package: any): any
	return themes.checkCoverage(package, ornate_gauge.needs)
end

function ornate_gauge.resolve(snapshot: any, package: any?, themeName: string?): any
	local sizeNeed = needByName("gauge:dial")
	local colorNeed = needByName("gauge:needle")
	local ringNeed = needByName("gauge:ring")

	local size = (snapshot.controlSizes or {})["gauge:dial"]
	local usedSize = type(size) ~= "table" or type(size.height) ~= "number"

	local ring = (snapshot.radii or {})["gauge:ring"]
	local usedRing = type(ring) ~= "number"

	local needle: any = nil
	if package ~= nil then
		local wanted = themeName or package.style.defaultTheme
		for _, theme in package.style.themes do
			if theme.name == wanted then
				needle = (theme.extra or {})["gauge:needle"]
			end
		end
	end
	local usedNeedle = type(needle) ~= "table" or type(needle.r) ~= "number"

	return {
		height = if usedSize then sizeNeed.fallback.height else size.height,
		paddingX = if usedSize then sizeNeed.fallback.paddingX else size.paddingX,
		iconSize = if usedSize then sizeNeed.fallback.iconSize else size.iconSize,
		ring = if usedRing then ringNeed.fallback else ring,
		needle = if usedNeedle then colorNeed.fallback else needle,
		usedFallback = { size = usedSize, needle = usedNeedle, ring = usedRing },
	}
end

function ornate_gauge.blueprint(Facet: any, runtime: any, resolved: any, opts: any?): any
	local Compose = Facet.Compose
	local Host = runtime.constructors
	local o: any = opts or {}
	local types: any = o.types or { UDim = UDim, UDim2 = UDim2, Vector2 = Vector2, Color3 = Color3, Enum = Enum }
	local UI = Facet.controls(runtime, { types = o.types })
	local name: string = o.id or "Gauge"
	local capPx = ornate_gauge.CAP_PX
	local needlePx = ornate_gauge.NEEDLE_PX
	local fraction = o.fraction

	local position = Compose.formula(function(use: any)
		local value = if fraction ~= nil then use(fraction) else 0
		return math.clamp(if type(value) == "number" then value else 0, 0, 1)
	end)

	local dialHeight = Compose.formula(function(use: any)
		local px = if o.heightPx ~= nil then use(o.heightPx) else resolved.height
		return types.UDim2.new(1, 0, 0, px)
	end)

	local tint = resolved.needle

	return Host.Frame(name)({
		Size = types.UDim2.fromScale(1, 0),
		AutomaticSize = types.Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Host.UIListLayout({
			SortOrder = types.Enum.SortOrder.LayoutOrder,
			Padding = types.UDim.new(0, 4),
		}),
		UI.Label(name .. "Label")({
			text = o.label or "Boiler pressure (gauge:dial)",
			textRole = "caption",
			LayoutOrder = 1,
		}),
		Host.ImageLabel(name .. "Dial")({
			LayoutOrder = 2,
			Size = dialHeight,
			BackgroundTransparency = 1,
			Image = ornate_gauge.ART.face,
			Host.UICorner({ CornerRadius = types.UDim.new(0, resolved.ring) }),
			Host.Frame(name .. "Track")({
				Size = types.UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Host.UIPadding({
					PaddingLeft = types.UDim.new(0, capPx),
					PaddingRight = types.UDim.new(0, capPx),
				}),
				Host.ImageLabel(name .. "NeedleGlow")({
					AnchorPoint = Compose.formula(function(use: any)
						return types.Vector2.new(use(position), 0.5)
					end),
					Position = Compose.formula(function(use: any)
						return types.UDim2.fromScale(use(position), 0.5)
					end),
					Size = types.UDim2.new(0, needlePx + 18, 1, 18),
					BackgroundTransparency = 1,
					Image = ornate_gauge.ART.needle,
					ImageColor3 = types.Color3.new(tint.r, tint.g, tint.b),
					ImageTransparency = 0.35,
					ZIndex = 1,
				}),
				Host.ImageLabel(name .. "Needle")({
					AnchorPoint = Compose.formula(function(use: any)
						return types.Vector2.new(use(position), 0)
					end),
					Position = Compose.formula(function(use: any)
						return types.UDim2.fromScale(use(position), 0)
					end),
					Size = types.UDim2.new(0, needlePx, 1, 0),
					BackgroundTransparency = 1,
					Image = ornate_gauge.ART.needle,
					ZIndex = 2,
				}),
			}),
			Host.ImageLabel(name .. "CapStart")({
				Size = types.UDim2.new(0, capPx, 1, 0),
				BackgroundTransparency = 1,
				Image = ornate_gauge.ART.endcap,
				ZIndex = 3,
			}),
			Host.ImageLabel(name .. "CapEnd")({
				AnchorPoint = types.Vector2.new(1, 0),
				Position = types.UDim2.fromScale(1, 0),
				Size = types.UDim2.new(0, capPx, 1, 0),
				BackgroundTransparency = 1,
				Image = ornate_gauge.ART.endcap,
				ZIndex = 3,
			}),
		}),
	})
end

return ornate_gauge
