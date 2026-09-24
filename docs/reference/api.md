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
and the `Props` and `Spec` contracts of each control. `Cell<T>`, `Readable<T>`,
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
- `pressHaptic`: a native `HapticEffect`. Each button that has no
  `PressHapticEffect` uses it as its native `PressHapticEffect`. Thus buttons,
  segments and toggles play the effect when they are pressed.
- `controlSize`: the control-size step (`compact`, `regular` or `large`) for
  theme icons.
- `onError`: receives a failure from the content of a presented Alert. The
  alert dismisses.
- `services`, `guiService`, `userInputService` and `types`: native dependencies.
- `inputParent` and `overlayParent`: placement targets.

The `theme` option does not install paint. Parent a `createStyleSheet` result
and its StyleLink in the native tree, with the same theme package source.
Ordinary Roblox consumers use the ambient services and datatypes. The runtime
that you supply must use the Compose Roblox host.

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
- `shape`: `rect` or `circle`.
- `icon` and `trailingIcon`.
- `image`, `imageAspectRatio` (default `16/9`) and `imageFraming` (`fit` or
  `crop`).
- `subtitle` and `row = { title, description, value, icon }`. A row button
  fills its width. It shows `icon` on the leading edge, the title and the
  description, and `value` as secondary text on the trailing edge. When the
  button has `onActivate` and no `trailingIcon`, it also shows a disclosure
  chevron. `value` and `icon` are static strings. `hint` shows as a second
  line of text below the label.
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

Native fades accept direct Compose tween options, such as
`transition = { seconds = 0.18, ease = Compose.easing.outQuad }`. Use `false`
to disable motion. Named Facet transition presets do not exist.

### NavigationStack

NavigationStack requires a writable `path`, `root` and `destinations`. The path
is an array of `{ id, value }` entries. `root` and each `destinations[id]` are
`{ title, content }`. Destination content receives the entry.

- To push, append an entry.
- To pop, remove the last entry.

`backLabel` sets the text of the native Back chrome. Compose `LayerStack` owns
the retained pages and their disposal.

### PageView

PageView requires a writable `selection` and `pages` with unique ids and
content factories. It supplies page navigation, indicators, and previous and
next actions. Use it for a sequential set of peer pages. TabView is for named
destinations. NavigationStack is for a drill-down path.

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
- Without `transition`, the presentation is immediate.

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
The Done action stays available.

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
delivered once. A callout is contextual teaching attached to a control. It is
not a second application presenter.

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
| `gap`, `crossGap` | `0`; the cross gap defaults to the gap. |
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
| `StatusIndicator` | `status`: `neutral`, `info`, `success`, `warning`, `error` or `accent`. `form`: dot, ring, square or dash. Optional `count`, `max` and `diameter`. A ring is a native inner stroke in the status color. A count grows into a pill that is never narrower than it is tall. |
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
  A type role needs a positive size, and a chrome shadow name must be a
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
