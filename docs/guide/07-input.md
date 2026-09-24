# Input and focus

## Mechanisms

These native mechanisms do the input work:

- GuiButton activation,
- TextBox editing,
- native InputContext and InputAction bindings,
- GuiService selection,
- UIDragDetector.

Compose owns their Instances and subscriptions. Facet supplies the control
eligibility and the interaction policy. Input contexts are siblings under a
native host. Do not nest them.

## Modal controls

A modal control:

- traps all native selection directions,
- selects an enabled initial item,
- owns the Back input,
- restores the previous selection if that object still exists.

The `GuiButton.Modal` property affects mouse locking. It is not a focus trap.

## Text input

TextInput keeps user edits separate from model synchronization. The engine owns
IME, the caret and the text selection. The control owns validation, numeric
bounds, and the change, commit and cancel behavior. An external model write
does not send an edit callback.

## Virtual collections

Virtual controls keep logical focus with Compose keys. They scroll through the
collection controls. They restore `GuiService.SelectedObject` when the
requested row exists. Keyboard and gamepad traversal must not depend on every
item being mounted.

## World surfaces

World-fixed UI is a flat two-dimensional SurfaceGui. Facet does not add VR,
gaze input, hand input or declarative three-dimensional layout. See
[native targets and boundaries](../reference/api.md#native-targets-and-boundaries).
