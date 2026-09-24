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
                text = function(use) return `Clicked {use(count)} times` end,
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

## Test a screen without Studio

You can mount a screen headlessly with Lune. This path needs a clone of this
repository and the pinned toolchain. Run `rokit install` from the repository
root.

The repository has a fake native engine in
[`tests/lib/native_engine.luau`](../../tests/lib/native_engine.luau). It makes
objects that act like Roblox Instances: properties, children, `FindFirstChild`
and events that a test can fire. It is not part of the Roblox package.

Save this script as `tests/counter.luau` and run
`lune run tests/counter.luau` from the repository root.

```luau
local Facet = require("../src")
local engineLib = require("./lib/native_engine")
local Compose = Facet.Compose

local engine = engineLib.new()
local runtime = Facet.Roblox.createRuntime(engine)
local Host = runtime.constructors
local UI = Facet.controls(runtime, { types = engine.types })

local function Counter()
    local count = Compose.cell(0)
    return Host.Frame "Counter" {
        UI.Label "Count" {
            text = function(use) return `Count: {use(count)}` end,
        },
        UI.Button "Add" {
            label = "Add one",
            onActivate = function()
                count:update(function(n) return n + 1 end)
            end,
        },
    }
end

local screen = engine.new("ScreenGui")
local stop, root = runtime.mount(Counter, screen)
root:FindFirstChild("Add").Activated.fire()
assert(root:FindFirstChild("Count").Text == "Count: 1")
stop()
assert(screen:FindFirstChild("Counter") == nil)
runtime:dispose()
```

- `engineLib.new()` makes the fake engine. Give it to
  `Facet.Roblox.createRuntime`.
- `Facet.controls` needs `types = engine.types`, because Lune does not have
  the Roblox datatypes as globals.
- `runtime.mount` returns the stop function and the mounted root.
- `Activated.fire()` sends the event that a click or a gamepad press sends.

The [standalone consumer test](../../tests/native_gallery.spec.luau) mounts the
screen module of `examples/consumer` in the same way.

A headless test proves state, events, structure and cleanup. It does not prove
native layout, `StyleSheet` paint, text measurement, device input or engine
performance. Those need a Studio check.

Inside this repository, put a spec under `tests/` and run it with
`lune run tests/run_one <name>`.

## Cleanup

Use Compose cleanup for external subscriptions that a component makes. The stop
function from `runtime.mount` releases its component. `runtime:dispose()`
releases the work that the runtime owns. Call the stop function before you
dispose the runtime.

You can make persistent model cells outside the mounted component. See
[Components](15-components.md) for state and ownership.
