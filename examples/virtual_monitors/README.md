# Virtual monitors

Three applications share one Compose Roblox runtime and one durable model. Facet
provides controls; Roblox provides the Instances, layouts, scrolling, input and
styling. `Host` is the runtime's native constructor table.

- **Discover:** a paged, windowed catalog of `UI.Card` items with live
  procedural previews. A card body opens the details. The primary action saves
  the game, and the More menu has Share, Not interested and Report. A save or a
  hide shows a `UI.Snackbar` with Undo. The details show a launch
  `UI.StepIndicator` (Find server, Load world, Join), a `UI.DateTimePicker` for
  a play session, star ratings, a trend line, and similar games in pages of six
  with `UI.Pagination`. A search with no results shows a `UI.Notice` with Clear
  filters. The Saved shelf button shows the saved count with `UI.badged`. The
  saved table has sortable columns, selection, drag ordering, a session column
  and notes that commit on Return or focus loss and restore on Escape.
- **Avatar:** an animated R15 explorer with a procedural fallback, palette and
  hat choices, rotation, shared turn increments, auto-spin, reset confirmation
  and a summary sheet with retained detents. `UI.NumberInput` accepts an exact
  angle or a sum, such as `90+45`, with `Facet.recipes.arithmetic.parse`. The
  preview and the settings share a row when space permits and wrap otherwise.
- **Chat:** editable prompts, persistent messages, streaming local replies,
  Stop, message removal with Undo, Clear, suggested prompts in a `UI.Grid` and
  optional end following. `UI.Vote` records the feedback for a reply. An affixed
  `UI.Notice` states that the responses are simulated. The draft field uses the
  field chrome, with Send as its trailing control. The Chat tab counts unread
  replies.

Each app uses `UI.Screen`, `UI.NavBar`, stacks, `UI.ScrollView` and `UI.fill`
for its layout. The header has the app title, the presentation, appearance and
About actions, and the profile avatar. The avatar opens a `UI.Popover` that
sets the presence (Online, Away or Busy) of every avatar. About is a
`UI.Dialog` that shows `Facet.VERSION` and `Facet.COMPOSE_COMMIT`. A
`UI.ErrorBoundary` contains each app: a failure shows "App stopped" with Try
again, and the header and the other apps stay. In spatial
mode, Focus fits a monitor to the camera, and All monitors returns to the
overview. In screen mode, native Facet tabs select the app. Model state
survives page and monitor disposal. Compact viewports and ten-foot interfaces
start in screen mode. An explicit choice takes precedence.

The entry script binds Facet to its Compose copy with
`Facet.bind(Facet.Compose, Facet.Roblox)`. It mounts ordinary `Host.SurfaceGui`
and `Host.ScreenGui` instances with `runtime.mount`. Each surface has a native
StyleSheet and StyleLink. `theme.luau` starts from the neutral type roles,
makes each app package with `Facet.themes.define`, checks the colors and
metrics that the screens need with `themes.checkCoverage`, and checks the icon
artwork with `themes.resolveIcon`. The package declares a raised
`monitorPanel` chrome, which the Avatar preview draws with `themes.skin`.

Collections use Facet's native `VirtualGrid`, `VirtualList` and `Table`
controls, which use Compose `OrderedCollection` placements. Compose keeps the
visible anchor during sorting. Avatar animation and scene clocks obey reduced
motion. Haptics play only for controls that change a value or a state.

`model.luau`, `catalog.luau` and `chat_model.luau` contain application data and
commands. They contain no UI objects or independent timers. `screens.luau`
builds Discover and the shared shell. `avatar.luau` and `chat.luau` build the
other two apps. `desktop.luau` supplies the tabs, and `scenes.luau` supplies the
procedural and R15 scene content.

Build from the repository root:

```sh
rojo build examples/virtual_monitors/default.project.json -o artifacts/virtual-monitors/virtual-monitors.rbxl
open -a RobloxStudio artifacts/virtual-monitors/virtual-monitors.rbxl
```

Press Play in Studio. The showcase needs no character and stays local and
unpublished. The monitors are flat two-dimensional interfaces placed in the
world; they provide no VR ray, gaze or hand-input implementation.

`workspace.VirtualMonitorsAPI` drives a running place for Studio evidence:
`Invoke("mode", "Screen" | "Spatial")`, `Invoke("dark", boolean)`,
`Invoke("focus", app)`, `Invoke("tab", app)`, `Invoke("open", gameId)` (opens
the details and starts a launch), `Invoke("close")` and `Invoke("chat", text)`.

Automated behavior coverage lives in `tests/native_virtual_monitors.spec.luau`.
`tests/native_virtual_monitors_coverage.spec.luau` mounts the three apps and the
screen mode, tours them, and fails with the names of each public Facet field,
control and theme function that the showcase does not use.
Studio evidence must exercise both presentations, Discover filtering, sorting,
card actions and details, saved notes, Avatar settings, streaming Chat,
appearance changes and teardown. A successful build or headless test is not a
substitute for that check.
