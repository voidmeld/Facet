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

function ornate_gauge.blueprint(ctx: any, resolved: any, opts: any?): any
	local Host, UI, Compose = ctx.Host, ctx.UI, ctx.Compose
	local D, D2, V2, C3, E = ctx.types.UDim, ctx.types.UDim2, ctx.types.Vector2, ctx.types.Color3, ctx.types.Enum
	local o: any = opts or {}
	local name: string = o.id or "Gauge"
	local capPx = ornate_gauge.CAP_PX
	local fraction = o.fraction
	local FLOOR = 1e-4

	local function share(use: any, leading: boolean): number
		local value = if fraction ~= nil then use(fraction) else 0
		local f = math.clamp(if type(value) == "number" then value else 0, 0, 1)
		return math.max(if leading then f else 1 - f, FLOOR)
	end

	local function spacer(suffix: string, order: number, leading: boolean): any
		return Host.Frame(name .. suffix)({
			LayoutOrder = order,
			BackgroundTransparency = 1,
			Size = D2.fromScale(0, 1),
			Host.UIFlexItem({
				FlexMode = E.UIFlexMode.Custom,
				GrowRatio = Compose.formula(function(use: any)
					return share(use, leading)
				end),
			}),
		})
	end

	local function cap(suffix: string, trailing: boolean): any
		return Host.ImageLabel(name .. suffix)({
			Image = ornate_gauge.ART.endcap,
			BackgroundTransparency = 1,
			AnchorPoint = V2.new(if trailing then 1 else 0, 0),
			Position = D2.fromScale(if trailing then 1 else 0, 0),
			Size = D2.new(0, capPx, 1, 0),
		})
	end

	local needle = resolved.needle
	return Host.Frame(name)({
		BackgroundTransparency = 1,
		Size = D2.new(1, 0, 0, 0),
		AutomaticSize = E.AutomaticSize.Y,
		Host.UIListLayout({ SortOrder = E.SortOrder.LayoutOrder, Padding = D.new(0, 4) }),
		UI.Label(name .. "Label")({
			LayoutOrder = 1,
			text = o.label or "Boiler pressure (gauge:dial)",
			textRole = "caption",
		}),
		Host.Frame(name .. "Dial")({
			LayoutOrder = 2,
			BackgroundTransparency = 1,
			Size = if o.heightPx ~= nil
				then function(use: any)
					return D2.new(1, 0, 0, use(o.heightPx))
				end
				else D2.new(1, 0, 0, resolved.height),
			Host.UICorner({ CornerRadius = D.new(0, resolved.ring) }),
			Host.ImageLabel(name .. "Face")({
				Image = ornate_gauge.ART.face,
				BackgroundTransparency = 1,
				Size = D2.fromScale(1, 1),
			}),
			Host.Frame(name .. "Track")({
				BackgroundTransparency = 1,
				Size = D2.fromScale(1, 1),
				Host.UIPadding({ PaddingLeft = D.new(0, capPx), PaddingRight = D.new(0, capPx) }),
				Host.UIListLayout({ FillDirection = E.FillDirection.Horizontal, SortOrder = E.SortOrder.LayoutOrder }),
				spacer("Lead", 1, true),
				Host.ImageLabel(name .. "Needle")({
					LayoutOrder = 2,
					Image = ornate_gauge.ART.needle,
					BackgroundTransparency = 1,
					Size = D2.new(0, ornate_gauge.NEEDLE_PX, 1, 0),
					Host.UIShadow({
						Color = C3.new(needle.r, needle.g, needle.b),
						Transparency = 0.35,
						BlurRadius = D.new(0, 18),
					}),
				}),
				spacer("Trail", 3, false),
			}),
			cap("CapStart", false),
			cap("CapEnd", true),
		}),
	})
end

return ornate_gauge
