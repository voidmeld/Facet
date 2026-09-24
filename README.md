# Facet

Facet is a library of Roblox UI controls. It uses Compose and the Roblox engine.

- Compose creates and owns the native Instances, bindings, collections and motion.
- Roblox does layout, text editing, scrolling, selection and styling.
- Facet adds control behavior and adaptive presentation.

UI and embedded 3D content use one composition path. Create a Compose Roblox
runtime, get the Facet controls for that runtime, and mount into a native
target. Each control root is an Instance. You can use native property names and
Compose structural operations directly.

## A working screen

1. Set `Workspace.PlayerScriptsUseInputActionSystem` to true in the place.
2. Put Facet in ReplicatedStorage.
3. Put this LocalScript in StarterPlayerScripts.

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

[Getting started](docs/guide/03-getting-started.md) explains this script.

## Working in this repository

- Run `tools/verify.sh full` for the verification of the current architecture.
  Read the [verification scope](docs/guide/18-verification-scope.md) for what
  that run does not cover.
- Run `tools/bench.sh` for benchmarks.
- Run `tools/package.sh build` and then `tools/package.sh status` to examine
  the distributable locally.

Start with the [guide](docs/guide/README.md), the
[API reference](docs/reference/api.md) and the
[contribution workflow](CONTRIBUTING.md). The gallery and the virtual monitors
are maintained examples. [Installing without Rojo](docs/guide/08-without-rojo.md)
explains how to install the built model. [package/README.md](package/README.md)
has the package build and publication policy.
