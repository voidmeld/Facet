# Getting started

1. Put the Facet package in ReplicatedStorage.
2. Set `Workspace.PlayerScriptsUseInputActionSystem` to true in the place.
3. Make a LocalScript in StarterPlayerScripts with this content.

```luau
local Facet = require(game.ReplicatedStorage:WaitForChild("Facet"))
local Compose = Facet.Compose
local runtime = Facet.Roblox.createRuntime()
local Host = runtime.constructors
local UI = Facet.controls(runtime)
local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")

local stop = runtime.mount(function()
    local count = Compose.cell(0)
    local sheet = Facet.themes.createStyleSheet(runtime)
    return Host.ScreenGui {
        Name = "Counter", ResetOnSpawn = false,
        sheet,
        Host.StyleLink { StyleSheet = Compose.static(sheet) },
        Host.Frame {
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(320, 120),
            Host.UIListLayout { Padding = UDim.new(0, 8) },
            UI.Label {
                label = function(use) return `Clicked {use(count)} times` end,
            },
            UI.Button {
                label = "Add one",
                onActivate = function() count:update(function(n) return n + 1 end) end,
            },
        },
    }
end, playerGui)

script.Destroying:Connect(function()
    stop()
    runtime:dispose()
end)
```

## What the script does

- `Facet.Roblox.createRuntime()` makes a Compose Roblox runtime.
- `runtime.constructors` is the table of native constructors. The script names
  it `Host`.
- `Facet.controls(runtime)` returns the control constructors for that runtime.
- `runtime.mount` runs the component and mounts its result into PlayerGui. It
  returns a stop function.
- `Facet.themes.createStyleSheet(runtime)` makes a StyleSheet. The sheet is a
  child of the ScreenGui. The StyleLink references it. See
  [Styling](05-styling.md).

## Cleanup

Use Compose cleanup for external subscriptions that a component makes. The stop
function from `runtime.mount` releases its component. `runtime:dispose()`
releases the work that the runtime owns. Call the stop function before you
dispose the runtime.

You can make persistent model cells outside the mounted component. See
[Components](15-components.md) for state and ownership.
