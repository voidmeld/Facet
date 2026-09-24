# Components

A component is a function that returns a native Instance.

- Make controls with `Facet.controls(runtime)`.
- Make native objects with `Host = runtime.constructors`.
- Make both inside a Compose owner. This is usually the function that you give
  to `runtime.mount`.
- Put a semantic name directly after the constructor: `Host.Frame "Toolbar" { ... }` or `UI.Button "Save" { ... }`. Do not write `Name = "..."` for a fixed name. Use `Name` only when the name is computed.
- Use numeric children and native property names.

## State and requests

A component runs when its owner is created. A reactive property body runs again
when a value that it reads changes. The whole component does not need to run
again.

| Purpose | Compose API |
|---|---|
| Local state | `Compose.cell` |
| Shared calculations | `Compose.formula` |
| External effects | `Compose.watch` |
| Teardown | `Compose.cleanup` |

This component uses the `Compose`, `Host` and `UI` setup from
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

- Read state through `use` in reactive bodies.
- `:peek()` reads the current value and does not subscribe. Use it in event
  callbacks.
- `:set` replaces a value.
- `:update` calculates the replacement from the previous value.

For an input value control, you can omit the change callback. The control then
writes a writable cell. If you supply a callback, update the model in it to
accept the request. Navigation controls have their own write-then-notify
contracts. See the [API reference](../reference/api.md#menus-and-navigation).

## Branches and keyed children

Use the Compose structural operations directly as native children.
`Compose.show` makes its branch while the condition is true. It disposes the
branch when the condition is false. State that the branch makes therefore
resets when the branch appears again. If state must survive hiding or
navigation, keep it outside that owner.

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

For a bounded collection that stays mounted, use `Compose.keyed` with `from`, a
key function and `render(current, index, key)`. Read the current item inside
property bindings. An existing key can receive a replacement item.

For large scrolling collections, use the Facet
[VirtualList or VirtualGrid](../reference/api.md#virtuallist-and-virtualgrid).
Keep durable row edits and selections in the model, outside the windowed row
owners. Compose `OrderedCollection` and `Pool` supply the collection mechanisms
for those controls. Screens do not need their own windowing.

## Ownership and native references

The `ref` callback of a control receives its native root Instance. A borrowed
Instance property, such as `StyleLink.StyleSheet`, uses
`Compose.static(instance)`. Ownership comes from making and parenting the node,
not from the reference.

- Use `runtime.connect` for native events that are bound to an owner.
- For an external connection, register its disconnect function with
  `Compose.cleanup`.
- The stop function from `runtime.mount` releases that mount. Stop the mounts
  before you call `runtime:dispose`.
- If durable model cells must outlive the screen component, keep them outside
  it.

## Portals, retained content and motion

Use `Compose.portal` for content under a different parent. Use
`Compose.LayerStack` for retained content. Facet navigation and presented
controls already manage their own content owners.

Use `runtime.spring`, `runtime.tween` and `runtime.timeline` for motion. Obey
the reduced-motion setting. Bind animated values to native properties. Roblox
StyleRule transitions own the theme paint animation.

See the [native API contract](../reference/api.md),
[adaptive composition](15-adaptive-recipes.md) and
[practical recipes](17-recipes.md).
