# Native primitives

Facet does not keep a parallel catalog of primitives. If Compose Roblox can
make the class, use it directly through `Host = runtime.constructors`.

```luau
return Host.Frame {
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    Host.UIListLayout {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 8),
    },
    UI.Label { label = "Inventory" },
    UI.Button { label = "Open", onActivate = openInventory },
}
```

A new Roblox class usually needs an example and applicable tests. It does not
need a Facet constructor, an adapter mapping, a layout rule or a renderer
branch. Confirm its native property and event contracts in the engine
documentation. Exercise it in Studio.

If Compose cannot express a necessary host operation, show the missing
capability in a focused upstream test. Change Compose upstream and synchronize
its generated snapshot. Do not patch the vendored files. Do not make a local
parallel runtime.

If the missing item is reusable interaction policy, not a primitive, follow
[new control](new-control.md).
