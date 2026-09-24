# Facet API

Facet supplies controls that use the Compose Roblox runtime. Compose makes and
owns the native tree. Roblox supplies layout, text editing, scrolling, selection
and styling. This reference describes the `0.12.0` surface.

## Public entry points

| Export | Contract |
|---|---|
| `VERSION` | The package version string. |
| `Compose` | The pinned Compose core module, by reference. Use its cells, formulas, owners and structural operations directly. |
| `Roblox` | The pinned Compose Roblox module, by reference. `createRuntime(engine?)` makes the native runtime. `createHost(engine?)` makes its host. |
| `controls(runtime, options?)` | Returns the control constructor table for that native runtime. |
| `themes` | Theme package definitions, native StyleSheet compilation, icons and skins. |
| `COMPOSE_COMMIT` | The full Compose commit of the pinned copy. The Facet tests use this commit. |
| `bind(Compose, Roblox)` | Returns a Facet table whose `controls` and `themes` use the Compose core module and the Compose Roblox module that you give. See [Your own Compose](#your-own-compose). |

### Types

The exported Luau types include `Facet`, `ComposeModule`, `ComposeRobloxModule`,
`Controls`, `ControlOptions`, `ThemePackage`,
and the `Props` and `Spec` contracts of each control. The layout types include
`Space`, `Padding` and `Extent`. `Cell<T>`, `Readable<T>`,
`Runtime`, `Owner` and `Use` are the Compose types. Collection, menu and picker
contracts keep the item and value types through callbacks. Native properties use
the Roblox property types. For example, `Size` accepts a `UDim2` or a reactive
source of a `UDim2`.

The pinned Luau solver sometimes needs explicit types for these values:

- reactive `use` parameters,
- content factories that return `Instance` or `GuiObject`,
- native anchors.

Literal options can need singleton annotations, such as
`presentation = "number" :: "number"`. These annotations keep the contract
without `any`.

Native Instance properties also accept `Compose.static(instance)`. The pinned
Compose release types the payload of this marker as `unknown`. Thus Luau cannot
check the class of the wrapped Instance. Ordinary property values and reactive
sources keep their native types.

Run `python3 tools/check_types.py` to check the Facet runtime source and the
positive and compile-fail public API witnesses. The checker uses pinned Roblox
definitions. It reports vendor diagnostics separately. It does not accept a
`--!strict` directive alone as proof of a typed API.

### Mounting

There is no Facet application, mounting service, render target, solver,
reactor or scene object. The caller owns the native targets. The caller calls
these runtime functions directly:

- `runtime.mount`,
- `runtime.mountFragment`,
- `runtime.decorate`,
- `runtime:dispose`.

`decorate` applies only properties and events. To mount native children, use
`mount` or `mountFragment`. The stop function that a mount returns ends that
mount. Stop the mounts before you dispose the runtime.

```luau
local Facet = require(game.ReplicatedStorage.Facet)
local Compose = Facet.Compose
local runtime = Facet.Roblox.createRuntime()
local Host = runtime.constructors
local UI = Facet.controls(runtime)
local stop = runtime.mount(function()
    local sheet = Facet.themes.createStyleSheet(runtime)
    return Host.ScreenGui {
        Name = "Example",
        sheet,
        Host.StyleLink { StyleSheet = Compose.static(sheet) },
        UI.Button { label = "Continue", onActivate = function() print("Continue") end },
    }
end, game.Players.LocalPlayer.PlayerGui)
```

### Your own Compose

A game that already uses Compose must use one Compose instance for its state
and for Facet. Two instances make two reactive graphs. A value from one graph
does not reliably update a reader in the other graph.

`Facet.bind(Compose, Roblox)` returns a table with the same fields as `Facet`.
Its `Compose` and `Roblox` fields are the modules that you give. Its `controls`
and `themes` use only those modules. The default `Facet` table is
`bind` applied to the pinned copy.

```luau
local Compose = require(game.ReplicatedStorage.Packages.Compose.core)
local ComposeRoblox = require(game.ReplicatedStorage.Packages.Compose.roblox)
local Facet = require(game.ReplicatedStorage.Packages.Facet).bind(Compose, ComposeRoblox)
local runtime = ComposeRoblox.createRuntime()
local UI = Facet.controls(runtime)
```

Give both modules from the same Compose copy. Make the runtime with that
`Roblox` module.

`bind` rules:

- The Facet tests use the Compose commit in `COMPOSE_COMMIT`. Facet supports a
  later Compose commit when it keeps the functions that Facet uses and their
  behavior.
- `bind` stops with an error when the Compose module does not have a function
  that Facet uses. The error names the function and the tested commit. `bind`
  cannot find a change in behavior. Run your tests when you change Compose.
- A control stops with an error that names the control when no owner of its
  Compose instance is active. This occurs when you build a control outside
  `runtime.mount`, or when the runtime comes from a different Compose instance.
- A control stops with an error that names the control and the option when an
  option is a cell or formula from a different Compose instance. `read` of a
  value from a different Compose instance also stops with an error.

## Constructor contract

`UI.Button(spec)` and `UI.Button("Name")(spec)` are equivalent construction
forms. The second form sets the name. Every constructor returns a native
Instance. `ref = function(instance) ... end` receives that root. Make controls
inside a Compose owner. This is usually the component that you give to
`runtime.mount`.

### Options and native properties

Control-specific options use lower camel case. Native properties keep their
Roblox names: `Size`, `Position`, `AutomaticSize`, `LayoutOrder`, `Visible`,
`TextSize` and the others. The control forwards native events, Compose property
and event keys, `Attributes` and numeric children to the host. To add native
tags, use `node:AddTag(name)`. An unsupported control option causes an error.
It does not become inert metadata. The error names the control and, when an
option is close, suggests it:
`Facet UI.Button: unknown option 'lable'. Did you mean 'label'?`. A spec that is
not a table gives `Facet UI.Button: expected a property table, got number`.

### State

Readables and `function(use)` bodies bind reactive properties. The caller owns
the state. An input value control writes a writable cell when the related
callback is absent. If you supply `onChange` or `onToggle`, the callback is a
request. Update the model in the callback to accept it. Navigation controls
document their own write-then-notify behavior below.

### Factory options

`controls` accepts these options:

- `theme`: a theme package or a readable of one. The controls use it for
  metrics, artwork and icon resolution.
- `reducedMotion` and `icons`: these can also be reactive. Control motion also
  follows `GuiService.ReducedMotionEnabled`. Motion is reduced when either one
  is true.
- `pressHaptic`: a native `HapticEffect`. Only a control that changes a state
  or a value plays it. See [Haptics](#haptics).
- `controlSize`: the control-size step (`compact`, `regular` or `large`) for
  theme icons.
- `onError`: receives a failure from the content of a presented Alert. The
  alert dismisses.
- `services`, `guiService`, `userInputService` and `types`: native dependencies.
- `inputParent` and `overlayParent`: placement targets.

### Motion

The controls animate navigation and presentation by default. All motion uses
the Compose runtime. Motion does not block input or focus. An exiting element
cannot be interacted with, and the selection never stays on it.

| Control | Enter | Exit |
|---|---|---|
| NavigationStack push | The new page slides in from the trailing edge. The old page moves 30 percent to the leading edge and dims. Critically damped spring with a 0.3 second period, visually complete in approximately 0.35 seconds. | Pop is the reverse. |
| TabView page change | Crossfade, 0.2 seconds, Quad Out. | The same. |
| Sheet | Slides up from the bottom, 0.3 seconds, Cubic Out. The scrim fades in. | Slides down, 0.2 seconds. |
| Alert | Scales from 0.94 to 1 and fades in, 0.2 seconds, Cubic Out. The scrim fades in. | The reverse, 0.15 seconds. |
| Callout, Button `help`, Menu, Picker menu | Scales from 0.9 to 1 from the edge nearest to the anchor, and fades in, 0.15 seconds, Cubic Out. | The reverse, 0.1 seconds. |

- Reduced motion (`reducedMotion` or `GuiService.ReducedMotionEnabled`) removes
  all of this motion. The change is immediate.
- A presentation that has not drawn a frame, or whose anchor is no longer
  available, leaves immediately.
- If you present a control again during its exit, the exit reverses.
- PageView keeps its native page swipe.

### Haptics

`pressHaptic` plays only for a control that changes a state or a value:

- Toggle and a Chip with `selected`.
- A Picker option that is not selected. A multiple Picker option always plays.
- A Stepper step.
- A Slider with a `step`. The effect plays once for each detent, not for each
  frame.
- Rating and LevelPicker.
- An Alert action with the `destructive` role or the `defaultAction` shortcut.

A plain Button, a tab, a menu row, a keyboard key and a link do not play it.
Set `haptic = true` on a Button to play `pressHaptic` for a game-specific
action. `haptic` can be a readable. An explicit `PressHapticEffect` always
wins.

The `theme` option does not install paint. Parent a `createStyleSheet` result
and its StyleLink in the native tree, with the same theme package source.
Ordinary Roblox consumers use the ambient services and datatypes. The runtime
that you supply must use the Compose Roblox host.

## Layout

The layout constructors make ordinary native containers. A container is a
`Frame` or a `ScrollingFrame` with a `UIListLayout` or a `UIGridLayout`, and a
`UIPadding` when you set `padding`. Roblox does the layout. Facet adds no
solver and no measurement pass. Each constructor accepts the native properties
of its root, and a native property that you set replaces the default value.

Write the children as dense numeric children. The container sets the
`LayoutOrder` of each child to its position in the list. Nodes that a
`Compose.show` or `Compose.keyed` child adds get the position of that child.
Nodes in one keyed child share that position. Set `LayoutOrder` in the row
when their order is important.

```luau
local sound = Compose.cell(true)
local function save() print("Saved") end
return UI.Screen "Settings" {
    gap = "s",
    UI.Label { text = "Settings", textRole = "title" },
    UI.ScrollView "Page" {
        gap = "s",
        UI.Toggle { label = "Sound", value = sound },
        UI.Button { label = "Save", onActivate = save },
    },
}
```

### Layout options

| Option | Values | Native result |
|---|---|---|
| `gap` | a spacing step or a number of pixels | `UIListLayout.Padding` |
| `padding` | a spacing step, a number, or `{ top?, right?, bottom?, left? }` | a `UIPadding` child |
| `width`, `height` | `"fill"`, `"hug"` or a number of pixels | `Size` and `AutomaticSize` |
| `align` | `start`, `center`, `end` or `stretch` | cross-axis alignment and `ItemLineAlignment` |
| `distribute` | `start`, `center`, `end`, `spaceBetween`, `spaceAround` or `spaceEvenly` | main-axis alignment and `HorizontalFlex` or `VerticalFlex` |

- The spacing steps are `xs`, `s`, `m`, `l` and `xl`. They come from
  `metrics.space` of the theme package in the `theme` factory option. The
  neutral values are 4, 8, 16, 24 and 40 pixels. A package without a step uses
  the neutral value.
- When the theme package changes, the containers write the new pixel values.
  The native layout objects stay the same.
- An unknown step, alignment or size causes an error that names the valid
  values.
- `"fill"` sets the scale of that axis to 1. `"hug"` sets `AutomaticSize` on
  that axis. A number sets the pixel offset.
- `align = "stretch"` sets `ItemLineAlignment.Stretch`, so each child fills the
  cross axis.
- A container writes an alignment property only when you set `align` or
  `distribute`.
- All options accept a value, a readable or a `function(use)` body.

### Screen

`UI.Screen(spec) -> Frame` is the root of a screen. It fills its parent
(`width` and `height` are `"fill"`) and stacks its children vertically. It has
`padding = "m"` by default. The ScreenGui `ScreenInsets` property keeps the
screen inside the device safe area. Options: `gap`, `padding`, `align`,
`distribute`, `width` and `height`.

### VStack and HStack

`UI.VStack(spec) -> Frame` stacks its children vertically. `UI.HStack(spec) ->
Frame` stacks them horizontally. Both hug their content by default. Options:
`gap`, `padding`, `align`, `distribute`, `wrap`, `width` and `height`. `wrap`
sets `UIListLayout.Wraps`. The shared props type is `StackProps`.

### ZStack

`UI.ZStack(spec) -> Frame` puts its children on top of each other. It has no
layout object. A later child gets a higher `ZIndex`. A child that sets its own
`ZIndex` keeps it. `alignH` and `alignV` (`start`, `center` or `end`) set the
`AnchorPoint` and the scale `Position` of each child. Options: `padding`,
`alignH`, `alignV`, `width` and `height`.

### ScrollView

`UI.ScrollView(spec) -> ScrollingFrame` scrolls its children. It fills its
parent by default. It contains a `UIListLayout` and sets `AutomaticCanvasSize`
and `ScrollingDirection` for its axis. Thus the content fits the scroll window
beside the scroll bar. `axis` is `"y"` (the default), `"x"` or `"xy"`. The
`"x"` axis stacks the children horizontally. Options: `axis`, `gap`, `padding`,
`align`, `distribute`, `width` and `height`.

### Grid

`UI.Grid(spec) -> Frame` puts its children in a `UIGridLayout`. `columns` is
required. It must be a whole number, 1 or more. The grid divides its width into
that number of cells. `gap` spaces the cells on both axes, and `rowGap`
replaces the vertical space. `cellHeight` is the cell height in pixels. The
default is the regular control height of the theme package. `aspectRatio` adds
a `UIAspectRatioConstraint` to the grid layout, which sets the cell height
from the cell width. `align` (`start`, `center` or `end`) aligns the cells
horizontally. The grid fills the width and hugs the height by default.

### fill

`UI.fill(weight?) -> UIFlexItem` makes a child grow along the main axis of its
stack. Put the result in the children of the control:
`UI.Label { text = "Name", UI.fill() }`. Without a weight, the item uses
`UIFlexMode.Fill`. With a weight, it uses `UIFlexMode.Custom` with that
`GrowRatio` and `ShrinkRatio`. The weight must be a positive number. For the
cross axis, use `align = "stretch"` on the stack or `width = "fill"` on a
container.

## Actions and input

### Button

`label`, `onActivate`, `enabled`, `disabled` and `busy` define the action. A
disabled or busy button cannot activate. The optional `repeatDelay` and
`repeatInterval` have the defaults `0.4` and `0.1` seconds. `shortcut` supplies
a key code and optional modifiers. `dialogAction` is `default` or `cancel`.

Presentation options:

- `appearance`, `role`, `selected`, `name`, `hint` and `pop`.
- `controlSize`: `compact`, `regular` or `large`.
- `corners`: `pill` or `square`, or a readable of one.
- `shape`: `rect` or `circle`. A circle with an authored `Size` on one axis
  only keeps that axis and matches the other axis to it.
- `icon` and `trailingIcon`.
- `image`, `imageAspectRatio` (default `16/9`) and `imageFraming` (`fit` or
  `crop`).
- `subtitle` and `row = { title, description, value, icon }`. A row button
  fills its width. It shows `icon` on the leading edge, the title and the
  description, and `value` as secondary text on the trailing edge. When the
  button has `onActivate` and no `trailingIcon`, it also shows a disclosure
  chevron. `value` and `icon` are static strings. `hint` shows as a second
  line of text below the label.
- `haptic`: a boolean or a readable. When it is true, the button plays the
  `pressHaptic` of the controls. The default is false. See [Haptics](#haptics).
- `help`: one sentence that describes the action. It shows in a small panel
  when a pointer rests on the button for 0.45 seconds, or when a gamepad
  selects the button. It does not show on touch, so do not put information in
  `help` that is available nowhere else.
- `compactLabel`: an alternative string or readable. The button uses it when a
  plain text button cannot fit its full label. It does not apply to icon, image
  or subtitle buttons.

The pointer callbacks are `onPointerDown`, `onPointerUp` and `onPointerCancel`.
Each callback works alone. `onPointerCancel` runs when a held pointer leaves
the button.

### Toggle

`value` is a boolean source. `onChange(next)` requests a new value. Without it,
the control updates the writable cell. `presentation` is `switch`, `checkbox` or
`button`. The checkbox presentation supports `mixed`. A read-only `value` or
`mixed` source requires `onChange`. `indicatorPosition` is
`leading` or `trailing`. The label, row, hint, enabled and common button styling
options apply.

### TextInput

`value` is the string model. Roblox TextBox owns editing, IME, the caret, the
text selection and focus. `onChange(text)` handles user edits. An external
model update does not send it. `onCommit(text, reason)` receives `submit` or
`focusLost`. `onCancel` observes cancellation and the restoration of the initial
value of the edit.

`presentation` is `plain`, `search` or `number`. The number presentation also
uses a writable `numericValue`, `min`, `max`, `parse` and `format`. If a
callback disables the input during a commit, the commit stops. `numericValue`
does not change and `onCommit` does not run.
`validate(proposed)` returns the accepted text, or `nil` to reject it.
`maxLength` counts UTF-8 characters.

The other options are `placeholder`, `multiline`, `invalid`, `enabled`,
`disabled`, `clearButton` and `clearButtonMode` (`never`, `always`,
`whileEditing` or `unlessEditing`). Native TextBox properties stay available.

### Stepper and Slider

Both take a numeric `value`, `min` (default `0`), `max` (default `1`), `step`,
`format`, `onChange`, `enabled` and `label`. The maximum must be more than the
minimum. A specified step must be positive. The Stepper step default is `1`.
The Slider default is continuous values.

By default, Slider shows an inline track and a value readout, with an optional
label. Its default native `AutomaticSize.Y` keeps the authored width and fits
the control height. `row` gives a stacked title, description and track.

Slider also supports `onCommit(value)`, `tapToPosition` (default true),
`thumbImage`, `trackImage` and `row`. Dragging uses native drag detection.
Keyboard and gamepad adjustment use the input actions of the control.

### Rating and LevelPicker

Both take a numeric `value`, a positive integer `count` (default `5`),
`allowZero` (default true), `readOnly`, `enabled` and `onChange`. The
`value` and `semanticValue` attributes stay in the range from the minimum to
`count`, also when the model holds a value outside it.

- Rating supports `glyphs = { filled, empty }` and `starSize`.
- LevelPicker supports `segment` (`bar`, `glyph` or `image`), `segmentSize`,
  `glyphs`, `images` and `tint` filled and empty Color3 pairs. A bar segment has
  the `facet-level-segment` tag, and a filled bar also has `facet-level-on`.

The named sizes are `small` (20), `medium` (28) and `large` (36).

### Vote

Vote is up, down or none over your value. It requires `value` (`up`, `down`
or `none`, or a readable of one) and `onChange(next)`, unless `readOnly` is
true. `summary` is your own text, such as "99% liked". The optional
`controlSize`, `enabled` and `controls` apply. The control sets
`controls.diagnostics()`.

- The caller owns `value`. A press calls `onChange(next)` once. The strip
  changes only when your value changes. Thus a refused vote never paints, and
  a change from up to down is one change.
- A press on the chosen side proposes `none`.
- The two sides are icon Buttons (`vote.up`, `vote.down`) with the names
  "Upvote" and "Downvote", in the `facet-segmented` strip that Picker uses.
  The chosen side has `facet-segment-current`. Each side is at least the
  target size (`targetSizes.minimum`).
- The summary is one line. Its whole text is in the `FacetLabel` attribute.
  Vote counts nothing.
- `readOnly = true` shows the same icons with your choice marked, with no
  Button and no selection stop. It is not disabled paint. A later
  `readOnly = false` without `onChange` keeps the vote read-only, with a
  warning and a diagnostic line.
- `enabled = false` gives the ordinary disabled Buttons. A late value that is
  not legal keeps the last legal value.

Pointer and touch press a side. Native gamepad selection moves between the
sides. The Activate action (Return or Space) and ButtonA propose the selected
side. The root has the attributes `FacetValue` and `FacetReadOnly`. For a
score out of five, use Rating. For a number that the player adjusts, use
Stepper.

### Chip and ShortcutHint

Chip takes `label` and either a boolean `selected` or `onRemove`.
`onToggle(next)` is controlled. The removal options are `removeLabel`,
`removeFocusFallback`, and native `leading` and `trailing` children.

ShortcutHint takes `keys = { { "Ctrl", "K" } }` or an `action` InputAction. It
also takes an optional `separator` and `controlSize`. The default separator is
` / `.

## Menus and navigation

### Menu and SplitButton

Menu takes an `items` array or readable. It also takes an optional `label`,
`icon`, writable `isPresented` and `enabled`.

Items have a stable `id` and a `label`. They have optional `icon`, `enabled`,
`hidden`, `children` and `onSelect`. Checked and selected items bind their
writable state. Native input actions supply opening and Back behavior. Nested
menus keep the control-specific navigation of the menu.

- `triggers` limits the routes that open the menu. The routes are `activate`,
  `secondary`, `longPress`, `keyboard` and `gamepad`. The default is all five.
- `presentation` is `automatic`, `menu` or `sheet`. `backLabel` sets the text
  of the Back row.
- When the player navigates by selection, an open menu selects its first
  enabled item. Back and Left close one level and return the selection to the
  item that opened it.
- The menu panel scales and fades from the edge nearest to its trigger. See
  [Motion](#motion).
- `edge` (`top`, `bottom`, `leading` or `trailing`) and `align` (`start`,
  `center` or `end`) place the root panel against its trigger. The default is
  `bottom` and `start`. When the panel does not fit on its edge and fits on
  the opposite edge, it flips. Submenus keep their position beside their
  parent level. A malformed value causes an error that names the option.
- `width` is the width of the floating panel in pixels, or a readable of one.
  `maxHeight` bounds the whole floating panel in pixels. The panel is always
  bounded by the screen, and its rows scroll inside it. The row ids and the
  activation do not change.
- A level whose `selected` group holds one of its rows opens with the
  selection on that row, and scrolls that row to the center of the list. A
  `checked` item does not move the landing.
- Every row is at least the target size (44) tall, and the label leads the row.
  A row can also have `badge` (a string, a number or a readable, shown as a
  Badge named `Count`), `avatar` (`{ name, image?, userId? }`, a compact
  Avatar that takes no selection), `sectionTitle` (a caption heading before the
  row, never a selection stop) and `shortcutLabel` (display text such as
  "Ctrl+B"). `shortcutLabel` binds no key. Bind the key where the action is.
  Picker passes the option `badge` to its menu rows.

SplitButton combines a primary `label` and `onActivate` action with the
secondary `items` of the menu. Use it when the secondary operations supplement
one clear primary action.

### Picker

Picker requires a writable `selected` and `options`. Each option has `value` and
`label`, and an optional `id`, `icon` and `enabled`. Options can be a plain
array or a readable.

The styles are `automatic`, `segmented`, `inline`, `radioGroup`,
`navigationLink` and `menu`. The `automatic` style follows the options, the
measured width and the native PreferredInput:

- If you supply `query`, it uses the navigation-link presentation.
- It uses `segmented` for four options or fewer when no option has a
  description and the picker is at least 360 pixels wide.
- Otherwise, for keyboard and mouse, and for touch, it uses a menu.
- For other input, it uses `inline` for six options or fewer, and a menu for
  larger sets.

A `label` shows on the leading edge of a horizontal segmented row, with the
control at its natural width on the trailing edge. The label shows above a vertical
segmented, inline or radio group control. A menu shows the label on the leading
edge of the row and the value on the trailing edge.

`onChanging(next, previous)` can return `false` to veto a change. The control
writes `selected`, and then calls `onChange(next)`. An optional writable `query`
filters the labels. The other options include `label`, `placeholder`, `axis`,
`sizing`, `iconOnly`, `textSize`, `isPresented` and `enabled`.

### ComboBox

ComboBox requires a writable string `value`, a writable string `text`, options
and an `acceptCustom` validator. The control combines editable search, option
selection and explicit acceptance of custom values. Keep the accepted value and
the text in progress in separate model cells.

### TabView

TabView requires a writable `selection` that names a declared tab. It also
requires `tabs` with unique `{ id, label, content }` entries. Tabs can be a
plain array or a readable. `content` is a factory that returns native content.

By default, Compose `LayerStack` keeps the visited content
(`retention = "all"`). Use `retention = "top"` to dispose departing pages after
their transition. Keep durable page state in the model.

Use `style = "sidebarAdaptable"` for peer destinations. The control shows a
sidebar on a sufficiently wide native viewport. It shows a bottom bar on other
viewports. `placement` sets an explicit choice. `railWidth`,
`sidebarPreference`, `sections`, accessories and
`customization = { order, hidden }` refine the presentation. Required tabs
cannot be hidden.

`onChange(id)` reports a user selection. A programmatic selection change does
not look like user input. The control owns scroll and focus restoration and
shoulder navigation.

A tab can have `indicator`, a StatusIndicator spec `{ form?, status?, count?,
max? }`. It shows in that tab's own button. The whole-control `indicator` is a
different setting. A tab with `enabled = false` stays in the strip, but no
route selects it: a press, shoulder navigation and the collapsed menu skip or
refuse it. A malformed tab indicator causes an error that names `indicator`.

`textSize` defaults to `fit`. In a bottom bar each tab gets an equal share of
the width, and its words shrink from the `control` type size toward the
`caption` size to fit that share before the engine truncates them. The control
measures the words at the control size. A number or a readable number sets a
fixed size.

A TabView that is built inside the page of another TabView is nested, also
when a branch of that page builds it later. A nested TabView uses a top band.

A page change uses a native crossfade. The default is
`transition = { seconds = 0.2, ease = Compose.easing.outQuad }`. Supply other
direct Compose tween options to change it. Use `false` to disable motion. Named
Facet transition presets do not exist. The first page shows without motion.

### NavigationStack

NavigationStack requires a writable `path`, `root` and `destinations`. The path
is an array of `{ id, value }` entries. `root` and each `destinations[id]` are
`{ title, content }`. Destination content receives the entry.

- To push, append an entry.
- To pop, remove the last entry.

`backLabel` sets the text of the native Back chrome. Compose `LayerStack` owns
the retained pages and their disposal.

A push slides the new page in from the trailing edge. The covered page moves
30 percent to the leading edge and dims. A pop plays the reverse. The popped
page stays until its motion completes. It cannot be interacted with, and it
cannot hold the selection. The default motion is a critically damped Compose
spring. `transition = { seconds, ease }` replaces the slide with a crossfade
that uses those Compose tween options.
`transition = false` disables motion. The pages that are present when the
stack mounts show without motion.

### PageView

PageView requires a writable `selection` and `pages` with unique ids and
content factories. It supplies page navigation, indicators, and previous and
next actions. Use it for a sequential set of peer pages. TabView is for named
destinations. NavigationStack is for a drill-down path.

### Pagination

Pagination selects one page of numbered results. It does not fetch data.
It requires `page` (a number or a readable) and `onChange(nextPage)`.

- `pageCount` is a whole number of 0 or more, or a readable of one. `nil`
  means that the count is unknown.
- `hasNext` and `hasPrevious` (default false) set the arrows for an unknown
  count. A known `pageCount` ignores them.
- `siblingCount` and `boundaryCount` are whole numbers from 0 to 20. The
  default of each is 1.
- `showFirstLast` (default false) adds First and Last arrows. Last shows only
  for a known count.
- `form` is `numbers` (default), `arrows` or `label`. `direction` is `ltr`
  (default) or `rtl`. `controlSize` and `enabled` are optional.
- `controls` is an optional table. The control sets `controls.diagnostics()`,
  which returns the refusal lines.

The caller owns `page`. A press proposes one page through `onChange`. The row
changes only when your value changes. Thus a refused proposal changes nothing.
A page outside the range shows clamped, with a warning and a diagnostic line.
The control never writes it back. A late value that is not legal keeps the
last legal value. A malformed value at construction causes an error.

The numbers form shows the boundary pages, the current page and
`siblingCount` pages on each side. An ellipsis replaces a gap of two or more
pages. The work is bounded by the two counts, not by `pageCount`. The control
measures the width of its root (`AbsoluteSize.X`). When the row does not fit,
the farthest boundary page goes first, then the farthest neighbour (the higher
page on a tie). When only the current page and the arrows do not fit, the row
shows "Page n of m". An unknown count always shows "Page n". Zero pages shows
"No pages" with no stops. One page has no enabled arrow.

Each page is a compact Button in a slot that is at least the target size
(`targetSizes.minimum`) wide. The arrows are icon Buttons of the same size.
The label keeps the width of the widest label that the count can make, so the
arrows do not move when the page gains a digit. Page nodes are keyed by page
number. When the selected page leaves the window, or a selected arrow becomes
disabled at an edge, the selection moves to the current page. `rtl` reverses
the row once. The root is a Frame that fills its width. `AutomaticSize` on X
causes an error, because the window narrows to the width that it gets.

The root has the attributes `FacetCurrent`, `FacetCount`, `FacetForm` and
`FacetDirection`. Use Pagination for results that you load one page at a time.
Use VirtualList for one long list and PageView to swipe between screens.

### StepIndicator

StepIndicator shows where a workflow is. It shows a list of step states. It
is not a number control. It requires `steps` (an array or a readable) and
`current` (a step id, `nil` or a readable). A step is `{ id, label,
description?, state?, navigable?, enabled? }`. `state` is `complete`,
`current`, `upcoming` or `error`.

- Step ids are nonempty and unique. Labels are nonempty and can repeat.
- `current` alone sets the current step. It places the underline and the
  summary "Step n of m — Label". `state = "current"` is accepted only on the
  step that `current` names.
- A step's `state` sets its cue and its state word: a check for `complete`,
  the error icon for `error`, and otherwise the step number in a circle. Thus
  an errored current step keeps its error cue. The state word shows under the
  label.
- A `current` that names no step shows "No current step". An empty list shows
  "No steps" and has no Steps button.
- A step is a Button only when it is `navigable`, it is not disabled, and you
  supply `onSelect`. Other steps are plain content and never selectable. A
  press on a permitted step calls `onSelect(id)` once. The control never
  writes `current`. Thus a refused step changes nothing.
- `sizing` is `fill` (default, each step gets the share of the widest label)
  or `hug` (each step gets its own label width). `listLabel` (default
  "Steps"), `controlSize`, `enabled` and `controls` are optional. The control
  sets `controls.diagnostics()`.

A malformed snapshot at construction causes an error. A later malformed
snapshot keeps the last legal one, with a warning and a diagnostic line. The
control measures its root width and the label text. When the steps do not
fit, the row changes to the summary and a Steps Menu. The menu lists every
step. Permitted steps select through the same `onSelect`. The menu closes
when your `current` changes, so a refused step leaves it open. The number
circle keeps an aspect ratio of 1 at every text size. The row stretches its
cells to one height with a native `ItemLineAlignment`.

The underline is a `facet-selection-indicator` frame. It moves to the new
current step on a spring. Reduced motion places it immediately. The root has
the attributes `FacetCurrent`, `FacetSummary`, `FacetForm` (`row` or
`summary`) and `FacetListOpen`.

### RadialMenu

The required `items` use the menu item model. The options are:

`isPresented`, `label`, `launcher`, `preset`, `distribution`, `navigation`,
`expansion`, `center`, `centerLabel`, `centerContent`, `centerPassThrough`,
`anchor`, `follow`, `clearance`, `ringWidth`, `contentFit`, `gestureSelection`,
`holdAction`, `enabled`, `onOpen` and `onClose`.

`holdAction` is a native InputAction Instance that the caller owns. The control
subscribes to its `Pressed` and `Released` events. It does not accept an action
name, and it does not define key bindings. Parent the action under a native
InputContext and declare the InputBindings there.

`completion` sets what item activation does: close, stay, return to the root,
or go back. You can navigate nested items. Checked and selected items update
their model. The geometry is specific to this control. It does not add a second
general layout or input system. A native GuiObject anchor or a projected
screen-point anchor connects the menu to an existing surface.

## Presented controls

### Alert

Supply a writable boolean `isPresented`, or a writable `item` cell where `nil`
means hidden. Also supply `title`, `message` and `actions`. The alert captures
the item payload for the active presentation and gives it to the content and
callback factories.

Actions have `id`, `label` and `role`, and an optional `enabled`, `shortcut` and
`onActivate(payload)`. Dismissal occurs before the action callback.

The control owns the initial selection, selection containment, Back and cancel,
and restoration to the previous selection if that object still exists.

Motion options:

- `transition = { source = nativeNode, seconds = 0.2, ease = Compose.easing.outQuad }`
  enables native source motion. `source` can also be a readable.
- `surface = "fullScreen"` fills the native presentation area.
- With `surface = "fullScreen"` and a source transition, both bounds
  interpolate from the source rectangle. A non-interactive native snapshot
  keeps the appearance during the handoff. Dismissal reverses to the source if
  it still exists. Compose owns the snapshot and the departing presentation.
  The source stays mounted.
- Native reduced motion makes the handoff immediate.
- Without `transition`, the alert scales from 0.94 to 1 and fades in. See
  [Motion](#motion).
- `transition = false` makes the presentation immediate.

The alert clears a writable `error` on dismissal. Use an alert for a brief
decision. `icon`, `severity`, suppression and custom content refine the
presentation.

### Sheet

Sheet requires a writable `isPresented` and a writable `detent`. The default
detents are `medium` and `large`. A custom entry is `{ id, fraction }` or
`{ id, height }`, never both.

Supply a `title` and a `content` factory that returns native children. The
sheet calls the factory without arguments. Its subtree fills the available body
region. The body uses a native vertical ScrollingFrame. Thus content taller
than the selected detent stays reachable, and the sheet chrome stays fixed.

Native drag detection resizes the sheet between the declared detents. The
grabber is also a selectable `Resize` button that moves to the next detent, for
touch taps, the mouse and the gamepad. The header shows the title and a `Done`
action named `Close`. `interactiveDismissDisabled` blocks gesture dismissal.
The Done action stays available. The sheet slides up from the bottom and slides
down when it closes. See [Motion](#motion).

### DisclosureGroup and CollapsibleView

Both require a writable `expanded` and `content`. DisclosureGroup expands its
content in the document flow. CollapsibleView opens its content as a larger
presented surface. For outer layout, use the native properties on their
returned roots.

### Callout

Callout requires a native `anchor` with a separate parent, content and
`onRetire`. The callout borrows the anchor. When a native ancestor of the anchor
is hidden, the callout is suspended. `seen`, `sessions`, `afterSessions`,
`featureUsed` and priority set eligibility and queue order. Retirement is
delivered once. `edge = "top"` puts the callout above the anchor. If there is
no room above and there is room below, the callout goes below the anchor. A
callout is contextual teaching attached to a control. It is not a second
application presenter. The callout scales and fades from the edge nearest to
its anchor. See [Motion](#motion).

## Collections

### VirtualList and VirtualGrid

Required: `from` (an array, readable or body) and
`render(current, placement, key)`. `key` is a function `(item, index) -> key`
or the name of the field that holds the identity, for example `key = "id"`. A
field name gives `tostring(item[field])` as the key. If you omit `key`, Compose
uses item identity. Render receives readables for the current item and its
placement, and returns native content. Keep durable row state outside that
render owner.

| Option | Default and meaning |
|---|---|
| `mode` | `windowed`; `all` deliberately mounts the entire collection. |
| `direction` | `vertical`; `horizontal` changes the scrolling axis. |
| `itemSize` | `40`, the estimated main-axis extent. |
| `gap`, `crossGap` | `0`; the cross gap defaults to the gap. A VirtualGrid keeps half of each gap (rounded up) at its outer edges, as a `UIPadding` on its `Items` frame and in its canvas extent. Thus content that paints past its cell, such as a lifted Card, is not cut by the scroll clip. |
| `columns` | The grid column count, default `1`; can be reactive. |
| `overscan` | `2`. |
| `measure` | `false`; set to observe the rendered native `AbsoluteSize`. |
| `measured` | An optional readable map from key to extent; overrides observed measurements. |
| `follow` | `none` or `end`, or a readable of one, with an optional `followThreshold`. |
| `status` | An optional writable Compose collection status cell. |
| `controls` | An optional table that the control fills with the Compose `indexOfKey`, `placementOf` and `offsetOf`. |
| `maxRetained` | The pool keeps at most `32` row hosts by default. |

The returned root is a ScrollingFrame. Compose `OrderedCollection` owns
indexing, window selection, anchor preservation and placement. The control
applies its desired offset to `CanvasPosition`. Sorting keeps the native anchor.
It does not force the first item to the top.

`snap = "item"` settles scrolling to the Compose placement boundaries. The
default is `none`. With `follow = "end"`, the list follows appended rows while
the viewport stays at the end. When a readable `follow` changes, the control
replaces its Compose `OrderedCollection` and mounts the rows again. Keep durable
row state in the model. Other values cause an error.

Optional collection focus uses `focus`, `initialFocus`, `autoFocus`,
`wrapFocus` and `disabled(item)`. With `wrapFocus = true`, `focus.next()`,
`focus.previous()` and the arrow and D-pad actions wrap at the two ends of the
collection. A list wraps only along its scrolling axis.

- `selection` is a writable key-set map.
- `selectionMode` defaults to single when you supply `selection` or its
  callback. Otherwise it defaults to none.
- `onSelectionChange(nextMap)`, `onActivate(item, key)` and `onReachEnd`
  connect control events to domain behavior.
- When the selection mode is not `none`, one mouse click selects a row. A
  double click, Return, a gamepad press or a touch tap runs `onActivate`. A
  double click keeps the selection. When the mode is `none`, each activation
  runs `onActivate`. Table rows follow the same rule.
- `selectable(item)`, `reorderable`, `movable(item)`, `dragLabel` and
  `onReorder(keys, insertionSlot)` use the same zero-based insertion contract
  among the remaining rows as Table.
- A keyboard or gamepad move steps along the scrolling axis. A vertical
  collection uses Up and Down. A horizontal collection uses Left and Right.
- A reorder that would move a row that is not movable does not occur.

Native properties and children stay available.

```luau
local rows = Compose.cell({ { id = "a", title = "Amber" } })
local list = UI.VirtualList {
    from = rows,
    key = "id",
    itemSize = 52,
    Size = UDim2.fromScale(1, 1),
    render = function(current)
        return UI.Button {
            label = function(use) return use(current).title end,
            onActivate = function() inspect(current:peek().id) end,
            Size = UDim2.new(1, 0, 0, 52),
        }
    end,
}
```

### Card

Card shows one item of a browsable collection: artwork, a title and an
optional caption, with a primary action and a More menu that show on
engagement. It requires `image` and `title` (nonempty strings or readables).
The other options are `caption`, `imageAspectRatio` (default `16/9`),
`imageFraming` (`fit` or `crop`), `onActivate`, `primaryAction = { label,
icon?, onActivate, enabled?, busy? }`, `menu = { items, label? }`, `reveal`
(`automatic` or `always`), `browseTarget`, `enabled` and `controls`.

Use a Card for a game, a track or a kart, where the picture helps the player
choose. For rows of text, use VirtualList or Table.

- With `onActivate`, the body is a Button. Without it, the body is plain
  artwork and text. The primary action is a Button. `menu` is a Menu behind a
  More trigger (`menu.label`, default "More"). The body, the primary action
  and More are sibling targets under a root that is not a Button. Thus a press
  runs exactly one of them. `enabled = false` applies to all three.
- A late value of `title` or `image` that is empty or of the wrong type keeps
  the last legal paint, with a warning and a diagnostic line.
- `always` keeps the action plate visible. `automatic` (the default) shows it
  at rest when the session has touch (`TouchEnabled` or a touch
  `PreferredInput`), and otherwise while the card is engaged. The card is
  engaged while the pointer is in it, the selection is in it, a press is held
  on one of its actions, its menu is open, its actions are entered, or the
  `browseTarget` is selected. A card with no body action and no
  `browseTarget` has no stop of its own, so it shows its actions at rest.
- The plate is a CanvasGroup below the body in the card's own layout. It is
  always laid out, so the card size never changes and the siblings never move.
  At rest it is transparent and not `Interactable`, so its actions take no
  press and no selection. The fade uses a Compose tween, so a quick reversal
  continues from the current value. Reduced motion shows and hides it
  immediately.
- While engaged, the card's `UIScale` named `Lift` rises to 1.04 on a spring,
  and a body Button shows its `UIShadow` named `LiftShadow`. A card with no
  body action has no shadow. The scale is paint only. Keep gutters of at least
  the scaled growth around each card. Reduced motion keeps only the shadow.
  When a `browseTarget` exists, the card puts a `UIScale` named `CardLift` with
  the same scale on it, so the selection ring grows with the card.

`browseTarget` is a function that returns the browse stop of the card, such
as the `RowHit` of a VirtualGrid cell. `controls` is an optional table. The
card sets `enterActions()`, `leaveActions()`, `diagnostics()` and the readables
`engaged`, `revealed`, `scale` and `revealExtent` (`{ body }`, the measured
root height). `enterActions()` holds the reveal and selects the first eligible
action. It returns false for a disabled or unmounted card, or when no action
is eligible. It never runs the primary action. While the actions are entered,
the action row is a `SelectionGroup` whose selection behavior is `Stop` on all
four sides. Escape or ButtonB leaves the actions and selects the browse stop.
The menu closes first when it is open. A press outside the card also leaves.
When the card is removed or recycled, it releases the entry.

The root has the attributes `FacetReveal`, `FacetRevealed`, `FacetEngaged`,
`FacetHovered`, `FacetFocusWithin`, `FacetPressing`, `FacetBrowsing`,
`FacetEntered`, `FacetMenuOpen` and `FacetBody` (`button` or `informational`).

```luau
local controls = {}
local cards = {}
UI.VirtualGrid {
    from = games,
    key = "id",
    columns = 3,
    itemSize = 320,
    measure = true,
    gap = 16,
    onActivate = function(_item, key) local entry = controls[key]; if entry then entry.enterActions() end end,
    render = function(current, _placement, key)
        controls[key] = {}
        local card = UI.Card {
            image = art,
            title = function(use) return use(current).title end,
            controls = controls[key],
            browseTarget = function()
                local node = cards[key]
                return node and node.Parent and node.Parent:FindFirstChild("RowHit")
            end,
            primaryAction = { label = "Play", onActivate = function() play(key) end },
            menu = { items = { { id = "hide", label = "Not interested", onSelect = function() hide(key) end } } },
        }
        cards[key] = card
        Compose.cleanup(function() cards[key], controls[key] = nil, nil end)
        return card
    end,
}
```

### Table

`from`, `key` and `columns` define the rows. `key` has the same forms as for
VirtualList. A column has:

- `id` and `label`,
- an optional pixel `width` (otherwise flex),
- `minWidth` (48) and `maxWidth` (1e6),
- `resizable` and `sortable` (both true),
- `value(item)` or `render(current, placement, key)`.

A numeric `priority` collapses larger values first. `"always"` prevents
collapse. The first column always stays visible. A shared CollapsibleView shows
collapsed and natively truncated values through the More action of the row.
The cell state stays retained.

`sort` is `nil` or `{ column, direction = "ascending" | "descending" }`.
`widths` is a map of column widths. `selection` is a key-set map.
`selectionMode` is `single`, `multi` or `none`. When you supply
`onSortChange`, `onWidthsChange` or `onSelectionChange`, it is a controlled
request. Otherwise the control updates the writable cells.

`selectable(item)`, `disabled(item)`, `onActivate(item, key, input, clickCount)`
and `rowActions(current, key)` specialize rows. `onActivate` receives the same
native activation facts as in VirtualList. `reorderable`, `movable(item)` and
`onReorder(keys, insertionSlot)` support native drag reorder. The insertion
slot is zero-based among the remaining rows. `editing` is a writable cell.

Sizes:

- The header height starts at 40.
- The estimated row height starts at the larger of 40 and the regular control
  height of the theme.
- The native touch and gamepad minimum row height is `44`.
- Native text bounds can make both larger.

`header = false` removes the header band. `scrolls = false` mounts all rows and
sizes the table to its content. Otherwise, `mode` selects the Compose windowed
or all lifetime. The collection measurement, status, controls, focus and
follow options also apply.

### RowActions

`content` is native content or a factory. `leading` and `trailing` contain
`{ id, label, icon, enabled, role, onActivate }` actions. `open` is `nil`,
`leading` or `trailing`. `onOpenChange` is controlled.

`actionWidth` has a minimum default of `88`. Native label bounds can make the
action tray larger. Full swipe is on by default. You can set it for each edge.
A row with no measured width does not open or run an action from a swipe.
A shared `coordinator` cell lets only one row be open. When a row opens,
through a gesture or a write to its `open` cell, the other rows close.

Native swipe, context, and keyboard and gamepad actions reach the same
commands. In a collection row, these actions also apply when the row itself
has the selection. A destructive action runs exactly once, after its Compose
departure animation. If the owner is removed, an unfinished departure is
cancelled. If the owner keeps the row, for example when the server refuses the
delete, the row returns to its full height on the next frame, and the action
can run again. A full swipe commits or opens a tray only after the row has a
measured width.
`reducedMotion`, `enabled` and `editing` stay explicit control options.

## Media and status

| Control | Main contract |
|---|---|
| `Label` | `text` or `label`, icon and iconPosition, textRole and role, and native text properties. `textRole` is one of `TYPE_ROLES`. Another value causes an error. Without an icon, it returns a TextLabel. With an icon, it returns a Frame row that holds the icon and a TextLabel. Native properties then apply to that Frame, so give it Frame properties only. |
| `Badge` | `label`, `status`, an optional icon and position, appearance, corners and control size. The icon and the label share one pill. The status appearance keeps a neutral pill and shows the status as a leading dot. |
| `StatusIndicator` | `status`: `neutral`, `info`, `success`, `warning`, `error` or `accent`. `form`: dot, ring, square or dash. Optional `count`, `max`, `diameter` and `name`. The `name` sets the accessible label. A ring is a native inner stroke in the status color. A count grows into a pill that is never narrower than it is tall. |
| `ProgressView` | `value`, `min` (0), `max` (1). `presentation`: bar, circular or spinner. label and endLabel, showValue and format, diameter, thickness, segments, and an optional trail `{ delay, duration }`. The endLabel shows after the value. With a label, a bar shows the value and the endLabel on the label row. Segments require the bar presentation. Diameter requires circular or spinner. A trail holds on damage, settles over its duration, and snaps on healing or reduced motion. A circular value is centered when the native text bounds fit. Otherwise it shows below the ring. A circular ring with no thickness uses 8 percent of its diameter, and not less than the theme metric. |
| `Skeleton` | A loading placeholder with a configurable form and line count. |
| `AsyncImage` | An image or source, an optional resource or loader, a placeholder, a failure label and a status callback. `imageProperties` forwards native properties and children to the inner ImageLabel. |
| `Avatar` | `name`; image, userId or resource; loader and onStatus; presence online, away, busy or offline; presence label and mark; diameter or controlSize; standard or icon form; optional activation. |
| `AvatarGroup` | `items` with id, name, image, userId and presence, and an optional `resource` shared-resource acquire function. max (4); stacked or spread layout; count or ellipsis overflow; onOverflow; diameter or controlSize. A stacked group has the `facet-avatar-stack` tag, and the theme draws a surface ring around each face. |
| `Stage` | A native ViewportFrame. A `camera` CFrame or a borrowed Camera, `fieldOfView`, and `content(runtime, world)` for 3D content that Compose owns. |

The AsyncImage loader receives `(source, resolve, reject)`. It can return a
cancellation. A superseded result cannot replace the current image. Loading and
failure stay observable. The control does not invent successful assets.
Resource lifetime uses Compose ownership and shared resources.

The Stage content callback mounts into its WorldModel. It can return a teardown
function. Use the `Host.Part`, `Host.Model` and other native constructors of the
same runtime. A 3D view inside a UI rectangle is not the same as 3D UI layout.

`UI.badged(host, value, direction?) -> Frame` puts a count or a dot on the
corner of a host, such as a Button, an icon Button or an Avatar. It returns a
Frame named `<host name>+badge` that hugs the host and takes its
`LayoutOrder`. A zero-size `Corner` frame sits at the top-right corner of the
host, or at the top-left when `direction` is `"rtl"`. It holds a Badge named
`CornerBadge`, centred on the corner. The Corner frame has no size, so the host
keeps its layout box, its hit area and its selection. `value` is a string, a
whole count (above 99 shows "99+"), `true` for a dot, or a readable of one.
`nil`, `false`, `0` and `""` show nothing. A TabView tab with an `icon` shows
its `badge` on the corner of the icon. A text tab keeps the count in its words.
The seal paints past the host by half its size, so give a host at a clipping
edge that much room.

## Themes

`themes.SCHEMA` is `facet-theme/2`. `TYPE_ROLES` and `REQUIRED_TYPE_ROLES` list
`caption`, `label`, `body`, `heading`, `title`, `control`, `strong` and
`numeral`. The `caption` role also uses the `contentSecondary` color.
If a definition sets `body` and does not set `strong`, `define` makes `strong`
from `body` with the `SemiBold` weight. If a definition sets `control` and does
not set `numeral`, `define` makes `numeral` from `control` with the `Bold`
weight. The derived role keeps the family, style, size and line height.

- `neutralPackage()` returns a mutable copy of the neutral theme package.
- `define(definition)` derives from `base` (neutral by default) and returns
  `package?, report`. Check `report.ok` before use. An accepted theme package is
  recursively frozen. Callbacks, cycles and malformed definitions are rejected.
  A type role needs a positive size. Each `metrics.space` step needs a pixel
  size of 0 or more. A chrome shadow name must be a
  package shadow or a preset (`raised` or `overlay`). Each palette pair needs a
  contrast of at least 4.5:1, which includes `onSelected` (or `content`) on
  `controlSelected`.
  Color channels and semantic contrast pairs are validated.
- `checkCoverage(package, needs)` returns `{ ok, covered, missing }`.
- `resolveIcon(package, name, state?)` resolves real image content.
- `createStyleSheet(runtime, packageOrReadable?, options?)` returns a native
  StyleSheet that Compose owns. See the list below.
- `skin(runtime, packageOrReadable, slot, options?)` builds native control
  artwork. The options include `state`, `target`, `label`, `ZIndex` and injected
  `types`.

`createStyleSheet` contract:

- Make the sheet inside a Compose owner. Parent it as a numeric child. A
  StyleLink only references the sheet. It does not parent it.
- The options are:
  - `types`: injected datatypes.
  - `theme`: the selected palette, as a name or a readable.
  - `name`: the native name.
  - `transition`: a native TweenInfo, a readable, or `false`.
  - `reducedMotion`: a boolean or a readable.
  - `preferredTransparency`: a number or a readable. The value multiplies the
    scrim transparency. Other rules keep their authored transparency. A value
    that is not a number has no effect. If you omit it, the sheet follows
    GuiService.
- Colors and opacity use native StyleRule transitions. The default duration is
  `metrics.motion.normal` of the theme package, or 0.2 seconds if it is
  omitted. The easing is Quad Out. The same timing applies across rules. Native
  transitions retarget interrupted changes.
- Reduced motion or `transition = false` sets zero-duration paint. If you omit
  reduced motion, the sheet follows GuiService.
- Explicit Instance paint still overrides stylesheet paint.

A theme package contains `identity`, `style = { defaultTheme, themes }`,
`metrics`, `chrome`, `assets`, `icons` and additional
`rules = { { selector, properties } }`. A palette contains `name`, `colors` and
`extra`. The main colors are `surface`, `surfaceStrong`, `content`,
`contentStrong`, `accent`, `onAccent`, `danger`, `onDanger`, `success`,
`onSuccess`, `warning` and `onWarning`. The extras include control states,
secondary content, hairlines and opacities.

StyleSheet rules own ordinary paint. Explicit Instance properties override
native styling intentionally. Give the same theme package readable to
`Facet.controls(runtime, { theme = package })` and to
`createStyleSheet(runtime, package)`. Mount the resulting sheet and a native
StyleLink in the target tree. See [custom themes](../guide/09-custom-themes.md)
and [skins](../guide/10-rich-skinning.md).

## Native targets and boundaries

Use the ordinary Compose Roblox constructors to mount:

- a ScreenGui into PlayerGui,
- a BillboardGui into an applicable world target,
- a SurfaceGui onto a part.

The native safe-area and sizing properties belong to those targets. World
surfaces stay flat two-dimensional UI. Facet does not supply ray, hand or gaze
input, or a VR layout mode.

Engine geometry settles asynchronously. When a control policy needs
measurements, observe the native bounds. Do not add a competing general solver.
Do not assume final text or layout bounds synchronously after construction.

The supported import boundary is the Facet root table and the Compose exports
that you can reach from it. Control implementation modules are private. The
vendored Compose tree is a generated, read-only snapshot. Make changes upstream
and synchronize them through the repository tooling.
