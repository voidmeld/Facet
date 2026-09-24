# Adaptive native composition

Make decisions from the available space and the published engine facts. Native
layouts own the resulting geometry. Facet controls own their internal adaptive
choices. Observe the native bounds when a screen must choose between two
different arrangements.

## A wrapping action band

```luau
return Host.Frame {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    Host.UIListLayout {
        FillDirection = Enum.FillDirection.Horizontal,
        Wraps = true,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    },
    UI.Button { LayoutOrder = 1, label = "Save", onActivate = save },
    UI.Button { LayoutOrder = 2, label = "Preview", onActivate = preview },
}
```

Wrapping changes the geometry. It does not change what an action means. When
the order is important, set `LayoutOrder` explicitly.

## Read native bounds

```luau
local frame = Host.Frame { Size = UDim2.fromScale(1, 1) }
local bounds = Compose.cell(frame.AbsoluteSize)
local connection = frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    bounds:set(frame.AbsoluteSize)
end)
Compose.cleanup(function() connection:Disconnect() end)
local stop = runtime.mount(function()
    return UI.VirtualGrid {
        from = rows,
        key = function(row) return row.id end,
        columns = function(use) return math.max(1, math.floor(use(bounds).X / 240)) end,
        itemSize = 180,
        render = renderCard,
        Size = UDim2.fromScale(1, 1),
    }
end, frame)
Compose.cleanup(stop)
return frame
```

The initial native bounds can be zero. Use safe minimum values. Let later engine
observations update the policy. Do not run a second settle loop to force
synchronous measurements.

## Text and safe areas

- Use `TextWrapped`, `AutomaticSize`, native constraints and the applicable
  flex behavior.
- Let the engine calculate the text bounds. Do not estimate glyph widths in a
  screen.
- Use the ScreenGui inset and safe-area properties to configure the target.
- Use the adaptable presentation of TabView. Do not make a new sidebar switch
  in each screen.

Keep the structural ownership stable when only a size changes. Use a property
binding for dimensions. Use `Compose.show` or `Compose.keyed` only when the
composition itself changes.
