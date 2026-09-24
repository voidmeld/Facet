# Custom themes

A game-owned theme package supplies semantic colors, typography, metrics, icons
and optional artwork. Facet compiles the theme package into native StyleRules.
A StyleLink applies those rules to the target tree. To change the look, change
the theme package. Do not add repeated paint overrides to each screen.

## Define and validate

1. Start from the neutral theme package.
2. Change the named values.
3. Validate the complete definition.

RGB values in a theme package use normalized channel tables. Native code still
uses Roblox datatypes for explicit properties.

```luau
local definition = Facet.themes.neutralPackage()
definition.identity.id = "my-game"
definition.identity.displayName = "My Game"
definition.metrics.controlSizes.regular.height = 48
definition.metrics.typography.title.size = 28
local package, report = Facet.themes.define(definition)
assert(report.ok, "Invalid game theme")
```

If validation fails, `define` returns `nil` and a report. It validates the RGB
channels and the semantic foreground and background contrast pairs. A
successful numeric contrast check does not prove that every image background or
selected state is readable. Examine the actual controls in Studio.

A theme package contains these fields:

| Field | Content |
|---|---|
| `identity` | Stable id, display name, version and schema metadata. |
| `style` | `defaultTheme` and the named palette array `themes`. |
| `metrics` | Typography, spacing, corner radii, control sizes and control-specific measures. |
| `icons` | Semantic icon names mapped to image content or declared assets. |
| `assets` | Art declarations with content ids and optional slice geometry. |
| `chrome` | Native or image-based skin recipes for semantic control slots. |
| `rules` | Additional native `{ selector, properties }` rules. |

Each palette has `name`, `colors` and `extra`.

- The main color roles include surfaces, content, accent, and the semantic
  success, warning and danger pairs.
- The extras hold the hover, pressed, selected and secondary-content values.
- The required type roles are caption, label, body, heading, title, control,
  strong and numeral.

The [API reference](../reference/api.md#themes) lists every color name.

## Apply and switch

Give the same theme package readable to the controls and to the StyleSheet.
`controls` uses it for metrics, icons and artwork. The StyleSheet supplies the
native paint. Make and parent the sheet inside the screen owner, as
[Styling](05-styling.md) describes.

```luau
local selectedPackage = Compose.cell(package)
local selectedPalette = Compose.cell(package.style.defaultTheme)
local UI = Facet.controls(runtime, { theme = selectedPackage })
local function Screen()
    local sheet = Facet.themes.createStyleSheet(runtime, selectedPackage, {
        theme = selectedPalette,
    })
    return Host.ScreenGui {
        sheet,
        Host.StyleLink { StyleSheet = Compose.static(sheet) },
        UI.Button { label = "Continue", onActivate = onContinue },
    }
end
```

Explicit Instance paint properties override the native stylesheet paint. Set
them only when the screen needs that override.

Keep native sizing in the layout of the screen. `controlSizes` and typography
feed the control measurements and paint. Spacing values are theme package data
for your native layout declarations. A change to `space.m` alone does not
change the UIPadding or UIListLayout of a screen.

## Coverage and icons

`checkCoverage(package, needs)` accepts a list of requirements. For example:

- `{ kind = "color", name = "accent" }` checks each palette.
- `{ section = "metrics.typography", name = "body", fields = { "size" } }`
  checks numeric fields.

The report lists the covered entries and the missing entries.

Icons resolve through `themes.resolveIcon`. Supply real image or vector image
assets. Do not use arbitrary text glyphs as interface icons. An image
declaration does not prove ownership or successful loading. Keep the asset
provenance with the theme package. Verify the images at native scale in the
running application.

See [rich skinning](10-rich-skinning.md) for artwork and the
[theme catalog](13-theme-catalog.md) for the maintained theme packages.
