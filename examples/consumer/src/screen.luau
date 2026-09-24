--!strict
local screen = {}
function screen.build(Facet: any, runtime: any, options: any?)
	local Compose = Facet.Compose
	local types = options and options.types or { UDim = UDim, UDim2 = UDim2, Enum = Enum }
	local Host = runtime.constructors
	local UI = Facet.controls(runtime, options)
	local count = Compose.cell(0)
	local sound = Compose.cell(true)
	local visible = Compose.cell(true)
	return Host.Frame "Consumer" {
		Size = types.UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Host.UIPadding({
			PaddingTop = types.UDim.new(0, 16),
			PaddingLeft = types.UDim.new(0, 16),
			PaddingRight = types.UDim.new(0, 16),
		}),
		Compose.show(visible, function()
			return Host.Frame "Panel" {
				Size = types.UDim2.fromScale(1, 0),
				AutomaticSize = types.Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Host.UIListLayout({ SortOrder = types.Enum.SortOrder.LayoutOrder, Padding = types.UDim.new(0, 12) }),
				UI.Label "Title" { text = "Facet consumer", textRole = "title" },
				UI.Label "Blurb" {
					text = "One component, local state, one theme. Press Bump and watch the count follow.",
					textRole = "caption",
					Size = types.UDim2.fromScale(1, 0),
					TextWrapped = true,
				},
				UI.Label "Count" {
					text = function(use)
						return if use(count) == 1 then "1 tap" else `{use(count)} taps`
					end,
					textRole = "heading",
				},
				UI.Toggle "Sound" { label = "Sound", value = sound },
				UI.Button "Bump" {
					label = "Bump",
					appearance = "emphasis",
					onActivate = function()
						count:update(function(value)
							return value + 1
						end)
					end,
				},
				UI.Button "Close" {
					label = "Close",
					onActivate = function()
						visible:set(false)
					end,
				},
			}
		end),
	}
end
return screen
