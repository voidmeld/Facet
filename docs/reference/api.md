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
| `civilDate` | Calendar arithmetic, words and fixed-offset instants for civil dates. See [Civil dates](#civil-dates). |
| `recipes` | Opt-in helpers. `recipes.arithmetic.parse` is a bounded arithmetic parser for a number field. See [Recipes](#recipes). |
| `bind(Compose, Roblox)` | Returns a Facet table whose `controls` and `themes` use the Compose core module and the Compose Roblox module that you give. See [Your own Compose](#your-own-compose). |

### Types

The exported Luau types include `Facet`, `ComposeModule`, `ComposeRobloxModule`,
`Controls`, `ControlOptions`, `ThemePackage`, `CivilDate`, `CivilRange`,
`CivilLocale`, `CivilDateModule`,
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
definitions. It raises the `LuauTarjanChildLimit` analyzer flag to 100000,
because the old Luau solver stops at its default limit of 10000 on the full
`Facet` type and reports "Code is too complex to typecheck". It reports vendor diagnostics separately. It does not accept a
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
- `onError`: receives a failure from the content of a presented Alert or
  Sheet, which then dismisses, and a failure from a Callout `onShow`. It also
  receives a failure that an `ErrorBoundary` without its own `onError`
  contains.
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
| Sheet | Slides up from the bottom, 0.3 seconds, Cubic Out. A side sheet slides in from its edge. The scrim fades in. | Slides down, or toward its edge, 0.2 seconds. |
| Alert | Scales from 0.94 to 1 and fades in, 0.2 seconds, Cubic Out. The scrim fades in. | The reverse, 0.15 seconds. |
| Callout, Button `help`, Menu, Picker menu, Popover | Scales from 0.9 to 1 from the edge nearest to the anchor, and fades in, 0.15 seconds, Cubic Out. | The reverse, 0.1 seconds. |
| Snackbar | Slides up from below the layer, 0.2 seconds. | Slides down, 0.2 seconds. |
| Dialog, Notice, NavBar | No motion. | No motion. |

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

### Selection

The controls use `GuiService.SelectedObject` for keyboard and gamepad focus.
The engine moves the selection with the D-pad and the arrow keys. Facet adds
these rules:

- Entry. When nothing is selected, the first D-pad press selects the first
  control of the active screen in layout order. An open modal is the active
  screen. The press does not move a selection that already exists.
- Tab and Shift+Tab. Tab selects the next control in layout order.
  Shift+Tab selects the previous control. The walk wraps at both ends. It
  stays inside an open modal. It skips hidden, disabled and removed controls.
  The `FacetTraversal` input context is a child of `inputParent`, or of the
  local `PlayerGui` when you do not set `inputParent`.
- Removal. When the selected control goes away, the selection moves to the
  nearest control that remains. A following control comes before a
  preceding control. A collection keeps the selection on its rows by key: it
  selects the next row, or the previous row when the removed row was the last.
- Scroll containers. A scroll container is not a stop. When the engine selects
  one, the selection moves to the child nearest to the entry edge. A TabView
  strip gives the selected tab. A container that has no controls passes the
  selection to the next control in the direction of travel.
- Value controls. While a Slider, Stepper, Rating, table column grip or a
  reorder move has the selection, Left and Right change the value. A Menu row
  with a submenu opens it on Right, and Left returns to the parent row. Up and
  Down still move the selection.

A control that restores its own selection sets the `FacetSelectionOwner`
attribute on its root. The removal and scroll-container rules do not change
the selection inside that root.

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

### ErrorBoundary

`UI.ErrorBoundary(spec) -> Frame` contains a failure in the region that it
builds. `view()` builds the region. `fallback(failure, retry)` builds the
content that replaces the region after a failure. Both are required.

- A failure in `view` when the boundary mounts, or in a later Compose update
  inside the region, disposes the region and shows the fallback. Siblings
  outside the boundary stay. The code that wrote the cell that caused the
  failure does not see an error.
- The boundary reports each failure once. `onError(failure)` receives it. If you
  do not set `onError`, the factory `onError` option receives it. The
  `FacetError` attribute of the frame holds the failure text.
- Call `retry()` to build the view again. A successful retry clears
  `FacetError`.
- A failure in the fallback is not contained.
- `width` and `height` take `fill`, `hug` or pixels. The default is `hug` on
  both axes.

The boundary uses `Compose.boundary`. A failure outside every boundary stays a
hard error.

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
  `help` that is available nowhere else. `help` can also be a table
  `{ title?, body, shortcut?, edge?, align? }`. `title` shows above the body.
  `body` can be empty only when `title` has the words. `shortcut` is a list of
  key chords such as `{ { "Ctrl", "K" }, { "F1" } }`. It is display text only
  and binds no key. `edge` (`top`, `bottom`, `leading` or `trailing`) and
  `align` (`start`, `center` or `end`) place the panel against the button. The
  panel uses the anchored placement of `UI.Popover`. A malformed table stops
  with an error that names `help`.
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

A switch or checkbox Toggle paints no plate and takes no `control` art from a
theme package. A settings row (a Toggle with `row`, `hint` or `icon`) has the
`facet-toggle-settings` tag. Its horizontal padding is the padding of a
Button, so its content lines up with Button rows in each theme.

### TextInput

`value` is the string model. Roblox TextBox owns editing, IME, the caret, the
text selection and focus. `onChange(text)` handles user edits. An external
model update does not send it. `onCommit(value, reason)` receives `submit` or
`focusLost`. The number presentation also reports `clamped`. `onCancel`
observes cancellation and the restoration of the initial value of the edit.

`presentation` is `plain`, `search` or `number`. The number presentation also
uses a writable `numericValue`, `min`, `max`, `parse` and `format`, and the
number options of [NumberInput](#numberinput). If a callback disables the input
during a commit, the commit stops. `numericValue` does not change and
`onCommit` does not run. `validate(proposed)` returns the accepted text, or
`nil` to reject it. `maxLength` counts UTF-8 characters.

The other options are `placeholder`, `multiline`, `invalid`, `enabled`,
`disabled`, `clearButton` and `clearButtonMode` (`never`, `always`,
`whileEditing` or `unlessEditing`). Native TextBox properties stay available.

- `readOnly`: a boolean or a readable boolean. A read-only field stays
  selectable, keeps full contrast and can take focus. `TextEditable` is false,
  the control refuses each edit, the clear button does not show and focus loss
  commits nothing. A live change keeps the same TextBox and the edit.
- `selectOnFocus`: `none` (the default), `all` or `end`, or a readable of one.
  The control applies it once for each focus session. A pointer focus applies
  it at the release of that pointer. Other focus applies it at once. A change
  during focus applies at the next focus. A live value that is not one of the
  three words causes an error, and the control keeps the last correct word. The
  TextBox has the `selectOnFocus` attribute only when you supply the option.
- `visibleLines`: a whole number of at least 1, for a multiline field only. The
  field shows that number of body lines in a native ScrollingFrame named
  `Viewport`. Longer text scrolls in the viewport, and the viewport keeps its
  size.

#### Field chrome

A field can have these field chrome options: `label`, `requiredMark`, `hint`,
`errorText`, `leading`, `trailing`, `controlSize`, `appearance` and `corners`.
A field without chrome options, number units, step buttons or `visibleLines`
keeps the native TextBox as its root. Other fields return a Frame. The root
Frame holds these children in order:

1. `Label`: a TextButton that is not selectable. Its `Title` text is the label.
   Activation focuses the TextBox. The label is 44 pixels tall or more, and
   its words sit at the bottom. It follows `enabled`.
2. `Input`: the plate. It holds `SearchIcon` or `Leading`, `Prefix`, the
   TextBox named `Field`, `Suffix`, `Clear`, `Decrement`, `Increment` and
   `Trailing`, in that order. A named `controlSize` puts the plate in an
   `Input+target` Frame that is 44 pixels tall or more.
3. `Message`: one line. It shows `errorText` when it is not empty, then the
   number rejection text, then `hint`. An error shows the `status.error` mark
   (`MessageMark`), adds the `facet-validation` tag to the text and the
   `facet-invalid` tag to the plate. The plate does not move or shake.

`requiredMark` is `required` or `optional`. It is notation only. It does not
validate. `required` adds ` *` to the label text, also for a readable label.
`optional` adds no word. Put localized "optional" text in `hint`.

`leading` and `trailing` are native Instances. `leading` is decoration and is
not a focus stop. A search field refuses `leading`, because its search mark
leads. The focusable parts of `trailing` come after the TextBox and the clear
button.

`appearance` is `standard` (the `facet-field` plate), `contrast` (the
`facet-control` plate) or `utility` (no plate). A readable word changes the tag
in place. A word that is not one of these causes an error, and the plate keeps
the last correct paint. `corners` is `pill` or `square`. It adds a native
UICorner named `Corners`. `controlSize` is `compact`, `regular` or `large`.

A word that the chrome does not know causes an error that names the option.

### NumberInput

`UI.NumberInput(spec)` is `UI.TextInput` with `presentation = "number"`. It
refuses `presentation`. `value` (the editable string) and `numericValue` (the
committed number) are cells that you own. Each TextInput option applies. These
options are for the number presentation only:

- `step`: a finite number above zero. The default is 1.
- `precision`: a whole number of decimal places from 0 to 10. A commit and a
  step press round half away from zero. Typing does not round.
- `stepButtons`: two 44 by 44 buttons, `Decrement` and `Increment`, after the
  clear button. They are ordinary focus stops and do not take the arrow keys.
  The control disables a button at the bound that it faces, and disables both
  buttons when the field is read-only or disabled. A press commits with `submit`. With `min` and
  `max`, a press follows the step grid from `min`.
- `prefix` and `suffix`: a string or a readable string beside the TextBox.
  They are not part of the draft.
- `scrub`: a boolean or a readable boolean. A horizontal drag across the
  TextBox changes the number. See below.

Without `precision`, a step press or a scrub rounds to the decimal places of
`step` and `min`. Thus three presses of 0.1 give 0.3.

A commit parses the draft. The default parser accepts an optional sign, digits
and one decimal point only. It refuses an exponent, grouping, hex and blanks.
`Facet.recipes.arithmetic.parse` adds arithmetic. A number outside `min` or
`max` becomes the bound, and `onCommit(number, "clamped")` reports it. A draft
that is empty, a sign alone or a point alone is incomplete. At commit, the
field restores the text of the last committed number and shows no message,
unless `requiredMark` is `required`. A draft that is not a number keeps its
text and shows "Enter a valid number.". `onCommit` receives the number.

`scrub` starts after 6 pixels of mouse travel or 14 pixels of touch travel. A
tap below that distance stays a native tap. A drag that is mostly vertical
stays native. A horizontal drag ends the edit without a commit and restores
the text of the edit start. Then each 8 pixels of total travel is one `step`,
with the rounding and bounds of the step buttons. `onChange` reports each new
text. The release commits once with `submit`. Escape or ButtonB, a change of
PreferredInput, disabling, `readOnly`, `scrub` turning off and disposal cancel
the drag: the number and the text return to the values at the drag start, and
nothing commits. A write of your own to `numericValue` during a drag ends the
drag, and your number stays.

```luau
local draft, laps = Compose.cell("3"), Compose.cell(3)
UI.NumberInput "Laps" {
    value = draft,
    numericValue = laps,
    min = 1,
    max = 99,
    stepButtons = true,
    label = "Laps",
}
```

### ColorPicker

`UI.ColorPicker(spec)` returns a Frame. The player uses it to choose any
colour, for example the paint of a kart. For a few named colours, use
`UI.Picker`. A fixed palette also fits `modes = { "swatches" }`.

```luau
local paint = Compose.cell(Color3.fromRGB(230, 57, 70))
UI.ColorPicker "KartPaint" {
    label = "Kart paint",
    value = paint,
    onChange = function(color)
        paint:set(color)
    end,
    onCommit = function(color)
        print("save", color)
    end,
}
```

- `value`: a Color3, or a readable of one. It is `nil` only with
  `allowEmpty = true`. Then the plate has a cross and the text is
  `placeholder`.
- `onChange(color)`: receives each proposal. It is necessary unless `value` is
  a writable cell or `readOnly` is true. With `allowEmpty`, a discarded draft
  that opened empty proposes `nil`.
- `onCommit(color)`: runs once at the end of each gesture.
- `alpha` and `onAlphaChange(alpha)`: an opacity from 0 to 1. They add the
  `Opacity` slider, and the text becomes `#RRGGBBAA`.
- `modes`: the techniques in tab order. Each is `swatches`, `spectrum`,
  `sliders` or `brick`. The default is the first three. Set it at construction.
- `swatches`: a list of Color3 values or `{ color, label? }` items, or a
  readable of one. The label or the hex text is the key of an item. Without
  it, the control shows a generated grid of 48 colours.
- `onSaveSwatch(color)` and `onRemoveSwatch({ color, label?, key })`: saved
  colours. See below.
- `style`: `automatic` (the default) or `inline`. Set it at construction.
  `automatic` is a well that opens a panel. `inline` shows the panel in place.
- `draft`: adds Cancel and Apply.
- `isPresented`, `onPresentedChange(next)` and `onDismiss(reason)`: the open
  state of the panel. The reason is `activate`, `outside`, `cancel`,
  `anchorLost` or `apply`. Without `isPresented`, the control keeps its own
  open state.
- `enabled` and `readOnly`: booleans or readables. A disabled well keeps its
  colour and does not open.
- The field chrome keys: `label`, `requiredMark`, `hint`, `errorText`,
  `controlSize`, `appearance` and `corners`. See
  [Field chrome](#field-chrome).

A value that is not legal at construction causes an error. A value that
becomes illegal later is not painted. The control keeps the last legal colour
and adds a line to the `diagnostics` attribute.

#### Proposals and commits

The colour belongs to you. Each change sends a proposal to `onChange`. The
control shows only the colour that you then hold. If you refuse a change,
nothing paints.

A gesture is a drag of the plane, a slider drag or step, a stick session, a
swatch press or a field commit. Without `draft`, each gesture commits once. B,
Escape, a tap outside and Done close the panel and keep the colour.

With `draft = true`, only Apply commits. Each other way out proposes the
colour that the panel opened with. Cancel does this too. If you write the
value while the panel is open, your value becomes the value that Cancel
restores. Apply has the `facet-accent` tag.

#### The well and the panel

A well with a `label` is a form row. The `Well` button holds `Title`, the
`Swatch`, the `Value` text and `Chevron`. A well without a label is the
swatch alone, 44 by 44 pixels. The `label` attribute of the well names the
colour, for example "Kart paint, #E63946".

The panel opens below the well. If there is not sufficient room below, it
opens above. If neither side has room, it opens beside the well. Otherwise it
takes the larger side, and its `Body` ScrollingFrame scrolls. The panel never
covers the well. On a touch screen narrower than 600 pixels, the panel is a
sheet at the bottom of the screen with a Done button. On a ten-foot screen,
the panel is a sheet at the center of the screen. The `placement` attribute is
`bottom`, `top`, `right`, `left`, `sheet` or `center`.

The panel holds these parts in order:

1. `Modes`: a `UI.Picker` of the techniques. It is present only with two or
   more modes.
2. `Body`: the `Technique` frame. Each technique stays mounted. The inactive
   techniques are not visible. The frame is as tall as the tallest technique,
   so the panel keeps one height when the tab changes.
3. `Opacity`: present only with `alpha`.
4. `Readout`: the `Preview` swatch, the `Format` picker (RGB, HSV and Hex) and
   the fields. On a touch screen, the readout comes before the body, so the
   finger does not cover it.
5. `Actions`: Cancel and Apply, or Done on a sheet.

#### Techniques

- `swatches`: the `Swatches` grid of 44 by 44 cells, at most 8 in a row. A
  press on a cell proposes its colour. The chosen cell shows `Check`.
- `spectrum`: the `Plane`, the `StickHint` and the `Hue` slider. The plane is
  two native layers. `Hue` has a white-to-hue UIGradient across. `Value` has
  a black UIGradient that fades in downward. A UIDragDetector on `Surface`
  sets saturation and brightness 1:1. The hue track is a rainbow UIGradient.
- `sliders`: the `Hue`, `Saturation` and `Brightness` sliders.
- `brick`: the 128 engine BrickColors in the `BrickGrid`, and the name of the
  chosen brick in `NameField` above the grid.

The thumbs are rings with a white band between two dark lines. The opacity
track shows the colour over a checker. If the preferred input changes during
a drag of the plane, the colour returns to the start of the drag.

On a touch screen, a bubble of the colour shows above the finger during a
drag of the plane or a strip. On a gamepad, the right stick moves the plane
while `Surface` has the selection. The stick input action sinks the stick, so
a camera does not turn. The D-pad still moves the selection. `StickHint`
shows while the plane has the selection.

The fields commit typed values. `Hex` accepts `#RGB` and `#RRGGBB`. With
`alpha`, it also accepts `#RRGGBBAA`. A hex text that is not legal stays in
the field with its error, and nothing commits. A change of the readout format
never changes the colour. A grey keeps the hue that the player set.

There is no eyedropper, because Roblox cannot read a screen pixel. Put your
own Button beside the well, and call `onChange` with the colour that it
sampled.

#### Saved colours

The control keeps no colours of its own. `swatches` stays yours.

- With `onSaveSwatch`, the grid ends with a `Save` cell named "Save colour".
  It proposes the current colour. It is disabled when the list has the colour.
- With `onRemoveSwatch`, an `Edit` button toggles editing. While editing, a
  cell shows `Remove`. A press on a cell proposes its removal. Delete,
  Backspace or ButtonX on the selected cell does the same. Then the selection
  moves to the cell that takes its place.

The root Frame has these attributes: `value`, `text`, `hue`, `saturation`,
`brightness`, `mode`, `format`, `presented`, `placement`, `hexError`,
`columns`, `editing` and `diagnostics`. `ref` receives the root Frame.

### DateTimePicker

`UI.DateTimePicker(spec)` returns a Frame. The player uses it to choose a
calendar date, a date range, or a date with a time. For a count of days, use
`UI.NumberInput`. For a few fixed dates, use `UI.Picker`.

```luau
local raceDay = Compose.cell({ year = 2026, month = 10, day = 3 })
UI.DateTimePicker "RaceDay" {
    label = "Race day",
    value = raceDay,
    onChange = function(date)
        raceDay:set(date)
    end,
    min = { year = 2026, month = 1, day = 1 },
}
```

The values are civil dates. See [Civil dates](#civil-dates). A date has no
time zone, so it does not move a day where the player sees it.

- `selection`: `single` (the default) or `range`. Set it at construction.
- A single picker uses `value`, `onChange(date)` and `onCommit(date)`. A range
  picker uses `range = { start?, finish? }`, `onRangeChange(range)` and
  `onRangeCommit(range)`. The keys of the other mode cause an error.
- `time`: a single picker only. The value also has `hour` and `minute`.
  `minuteStep` is the minute grid. It must divide 60. The default is 5.
  `hourCycle` is 12 or 24. The default comes from `locale`.
- `min` and `max`: inclusive bounds, or readables of them. `isDateDisabled(date)`
  returns true for a day that the player cannot choose.
- `weekStart`: 1 (Sunday) to 7 (Saturday). The default is 1.
- `locale`: `months`, `weekdays` (short names, Sunday first), `order` (`mdy`,
  `dmy` or `ymd`), `separator` and `hourCycle`.
- `clock()`: returns today. The default is the local clock of the player.
  `referenceDate` sets the month that an empty picker opens on.
- `presets`: a range picker only. Each preset is
  `{ id, label, range = function(today) }`.
- `draft`: adds Reset all, Cancel and Apply.
- `style`: `automatic` (the default) or `inline`. Set it at construction.
  `automatic` is a field that opens a calendar panel. `inline` shows the
  calendar in place.
- `format(date)`: the words of the field. A custom `format` turns off typed
  entry. `placeholder` is the text of an empty field.
- `isPresented`, `onPresentedChange(next)` and `onDismiss(reason)`: the open
  state of the panel. The reason is `activate`, `outside`, `cancel`,
  `anchorLost` or `apply`. Without `isPresented`, the control keeps its own
  open state.
- `enabled` and `readOnly`: booleans or readables. A read-only picker can omit
  the change callback.
- The field chrome keys: `label`, `requiredMark`, `hint`, `errorText`,
  `controlSize`, `appearance` and `corners`. See
  [Field chrome](#field-chrome).

#### Proposals and commits

The value belongs to you. A pick sends a proposal to `onChange` or
`onRangeChange`. The calendar shows only the value that you then hold. If you
refuse a pick, the calendar does not change.

Without `draft`, each change commits at once. A pick, a time step and a typed
date each call `onCommit`. A single pick without `time` also closes the panel.
In a range, the first pick sets `start`. The second pick sets `finish`. If the
second day is earlier, the two ends change places. `onRangeCommit` runs only
when both ends are set. B, Escape and a tap outside close the panel and keep
the value.

With `draft = true`, only Apply commits. Typed text also only proposes. Each
other way out proposes the value that the panel opened with. Cancel does this
too. Reset all proposes an empty value. If you write the value while the panel
is open, your value becomes the value that Cancel restores.

A pointer or a finger can drag the start or the end of a complete range. Each
move proposes a new range. If the end crosses the other end, the two ends
change places. The release commits once, as the draft rules permit. A cancelled
drag proposes the range that the drag started from. A press on another day
does not start a drag, so a tap there still picks.

#### The field

The field is the `Field` plate in the field chrome. When the preferred input
is keyboard and mouse, the field holds a native TextBox named `Entry`.
Otherwise, it holds a button named `Show`. The calendar button `Open` is at
the trailing edge of the plate.

`Entry` takes the numeric form of the locale when focus leaves it. A year has
four digits. A typed range is two dates with " – " or " - " between them. If
the text is not a date, or the day is not available, the text stays. The field
shows the error in the message line and adds the `facet-invalid` tag to the
plate. Nothing commits. An empty text proposes an empty value.

The panel opens below the field, aligned to its leading edge. If there is not
sufficient room below, the panel opens above the field. The panel stays 8
pixels from the screen edges. The `CalendarSurface` ScrollingFrame holds the
calendar. It is never taller than the screen, so a tall calendar scrolls. On a touch screen narrower than 600 pixels, the
panel is a sheet at the bottom of the screen with a Done button. On a ten-foot
screen, the panel is a sheet at the center of the screen. The panel is a native
modal. A tap outside the panel, B or Escape closes it. When it closes, the
selection returns to the control that had it before.

#### The calendar

The `Calendar` frame holds these parts in order:

1. `Header`: `Previous`, the `Month` and `Year` menus, and `Next`.
2. `Panes`: `Pane1`, and `Pane2` for a wide range picker. Each pane holds
   `Weekdays` and `Days`, with 42 day buttons `D1` to `D42`.
3. `PageHint`: the page keys, only while the preferred input is a gamepad.
4. `Time`: the `Hour` and `Minute` number fields, and `Half` (AM and PM) on a
   12-hour clock. On touch, it also holds the `Times` list.
5. `Presets`: one chip for each preset, named `Preset-<id>`.
6. `Actions`: `ResetAll` at the leading edge, then `Cancel` and `Apply` in the
   `Commit` row. A sheet without `draft` shows `Done`.

A single date shows one month. A range shows two consecutive months when the
width holds them. The title of each month shows only with two months.

A day outside `min` and `max`, or refused by `isDateDisabled`, stays in the
grid. It is selectable, its label ends with "unavailable", its `Strike` line
shows, and a press does nothing. A day of the next or the previous month is
dim. A press chooses it, but it is not selectable.

The month menu disables a month outside the bounds. The year menu lists only
the years inside `min` and `max`. A side with no bound lists 100 years from
the shown year. Each menu opens with the selection on the shown month or year.
A choice moves the calendar to the nearest month inside the bounds. `Previous`
and `Next` stop at a month that is fully outside the bounds.

The day buttons use native GuiService selection. The arrow keys and the
D-pad move one day or one week. Right on the last day of a week moves to the
next day. Left and Right page the month past the first or the last day. Up and
Down move across the shown months. From the first row, Up goes to the `Month`
menu. From the last row, Down goes to the `Hour` field, else to the first
action, else to the next control below. L1, R1, Comma and Period page the
month from each day. When selection enters the grid from another control, it
goes to the chosen day, else to today.

`time` adds the `Hour` and `Minute` fields. Their step buttons follow the
minute grid. The top minute is the last step before 60. `Half` changes between
AM and PM. On touch, the `Times` list shows each time on the minute grid. It
opens at the held time, else at the time of `clock()`.

#### Native state

`ref` receives the root Frame. The root has the `facet-date-time-picker` tag
and these attributes: `month` (for example `2026-09`), `dual`, `route`
(`inline`, `popover` or `sheet`), `presented`, `text`, `typedError` and
`diagnostics`. A readable value that is not a legal date does not change the
picker. The picker keeps the last legal value, adds one to `diagnostics`, and
sends the message to the `onError` factory option.

The theme paints the calendar through these tags: `facet-calendar-day`,
`facet-calendar-band`, `facet-calendar-disc`, `facet-calendar-end`,
`facet-calendar-today`, `facet-calendar-strike`, `facet-calendar-number`,
`facet-calendar-dim`, `facet-calendar-chosen` and `facet-calendar-chosen-end`.

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

Slider shapes. `axis`, `range`, `minGap` and `thumb` are construction options.
A readable value for one of them causes an error that names the option.

- `axis`: `x` (the default) or `y`. A `y` track runs from bottom to top. Its
  arrows are Up and Down, and Left and Right do not change it. The arrow that
  moves the selection onto a slider does not also change the value.
- `range`: `value` holds `{ lower, upper }`. Each change calls
  `onChange(pair, { thumb = "lower" | "upper" })`, and each completed gesture
  calls `onCommit(pair, { thumb })` once. The two handles, `HandleLower` and
  `HandleUpper`, are 44 by 44 selection stops, and the fill spans between
  them. The handles never cross. A drag keeps the handle that it started
  with. A press on the track moves the nearer handle. For coincident handles,
  a press below the pair moves the lower one and a press above moves the upper
  one. The arrows move the selected handle and stay on it when `minGap` stops
  the move. With gamepad input, the arrows move the selection between the
  handles until ButtonA engages the handle. ButtonB releases it. A pair that
  is not legal at construction causes an error. A pair that becomes illegal
  later is not painted or written back: the control keeps the last legal pair
  and adds a line to the `diagnostics` attribute.
- `minGap`: a number from 0 (the default) to the width of the range. It is the
  least distance between the handles.
- `thumb`: `always` (the default), `auto` or `none`. `auto` shows the handle on
  hover, selection, drag and with touch input. `none` never shows it. Input
  and the readout do not change.
- `thumbContent(info)`: builds the knob once for each handle.
  `info = { thumb, value, fraction, dragging, enabled }`. `thumb` is `value`,
  `lower` or `upper`. The other four are readables. The knob has no
  `sliderThumb` art and grows from 24 by 24 to fit its content. You cannot
  use it with `thumbImage`.
- `trackContent()`: builds a track node once, for example a colour ramp. It
  replaces the rail and the fill, and fills the track. You cannot use it with
  `trackImage`.
- `rotation`: degrees, or a readable of them. It turns the painted track only.
  The control turns a press back by the same angle, so it reads the value that the
  upright track reads. The label and the readout stay upright.
- `controlSize`: `compact`, `regular` or `large`. It sets the painted track
  thickness (4, 6 or 8 pixels). The track stays 44 pixels thick as a target.

Losing the input class during a drag (a change of `PreferredInput`) restores
the value, or the whole pair, from the start of the drag. The later move and
release commit nothing.

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
`onToggle(next)` is controlled. The other options are `editing`,
`removeLabel`, `removeFocusFallback`, and native `leading` and `trailing`
children.

Removal is edit mode. A chip with both `selected` and `onRemove` requires
`editing`, a boolean or a readable boolean that you own. A chip with
`onRemove` and no `selected` is always in edit mode. Outside edit mode, a
chip only selects and shows no close mark. In edit mode, a `Remove` text mark
shows inside the one chip button, and the `AccessibleLabel` attribute is
`removeLabel` (the default is "Remove" and the label). Then activation, and
Delete, Backspace or ButtonX while the chip is selected, call `onRemove`. The
mark is not a separate button or focus stop. `onRemove` does not change your
collection. Remove the item yourself. When a selected chip is removed,
selection moves to the next removable chip, then the previous one, then
`removeFocusFallback`. A Delete or Backspace key that is still down when
selection arrives does not remove the next chip.

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
  enabled item. If an enabled selected item holds the value of its group, the
  menu selects that item instead. Back and Left close one level and return the selection to the
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
`navigationLink`, `menu` and `cards`. The `automatic` style never chooses
`cards`. The `automatic` style follows the options, the
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

Picker is a field. These options apply:

- `requiredMark`, `hint` and `errorText`: as on [TextInput](#field-chrome). The
  message line shows under the picker in each style. An error adds the
  `facet-invalid` tag to a menu trigger. The picker does not move.
- `controlSize`: the height of the menu trigger, the segments and the rows.
- `appearance`: for `menu` and `navigationLink`, `standard`, `contrast` (the
  emphasis plate) or `utility`. For `segmented`, `filled` (the default plate),
  `stroke` (the `facet-segmented-stroke` tag) or `utility` (no plate).
  `automatic` takes all five words and maps them onto the style on screen.
  `inline`, `radioGroup` and `cards` refuse `appearance`. A readable word that
  is not in the family causes an error, and the last correct paint stays.
- `corners`: `pill` or `square`, on the menu trigger or the segmented strip.
- `maxHeight`: for `menu`, `navigationLink` and `automatic`, a finite number of
  pixels above zero. It caps the open panel. The panel always shows one row.
- `indicatorPosition`: for `radioGroup` only, `leading` (the default) or
  `trailing`. It puts the radio mark on that edge of each row.

A labelled `menu` picker shows its title above a trigger at the leading edge.
A labelled `navigationLink` shows the title and the chosen value in one row
button. A searchable list marks the chosen row with a check and paints no
selection plate. Opening a menu puts the selection on the chosen row.

The `cards` style shows each option as a card with the `facet-card-option`
tag: the icon, the label, the description, `meta` and `badge`. The chosen card
has the emphasis plate. With `axis = "x"`, the cards wrap onto more lines.
With `required = false`, activating the chosen card again sets `selected` to
`nil`.

Options also take `meta` (secondary text), `sectionTitle` (a caption heading
above the option in menus and in stacked rows), `avatar = { name, image?,
userId? }` (an Avatar at the leading edge of a menu row, which adds no stop)
and `indicator = { status, form?, count? }` (a StatusIndicator that follows
the live option record). A menu row also shows `badge` as a `Badge` with a
`Count`. Menu items take the same `badge`, `meta`, `avatar` and `sectionTitle`
fields, and Menu takes `maxHeight`.

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
`{ id, height }`, never both. The `hug` entry fits the body and the pinned
regions. It measures again when the content changes, and it stays inside the
safe room and above a minimum of four target heights.

Supply a `title` and a `content` factory that returns native children. The
sheet calls the factory without arguments. Its subtree fills the body region.
The body uses a native vertical ScrollingFrame named `SheetContent`. Thus
content taller than the selected detent stays reachable, and the sheet chrome
stays fixed.

Layout options:

- `placement`: `automatic` (the default, the bottom edge), `bottom`, `center`
  or `side`. A side sheet docks to `edge` (`left` or `right`, default
  `right`). Its detents stay vertical. It slides in from its edge and leaves
  toward it. Under reduced motion it arrives and leaves at once.
- `width`: `automatic`, `narrow` or `wide`. These are the Dialog widths:
  `controls.alert.maxWidth`, `controls.popup.panelWidth` and
  `controls.dialog.wideWidth`. The safe room bounds each one.
- `header`: absent shows `title`. An Instance or a factory replaces the title.
  `false` removes the title row.
- `hero`: `{ image | content, aspectRatio | height, scaleMode?, background?,
  sticky? }`. A sticky hero stays pinned above the body. Otherwise it scrolls
  with the body. With `header = false`, the close control sits over the hero.
- `actions`: a list of `{ id, label, role?, enabled?, busy?, onActivate }`.
  They stay pinned below the body and never close the sheet. `actionLayout`
  is `automatic`, `row` or `stacked`. Cancel runs an enabled `role = "cancel"`
  action first.
- `contentInset`: `standard` (8 pixels) or `none`. It changes only the body
  padding.
- `scrollPolicy`: `always` (the default) keeps the body scrolling at every
  height. `atLargestDetent` stops the body scroll below the tallest detent.
- `closeButton`: `true` (the default), `false`, or a string or readable label
  for the close button. The default label is `Done`.

When the pinned regions and a short body do not fit the panel, every region
moves into one scrolling column named `Room`. Thus each action stays
reachable. The on-screen keyboard height comes off the room, and the panel
sits above the keyboard.

Native drag detection resizes the sheet. The grabber detector starts a drag at
once. A second detector on the panel starts a drag only after 6 pixels, or 14
pixels on touch. A release goes to the detent nearest to the released height
plus 0.15 seconds of its velocity. A hold before the release has no velocity.
A drag below 70 percent of the lowest detent dismisses the sheet. Past the
limits the drag resists. `interactiveDismissDisabled` holds the sheet near its
lowest detent and blocks Back and the backdrop. An outside detent change
during a drag ends the drag. Only one drag runs at a time.

The grabber is also a selectable button that moves to the next detent. Its
accessible label reads `Size: Medium`, and `Size: Fit` for `hug`. A bottom
sheet slides up from the bottom and slides down when it closes. See
[Motion](#motion).

### DisclosureGroup and CollapsibleView

Both require a writable `expanded` and `content`. DisclosureGroup expands its
content in the document flow. CollapsibleView opens its content as a larger
presented surface. For outer layout, use the native properties on their
returned roots.

### Callout

Callout requires a native `anchor` with a separate parent and `onRetire`. The
callout borrows the anchor. When a native ancestor of the anchor is hidden, the
callout is suspended. `seen`, `sessions`, `afterSessions`, `featureUsed` and
priority set eligibility and queue order. Each fact can be a value, a readable
or a function of `use`. Retirement is delivered once. A callout is contextual
teaching attached to a control. It is not a second application presenter.
`edge = "top"` puts the callout above the anchor. If there is no room above
and there is room below, the callout goes below the anchor. The callout
scales and fades from the edge nearest to its anchor. See [Motion](#motion).

The plate parts are optional, but the plate must show something:

- `content`: an Instance or a factory.
- `title`: a string or a bound string. It shows as a heading.
- `media`: `{ image, aspectRatio | height, scaleMode?, background? }`.
- `steps`: `{ index, count }`. It shows `index of count`.
- `actions`: one or two `{ id, label, role?, enabled?, busy?, onActivate }`.
  They replace the bottom `Got it` button. A press retires the plate with the
  reason `action`, once, also when `onActivate` fails. A disabled or busy
  action does not run.
- `closeButton`: `true` adds a close control at the top. It retires the plate
  with the reason `dismissed`.

A failure in `onShow` does not stop the plate. The failure goes to the
`onError` factory option, or to a warning.

### Dialog

`UI.Dialog` returns an empty anchor Frame. The panel is a modal surface.

```luau
local open = Compose.cell(false)
runtime.mount(function()
    return Host.ScreenGui {
        UI.Dialog "Leave" {
            isPresented = open,
            onPresentedChange = function(nextValue) open:set(nextValue) end,
            onDismiss = function(reason) print(reason) end,
            title = "Leave the race?",
            content = function() return UI.Label { label = "Your lap will not count." } end,
            actions = {
                { id = "Stay", label = "Stay", role = "cancel", onActivate = function() open:set(false) end },
                { id = "Leave", label = "Leave", role = "destructive", onActivate = function() open:set(false) end },
            },
        },
    }
end, playerGui)
```

The caller owns `isPresented`. The dialog reads it and never writes it. The
close button, Cancel and a tap on the backdrop call `onPresentedChange(false)`.
The dialog closes only when the fact changes. A refused proposal keeps the same
panel and selection. Without `onPresentedChange`, set `closeButton = false`.
Then the backdrop and Cancel do nothing.

Actions never close the dialog. Each action runs its `onActivate`. A false that
the caller accepts in that callback reports `action`. Cancel runs an enabled
`role = "cancel"` action first. Otherwise Cancel proposes false. The one
`role = "default"` action answers Return. A disabled or busy action does not
run. `onDismiss(reason)` reports each closure once, after its cleanup:
`close`, `outside`, `cancel` or `action`. The caller's own false and owner
disposal report `cancel`. A failing callback is raised after the dialog state
is consistent.

Other options:

- `title`, `actionLabel`: strings or bound strings. An empty bound title hides
  until it has text.
- `content`: a factory for the one body. The body scrolls between the pinned
  header, hero, action label and actions.
- `hero`: the shared media shape.
- `actionLayout`: `automatic`, `row` or `stacked`. `automatic` puts two short
  actions in a row and stacks three or more. A row that cannot show the full
  labels also stacks.
- `width`: `automatic`, `narrow` or `wide`.
- `contentSelectable`: `true` (the default) makes an overflowing body one
  selectable stop. With the selection on it, Up and Down scroll the body. At
  each end the selection moves on.

A dialog needs a title, content, a hero, an action label or actions. The
height is the layer height less the keyboard height and the margins. When the
pinned regions and a short body do not fit, every region moves into one
scrolling column named `Room`. The dialog has no enter or exit motion.

### Popover

`UI.Popover` returns its `trigger`, or an empty Frame for a `source` popover.

```luau
local open = Compose.cell(false)
runtime.mount(function()
    return Host.ScreenGui {
        UI.Popover "About" {
            isPresented = open,
            onPresentedChange = function(nextValue) open:set(nextValue) end,
            trigger = UI.Button { label = "About scoring" },
            maxWidth = 320,
            content = function() return UI.Label { label = "Laps score by position." } end,
        },
    }
end, playerGui)
```

Supply exactly one of `trigger` (a native GuiButton) or `source`. `source` is
`{ node = GuiObject }` or `{ rect = { x, y, w, h } }`. A trigger press, Cancel
and a tap outside call `onPresentedChange(next)`. The popover changes only when
the caller's fact changes. An open popover is modal, so a press on its own
trigger lands outside it. `onDismiss(reason)` reports each closure once:
`cancel`, `outside` or `anchorLost`. The trigger proposal uses `trigger`.

When a source node leaves the layer, the popover closes at once, proposes
false and reports `anchorLost`. It does not open again until the caller's fact
goes from false to true. A source node that is not mounted yet is not lost.
The popover waits for it and warns once. A `rect` source never draws a tail.

Placement options: `edge` (`top`, `bottom`, `leading` or `trailing`), `align`
(`start`, `center` or `end`), `gap` (pixels, default 8) and `crossOffset`
(pixels along the alignment axis). The placement tries the preferred edge,
then the opposite edge. When neither side holds the panel, it hangs beside the
source before any clamp. `maxWidth` and `maxHeight` bound the whole panel,
chrome included, inside the live safe box. The body scrolls. `tail = false`
removes the arrow.

`compact` is `sheet` (the default) or `popover`. With `sheet`, a touch player
on a layer narrower than 600 pixels gets the Sheet route. A live change of
input or width switches the route without a proposal. Only one content owner
exists at a time, and the selection returns to the same content node.

The trigger keeps its own `onActivate`. The panel scales and fades from the
edge nearest to its source. See [Motion](#motion).

### Snackbar

`UI.Snackbar` returns an empty anchor Frame. The row shows at the bottom center
of the layer.

```luau
local shown = Compose.cell(true)
runtime.mount(function()
    return Host.ScreenGui {
        UI.Snackbar "Saved" {
            isPresented = shown,
            message = "Settings saved",
            duration = 4,
            onPresentedChange = function(nextValue) shown:set(nextValue) end,
            action = { label = "Undo", onActivate = function() print("undo") end },
        },
    }
end, playerGui)
```

The caller owns `isPresented`. Close, Cancel on a selected row, a timeout and a
supersession propose false through `onPresentedChange(false)`. The row leaves
only when the fact is false. A refusal keeps the same row. `onDismiss(reason)`
reports each retirement once: `action`, `close`, `timeout`, `superseded` or
`cancel`. The caller's own false and owner teardown report `cancel`.

- `message`: a string or a bound string. It wraps.
- `icon`: an icon name or an image source.
- `action`: `{ label, onActivate }`. It runs once and never closes the row by
  itself.
- `closeButton`: `true` (the default) or `false`. A close button or a
  `duration` needs `onPresentedChange`.
- `duration`: seconds of readable time. `nil` keeps the row until the caller
  hides it. The timeout asks once, at the larger of `duration` and 2.5
  seconds. A refusal keeps the row.
- `priority`: higher rows go first. A strictly higher priority can ask the
  shown row to leave after 2.5 readable seconds, once for each row.

Readable time pauses while the row is hovered or selected, or while a modal is
open. Queued time does not count. One row shows and up to eight wait. Nine rows
can be shown, waiting or leaving. A tenth admission stops with an error. A message-only row hugs its text.
A row with an action or a close button uses `controls.snackbar.maxWidth`,
bounded by the layer. The action moves below long text. Arrival never takes the
selection. Cancel on a selected row returns the selection to the content, also
when the caller refuses. A visible row sets the `FacetInsetBottom` attribute on
its layer until it has slid out. The row slides up to enter and down to leave.
Under reduced motion it arrives and leaves at once.

To show a snackbar from code, mount a `UI.Snackbar` with `runtime.mount`. The
stop function that the mount returns releases the row and reports `cancel`.

### Notice

`UI.Notice` returns the notice Frame. It keeps a status in the page until the
state changes. It is never modal.

- `message`: required, a string or a bound string. `title` is optional.
- `severity`: `info` (the default), `success`, `warning` or `error`.
- `appearance`: `standard` or `emphasis`. `emphasis` fills the plate with the
  severity color.
- `icon`: `true` (the severity icon), `false`, or an icon name or source.
- `link`: `{ label, onActivate }`. It uses the link appearance on a standard
  plate.
- `actions`: up to two actions. Roles only paint. There is no default or
  cancel key.
- `onDismiss`: shows a close button and reports the press. Remove the notice
  yourself.
- `placement`: `inline` (the default) or `affixed`.

The link and actions sit beside the copy when the measured width holds them.
Otherwise they move below it. The notice does not take the selection. An
affixed notice fills the width and sets the `FacetInsetTop` attribute on its
layer to its bottom edge. Several affixed notices keep the deepest edge.
Content that must avoid the notice reads the attribute and pads by it.

### NavBar

`UI.NavBar` returns the bar Frame: `{ onBack?, backLabel?, title?, titleSize?,
leading?, center?, trailing?, gap?, padding? }`.

The first row holds Back, `leading` and a `center` that fills the remaining
width. Without `center`, the title shows on one line and truncates. `trailing`
is one GuiObject. Put a cluster in a Frame. When the center would fall under
`controls.popup.panelWidth`, the trailing node moves to a second row. The
center is not rebuilt, so a search field keeps its text. Back shows the
`chevron.leading` icon. `gap` and `padding` are pixels or `space` metric
names.

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
engagement. It requires `title` and `image` (nonempty strings or readables).
`artwork` can replace `image`. The other options are `caption`,
`imageAspectRatio` (default `16/9`),
`imageFraming` (`fit` or `crop`), `onActivate`, `primaryAction = { label,
icon?, onActivate, enabled?, busy? }`, `menu = { items, label? }`, `reveal`
(`automatic` or `always`), `browseTarget`, `enabled` and `controls`.

Use a Card for a game, a track or a kart, where the picture helps the player
choose. For rows of text, use VirtualList or Table.

- The artwork frame is as wide as the card. Its height is the measured card
  width divided by `imageAspectRatio`.
- `artwork` is a factory that returns a GuiObject, such as a `Stage` preview.
  The card mounts it once in the artwork frame and sizes it to fill the frame. With `image`, the image shows under the
  artwork. The card owns the artwork and releases it with the card.
- With `onActivate`, the body is a Button. `onActivate(input)` receives the
  native input of the activation, or `nil`. Without it, the body is plain
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

In `multi` mode, the selection keys are the same in Table, VirtualList and
VirtualGrid:

- A plain mouse click selects only that row.
- Ctrl-click or Cmd-click adds the row to the selection or removes it.
- Shift-click selects the rows from the anchor to the clicked row. The anchor
  is the last row that a click without Shift selected. A second Shift-click
  makes the range again from the same anchor. Rows that you added with
  Ctrl-click before the anchor stay selected.
- A touch tap, a gamepad press and a plain Return add the row or remove it.
  Return with Ctrl, Cmd or Shift follows the click rules.
- Shift with an arrow key, Home or End moves the focus and selects the range
  from the anchor to the focused row. Without an anchor, the focused row
  becomes the anchor.
- An arrow key without Shift moves the focus and does not change the
  selection.

In `single` mode, each activation selects only that row, and the modifiers
have no effect. Rows that `selectable` or `disabled` refuse are never selected.

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

A mouse click or a touch outside an open row closes its tray. The row observes
`UserInputService.InputBegan` only while its tray is open, and it does not
consume the input. Thus the control under the pointer also receives the press.
A press inside the row, which includes its tray, does not close the tray. A
press during a destructive commit does not stop the commit. The check uses the
row bounds on a ScreenGui, with the top bar inset when the ScreenGui ignores
it. A row on a SurfaceGui or a BillboardGui does not close from an outside
press.

## Media and status

| Control | Main contract |
|---|---|
| `Label` | `text` or `label`, icon and iconPosition, textRole and role, `truncate`, `textSize`, and native text properties. `textRole` is one of `TYPE_ROLES`. Another value causes an error. Without an icon, it returns a TextLabel. With an icon, it returns a Frame row that holds the icon and a TextLabel. Native properties then apply to that Frame, so give it Frame properties only. See [Label text fit](#label-text-fit). |
| `Badge` | `label`, `status`, an optional icon and position, appearance, corners and control size. The icon and the label share one pill. The status appearance keeps a neutral pill and shows the status as a leading dot. |
| `StatusIndicator` | `status`: `neutral`, `info`, `success`, `warning`, `error` or `accent`. `form`: dot, ring, square or dash. Optional `count`, `max`, `diameter` and `name`. The `name` sets the accessible label. A ring is a native inner stroke in the status color. A count grows into a pill that is never narrower than it is tall. |
| `ProgressView` | `value`, `min` (0), `max` (1). `presentation`: bar, circular or spinner. label and endLabel, showValue and format, diameter, thickness, segments, and an optional trail `{ delay, duration }`. The endLabel shows after the value. With a label, a bar shows the value and the endLabel on the label row. Segments require the bar presentation. Diameter requires circular or spinner. A trail holds on damage, settles over its duration, and snaps on healing or reduced motion. A circular value is centered when the native text bounds fit. Otherwise it shows below the ring. A circular ring with no thickness uses 8 percent of its diameter, and not less than the theme metric. |
| `Skeleton` | A loading placeholder with a configurable form and line count. |
| `AsyncImage` | An image or source, an optional resource or loader, a placeholder, a failure label and a status callback. `imageProperties` forwards native properties and children to the inner ImageLabel. |
| `Avatar` | `name`; image, userId or resource; loader and onStatus; presence online, away, busy or offline; presence label and mark; diameter or controlSize; standard or icon form; optional activation. |
| `AvatarGroup` | `items` with id, name, image, userId and presence, and an optional `resource` shared-resource acquire function. max (4); stacked or spread layout; count or ellipsis overflow; onOverflow; diameter or controlSize. A stacked group has the `facet-avatar-stack` tag, and the theme draws a surface ring around each face. |
| `Stage` | A native ViewportFrame. A `camera` CFrame or a borrowed Camera, `fieldOfView`, and `content(runtime, world)` for 3D content that Compose owns. |

### Label text fit

`truncate = "end"` sets the native `TextTruncate.AtEnd`. `truncate = "middle"`
keeps the start and the end of the value and puts an ellipsis between them,
for example `Coastal circui…lap 14`. Use it when the end identifies the value,
such as a file name, a path or an id.

- The label is one line. It fills the width and hugs the height by default.
  `TextWrapped = true` or `RichText = true` with `truncate = "middle"` causes
  an error.
- The label measures each candidate with the engine `TextBounds` of the label
  itself, so the measurement uses the painted face and size. A cut never
  divides a UTF-8 character. When the value fits, the label shows all of it.
  When no character fits, it shows only the ellipsis.
- The label cuts the value again when the value, the width, `TextSize` or
  `FontFace` changes. It does not measure on other changes. Before the label
  has a width, it shows all of the value.

`textSize = "fit"` sets `TextScaled` and adds a `UITextSizeConstraint`. The
engine then paints the largest size that fits the box of the label. The
default box fills its parent. `textSize = { fit = { cap = size, floor = size } }`
sets the band. A size is a pixel number or a type role name. The default `cap`
is the `textRole` of the label, or `body`. The default `floor` is `caption`.
Role sizes come from the theme package and follow a theme change. Another
`textSize` value, or another key in `fit`, causes an error.

The AsyncImage loader receives `(source, resolve, reject)`. It can return a
cancellation. A superseded result cannot replace the current image. Loading and
failure stay observable. The control does not invent successful assets.
Resource lifetime uses Compose ownership and shared resources.

The Stage content callback mounts into its WorldModel. It can return a teardown
function. Use the `Host.Part`, `Host.Model` and other native constructors of the
same runtime. A 3D view inside a UI rectangle is not the same as 3D UI layout.

### badged

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

- `neutralPackage()` returns a mutable copy of the neutral theme package. It
  declares two palettes, `Dark` (the default) and `Light`. Both palettes pass
  the contrast gate of `define`.
- `define(definition)` derives from `base` (neutral by default) and returns
  `package?, report`. Check `report.ok` before use. An accepted theme package is
  recursively frozen. Callbacks, cycles and malformed definitions are rejected.
  A type role needs a positive size. Each `metrics.space` step needs a pixel
  size of 0 or more. A chrome shadow name must be a
  package shadow or a preset (`raised` or `overlay`). Each palette pair needs a
  contrast of at least 4.5:1, which includes `onSelected` (or `content`) on
  `controlSelected`.
  Color channels and semantic contrast pairs are validated. A package that
  does not declare `style.themes` gets only the first palette of its base. Thus
  a package derived from Neutral has one palette unless it declares more.
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

## Civil dates

`Facet.civilDate` is the calendar that `UI.DateTimePicker` keeps its values in.
A `CivilDate` is `{ year, month, day, hour?, minute? }` in no time zone. A
`CivilRange` is `{ start?, finish? }`.

- Arithmetic: `isLeap(year)`, `daysIn(year, month)`, `toDays(d)` and
  `fromDays(n)` (days from 1970-01-01), `dateOf(d)` (the date without its
  time), `addDays(d, n)`, `addMonths(d, n)`, `compare(a, b)` (by date),
  `same(a, b)` (every field), `weekday(d)` (1 is Sunday),
  `monthGrid(year, month, weekStart)` (six weeks of dates),
  `within(d, min?, max?)`, `clampRange(range, min?, max?)` and
  `problem(d, withTime?)`. `addMonths` clamps the day: January 31 plus one
  month is the last day of February. `clampRange` returns `nil` when the range
  is fully outside the bounds. `problem` returns why a value is not a date, or
  `nil`.
- Words: `format(d, locale?)`, `formatTime(d, hourCycle)` and
  `parse(text, locale?, withTime?)`. They use the numeric order of the locale.
  `parse` returns two values, `(date?, why?)`. Test the date before you use it.
  A year has four digits. On a 12-hour clock, an hour from 1 to 12 needs AM or
  PM. `ENGLISH` is the default locale: `months`, `weekdays` (Sunday first),
  `order` (`mdy`, `dmy` or `ymd`), `separator` and `hourCycle`.
- Instants: `fromUnix(seconds, offsetMinutes)` and
  `toUnix(date, offsetMinutes)` always name their offset. There is no zone
  database. Convert a zone with daylight time to a fixed offset yourself.
  `systemClock(offsetMinutes?)` returns the default clock: the local date and
  time of the player, or the engine clock at the offset that you name.

```luau
local civil = Facet.civilDate
local start = { year = 2026, month = 2, day = 27 }
print(civil.format(civil.addDays(start, 3))) -- "03/02/2026"
local date, why = civil.parse("02/30/2026")
if date == nil then
    print(why)
end
```

## Recipes

`Facet.recipes.arithmetic.parse(text)` returns a finite number or `nil` for
any value. Give it to a number field as `parse`. It accepts `+`, `-`, `*`, `/`,
parentheses, the typographic signs `×`, `÷` and `−`, and blanks. It refuses a
division by zero, an exponent, a hex number, more than 256 characters and more
than 32 levels of nesting. It never compiles the text.

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
