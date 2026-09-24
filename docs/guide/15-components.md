# Components

A component is a function returning a native Instance. Create controls through
`Facet.controls(runtime)` and native objects through `Host = runtime.constructors`.
Construct them inside a Compose owner, normally the function passed to
`runtime.mount`. Use constructor names or `Name`, numeric children and native
property names.

## State and requests

A component runs when its owner is created. Reactive property bodies run again
when the values they read change; the whole component does not need to rebuild.
Keep local state in `Compose.cell`, shared calculations in `Compose.formula`,
external effects in `Compose.watch` and teardown in `Compose.cleanup`.

This component assumes the `Compose`, `Host` and `UI` setup from
[Getting started](03-getting-started.md):

```luau
local function Settings()
    local enabled = Compose.cell(true)
    local status = Compose.formula(function(use)
        return if use(enabled) then "Notifications are on" else "Notifications are off"
    end)
    return Host.Frame {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Host.UIListLayout { Padding = UDim.new(0, 8) },
        UI.Toggle {
            label = "Notifications",
            value = enabled,
            onChange = function(nextValue) enabled:set(nextValue) end,
        },
        UI.Label { label = status },
    }
end
```

Read state through `use` in reactive bodies. `:peek()` reads the current value
without subscribing and is useful in event callbacks. `:set` replaces a value;
`:update` calculates its replacement from the previous value. For input value
controls, omit the change callback to let the control write a writable cell.
When a callback is supplied, update the model there to accept the request.
Navigation controls have their own write-then-notify contracts in the
[API reference](../reference/api.md#menus-and-navigation).

## Branches and keyed children

Use Compose structural operations directly as native children. `Compose.show`
creates its branch while the condition is true and disposes it when false.
State created inside the branch therefore resets on the next appearance. Keep
state outside that owner when it must survive hiding or navigation.

```luau
local detailsOpen = Compose.cell(false)
return Host.Frame {
    Size = UDim2.fromScale(1, 1),
    Host.UIListLayout { Padding = UDim.new(0, 8) },
    UI.Toggle { label = "Show details", value = detailsOpen },
    Compose.show(detailsOpen, function()
        return UI.Label { label = "Changes are saved to this session." }
    end),
}
```

For a bounded collection that should stay mounted, use `Compose.keyed` with
`from`, a key function, and `render(current, index, key)`. Read the current item
inside property bindings; an existing key can receive a replacement item.
For large scrolling collections, use Facet's
[VirtualList or VirtualGrid](../reference/api.md#virtuallist-and-virtualgrid).
Keep durable row edits and selections in the model, outside windowed row owners.
Compose OrderedCollection and Pool supply the collection mechanisms used by
those controls; screens do not need to implement their own windowing.

## Ownership and native references

A control's `ref` callback receives its native root Instance. A borrowed Instance
property such as `StyleLink.StyleSheet` uses `Compose.static(instance)`; ownership
comes from constructing and parenting the node, not from the reference.

Use `runtime.connect` for owner-bound native events or register an external
connection's disconnect function with `Compose.cleanup`. The stop function
returned by `runtime.mount` releases that mount. Stop mounts before calling
`runtime:dispose`. Keep durable model cells outside the screen component when
they must outlive it.

Use `Compose.portal` for another parent and `Compose.LayerStack` for retained
content. Facet navigation and presented controls already manage their own
content owners. Use `runtime.spring`, `runtime.tween` and `runtime.timeline` for
motion and honor reduced motion. Bind animated values to native properties;
Roblox StyleRule transitions own theme paint animation.

See the [native API contract](../reference/api.md),
[adaptive composition](15-adaptive-recipes.md) and
[practical recipes](17-recipes.md).
