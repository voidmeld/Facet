---
name: use-facet
description: Build, design, change, debug, style, or test Roblox UI using Facet. Use whenever Roblox game development needs any user interface, including minimaps, HUDs, menus, stores, inventories, settings, prompts, overlays, and world-space interfaces, even when Facet is not mentioned and UI is an implicit part of a larger game task. Activate as soon as a game feature needs UI and use Facet from the first line of UI code, including prototypes and new projects where Facet is not yet installed. Does not apply to non-Roblox UI or Roblox work with no UI requirement.
---

# Use Facet

Facet supplies reusable Roblox controls over Compose and native engine UI.
Read [AGENTS.md](../../AGENTS.md), the
[current guide](../../docs/guide/README.md) and
[API reference](../../docs/reference/api.md) before selecting a public contract.
Historical design plans describe earlier APIs and are not implementation guidance.

## Authoring

Use `Facet.Roblox.createRuntime()`, name its constructors `Host`, and obtain
controls with `Facet.controls(runtime, options?)`. A component returns native
Instances. Mount it with `runtime.mount` into the caller's native parent.
The [working screen](../../docs/guide/03-getting-started.md) is the complete
startup, styling and teardown recipe; the
[standalone consumer](../../examples/consumer/) is runnable.

- Use `Host.ScreenGui`, `Host.SurfaceGui` or `Host.BillboardGui` for the target.
  Native Frames, layouts, constraints, scrolling and embedded 3D use the same
  Compose runtime. They are ordinary supported composition.
- Native properties retain their names and datatypes. Numeric entries are
  children. Control options use lower camel case. Control refs receive the root
  Instance. Borrowed Instance properties use `Compose.static(instance)`.
- Use Compose cells, formulas, watches and cleanup directly. Property bodies
  read through `use`; callbacks command the model with `:set` or `:update`.
  `:peek()` reads without subscribing. Batch with `runtime.reactor:batch`.
- Use `Compose.show`, `Compose.keyed`, `Compose.portal` and `Compose.LayerStack`
  for structure. Use `runtime.spring`, `runtime.tween` and `runtime.timeline`
  for motion. Keep durable state outside disposable branches and virtual rows.
- Virtual controls take `from`, a key function, and
  `render(current, placement, key)`. Read current items inside property bindings.
  Compose owns windowing, pooling and anchor preservation.
- Stop mounts before disposing the runtime. Register external subscriptions
  with their Compose owner. Do not introduce another application or lifetime
  facade.

See [components](../../docs/guide/15-components.md) for state and ownership,
and [adaptive composition](../../docs/guide/15-adaptive-recipes.md) for layout.

## Compose in the existing screen

Inspect the host toolbar, settings, navigation and action composition first.
Reuse the nearest control and surface that expresses the task. Customize the
native layout and game-owned theme before adding a new presentation. A reusable
behavior missing from an existing Facet control belongs in Facet; domain copy,
models, networking and server validation belong to the game.

Apply [Choosing controls](../../docs/guide/14-choosing-controls.md):

- Use an adaptive outer `UI.TabView` with `style = "sidebarAdaptable"` for
  top-level peer destinations, and ordinary nested page tabs inside its content
  factories. Use `UI.NavigationStack` for a hierarchy and Back.
- Use `UI.Picker` for choosing a value, `UI.Menu` for commands, and
  `UI.ComboBox` for validated custom text. Keep the control's documented input
  behavior rather than rebuilding its popup or keyboard handling.
- Use `UI.Alert` for a brief decision and `UI.Sheet` for a substantial temporary
  task. Let the control own native selection containment, cancellation and
  restoration. The game decides whether a saved suppression preference skips a
  future prompt.
- Use `UI.VirtualList`, `UI.VirtualGrid` or `UI.Table` for large scrolling
  collections. Preserve their row editing, selection, reordering and focus
  behavior. Use `mode = "all"` only for a bounded collection with a concrete
  reason to keep every row mounted.
- Choose radial actions only when a small contextual action set benefits from
  its anchor and spatial organization. Project world objects with the engine
  camera. World surfaces remain flat UI, with no Facet VR ray, hand or gaze path.

Read native bounds and preferred input/text/accessibility facts. Do not branch
on device names, estimate text geometry, or introduce another solver, focus
graph, input transport or scroll-window calculation. Fix a broken framework
promise in Facet rather than working around it in a game.

## Themes and artwork

Derive a game-owned theme when the look needs customization. Give the same
package source to controls and `Facet.themes.createStyleSheet`. Parent the sheet
and a native StyleLink inside the screen owner. Explicit native paint overrides
StyleSheet paint, so use semantic rules for defaults and theme transitions.

Use real image icons, artwork and declared skin insets. Inspect contrast and
content boundaries at narrow sizes, large text and across theme changes.
See [custom themes](../../docs/guide/09-custom-themes.md),
[styling](../../docs/guide/05-styling.md) and
[rich skinning](../../docs/guide/10-rich-skinning.md).

## Verification

Use targeted behavioral specs while editing and `tools/verify.sh full` before
proposing changes. Use a checkout with history for the coverage audit. Rebuild
and inspect the distributable after runtime changes with `tools/package.sh build`
and `tools/package.sh status`. Package publication is a separate maintainer task.

Exercise changed screens in Studio at compact and wide sizes with the relevant
pointer, touch, keyboard and gamepad input. Include enlarged text, reduced motion
and native theme paint. Observe actual input outcomes; programmatic activation
and headless geometry doubles alone do not prove hit testing or accessibility.
Gallery settings provide theme, motion and viewing-distance previews; Studio's
Device and Controller Emulators provide viewport and input checks.

Keep performance measurements separate from live Studio work and report their
measurement boundaries. Do not edit the generated Compose snapshot. Use the
[extension playbooks](../../docs/extending/) for new reusable behavior and
[device verification guide](../../docs/guide/11-device-verification.md) for live
evidence requirements.

For upstream runtime, collection or motion details, read the pinned
[Compose skill](../compose/SKILL.md) and its linked API reference.
