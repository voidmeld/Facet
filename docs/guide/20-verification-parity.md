# Verification parity with main

This page compares the verification of the native cutover (PR22) with the
verification on `main`. It compares test assertions, not file names. It
also compares the verification producers. The data is in
[`tools/lune/verification_parity.json`](../../tools/lune/verification_parity.json).
[Verification scope](18-verification-scope.md) records the earlier,
file-level audit.

## Result

Verification on the candidate is weaker than on `main`. The candidate does
not verify some behavior that it still promises. The sections below show
where.

- 894 main cases test behavior that `api.md`, a guide or `src`
  still promises, but no candidate case tested it. This audit adds tests
  for 56 of these cases. 838 cases remain.
- 1,679 of the 2,350 covered cases have a weaker
  candidate assertion. Usually one candidate case replaces several main
  edge cases.
- 1,581 cases moved to a Roblox Engine or Compose mechanism. For about
  845 of them, no candidate test and no live Studio record show that
  Facet uses the mechanism correctly.
- Of 130 main `full` producers, 39 have no replacement although
  their subject still exists.
- The release gate cannot pass. No producer writes
  `artifacts/verify/latest-release.json`, so `tools/package.sh publish`
  refuses with `gate-evidence-missing`. This fails closed.
- The audit found 10 open defects in `src` and
  3 in the examples.

## Method

1. Load `tests/run.luau` at the baseline with registration recorded and
   execution suppressed. This gives 10,848 cases in 500 spec files.
2. Read each main spec. Group its cases into behavioral contracts. A
   contract is a behavior that a game author can rely on.
3. Classify each contract against the candidate tests, `api.md`, the guides
   and `src`.
4. Open each cited candidate case and confirm its assertion. Do not trust
   the candidate coverage ledger.
5. Probe the reported defects again at the recheck commit.

| Item | Value |
|---|---|
| Baseline | `a8c8895673c0745506908b66dc89f8cead6b66f3` |
| Candidate audited | `131e9dc7` |
| Candidate rechecked | `eddfa580` |
| Main cases | 10,848 |
| Contracts | 2,290 |
| Candidate cases at recheck | 675 |

Another session changed `src` during the audit. Some defects were fixed
during the audit. [Fixed during the audit](#fixed-during-the-audit) lists
them. A gap can also close after the audited commit. Check the gap against
the current tests before you write a test.

## Classes

| Class | Meaning | Contracts | Main cases (audit) | Main cases (with new tests) |
|---|---|---:|---:|---:|
| a | Covered by a candidate case | 805 | 2,294 | 2,350 |
| b | Retired. The Roblox Engine or Compose owns the mechanism | 306 | 1,581 | 1,581 |
| c | Retired. The feature or code was deleted and is not promised | 822 | 6,079 | 6,079 |
| d | Gap. A promise remains and no candidate case verifies it | 357 | 894 | 838 |

Class c is the largest class. Most of it tested the deleted solver,
renderer, focus graph, input system, presenter, paint layer and their seams.
Those checks cannot run against the native implementation. Their retirement
is correct when the public API no longer makes the promise.

## Contract groups

"Weaker" counts the covered cases with a weaker candidate assertion. The
last column names the candidate specs that the group cites most.

| Group | Main cases | a | Weaker | b | c | d | Candidate coverage |
|---|---:|---:|---:|---:|---:|---:|---|
| Reactive core | 63 | 22 | 16 | 4 | 36 | 1 | `native_compose_contract`, `native_public_surface`, `native_navigation` |
| Lifetime and ownership | 316 | 123 | 103 | 6 | 168 | 19 | `native_conformance`, `native_stress`, `native_themes_media` |
| Layout and geometry | 1,326 | 71 | 58 | 359 | 872 | 24 | `native_inputs`, `native_navigation`, `native_themes_media` |
| Text measurement and fit | 497 | 44 | 38 | 232 | 202 | 19 | `native_inputs`, `native_collections`, `native_text_preference` |
| Focus and selection | 532 | 76 | 47 | 257 | 172 | 27 | `native_navigation`, `native_collections`, `native_inputs` |
| Input actions | 332 | 66 | 41 | 105 | 121 | 40 | `native_inputs`, `native_navigation`, `native_collections` |
| Pointer, touch and drag | 368 | 57 | 47 | 97 | 208 | 6 | `native_collections`, `native_radial_controls`, `native_virtual_monitors` |
| Scrolling | 330 | 75 | 59 | 100 | 137 | 18 | `native_collections`, `native_gallery_collections`, `native_virtual_monitors` |
| Motion | 581 | 118 | 80 | 33 | 404 | 26 | `native_themes_media`, `native_navigation`, `native_inputs` |
| Paint and theming | 709 | 98 | 67 | 70 | 440 | 101 | `native_themes_media`, `native_inputs`, `native_navigation` |
| Theme packages | 379 | 85 | 68 | 0 | 233 | 61 | `native_themes_media`, `native_inputs`, `native_gallery_shell` |
| Icons and media | 251 | 86 | 66 | 37 | 98 | 30 | `native_themes_media`, `native_stress`, `native_public_surface` |
| Action controls | 394 | 61 | 57 | 1 | 297 | 35 | `native_inputs`, `native_navigation`, `native_themes_media` |
| Value controls | 249 | 171 | 128 | 0 | 28 | 50 | `native_inputs`, `native_themes_media`, `native_navigation` |
| Text input | 119 | 51 | 26 | 28 | 21 | 19 | `native_inputs`, `native_navigation`, `native_collections` |
| Menus and pickers | 141 | 80 | 53 | 0 | 37 | 24 | `native_navigation`, `radial_geometry`, `native_collections` |
| Navigation containers | 72 | 50 | 36 | 1 | 2 | 19 | `native_navigation`, `native_gallery_shell`, `native_radial_controls` |
| Presented surfaces | 287 | 105 | 81 | 5 | 158 | 19 | `native_navigation`, `native_gallery_parity`, `native_gallery_workflows` |
| Virtual collections | 214 | 151 | 127 | 3 | 52 | 8 | `native_collections`, `native_gallery_collections`, `native_perf_principles` |
| Tables | 156 | 76 | 40 | 1 | 58 | 21 | `native_collections`, `native_gallery_workflows`, `native_gallery_collections` |
| Row actions | 264 | 121 | 101 | 0 | 112 | 31 | `native_collections`, `native_gallery_workflows`, `native_gallery_collections` |
| HUD and world targets | 166 | 43 | 34 | 50 | 70 | 3 | `native_hud`, `native_themes_media`, `native_outpost_terminal` |
| Adaptive environment | 419 | 19 | 16 | 51 | 336 | 13 | `native_navigation`, `native_radial_controls`, `native_gallery_shell` |
| Public surface | 366 | 79 | 59 | 0 | 277 | 10 | `native_conformance`, `native_registration`, `native_parity_gaps` |
| Docs, examples and tooling | 498 | 17 | 11 | 0 | 447 | 34 | `native_documentation`, `native_registration`, `scenario_require_paths` |
| Gallery and examples | 425 | 195 | 120 | 113 | 66 | 51 | `native_gallery`, `native_games`, `native_gallery_collections` |
| Reference apps | 327 | 59 | 38 | 22 | 153 | 93 | `native_reference_apps`, `native_outpost_rules`, `scenario_require_paths` |
| Performance | 792 | 82 | 34 | 4 | 704 | 2 | `native_perf_principles`, `native_themes_media`, `native_perf_lab` |
| Replication and server state | 55 | 19 | 14 | 0 | 24 | 12 | `native_outpost_terminal`, `native_stress`, `native_gallery` |
| Error handling and refusals | 220 | 50 | 14 | 2 | 146 | 22 | `native_navigation`, `native_parity_gaps`, `native_themes_media` |

## Where verification is weaker

### Geometry and native mechanisms

The headless engine does not solve Roblox layout or text bounds. Main tested
its own solver. Thus the candidate has no headless oracle for these
results:

- final positions and sizes of controls,
- text fit and truncation at the largest text size,
- safe-area and top-bar insets,
- the fit of the showcase on each viewport (`overflow_sweep`, 124 cases),
- selection visuals and scroll-into-view geometry.

`tools/lune/parity_blockers.json` still lists three pending live risks. The
`coverage` producer fails for this reason. Studio evidence for the other
native mechanisms is not recorded per contract.

### Workloads

| Main workload | Main size | Candidate |
|---|---|---|
| Scheduler fuzz | 400 seeded cases | None. Compose owns the scheduler. Its own tests do not run here. |
| Layout fuzz | 400 cases and 60 adversarial cases | None. Roblox layout is not fuzzed. |
| Replication fuzz | 400 seeded cases | 400 seeded deliveries against an example model |
| Fault scenarios | 9 scenarios, 200 iterations each | 200 seeded async fault storms and 200 preference storms |
| Soak | Presenter and scene soak fixtures | 200 modal cycles and 100 structural cycles, twice |
| Accessibility and localization corpus | Corpus CLI and fixtures | UTF-8 edit storms only |

### Ledger quality

The audit recorded 187 disagreements with the candidate
coverage ledger (`tools/lune/coverage_*.json`). These are the common types:

- The ledger cites a case that does not assert the mapped behavior.
- The ledger calls a spec a retired mechanism, but `api.md` still promises
  the behavior.
- The ledger calls a deleted module "replaced".
- The ledger hides a changed behavior in `retiredAssertions`.

The `replacement-cases` producer only checks that cited cases pass. It does
not check that they assert the behavior.

## Producers

| Status | Main `full` producers |
|---|---:|
| Equivalent candidate producer | 18 |
| Replaced by a different check | 5 |
| Replaced by a weaker check | 6 |
| Partly replaced | 2 |
| Runs in CI only | 1 |
| Retired with its subject | 59 |
| Gap: the subject exists, the check does not run | 39 |

These producers are gaps:

| Main producer | Environment | Note |
|---|---|---|
| `check_experiment_markers` | deterministic | No scan for ZZ scratch markers in src. |
| `check_brand_drift` | deterministic | Brand-name drift check deleted. |
| `check_brand_drift-selftest` | deterministic | See the row above. |
| `check_brand_drift-skip-builds` | deterministic | See the row above. |
| `check_call_shape_drift` | deterministic | Call-shape drift of examples and docs is not checked. |
| `check_call_shape_drift-selftest` | deterministic | See the row above. |
| `check_device_captures` | device | Recorded Studio/device evidence validator deleted; live evidence now lives in parity_blockers.json and is not schema-checked per row. |
| `check_device_sweep-selftest` | device | Recorded Studio/device evidence validator deleted; live evidence now lives in parity_blockers.json and is not schema-checked per row. |
| `check_doc_style` | deterministic | Simplified Technical English style checker deleted; docs are not linted. |
| `check_doc_style-selftest` | deterministic | See check_doc_style. |
| `check_eq6_evidence` | studio | Recorded Studio/device evidence validator deleted; live evidence now lives in parity_blockers.json and is not schema-checked per row. |
| `check_maintainer_map_cli` | deterministic | docs/MAINTAINERS.md map is no longer checked against the tree. |
| `check_maintainer_map_cli-selftest` | deterministic | See check_maintainer_map_cli. |
| `check_matrix_rows` | studio | Recorded Studio/device evidence validator deleted; live evidence now lives in parity_blockers.json and is not schema-checked per row. |
| `check_no_fusion` | deterministic | Tool exists; not run. Fails locally only on an ignored artifacts/verify/scaffold snapshot. |
| `check_no_fusion-selftest` | deterministic | Tool exists and passes; not run. |
| `check_no_screen_key_bindings` | deterministic | No scan that screens do not bind raw keys; AGENTS.md still forbids screen-local input. |
| `check_no_screen_key_bindings-selftest` | deterministic | See the row above. |
| `check_perf_captures` | device | Tool exists; exits 1: cannot read rowVersion from examples/performance/lab/rows.luau. |
| `check_perf_gate_evidence-budgets` | studio | Tool exists; not run. 10 of 11 modes exit 1 (evidence files missing); budgets passes. |
| `check_perf_gate_evidence-device-matrix` | studio | Tool exists; not run. 10 of 11 modes exit 1 (evidence files missing); budgets passes. |
| `check_perf_gate_evidence-falsifiable` | studio | Tool exists; not run. 10 of 11 modes exit 1 (evidence files missing); budgets passes. |
| `check_perf_gate_evidence-headless-linkage` | studio | Tool exists; not run. 10 of 11 modes exit 1 (evidence files missing); budgets passes. |
| `check_perf_gate_evidence-large-text` | studio | Tool exists; not run. 10 of 11 modes exit 1 (evidence files missing); budgets passes. |
| `check_perf_gate_evidence-native-reference` | studio | Tool exists; not run. 10 of 11 modes exit 1 (evidence files missing); budgets passes. |
| `check_perf_gate_evidence-perf-gate` | studio | Tool exists; not run. 10 of 11 modes exit 1 (evidence files missing); budgets passes. |
| `check_perf_gate_evidence-prior-gates` | studio | Tool exists; not run. 10 of 11 modes exit 1 (evidence files missing); budgets passes. |
| `check_perf_gate_evidence-scopes` | studio | Tool exists; not run. 10 of 11 modes exit 1 (evidence files missing); budgets passes. |
| `check_perf_gate_evidence-studio` | studio | Tool exists; not run. 10 of 11 modes exit 1 (evidence files missing); budgets passes. |
| `check_perf_gate_evidence-theme-cost` | studio | Tool exists; not run. 10 of 11 modes exit 1 (evidence files missing); budgets passes. |
| `check_perf_place` | studio | Tool exists; exits 1: the built place has no PerfLab native_list or scenario runner. |
| `check_perf_scenes` | deterministic | Tool exists; exits 1: radial-menu-open-close never opened, dense-motion and control-motion did not do their work. |
| `check_perf_scenes-themes` | deterministic | Tool exists; exits 1: no measured themeSwap; xp-a3 row missing. |
| `check_row_actions_matrix` | device | Recorded Studio/device evidence validator deleted; live evidence now lives in parity_blockers.json and is not schema-checked per row. |
| `check_theme_drift_cli` | deterministic | No drift check between theme packages and their built artifacts beyond theme-artifacts selftest. |
| `check_traversal_evidence` | studio | Recorded Studio/device evidence validator deleted; live evidence now lives in parity_blockers.json and is not schema-checked per row. |
| `check_xp_matrix` | device | Recorded Studio/device evidence validator deleted; live evidence now lives in parity_blockers.json and is not schema-checked per row. |
| `corpus_cli` | deterministic | Accessibility and localization corpus (a11y_l10n_corpus) was deleted; native_stress covers UTF-8 editing only. |
| `doctor` | deterministic | tools/doctor.sh exists and passes; not run. |

These producers are weaker replacements:

| Main producer | Candidate | Note |
|---|---|---|
| `check_public_surface` | public-allowlist + native_registration + native_public_surface | No generated public-surface snapshot diff. |
| `check_docs_cli` | native_documentation spec | Checks the snippets it names; no whole-guide API drift scan. |
| `check_example_drift_cli` | native_documentation + architecture | No guide/example source drift check. |
| `check_manifest_integrity` | package-status | Package manifest only. |
| `faults` | native_stress (200 seeded fault storms) | Main ran 9 fault scenarios x 200 iterations. |
| `fuzz-replication` | native_stress (400 seeded deliveries) | Facet replication module deleted; test covers an example model. |
| `package-verify` | package-build + package-status + package-canary | tools/package.sh verify passes on the candidate but is not run as one producer. |
| `soak` | native_stress (200 modal cycles, 100 structural cycles) | Main soak ran the full presenter and scene soak fixtures. |

Other producer differences:

- Release tier: `tools/verify.sh release` runs the same commands as `full`.
  Main also ran `prove_perf_gate` and `render` in the release tier.
  `tools/lune/prove_perf_gate.luau` still exists and does not run.
- Release evidence: no producer writes `latest-release.json`. A release
  refuses to publish until a producer writes it.
- CI: the job moved from `ubuntu-latest` to `macos-15`. Ubuntu is not
  verified.
- New candidate producers: `vendor`, `comments`, `architecture`, `coverage`,
  `replacement-cases`, `package-canary`, and the gallery, monitors,
  performance and consumer builds.

## Defects found

Each item describes a test that fails today. The audit did not fix them.

| ID | File | Defect | Failing test |
|---|---|---|---|
| B1 | `src/ui/collections.luau` | wrapFocus does not wrap arrow or D-pad navigation | Mount a VirtualList of 5 rows with wrapFocus = true and focus = {}. Set AbsoluteWindowSize to (200, 100). Call focus.focus(5). Fire FacetCollectionDown.CollectionDown.Pressed. Expect focus.current to be 1. Actual: 5. The arrow actions call focusScope.move, which ignores wrap; only focus.next wraps. |
| B2 | `src/ui/collection_row_actions.luau` | Full swipe runs an action on an unmeasured row | Mount RowActions with one trailing action and do not set AbsoluteSize. Fire DragStart (100, 0), DragContinue (85, 0), DragEnd. Expect no action. Actual: the action runs, because abs(0) >= 0 * 0.7. |
| B3 | `src/ui/collection_row_actions.luau` | A kept row stays collapsed after a destructive action | Mount RowActions with open = "trailing", a destructive Delete action and reducedMotion = true. Set AbsoluteSize (300, 40). Activate Delete and keep the row (the server refuses). Set open to "trailing" and activate Delete again. Expect a second commit and a usable row. Actual: committing is never cleared, the UIDragDetector stays disabled and the second commit does not run. |
| B4 | `src/ui/inputs.luau` | A number TextInput commits after its parse callback disables it | Mount TextInput with presentation = "number", enabled cell true, and parse that sets enabled to false. Capture focus, set Text to "5", release focus with submit. Expect no onCommit and numericValue 2. Actual: onCommit runs and numericValue becomes 5. |
| B5 | `src/ui/inputs.luau` | onPointerCancel alone never fires | Mount Button with only onPointerCancel. Fire InputBegan (MouseButton1) and MouseLeave. Expect one call. Actual: zero. The listeners connect only when repeatDelay, repeatInterval, onPointerDown or onPointerUp is present. |
| B6 | `src/ui/inputs.luau` | Input controls ignore GuiService.ReducedMotionEnabled | Set GuiService.ReducedMotionEnabled = true and do not pass the reducedMotion factory option. Mount Button with pop = true, fire Activated and heartbeat 0.1. Expect UIScale.Scale 1. Actual: the pop animates. The StyleSheet and the navigation surfaces follow GuiService; Button pop, the validation pulse and the busy dots do not. |
| B7 | `src/ui/collections.luau` | A readable follow option is accepted and ignored | Mount VirtualList with follow = Compose.cell("end"). Expect an error, because api.md says follow is static and an unsupported option causes an error. Actual: it mounts and behaves as follow = "none". |
| B8 | `src/ui/media.luau` | Label with an icon returns a Frame | Mount Label with text and icon. Expect a TextLabel root, as api.md says. Actual: a Frame. |
| B9 | `src/ui/media.luau` | ProgressView endLabel hides the showValue readout | Mount ProgressView with value 0.5, showValue = true and endLabel = "End". Expect a "50%" text. Actual: no text shows the value. |
| B10 | `src/ui/inputs.luau` | Button corners rejects a readable, but Badge corners accepts one | Mount Button with corners = Compose.cell("square"). Expect it to mount, the same as Badge. Actual: an error. api.md does not say that corners is static. Low severity. |
| E1 | `examples/gallery/examples/05_word_game.luau` | Word-game keys and the active row no longer show state by paint | Mount the word game and guess RULES against REACT. Expect key_R and key_U to carry different surfaces, and the active row to carry an outline. Actual: the surface formulas are computed and never applied. |
| E2 | `examples/gallery/examples/02_playlist_table.luau` | Playlist plays a track on one click; its hint says double-click | Mount the playlist and fire one RowHit.Activated with MouseButton1. Expect selection only. Actual: nowPlaying changes. |
| E3 | `examples/themes/ornate_gauge.luau, examples/themes/custom_control.luau` | Theme fixtures call deleted constructors | Call each fixture blueprint with Facet.controls(runtime). Expect a mounted view. Actual: UI.ZStack, UI.HStack and UI.VStack are nil. docs/guide/13-theme-catalog.md still calls them tested fixtures. |

### Fixed during the audit

The concurrent session fixed these reported defects before the recheck:

- `91702428`: Transparent tap-away catchers became opaque at PreferredTransparency 0; the theme scrim did not reach the modal scrim.
- `f2929ef1`: Picker valueAlignment was inert; Stepper used text glyphs; Badge corners did not follow a readable.
- `8781d9f8`: define accepted malformed type roles and unknown shadow presets; unreadable selected-label contrast passed.
- `8b19bba9`: corners layers ignored layer.asset; derived packages kept stale state art; skinned toggle fills were outranked.
- `3aa388a5`: Alert shortcut "cancelAction" and non-table transitions were silently ignored.

## Gaps closed by this audit

[`tests/native_parity_gaps.spec.luau`](../../tests/native_parity_gaps.spec.luau)
adds these cases:

| Candidate case | Closes | Main cases | Also partly covers |
|---|---|---:|---|
| keeps the changelog release heading equal to Facet.VERSION | apps-115 | 1 | - |
| refuses an unknown lower-case option on every public constructor | collections-221, mech1-26, mech3-44, themes-P1-97 | 33 | - |
| shows button help when gamepad selection rests on the button and hides it on deselection | inputs-91, mech3-70 | 4 | - |
| disables a stepper direction at its bound and refuses the step | inputs-214 | 2 | - |
| reports a failed alert body to the onError factory option and dismisses once | mech1-114 | 1 | - |
| tags a disabled button for the theme disabled rule and lets a package retune it | mech2-24 | 3 | - |
| keeps at most the documented number of pooled row hosts | mech2-31 | 2 | - |
| fills the controls table with indexOfKey, placementOf and offsetOf | mech2-86 | 2 | - |
| refuses malformed documented options with a named error | navigation-2-24, navigation-3-45, navigation-4-10, navigation-5-28 | 8 | apps-198, collections-129, inputs-43, inputs-104, inputs-150, inputs-188, navigation-3-81, navigation-4-45 |
| delivers onActivate with the item and key and skips disabled rows | - | 0 | collections-184 |
| wraps rating activation to zero only when allowZero and ignores a disabled rating | - | 0 | inputs-156 |

## Proposed tests for the largest gaps

Each proposal is headless. Use the fake engine in `tests/lib/native_engine.luau`.

- **Paint rules.** Compile the neutral sheet. For each Button role and appearance tag, read the rule for the button, its caption and its icon. Expect the palette color. Change the package palette and expect the rule to change.
- **Control size.** Mount Button and ShortcutHint with `controlSize = "tiny"`. Expect an error that names compact, regular and large. Bind a cell and set an illegal value. Expect the last legal height.
- **Theme packages.** For each shipped package, call `checkCoverage` with every icon name that a control requests. Expect no missing name. Expect every `.facet-type-<role>` rule to use the package font.
- **Value controls.** Mount Slider with `thumbImage` and `trackImage`. Expect the images on the thumb and track. Hold Increase on a Stepper, then present a modal. Expect the value to stop changing.
- **Row actions.** Mount a Table with `rowActions`. Open one row, then open a second row with a shared coordinator. Expect the first row to close. Press Delete on a focused row. Expect one commit.
- **Tables.** Mount a Table with fixed and flexible columns. Set the viewport size. Expect the header and body column edges to match. Expect no resize grip on a column with `resizable = false`.
- **Navigation.** Mount a TabView. Select a control inside page content. Fire the next-tab shoulder action. Expect the next tab, as `api.md` says the control owns shoulder navigation.
- **Collections.** Mount a horizontal VirtualList with focus. Fire Right. Expect the next key and a scroll into view. Mount with `snap = "item"` and scroll to the end. Expect the end offset.
- **Radial menu.** Mount RadialMenu with `follow = "fixed"`, `centerPassThrough = true` and `launcher = false`. Drive the D-pad and the commit action. Expect the selected item and one activation.
- **Error handling.** For each control family, pass each documented enumeration an unknown value. Expect a named error before a native node is created.
- **Reference apps.** Drive each reference app through its model and its mounted controls: Glade purchase and reset, Cartwheel brew states and guild name rejection, Sipworks search and plurals, Foyer badge and loader.

## Gap list

Each ID is a contract in the data file. The data file has the promise, the
main specs and a proposed test for each gap. Framework gaps come first.
Example and reference-app gaps follow in a summary.

| ID | Group | Main cases | Contract |
|---|---|---:|---|
| navigation-3-70 | Reactive core | 1 | Redirect inside onChange never reaches observers |
| navigation-5-18 | Lifetime and ownership | 5 | retention='top' disposes departing pages, rebuilds on return, stays memory-neutral |
| apps2-101 | Lifetime and ownership | 3 | Demo cleanup ordering: resources outlive the presented tree; same-frame dispose+dismiss is clean; self-presenting demo disposed once |
| navigation-2-04 | Lifetime and ownership | 2 | Expanded CollapsibleView releases its surface on unmount and across open/close cycles |
| navigation-2-38 | Lifetime and ownership | 2 | Open menus release every level on repeated enter/back and on dispose |
| navigation-2-72 | Lifetime and ownership | 2 | Nested menu and forced sheet content toggle checked state and release with the trigger |
| collections-86 | Lifetime and ownership | 1 | Disposing while the menu is open dismisses the menu surface |
| navigation-1-25 | Lifetime and ownership | 1 | Disposing an open alert restores ownership |
| navigation-1-61 | Lifetime and ownership | 1 | Dispose takes the plate down and frees the queue slot |
| navigation-5-17 | Lifetime and ownership | 1 | Unvisited tabs are never built (lazy) |
| themes-P1-92 | Lifetime and ownership | 1 | Held shared driver released after later construction refuses |
| navigation-3-63 | Layout and geometry | 4 | sizing hug/fill, unequal widths, reactive, unknown refused |
| apps2-192 | Layout and geometry | 3 | Corner/portrait rings keep >=44px buttons inside the surface before falling back |
| navigation-1-40 | Layout and geometry | 3 | Callout align leading/trailing and automatic flip to the opposite edge |
| navigation-5-35 | Layout and geometry | 3 | Foot pinned to rail bottom; strip between head and foot; factory receives placement |
| navigation-5-38 | Layout and geometry | 3 | aboveBar dock sits between content and band with no gap (portrait and landscape) |
| apps2-61 | Layout and geometry | 2 | Wrap toggle flips wrapping on the same nodes; Block align moves only the block |
| navigation-5-36 | Layout and geometry | 2 | Trailing accessory at the band's trailing edge, clear of tabs |
| navigation-1-43 | Layout and geometry | 1 | No tail requested means no tail |
| navigation-1-69 | Layout and geometry | 1 | Nothing on the callout page crosses a lateral edge at swept sizes |
| navigation-5-31 | Layout and geometry | 1 | Sidebar rail width: default and declared |
| themes-P1-48 | Layout and geometry | 1 | Icon badge height equals plain caption; icon side respected |
| paint-148 | Text measurement and fit | 9 | Type roles compile to native font rules and tags |
| navigation-1-20 | Text measurement and fit | 4 | Measured action-label rung decides row vs stack; nothing is cut |
| navigation-1-38 | Text measurement and fit | 4 | Blank or readable titles mount nothing; long titles wrap full width |
| navigation-5-30 | Text measurement and fit | 2 | Bound textSize reaches the tabs and re-reads |
| collections-255 | Focus and selection | 4 | Horizontal list Left/Right steps, Up/Down inert, D-pad parity, scroll into view |
| navigation-2-31 | Focus and selection | 4 | Cancel/ButtonB and Left close one level; Right enters a focused submenu only |
| collections-245 | Focus and selection | 3 | Transposed horizontal grid navigation and scroll-into-view |
| apps-179 | Focus and selection | 2 | Disabled control leaves navigation |
| apps2-179 | Focus and selection | 2 | A selected column is released on Cancel, second Activate, or when focus leaves the table |
| apps2-232 | Focus and selection | 2 | D-pad reaches both tab strips and an alert, traps focus, restores its launcher; shoulders route to inner tabs and Back through the journey |
| mech1-130 | Focus and selection | 2 | Collection wrapFocus/autoFocus |
| navigation-3-15 | Focus and selection | 2 | Pop restores remembered focus even when surviving shell chrome holds selection |
| apps-146 | Focus and selection | 1 | Nested modals restore focus in LIFO order |
| collections-230 | Focus and selection | 1 | Cells get a focus readable that follows the ring |
| collections-234 | Focus and selection | 1 | Grid Left/Right steps cell by cell |
| collections-270 | Focus and selection | 1 | wrapFocus wraps the ring at both ends |
| navigation-2-37 | Focus and selection | 1 | Back restores selection to the row that led into the left level |
| navigation-3-16 | Focus and selection | 1 | Remembered target disabled while away falls back to first selectable |
| collections-287 | Input actions | 7 | Pad focus traversal into the tray and back, leading entry, menu closes with the row, sibling during commit, ButtonX, both key spellings |
| collections-84 | Input actions | 7 | Shift+Return menu toggle |
| apps-163 | Input actions | 5 | Exactly one Activate per press across the InputAction and native Activated paths |
| inputs-101 | Input actions | 5 | Modifier-gated shortcut bindings |
| navigation-2-27 | Input actions | 5 | Secondary click, keyboard chord, gamepad button open the menu; only declared triggers are honoured (tap is not long-press) |
| navigation-5-13 | Input actions | 3 | Shoulder paging (L1/R1) and its focus gating |
| apps2-184 | Input actions | 2 | D-pad step moves selection and candidate together; stick release returns d-pad |
| collections-187 | Input actions | 2 | Revealed trailing and leading trays are reachable by pad |
| collections-40 | Input actions | 2 | Losing the keyboard and gamepad capabilities cancels an armed grab; the grab continues when a pointer arrives |
| navigation-4-63 | Input actions | 1 | Shoulder paging from content only when opted in; value controls keep shoulder adjustment |
| navigation-4-65 | Input actions | 1 | Nested content paging clamps at the inner boundary and never pages outer tabs |
| collections-114 | Pointer, touch and drag | 2 | An unmeasured row (width <= 0) never full-swipe commits |
| apps2-208 | Pointer, touch and drag | 1 | Item disabled mid-drag does not fire on release |
| apps2-215 | Pointer, touch and drag | 1 | centerPassThrough leaves the center input-transparent |
| navigation-4-40 | Pointer, touch and drag | 1 | Dragging down past the smallest detent dismisses; touch targets meet 44px |
| navigation-4-48 | Pointer, touch and drag | 1 | Grabbing during resize motion continues from the painted height |
| navigation-1-19 | Scrolling | 4 | A card with room grows to fit and does not scroll |
| collections-128 | Scrolling | 3 | Snap at the end of the list: the last page settles to the end; a decisive drag back leaves it |
| collections-225 | Scrolling | 3 | The grid anchor holds under line-extent and column-count changes |
| collections-129 | Scrolling | 2 | Snap idle churn guard and snap vocabulary refusal |
| navigation-5-06 | Scrolling | 2 | A visible selection issues no scroll, repeatedly |
| collections-216 | Scrolling | 1 | Shrinking rows at the bottom leaves the list flush |
| collections-250 | Scrolling | 1 | Keep-visible writes X on a horizontal list |
| collections-302 | Scrolling | 1 | Shrinking the end corrects the engine |
| navigation-4-67 | Scrolling | 1 | Returning to a tab restores its scroll position (keyed anchor after reorder, page not retained) |
| themes-P1-76 | Motion | 6 | Visible-step count and full-vs-reduced write differential for bar/circular/spinner |
| apps2-92 | Motion | 4 | The motion setting survives a demo swap |
| navigation-3-04 | Motion | 3 | NavigationStack fade transition and reduced-motion swap |
| apps-258 | Motion | 2 | Source that moves or is a readable during flight; keeps last origin when it disappears |
| inputs-25 | Motion | 2 | No pop transform without pop; held repeat does not re-kick pop |
| navigation-3-24 | Motion | 2 | Fade transitions retire pages; rapid forward/back leaves one opaque interactive page |
| paint-37 | Motion | 2 | Indeterminate bar sweeping segment stays inside the track |
| inputs-162 | Motion | 1 | Control motion follows the player's reduced-motion preference with no consumer wiring |
| navigation-5-25 | Motion | 1 | No transition declared means no fade layer |
| navigation-5-50 | Motion | 1 | No declaration leaves no transition |
| themes-P1-75 | Motion | 1 | Reduced motion sub-tick hold then move: indeterminate bar |
| themes-P1-78 | Motion | 1 | Switching policy mid-cycle steps, never restarts |
| themes-P5-41 | Paint and theming | 9 | Every tag the framework emits is selected by a rule in every sheet |
| navigation-3-50 | Paint and theming | 8 | Current-option paint follows selection and indicator choice (none/underline/inline) |
| themes-P5-49 | Paint and theming | 8 | Preference touches only backdrops, never hairlines, disabled dim or authored opacity |
| paint-08 | Paint and theming | 7 | Role/appearance/corners vocabulary paint and state precedence |
| themes-P3-10 | Paint and theming | 5 | Typography roles compile into native rules (.facet-type-<role>, .facet-button, captions) and follow package edits; Label textRole reaches them |
| apps2-26 | Paint and theming | 4 | Active row cue is not a colour: outlined plate follows the active row, next-letter mark |
| themes-P2-16 | Paint and theming | 4 | Badge chrome slot: an ornate package skins the badge seal with its insets |
| themes-P2-25 | Paint and theming | 4 | A per-view image overrides the theme skin for one node (Slider thumbImage and trackImage) |
| themes-P5-23 | Paint and theming | 4 | Selected label contrast holds against the selection ART (plate samples) |
| navigation-4-12 | Paint and theming | 3 | A Picker/Menu popup catcher is invisible (resolves to fully transparent) |
| paint-114 | Paint and theming | 3 | Accent/control corner radius follows package radii live |
| paint-75 | Paint and theming | 3 | Value-control own-paint tags independent of skinning |
| themes-P2-32 | Paint and theming | 3 | Slider thumb and rail paint opaque on every package, and badge and accent fills stay solid |
| themes-P5-13 | Paint and theming | 3 | Gradient packages stay readable and reach ::UIGradient rules |
| themes-P5-46 | Paint and theming | 3 | Selected label on controlSelected clears 4.5:1 in every shipped theme |
| apps2-19 | Paint and theming | 2 | Committed vs uncommitted is not a colour: solid vs outline plate, ASCII mark |
| paint-02 | Paint and theming | 2 | Content text/icon colors per role and appearance rule |
| paint-106 | Paint and theming | 2 | Every value-control own-paint slot gets a solid fill with corner/hairline |
| paint-119 | Paint and theming | 2 | onIndicator caption role tag and rule |
| themes-P2-09 | Paint and theming | 2 | Palette chrome gradients compile to ::UIGradient rules per palette |
| themes-P2-11 | Paint and theming | 2 | Cascade order: StyleRule Priority follows declaration order (resting before states, contributions last) |
| themes-P2-21 | Paint and theming | 2 | Metric changes (radii, strokes, typography) repaint live |
| themes-P5-48 | Paint and theming | 2 | Garbage preference is the identity |
| apps2-221 | Paint and theming | 1 | Divider edges honour leading/trailing insets and heavy thickness under each theme |
| navigation-5-22 | Paint and theming | 1 | Selection indicator default (underline on top band) |
| paint-110 | Paint and theming | 1 | Parent-role caption variants |
| paint-29 | Paint and theming | 1 | Picker selection rides the style tag |
| themes-P1-125 | Paint and theming | 1 | Bound dimmed blends image and back |
| themes-P1-47 | Paint and theming | 1 | Icon badge keeps its icon through reactive status paint |
| themes-P1-49 | Paint and theming | 1 | Utility plateless and status leading dot appearances |
| themes-P2-34 | Paint and theming | 1 | The toggle's ON track uses that theme's accent |
| themes-P2-39 | Paint and theming | 1 | A skinned role button keeps its role text colours |
| themes-P2-63 | Paint and theming | 1 | Icons carry no instance paint; the tint comes from the sheet |
| themes-P3-12 | Paint and theming | 1 | Package chromeGradient paints the chrome slots via native UIGradient rules |
| themes-P4-25 | Paint and theming | 1 | Bar family owns solid native paint (track/fill rules) when unskinned |
| themes-P5-28 | Paint and theming | 1 | Suppression outranks each value slot's own paint rule |
| themes-P5-42 | Paint and theming | 1 | Themed corner radii follow the installed package |
| themes-P5-03 | Theme packages | 13 | Declared theme classes (palette/metric/font/asset) are real, corpus covers all four |
| themes-P1-69 | Theme packages | 10 | Every shipped package authors its own circular/spinner metrics and the corpus spans 2x |
| themes-P5-04 | Theme packages | 5 | Recipes name declared assets, never raw ids |
| themes-P5-22 | Theme packages | 5 | Platform pair: touch vs pointer metrics, hover art, tile stripe |
| apps2-117 | Theme packages | 3 | Neutral first then sorted by name; re-selecting the installed package is a no-op; selecting a theme within the active package |
| apps2-118 | Theme packages | 3 | FacetThemes folder: ignores non-packages, excludes testOnly fixtures, lists every shipping package (ornate with two themes) |
| inputs-227 | Theme packages | 3 | Per-view thumbImage/trackImage override |
| paint-152 | Theme packages | 3 | Unauthored strong/numeral derive from the package face |
| themes-P4-37 | Theme packages | 3 | Omitted semantic pairs ride the neutral fallbacks, including derived two-variant packages |
| themes-P2-01 | Theme packages | 2 | `content` and `contentId` both resolve to the same image |
| themes-P4-29 | Theme packages | 2 | Derivation from base inherits unrestated values and is gated as strictly |
| themes-P5-05 | Theme packages | 2 | Bogus art still compiles and skins a full stack (asset failure is runtime) |
| themes-P5-15 | Theme packages | 2 | Shipped palettes declare their own success/warning, distinct from accent/content |
| themes-P1-70 | Theme packages | 1 | Package that authors nothing still answers the three metrics |
| themes-P3-26 | Theme packages | 1 | Unknown typography role is rejected at construction |
| themes-P4-33 | Theme packages | 1 | Non-finite (NaN) numbers are rejected |
| themes-P4-46 | Theme packages | 1 | Unstated states fall back to default art (and skin state precedence disabled > pressed > hover > selected) |
| themes-P4-50 | Theme packages | 1 | A derived package override cannot leave a stale base state |
| paint-54 | Icons and media | 10 | Every shipped package resolves every framework icon to art |
| themes-P3-22 | Icons and media | 3 | contentId is an alias of content: both spellings yield the same native Image/rules as plain strings |
| paint-53 | Icons and media | 2 | Framework icon list matches the names controls request |
| themes-P2-23 | Icons and media | 2 | Slider rail paints sliced and the thumb paints whole (sliced=false) |
| themes-P2-54 | Icons and media | 2 | Stepper increment and decrement use semantic icons, not the U+2212 glyph |
| paint-24 | Icons and media | 1 | Unknown semantic icon refused |
| paint-79 | Icons and media | 1 | Button imageFraming fit/crop |
| themes-P1-23 | Icons and media | 1 | presenceMark=false suppresses the mark but keeps presence in the label |
| themes-P1-25 | Icons and media | 1 | Refuses invalid name/form/presence before acquiring |
| themes-P1-40 | Icons and media | 1 | Non-string overflowLabel refused and recovered |
| themes-P2-38 | Icons and media | 1 | A flat package still tints framework icons (with no instance paint) |
| themes-P2-43 | Icons and media | 1 | Eleven common framework icons (status, calendar, clock, vote, person, chevron ends) resolve to standard art |
| themes-P2-46 | Icons and media | 1 | Framework icons are tinted by the palette content role, not left white |
| themes-P2-47 | Icons and media | 1 | A status plate re-letters the picture on it |
| themes-P2-48 | Icons and media | 1 | An unknown icon name resolves to nothing |
| themes-P2-62 | Icons and media | 1 | A status plate re-letters the picture: kind tag and direct child |
| paint-06 | Action controls | 8 | Unknown controlSize refused; live bad rung keeps last legal value |
| inputs-17 | Action controls | 4 | Busy label and spinner dots stay inside the button plate in every package |
| inputs-43 | Action controls | 3 | Unknown shape/icon names are refused at construction |
| collections-184 | Action controls | 2 | Keyboard/gamepad row activation fires onActivate for that row |
| collections-232 | Action controls | 2 | Pointer, touch and keyboard activation of a grid cell (onActivate) |
| collections-253 | Action controls | 2 | Pointer and touch tap activate a horizontal item |
| collections-263 | Action controls | 2 | Row tap activates (pointer and touch) |
| paint-16 | Action controls | 2 | Chip default shape and leading/trailing accessories |
| paint-30 | Action controls | 2 | Disabled Picker and DisclosureGroup refuse interaction |
| apps2-08 | Action controls | 1 | A tap while the board resolves is refused in words and costs nothing |
| apps2-20 | Action controls | 1 | A spent rack slot is disabled, not a live blank button |
| apps2-230 | Action controls | 1 | Status and identity recipes reset through their shared commands |
| collections-244 | Action controls | 1 | Horizontal grid cell tap activates |
| inputs-26 | Action controls | 1 | Button renders caller children inside the button |
| inputs-29 | Action controls | 1 | Role vocabulary accepted and unknown roles rejected |
| navigation-5-23 | Action controls | 1 | Every tab meets the 44px target floor |
| paint-60 | Action controls | 1 | Button pointer callbacks |
| inputs-104 | Value controls | 5 | Count, unknown key, segment, segmentSize and glyphs-on-bar refusals |
| themes-P4-10 | Value controls | 5 | Per-control art override (Slider thumbImage/trackImage) reaches the control and beats the theme ladder; no override stays on theme |
| themes-P5-35 | Value controls | 5 | Skinned toggle parts drop their pill, restore when unskinned, geometry unchanged |
| inputs-81 | Value controls | 3 | Slider/Stepper/Rating abandon a held adjustment when a modal owns input |
| navigation-5-21 | Value controls | 3 | Tab labels: id fallback, icon-only accessible name, badges on unselected tabs |
| inputs-105 | Value controls | 2 | Value clamped to run and semantic text in range |
| inputs-109 | Value controls | 2 | Glyph segments and starSize |
| inputs-150 | Value controls | 2 | Count and starSize refusals |
| inputs-152 | Value controls | 2 | Value clamped and semantic text in range |
| inputs-202 | Value controls | 2 | Read-only value/mixed require a request callback |
| inputs-224 | Value controls | 2 | Disabled Slider refuses drag and Adjust and leaves focus order |
| inputs-57 | Value controls | 2 | Chip rejects a missing selected/onRemove and read-only selected without onToggle |
| paint-42 | Value controls | 2 | Bar value readout placement and track thickness |
| paint-44 | Value controls | 2 | endLabel beside the value and on indeterminate activity |
| apps2-02 | Value controls | 1 | Consumer Sound toggle carries the screen-owned value |
| inputs-114 | Value controls | 1 | Disabled picker refuses every input class |
| inputs-151 | Value controls | 1 | Glyphs fill up to the value and repaint in place |
| inputs-156 | Value controls | 1 | Disabled rating refuses every input |
| inputs-55 | Value controls | 1 | Flipping selected repaints in place |
| inputs-61 | Value controls | 1 | Removable chip respects inherited disabled |
| inputs-72 | Value controls | 1 | Chip enforces live enabled through mounted activation |
| themes-P1-114 | Value controls | 1 | Checked rung metrics |
| themes-P1-53 | Value controls | 1 | Live caption mounts/removes while icon and plate retained |
| themes-P1-89 | Value controls | 1 | Bound rung validated and recovers to regular |
| themes-P1-91 | Value controls | 1 | Refuses malformed form-specific declarations without a driver |
| inputs-196 | Text input | 6 | Numeric parse/format/validate cannot commit after disabling or disposing the control |
| apps2-29 | Text input | 5 | Temperature converter: numeric field only, live Preview vs committed Result, Enter and focus-loss commit, validate rejects |
| inputs-185 | Text input | 2 | Invalid UTF-8 edits are rejected |
| inputs-188 | Text input | 2 | clearButton=true means always; unknown mode is refused |
| inputs-197 | Text input | 1 | Numeric specs refuse nonfinite bounds and bad callbacks |
| inputs-73 | Text input | 1 | TextInput refuses both enabled and disabled |
| navigation-2-09 | Text input | 1 | ComboBox refuses malformed/missing required fields |
| navigation-2-12 | Text input | 1 | Custom validation that disposes the control cannot commit |
| navigation-2-36 | Menus and pickers | 4 | presentation option forces menu/sheet reactively, including into automatic and at compact widths |
| collections-82 | Menus and pickers | 3 | Menu inertness for Delete, full swipe closes the menu, 10 toggles leak nothing |
| apps-198 | Menus and pickers | 2 | Picker refuses malformed option and callback contracts |
| navigation-2-29 | Menus and pickers | 2 | A wholly disabled menu still opens; a disabled item is inert and the menu stays |
| navigation-3-76 | Menus and pickers | 2 | Menu opens anchored to the trigger and fits the viewport |
| navigation-3-87 | Menus and pickers | 2 | Menu width fits widest row and popover fit at the safe width |
| navigation-4-18 | Menus and pickers | 2 | Named/sparse option tables and malformed options are refused at construction |
| apps2-212 | Menus and pickers | 1 | launcher=false leaves no built-in trigger |
| navigation-2-23 | Menus and pickers | 1 | Controller long choice lists use the larger presentation; short lists stay quick |
| navigation-2-39 | Menus and pickers | 1 | backLabel reaches the Back row |
| navigation-2-44 | Menus and pickers | 1 | Submenu row carries a trailing chevron |
| navigation-3-77 | Menus and pickers | 1 | Re-activating trigger or gamepad B closes without changing selection |
| navigation-3-84 | Menus and pickers | 1 | valueAlignment moves a labelled menu value |
| navigation-3-86 | Menus and pickers | 1 | radioGroup style pick |
| navigation-5-47 | Navigation containers | 5 | Scenario behaviors still promised but untested: pill in adaptable nav, badge on unselected tab, 44px floor, shoulders, reveal-once |
| navigation-1-02 | Navigation containers | 3 | TabView placement changes keep tab strip, scroller and page owners (no rebuild, no leak) |
| navigation-5-08 | Navigation containers | 3 | A nested TabView resolves topBar and depth stays balanced when a factory throws |
| apps2-107 | Navigation containers | 2 | Stepping wraps both ways, a full cycle returns, unknown current id yields a real demo |
| apps2-200 | Navigation containers | 2 | One navigation control per center policy; Close/Back by depth |
| navigation-5-40 | Navigation containers | 2 | Re-home between a slot's own homes; nil factory mounts nothing |
| apps2-202 | Navigation containers | 1 | Removing an open ancestor returns to the nearest valid page |
| navigation-4-61 | Navigation containers | 1 | Customization ignores stale ids, protects required tabs, reorders without remount, hidden selection falls back |
| apps2-46 | Presented surfaces | 6 | Confirm dialog outcomes: Delete opens, Cancel records kept, Confirm changes the screen, Restore repeats, double Delete does not stack |
| navigation-1-54 | Presented surfaces | 3 | Initial seen/featureUsed and afterSessions gate eligibility |
| inputs-93 | Presented surfaces | 2 | Help plate takes no focus and wraps long text |
| navigation-1-16 | Presented surfaces | 2 | A live layout flip moves the same mounted actions and keeps selection |
| navigation-5-54 | Presented surfaces | 2 | Menu/expand catchers never paint an opaque full-viewport node |
| navigation-1-26 | Presented surfaces | 1 | Default OK action when none authored |
| navigation-1-29 | Presented surfaces | 1 | Custom content ids are not interpreted as alert actions |
| navigation-2-61 | Presented surfaces | 1 | Alert (including fullScreen) has no outside-tap dismissal |
| navigation-3-31 | Presented surfaces | 1 | Desktop confirmation: compact centered card, horizontal actions |
| navigation-4-69 | Virtual collections | 3 | VirtualGrid and Table keep keyed scroll anchors across insertion while their tab is away (editing on/off) |
| apps2-177 | Virtual collections | 2 | Column resize on a virtualized 2000-row table remounts only the window at the new width |
| collections-21 | Virtual collections | 2 | followThreshold and rejoining the tail after returning to the end |
| apps2-49 | Virtual collections | 1 | A sideways engine scroll slides the card rail window along X |
| apps2-178 | Tables | 5 | Header column boundaries match the body's, with and without a scrollbar gutter, stable after resize |
| apps2-37 | Tables | 4 | Double-click plays, single click only selects, slow clicks play nothing, touch first tap plays; Restore clears what was playing |
| apps2-167 | Tables | 2 | Resizable column grows a grip; a locked (resizable=false) column has none and binds no adjust key |
| apps2-172 | Tables | 2 | Rating sorts by live signal; Artist sorts by value with source-index tie-break |
| apps2-174 | Tables | 2 | Top button bakes the sort; removing a row keeps the sort |
| collections-134 | Tables | 2 | Header offset for the reorder and disclosure gutters keeps columns aligned |
| apps2-33 | Tables | 1 | Playlist columns align name and rating under their headers |
| collections-136 | Tables | 1 | Headerless table (header = false) |
| collections-139 | Tables | 1 | A collapse sum equal to the available room fits |
| collections-207 | Tables | 1 | Header and body cells span the same columns in every shape and package |
| collections-170 | Row actions | 10 | Table rowActions behaviors: shared coordinator, reorder coexistence, tray tap, editing minus, disposal, refresh cancel, Delete key, commit collapse, handle plus minus |
| collections-256 | Row actions | 4 | Horizontal reorder: pointer X slot, release X commit, X autoscroll, Left/Right armed stepping |
| collections-77 | Row actions | 4 | Close on another row's gesture/menu, on scroll, with the Cancel key, and on unmount |
| apps2-35 | Row actions | 3 | Scrolling the page closes a swiped-open tray; a swipe never plays the track (touch and mouse) |
| collections-194 | Row actions | 3 | A rowActions-only table is reachable and Delete/pad fires |
| collections-89 | Row actions | 2 | A sibling gesture or scroll during a commit does not cancel it |
| collections-121 | Row actions | 1 | A pinned row cannot be displaced by a movable row |
| collections-173 | Row actions | 1 | A viewport table closes an open tray on its own body scroll |
| collections-282 | Row actions | 1 | A row whose actions are nil declines the gesture |
| collections-303 | Row actions | 1 | The insertion slot snaps on ragged midpoints |
| collections-72 | Row actions | 1 | A destructive commit recovers when the owner keeps the row |
| apps2-190 | HUD and world targets | 2 | Anchor clearance sizes the hole; follow=fixed keeps opening geometry |
| themes-P1-101 | HUD and world targets | 1 | Camera position/lookAt/fov |
| collections-110 | Adaptive environment | 4 | A short landscape drops the heading; the first row is visible on all surfaces |
| navigation-3-74 | Adaptive environment | 4 | Automatic count/width/description/query rungs |
| navigation-2-32 | Adaptive environment | 2 | Touch preferred input resolves the sheet idiom at any width |
| navigation-1-03 | Adaptive environment | 1 | Gamepad/TV presentation forces top bar tabs |
| navigation-1-63 | Adaptive environment | 1 | No device branch in the callout source |
| navigation-3-23 | Adaptive environment | 1 | Viewport/theme/input/reduced-motion switches keep the mounted page |
| navigation-3-55 | Public surface | 3 | Nameless option, empty bound label and iconOnly without icons are refused |
| apps-117 | Public surface | 1 | init.luau re-exports contract types |
| inputs-67 | Public surface | 1 | compactLabel refused on content/icon/image buttons |
| navigation-3-17 | Public surface | 1 | Malformed specs, paths and route entries are refused before creating a page |
| navigation-3-52 | Public surface | 1 | Indicator 'automatic' legal; refusal names the set |
| navigation-3-81 | Public surface | 1 | Declared style bypasses the ladder; unknown style refused |
| navigation-4-35 | Public surface | 1 | Unknown indicator or axis is rejected naming the legal set |
| navigation-4-45 | Public surface | 1 | Rejects unknown detents, duplicate ids and a read-only detent cell |
| apps2-139 | Performance | 1 | Row count clamped to the declared ceiling |
| apps2-148 | Performance | 1 | Two captures are the same workload only when every identity field agrees |
| apps2-42 | Replication and server state | 7 | Settings sync: every state reachable by on-screen controls, status names next action, reset unanswered, second change refused visibly, idle Deliver explains, bounded newest-first history |
| apps2-128 | Replication and server state | 5 | Unengaged terminal sends nothing and states the objective; ADJUST updates budget line/verdict; an edit retires the last outcome; exit is idempotent |
| navigation-1-35 | Error handling and refusals | 3 | Invalid transition options are refused at build |
| navigation-5-42 | Error handling and refusals | 3 | Refuse unknown slot, non-function slot, and a slot the declared placement cannot host |
| apps2-115 | Error handling and refusals | 2 | A demo that cannot build is not reported mounted; the scriptable API answers with what it delivered |
| apps2-83 | Error handling and refusals | 2 | A demo that cannot be mounted is stamped and spoken |
| collections-50 | Error handling and refusals | 2 | A theme metrics snapshot without derived row keys, or with NaN scale, falls back |
| collections-51 | Error handling and refusals | 2 | Unknown RowActions options and unknown action roles are refused |
| navigation-1-55 | Error handling and refusals | 2 | Missing onRetire and unknown keys are refused |
| navigation-5-52 | Error handling and refusals | 2 | Refuse unknown transition fields and a string name |
| navigation-1-28 | Error handling and refusals | 1 | Refuses misspelled fields, duplicate action ids and two cancel roles |
| navigation-5-26 | Error handling and refusals | 1 | A transition must be a table of tween options |
| paint-41 | Error handling and refusals | 1 | Unknown ProgressView presentation refused |
| themes-P4-42 | Error handling and refusals | 1 | Self-referential definition terminates (cycles rejected) |

Example and reference-app gaps:

| Group | Contracts | Main cases |
|---|---:|---:|
| Docs, examples and tooling | 11 | 34 |
| Gallery and examples | 17 | 51 |
| Reference apps | 43 | 93 |

## Use the data

- `totals` has the class counts before and after the new tests.
- `contracts` has one record for each contract. A record has the main
  specs, the class, the cited candidate cases and the gap.
- `producers.rows` maps each main `full` producer to its candidate status.
- `bugs` has a failing-test description for each open defect.
- `totals.uncitableCandidateCases` lists citations that are not suite case
  IDs, such as producers and groups of cases.

When you close a gap, add the candidate case ID to the contract and change
its class to `a`. When you retire a promise, change `api.md` first.
