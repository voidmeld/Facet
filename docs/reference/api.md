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

### Types

The exported Luau types include `Controls`, `ControlOptions`, `ThemePackage`,
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
It does not become inert metadata.

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
- `reducedMotion` and `icons`: these can also be reactive.
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
- `corners`: `pill` or `square`.
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

### Toggle

`value` is a boolean source. `onChange(next)` requests a new value. Without it,
the control updates the writable cell. `presentation` is `switch`, `checkbox` or
`button`. The checkbox presentation supports `mixed`. `indicatorPosition` is
`leading` or `trailing`. The label, row, hint, enabled and common button styling
options apply.

### TextInput

`value` is the string model. Roblox TextBox owns editing, IME, the caret, the
text selection and focus. `onChange(text)` handles user edits. An external
model update does not send it. `onCommit(text, reason)` receives `submit` or
`focusLost`. `onCancel` observes cancellation and the restoration of the initial
value of the edit.

`presentation` is `plain`, `search` or `number`. The number presentation also
uses a writable `numericValue`, `min`, `max`, `parse` and `format`.
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
`allowZero` (default true), `readOnly`, `enabled` and `onChange`.

- Rating supports `glyphs = { filled, empty }` and `starSize`.
- LevelPicker supports `segment` (`bar`, `glyph` or `image`), `segmentSize`,
  `glyphs`, `images` and `tint` filled and empty pairs.

The named sizes are `small` (20), `medium` (28) and `large` (36).

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

SplitButton combines a primary `label` and `onActivate` action with the
secondary `items` of the menu. Use it when the secondary operations supplement
one clear primary action.

### Picker

Picker requires a writable `selected` and `options`. Each option has `value` and
`label`, and an optional `id`, `icon` and `enabled`. Options can be a plain
array or a readable.

The styles are `automatic`, `segmented`, `inline`, `radioGroup`,
`navigationLink` and `menu`. The `automatic` style follows the native
PreferredInput:

- If you supply `query`, it uses the navigation-link presentation.
- For keyboard and mouse, and for touch, it uses a menu.
- For other input, it uses `segmented` for four options or fewer, and `inline`
  for larger sets.

`onChanging(next, previous)` can return `false` to veto a change. The control
writes `selected`, and then calls `onChange(next)`. An optional writable `query`
filters the labels. The other options include `label`, `placeholder`, `axis`,
`sizing`, `iconOnly`, `textSize`, `valueAlignment`, `isPresented` and `enabled`.

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

Native drag detection resizes the sheet between the declared detents.
`interactiveDismissDisabled` blocks gesture dismissal. The explicit Close
action stays available.

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
`render(current, placement, key)`. `key` is a function. If you omit it, Compose
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
| `follow` | The Compose `none` or `end` policy, with an optional `followThreshold`. |
| `status` | An optional writable Compose collection status cell. |
| `controls` | An optional table that the control fills with the Compose `indexOfKey`, `placementOf` and `offsetOf`. |
| `maxRetained` | The pool keeps at most `32` row hosts by default. |

The returned root is a ScrollingFrame. Compose `OrderedCollection` owns
indexing, window selection, anchor preservation and placement. The control
applies its desired offset to `CanvasPosition`. Sorting keeps the native anchor.
It does not force the first item to the top.

`snap = "item"` settles scrolling to the Compose placement boundaries. The
default is `none`. `follow` is a static Compose option. To change its policy,
replace the collection owner through `Compose.keyed`.

Optional collection focus uses `focus`, `initialFocus`, `autoFocus`,
`wrapFocus` and `disabled(item)`.

- `selection` is a writable key-set map.
- `selectionMode` defaults to single when you supply `selection` or its
  callback. Otherwise it defaults to none.
- `onSelectionChange(nextMap)`, `onActivate(item, key)` and `onReachEnd`
  connect control events to domain behavior.
- `selectable(item)`, `reorderable`, `movable(item)`, `dragLabel` and
  `onReorder(keys, insertionSlot)` use the same zero-based insertion contract
  among the remaining rows as Table.

Native properties and children stay available.

```luau
local rows = Compose.cell({ { id = "a", title = "Amber" } })
local list = UI.VirtualList {
    from = rows,
    key = function(item) return item.id end,
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

`from`, `key` and `columns` define the rows. A column has:

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

`selectable(item)`, `disabled(item)`, `onActivate(item, key)` and
`rowActions(current, key)` specialize rows. `reorderable`, `movable(item)` and
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
A shared `coordinator` cell lets only one row be open.

Native swipe, context, and keyboard and gamepad actions reach the same
commands. A destructive action runs exactly once, after its Compose departure
animation. If the owner is removed, an unfinished departure is cancelled.
`reducedMotion`, `enabled` and `editing` stay explicit control options.

## Media and status

| Control | Main contract |
|---|---|
| `Label` | `text` or `label`, icon and iconPosition, textRole and role, and native text properties. Returns a TextLabel. |
| `Badge` | `label`, `status`, an optional icon and position, appearance, corners and control size. |
| `StatusIndicator` | `status`: `neutral`, `info`, `success`, `warning`, `error` or `accent`. `form`: dot, ring, square or dash. Optional `count`, `max` and `diameter`. |
| `ProgressView` | `value`, `min` (0), `max` (1). `presentation`: bar, circular or spinner. label and endLabel, showValue and format, diameter, thickness, segments, and an optional trail `{ delay, duration }`. Segments require the bar presentation. Diameter requires circular or spinner. A trail holds on damage, settles over its duration, and snaps on healing or reduced motion. A circular value is centered when the native text bounds fit. Otherwise it shows below the ring. |
| `Skeleton` | A loading placeholder with a configurable form and line count. |
| `AsyncImage` | An image or source, an optional resource or loader, a placeholder, a failure label and a status callback. `imageProperties` forwards native properties and children to the inner ImageLabel. |
| `Avatar` | `name`; image, userId or resource; loader and onStatus; presence online, away, busy or offline; presence label and mark; diameter or controlSize; standard or icon form; optional activation. |
| `AvatarGroup` | `items` with id, name, image, userId and presence, and an optional `resource` shared-resource acquire function. max (4); stacked or spread layout; count or ellipsis overflow; onOverflow; diameter or controlSize. |
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
`numeral`.

- `neutralPackage()` returns a mutable copy of the neutral theme package.
- `define(definition)` derives from `base` (neutral by default) and returns
  `package?, report`. Check `report.ok` before use. An accepted theme package is
  recursively frozen. Callbacks, cycles and malformed definitions are rejected.
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
