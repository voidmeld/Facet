--!strict

local example = { title = "Temperature Converter" }
local function acceptNumeric(proposed: string): string?
	return if string.match(proposed, "^%-?%d*%.?%d*$") then proposed else nil
end
local function toCelsius(text: string): number?
	local n = tonumber(text)
	return if n then (n - 32) * 5 / 9 else nil
end
function example.build(ctx: any)
	local UI, Compose, Host = ctx.UI, ctx.Compose, ctx.Host
	local UDim, UDim2, Vector2, Color3, Enum =
		ctx.types.UDim, ctx.types.UDim2, ctx.types.Vector2, ctx.types.Color3, ctx.types.Enum
	local fahrenheit = Compose.cell("")
	local celsius = Compose.cell(nil :: number?)

	local liveCelsius = Compose.formula(function(use)
		return toCelsius(use(fahrenheit))
	end)
	local function clear()
		ctx.runtime:batch(function()
			fahrenheit:set("")
			celsius:set(nil)
		end)
	end
	local built: any = { clearPath = "/TempConverter/Page/Clear", dispose = function() end, clear = clear }
	function built.fahrenheitText()
		return fahrenheit:peek()
	end
	function built.liveCelsius()
		return liveCelsius:peek()
	end
	function built.celsius()
		return celsius:peek()
	end
	function built.screen()
		return Host.Frame "TempConverter" {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Host.UIPadding({
				PaddingTop = UDim.new(0, 16),
				PaddingBottom = UDim.new(0, 16),
				PaddingLeft = UDim.new(0, 16),
				PaddingRight = UDim.new(0, 16),
			}),
			Host.ScrollingFrame "Page" {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.new(),
				ScrollBarThickness = 6,
				Host.UIListLayout({
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 8),
				}),
				UI.Label({
					LayoutOrder = 1,
					Name = "Title",
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					text = "Fahrenheit → Celsius",
					textRole = "title",
					TextWrapped = true,
					TextYAlignment = Enum.TextYAlignment.Top,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),
				UI.Label({
					LayoutOrder = 2,
					Name = "Prompt",
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					text = "Enter a temperature in °F:",
					TextWrapped = true,
					TextYAlignment = Enum.TextYAlignment.Top,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),
				UI.TextInput({
					LayoutOrder = 3,
					Name = "Fahrenheit",
					value = fahrenheit,
					placeholder = "e.g. 212",
					validate = acceptNumeric,
					onCommit = function(text)
						celsius:set(toCelsius(text))
					end,
				}),
				UI.Label({
					LayoutOrder = 4,
					Name = "Preview",
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					text = function(use)
						local c = use(liveCelsius)
						return if c == nil
							then "Preview: —"
							else string.format("Preview: %g °C  (live, as you type)", c)
					end,
					TextWrapped = true,
					TextYAlignment = Enum.TextYAlignment.Top,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),
				UI.Label({
					LayoutOrder = 5,
					Name = "Result",
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					textRole = "heading",
					text = function(use)
						local c = use(celsius)
						return if c == nil then "Result: —" else string.format("Result: %g °C", c)
					end,
					TextWrapped = true,
					TextYAlignment = Enum.TextYAlignment.Top,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),
				UI.Button({ LayoutOrder = 6, Name = "Clear", label = "Clear", onActivate = clear }),
			},
		}
	end
	return built
end
return example
