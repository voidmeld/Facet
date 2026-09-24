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
local app = Facet.app({ name = "Counter" })
local UI = app.UI

app.mount(function()
    local count = Compose.cell(0)
    return UI.Screen {
        gap = "s",
        UI.Label {
            text = function(use) return `Clicked {use(count)} times` end,
        },
        UI.Button {
            label = "Add one",
            onActivate = function() count:update(function(n) return n + 1 end) end,
        },
    }
end)

script.Destroying:Connect(app.dispose)
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
