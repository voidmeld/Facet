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
  still promises, but no candidate case tested it. The parity tests close
  472 of these cases. One case moved to class c, because `api.md`
  no longer makes its promise. 421 cases remain.
- 1,697 of the 2,766 covered cases have a weaker
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
- The audit found 10 defects in `src` and 3 in the examples. The paint
  and theme tests fixed E1, 4 more defects in `src` and 2 in the examples.
  The control and navigation tests fixed 3 audit defects and 7 more
  defects in `src`.

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
| a | Covered by a candidate case | 977 | 2,294 | 2,766 |
| b | Retired. The Roblox Engine or Compose owns the mechanism | 306 | 1,581 | 1,581 |
| c | Retired. The feature or code was deleted and is not promised | 823 | 6,079 | 6,080 |
| d | Gap. A promise remains and no candidate case verifies it | 184 | 894 | 421 |

Class c is the largest class. Most of it tested the deleted solver,
renderer, focus graph, input system, presenter, paint layer and their seams.
Those checks cannot run against the native implementation. Their retirement
is correct when the public API no longer makes the promise.

## Contract groups

"Weaker" counts the covered cases with a weaker candidate assertion. The
last column names the candidate specs that the group cites most.

| Group | Main cases | a | Weaker | b | c | d | Candidate coverage |
|---|---:|---:|---:|---:|---:|---:|---|
| Reactive core | 63 | 23 | 16 | 4 | 36 | 0 | `native_compose_contract`, `native_public_surface`, `native_navigation` |
| Lifetime and ownership | 316 | 136 | 103 | 6 | 168 | 6 | `native_conformance`, `native_stress`, `native_themes_media` |
| Layout and geometry | 1,326 | 88 | 58 | 359 | 872 | 7 | `native_inputs`, `native_navigation`, `native_parity_navigation` |
| Text measurement and fit | 497 | 54 | 38 | 232 | 202 | 9 | `native_inputs`, `native_collections`, `native_parity_navigation` |
| Focus and selection | 532 | 81 | 47 | 257 | 172 | 22 | `native_navigation`, `native_collections`, `native_inputs` |
| Input actions | 332 | 101 | 48 | 105 | 121 | 5 | `native_inputs`, `native_navigation`, `native_collections` |
| Pointer, touch and drag | 368 | 61 | 47 | 97 | 208 | 2 | `native_collections`, `native_radial_controls`, `native_virtual_monitors` |
| Scrolling | 330 | 82 | 60 | 100 | 137 | 11 | `native_collections`, `native_gallery_collections`, `native_virtual_monitors` |
| Motion | 581 | 120 | 80 | 33 | 404 | 24 | `native_themes_media`, `native_navigation`, `native_inputs` |
| Paint and theming | 709 | 199 | 71 | 70 | 440 | 0 | `native_themes_media`, `native_inputs`, `native_navigation` |
| Theme packages | 379 | 146 | 68 | 0 | 233 | 0 | `native_themes_media`, `native_inputs`, `native_gallery_shell` |
| Icons and media | 251 | 86 | 66 | 37 | 98 | 30 | `native_themes_media`, `native_stress`, `native_public_surface` |
| Action controls | 394 | 62 | 57 | 1 | 297 | 34 | `native_inputs`, `native_navigation`, `native_themes_media` |
| Value controls | 249 | 221 | 128 | 0 | 28 | 0 | `native_inputs`, `native_parity_controls`, `native_themes_media` |
| Text input | 119 | 51 | 26 | 28 | 21 | 19 | `native_inputs`, `native_navigation`, `native_collections` |
| Menus and pickers | 141 | 102 | 58 | 0 | 38 | 1 | `native_navigation`, `native_parity_navigation`, `radial_geometry` |
| Navigation containers | 72 | 59 | 36 | 1 | 2 | 10 | `native_navigation`, `native_gallery_shell`, `native_radial_controls` |
| Presented surfaces | 287 | 116 | 81 | 5 | 158 | 8 | `native_navigation`, `native_parity_navigation`, `native_gallery_parity` |
| Virtual collections | 214 | 151 | 127 | 3 | 52 | 8 | `native_collections`, `native_gallery_collections`, `native_perf_principles` |
| Tables | 156 | 76 | 40 | 1 | 58 | 21 | `native_collections`, `native_gallery_workflows`, `native_gallery_collections` |
| Row actions | 264 | 149 | 101 | 0 | 112 | 3 | `native_collections`, `native_parity_controls`, `native_gallery_workflows` |
| HUD and world targets | 166 | 43 | 34 | 50 | 70 | 3 | `native_hud`, `native_themes_media`, `native_outpost_terminal` |
| Adaptive environment | 419 | 27 | 17 | 51 | 336 | 5 | `native_navigation`, `native_parity_navigation`, `native_radial_controls` |
| Public surface | 366 | 86 | 59 | 0 | 277 | 3 | `native_conformance`, `native_registration`, `native_parity_gaps` |
| Docs, examples and tooling | 498 | 18 | 11 | 0 | 447 | 33 | `native_documentation`, `native_registration`, `scenario_require_paths` |
| Gallery and examples | 425 | 204 | 120 | 113 | 66 | 42 | `native_gallery`, `native_games`, `native_gallery_collections` |
| Reference apps | 327 | 59 | 38 | 22 | 153 | 93 | `native_reference_apps`, `native_outpost_rules`, `scenario_require_paths` |
| Performance | 792 | 82 | 34 | 4 | 704 | 2 | `native_perf_principles`, `native_themes_media`, `native_perf_lab` |
| Replication and server state | 55 | 19 | 14 | 0 | 24 | 12 | `native_outpost_terminal`, `native_stress`, `native_gallery` |
| Error handling and refusals | 220 | 64 | 14 | 2 | 146 | 8 | `native_navigation`, `native_parity_navigation`, `native_parity_gaps` |

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
| B4 | `src/ui/inputs.luau` | A number TextInput commits after its parse callback disables it | Mount TextInput with presentation = "number", enabled cell true, and parse that sets enabled to false. Capture focus, set Text to "5", release focus with submit. Expect no onCommit and numericValue 2. Actual: onCommit runs and numericValue becomes 5. |
| B5 | `src/ui/inputs.luau` | onPointerCancel alone never fires | Mount Button with only onPointerCancel. Fire InputBegan (MouseButton1) and MouseLeave. Expect one call. Actual: zero. The listeners connect only when repeatDelay, repeatInterval, onPointerDown or onPointerUp is present. |
| B6 | `src/ui/inputs.luau` | Input controls ignore GuiService.ReducedMotionEnabled | Set GuiService.ReducedMotionEnabled = true and do not pass the reducedMotion factory option. Mount Button with pop = true, fire Activated and heartbeat 0.1. Expect UIScale.Scale 1. Actual: the pop animates. The StyleSheet and the navigation surfaces follow GuiService; Button pop, the validation pulse and the busy dots do not. |
| B7 | `src/ui/collections.luau` | A readable follow option is accepted and ignored | Mount VirtualList with follow = Compose.cell("end"). Expect an error, because api.md says follow is static and an unsupported option causes an error. Actual: it mounts and behaves as follow = "none". |
| B8 | `src/ui/media.luau` | Label with an icon returns a Frame | Mount Label with text and icon. Expect a TextLabel root, as api.md says. Actual: a Frame. |
| B10 | `src/ui/inputs.luau` | Button corners rejects a readable, but Badge corners accepts one | Mount Button with corners = Compose.cell("square"). Expect it to mount, the same as Badge. Actual: an error. api.md does not say that corners is static. Low severity. |
| E2 | `examples/gallery/examples/02_playlist_table.luau` | Playlist plays a track on one click; its hint says double-click | Mount the playlist and fire one RowHit.Activated with MouseButton1. Expect selection only. Actual: nowPlaying changes. |
| E3 | `examples/themes/ornate_gauge.luau, examples/themes/custom_control.luau` | Theme fixtures call deleted constructors | Call each fixture blueprint with Facet.controls(runtime). Expect a mounted view. Actual: UI.ZStack, UI.HStack and UI.VStack are nil. docs/guide/13-theme-catalog.md still calls them tested fixtures. |

### Fixed during the audit

The concurrent session fixed these reported defects before the recheck:

- `91702428`: Transparent tap-away catchers became opaque at PreferredTransparency 0; the theme scrim did not reach the modal scrim.
- `f2929ef1`: Picker valueAlignment was inert; Stepper used text glyphs; Badge corners did not follow a readable.
- `8781d9f8`: define accepted malformed type roles and unknown shadow presets; unreadable selected-label contrast passed.
- `8b19bba9`: corners layers ignored layer.asset; derived packages kept stale state art; skinned toggle fills were outranked.
- `3aa388a5`: Alert shortcut "cancelAction" and non-table transitions were silently ignored.

### Fixed with the paint and theme tests

A test in the new paint and theme specs showed each of these defects. The
same change fixes it.

| ID | File | Defect |
|---|---|---|
| B11 | `src/ui/nav_menu.luau` | A Picker with `indicator = "none"` removed every selection cue. The chosen option now keeps its static current tags. |
| B12 | `src/ui/themes.luau` | The transparency preference scaled dividers, soft fills, current-choice fills and package rules. At preference 0, an accent caption sat on an opaque accent fill. Now the preference scales only the scrim. |
| B13 | `src/ui/media.luau` | Label accepted an unknown `textRole` and added an inert tag. Now it causes an error. |
| B14 | `src/ui/themes.luau` | A package that set `body` and `control` but not `strong` or `numeral` got the neutral face for them. Now `define` derives them from the package face. |
| E1 | `examples/gallery/examples/05_word_game.luau` | The word-game keys and the active row did not show their state. The keys now use Button appearances, and the active row has an outline. The caret has the empty color, so the caret mark is the cue. |
| E4 | `examples/gallery/scenarios/status_indicator.luau` | The guide label used `textRole = "secondary"`. It now uses `role = "secondary"`. |
| E5 | `examples/gallery/scenarios/recipes_common.luau`, `examples/gallery/examples/06_tile_game.luau` | The recipe dividers used a fixed inset and color. They now use the theme spacing, hairline and `facet-divider` paint. A pending crossword tile now has an outline. A committed tile does not. |

### Fixed with the control and navigation tests

A test in the new control and navigation specs showed each of these
defects. The same change fixes it. `bugs` in the data file has each
reproduction.

| ID | File | Defect |
|---|---|---|
| B2 | `src/ui/collection_row_actions.luau` | Full swipe runs an action on an unmeasured row. |
| B3 | `src/ui/collection_row_actions.luau` | A kept row stays collapsed after a destructive action. |
| B9 | `src/ui/media.luau` | ProgressView endLabel hides the showValue readout. |
| B15 | `src/ui/collection_row_actions.luau` | A write to the open cell of a coordinated row closed at once. |
| B16 | `src/ui/collection_row_actions.luau` | A selected table row could not reach its row actions. |
| B17 | `src/ui/collection_reorder.luau` | A horizontal keyboard move stepped with Up and Down only. |
| B18 | `src/ui/nav_menu.luau` | A menu opened by a selection player selected the panel. |
| B19 | `src/ui/nav_menu.luau` | Picker refused a readable indicator that holds nil. |
| B20 | `src/ui/inputs.luau` | Rating and LevelPicker published values outside their run. |
| B21 | `src/ui/inputs.luau` | Toggle accepted a read-only mixed state without onChange. |

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

[`tests/native_parity_paint.spec.luau`](../../tests/native_parity_paint.spec.luau)
closes every gap in the paint and theming group. A contract that two cases
close counts once, in the first row.

| Candidate case | Closes | Main cases | Also partly covers |
|---|---|---:|---|
| compiles the button role and appearance vocabulary to palette rules above their base states | paint-02, paint-08, paint-110, paint-119, themes-P2-39 | 13 | - |
| tags each button role, appearance and corner choice for the matching rule | paint-02, paint-08, paint-119 | 0 | - |
| moves the picker current-option tags with the selection and the indicator choice | navigation-3-50, paint-29 | 9 | - |
| keeps the picker menu catcher invisible at every background preference | navigation-4-12 | 3 | - |
| marks the selected tab by placement and indicator choice | navigation-5-22 | 1 | - |
| paints every value-control own slot solid in every shipped package and palette | paint-106, themes-P2-32, themes-P2-34, themes-P4-25 | 7 | - |
| tags unskinned value-control slots for their own paint and keeps the tags when skinned | paint-75, themes-P5-28 | 4 | themes-P5-35 |
| repaints corner radii and type roles in place when package metrics change | paint-114, themes-P2-21, themes-P5-42 | 6 | - |
| compiles every type role to native font rules and tags labels with their role | themes-P3-10 | 5 | paint-148 |
| compiles palette chrome gradients to UIGradient rules and removes them with the palette | themes-P2-09, themes-P3-12, themes-P5-13 | 6 | - |
| orders rule priority by declaration with states after rests and package rules last | themes-P2-11 | 2 | - |
| keeps an icon badge icon through reactive status paint and switches badge appearances | themes-P1-47, themes-P1-49 | 2 | - |
| skins the badge seal from the package badge slot and removes it with the package | themes-P2-16 | 4 | - |
| blends a bound dimmed async image and restores it | themes-P1-125 | 1 | - |
| lets per-view slider images replace the theme skin on that node only | themes-P2-25, inputs-227 | 7 | themes-P4-10 |
| leaves icon tint and transparency to the style sheet | themes-P2-63 | 1 | - |
| keeps the selected label readable on the selection fill and its sampled art in every shipped theme | themes-P5-23, themes-P5-46 | 7 | - |
| treats a garbage transparency preference as the identity | themes-P5-48 | 2 | - |
| scales only the scrim backdrop by the transparency preference | themes-P5-49 | 8 | - |
| insets and paints the recipe dividers from the installed theme | apps2-221 | 1 | - |
| marks the active word row and pending crossword tiles without relying on color | apps2-19, apps2-26 | 6 | - |
| selects every tag the framework emits with a rule in every shipped sheet | themes-P5-41 | 9 | - |

`keeps a transparent menu catcher transparent at every background preference`
in `native_navigation` also covers navigation-4-12.

[`tests/native_parity_themes.spec.luau`](../../tests/native_parity_themes.spec.luau)
closes every gap in the theme packages group.

| Candidate case | Closes | Main cases | Also partly covers |
|---|---|---:|---|
| derives unauthored strong and numeral roles from the package face | paint-152 | 3 | - |
| authors circular and spinner metrics in every reference package across a twofold span | themes-P1-69 | 10 | - |
| answers the progress metrics from neutral for a package that authors none | themes-P1-70 | 1 | - |
| resolves content and contentId to the same skin and icon image | themes-P2-01 | 2 | themes-P3-22 |
| refuses an unknown text role and follows a bound role | themes-P3-26 | 1 | - |
| inherits unrestated base values in a derived package and gates it as strictly | themes-P4-29 | 2 | - |
| rejects non-finite theme numbers with the field path | themes-P4-33 | 1 | themes-P4-42 |
| paints omitted semantic pairs from the neutral fallbacks in every palette | themes-P4-37 | 3 | - |
| falls back to default art for unstated states and ranks disabled over pressed over hover over selected | themes-P4-46 | 1 | - |
| shows the derived default art in a state the derived package no longer declares | themes-P4-50 | 1 | - |
| exercises every declared theme class of each reference package against neutral | themes-P5-03 | 13 | - |
| names declared rbxassetid assets in every chrome and icon recipe | themes-P5-04 | 5 | - |
| compiles and skins a full stack when a declared asset is bogus | themes-P5-05 | 2 | - |
| declares distinct success and warning pairs in every reference palette | themes-P5-15 | 2 | - |
| pairs touch and pointer metrics, hover art and the tile stripe | themes-P5-22 | 5 | - |
| loads only shipping theme package modules from the gallery theme folder | apps2-118 | 3 | - |
| lists Neutral first then names, keeps the installed package on reselection and selects a palette | apps2-117 | 3 | - |

### Control and navigation parity tests

[`tests/native_parity_controls.spec.luau`](../../tests/native_parity_controls.spec.luau)
and
[`tests/native_parity_navigation.spec.luau`](../../tests/native_parity_navigation.spec.luau)
close 117 contracts with 254 main cases. They cover the value
controls, the input actions, the row actions, Menu, TabView, Picker, Sheet,
Callout and Alert. A contract that several cases close counts its main cases
on its first case.

| Spec | Candidate case | Closes | Main cases | Also partly covers |
|---|---|---|---:|---|
| `native_parity_controls` | repaints a chip in place, refuses incomplete chips and honors live and inherited disabled | inputs-55, inputs-57, inputs-61, inputs-72 | 5 | - |
| `native_parity_controls` | stops a held value adjustment when a modal takes input and waits for a fresh press | inputs-81 | 3 | - |
| `native_parity_controls` | refuses malformed level picker and rating declarations with named errors | inputs-104, inputs-150 | 7 | - |
| `native_parity_controls` | publishes level values inside the declared run and paints glyphs in place | inputs-105, inputs-109, inputs-151, inputs-152 | 7 | - |
| `native_parity_controls` | refuses pointer, drag and focused adjustment on a disabled level picker, rating and slider | inputs-114, inputs-156, inputs-224 | 4 | - |
| `native_parity_controls` | requires a request callback for a read-only toggle value or mixed state | inputs-202 | 2 | - |
| `native_parity_controls` | edits the consumer's caller-owned sound value through its toggle | apps2-02 | 1 | - |
| `native_parity_controls` | shows a bar value readout beside its label, keeps the end label with it and applies thickness | paint-42, paint-44 | 4 | - |
| `native_parity_controls` | mounts and removes a live badge caption while keeping its icon and plate | themes-P1-53 | 1 | - |
| `native_parity_controls` | sizes skeleton and status indicator rungs live and recovers from an illegal rung | themes-P1-89, themes-P1-91, themes-P1-114 | 3 | - |
| `native_parity_controls` | puts per-view slider artwork ahead of the theme skin and keeps the theme skin without it | themes-P4-10 | 5 | - |
| `native_parity_controls` | drops the toggle pill under skin art, restores it without art and keeps the knob geometry | themes-P5-35 | 5 | - |
| `native_parity_controls` | recovers a kept row after a destructive commit so a later commit runs again | collections-72 | 1 | - |
| `native_parity_controls` | closes an open row on another row's gesture or menu, the Cancel key, and unmount | collections-77, collections-287 | 4 | - |
| `native_parity_controls` | toggles the row menu with Shift+Return, reveals it with ButtonX and dismisses it with the row | collections-84, collections-86, collections-287 | 8 | - |
| `native_parity_controls` | moves pad selection into a revealed tray and back, and deletes once from either key | collections-187, collections-287 | 9 | - |
| `native_parity_controls` | keeps a destructive commit running through a sibling gesture and a table scroll | collections-89, collections-287 | 2 | - |
| `native_parity_controls` | declines row gestures until actions exist and keeps the drag detector off without them | collections-282 | 1 | - |
| `native_parity_controls` | coordinates table row trays, closes them on body scroll and deletes from a focused row | collections-170, collections-173, collections-194 | 14 | - |
| `native_parity_controls` | refuses a reorder that would displace a pinned row and accepts one that keeps it in place | collections-121 | 1 | - |
| `native_parity_controls` | cancels an armed keyboard move when keyboard and gamepad both leave and keeps it when a pointer arrives | collections-40 | 2 | - |
| `native_parity_controls` | reorders a horizontal list along X by pointer, autoscroll and Left and Right stepping | collections-256 | 4 | - |
| `native_parity_controls` | finds the insertion slot from measured midpoints on ragged rows | collections-303 | 1 | - |
| `native_parity_controls` | binds modifier shortcuts only with their modifier and adds the unmodified dialog key | inputs-101 | 5 | - |
| `native_parity_controls` | activates a selected button once per Activate action press and once per native activation | - | 0 | apps-163 |
| `native_parity_controls` | moves radial selection and the commit candidate together on the D-pad and returns to it after the stick | apps2-184 | 2 | - |
| `native_parity_controls` | combines table row actions with reorder handles, editing, refresh and disposal | collections-170 | 0 | - |
| `native_parity_controls` | closes a swiped playlist tray when the table scrolls | - | 0 | apps2-35 |
| `native_parity_controls` | never commits or opens a row that has no measured width | collections-114 | 2 | - |
| `native_parity_controls` | keeps Delete and swipes inert while the row menu is open and leaks nothing across menu toggles | collections-51, collections-82 | 5 | - |
| `native_parity_navigation` | pages tabs with the shoulders from the strip, wraps there and clamps when paging from content | navigation-4-63, navigation-5-13 | 4 | - |
| `native_parity_navigation` | pages the inner tab view from nested content, clamps at its boundary and leaves the outer tabs | navigation-4-65 | 1 | - |
| `native_parity_navigation` | builds only visited tabs and disposes departing pages under top retention | navigation-5-17, navigation-5-18 | 6 | - |
| `native_parity_navigation` | resolves a nested tab view to a top band and keeps nesting balanced after a failed page | navigation-5-08 | 3 | - |
| `native_parity_navigation` | places sidebar head and foot accessories around the strip and passes the placement to builders | navigation-5-35 | 3 | - |
| `native_parity_navigation` | docks trailing and above-bar accessories against the band and re-homes them with the placement | navigation-5-36, navigation-5-38, navigation-5-40 | 7 | - |
| `native_parity_navigation` | refuses unknown accessory slots, non-function builders, unhostable slots and malformed transitions | navigation-5-26, navigation-5-42, navigation-5-52 | 6 | - |
| `native_parity_navigation` | uses a plain native frame and hides the old page immediately when no transition is declared | navigation-5-25, navigation-5-50 | 2 | - |
| `native_parity_navigation` | labels tabs by id, keeps icon-only names accessible and badges unselected tabs in place | navigation-5-21 | 3 | - |
| `native_parity_navigation` | underlines the selected top tab by default, fills bottom and sidebar tabs and follows the indicator | - | 0 | - |
| `native_parity_navigation` | keeps every tab at the 44 pixel target floor and reads a bound text size and rail width | navigation-5-23, navigation-5-30, navigation-5-31 | 4 | - |
| `native_parity_navigation` | reveals an offscreen selected tab once and never scrolls for a visible one | navigation-5-06 | 2 | - |
| `native_parity_navigation` | keeps the strip, the page and its owner across placement changes and round trips | navigation-1-02 | 3 | - |
| `native_parity_navigation` | moves adaptable tabs to a top band while a gamepad is the preferred input | navigation-1-03 | 1 | - |
| `native_parity_navigation` | orders customized tabs, skips stale ids, protects required tabs and falls back from a hidden selection | navigation-4-61 | 1 | - |
| `native_parity_navigation` | keeps a retained tab's scroll position on return and resets it when restoreScroll is off | navigation-4-67 | 1 | - |
| `native_parity_navigation` | opens a menu only through its declared triggers and binds the keyboard and gamepad chords | navigation-2-27 | 5 | - |
| `native_parity_navigation` | opens a wholly disabled menu and keeps it open when a disabled item is activated | navigation-2-29 | 2 | - |
| `native_parity_navigation` | unwinds submenus one level at a time and enters a branch only from a focused branch row | navigation-2-31, navigation-2-37, navigation-2-44 | 6 | - |
| `native_parity_navigation` | follows the presentation option and touch input between the menu and sheet idioms | navigation-2-32, navigation-2-36, navigation-2-39 | 7 | - |
| `native_parity_navigation` | toggles nested checked items in both idioms and releases every level with the trigger | navigation-2-38, navigation-2-72 | 4 | - |
| `native_parity_navigation` | anchors the menu panel below its trigger, sizes it from the widest row and keeps it inside the viewport | navigation-3-76, navigation-3-87 | 4 | - |
| `native_parity_navigation` | keeps a picker and menu tap-away catcher invisible at every background preference | navigation-5-54 | 2 | - |
| `native_parity_navigation` | picks from a vertical radio group and moves the current paint with the selection and indicator | navigation-3-86 | 1 | - |
| `native_parity_navigation` | sizes segments by fill or hug without replacing them and refuses unknown sizing | navigation-3-63 | 4 | - |
| `native_parity_navigation` | refuses malformed picker options, labels, icons, indicators, axes and styles | apps-198, navigation-3-52, navigation-3-55, navigation-3-81, navigation-4-18, navigation-4-35 | 10 | - |
| `native_parity_navigation` | resolves the automatic picker by width, description, count, input and query | navigation-2-23, navigation-3-74 | 5 | - |
| `native_parity_navigation` | never shows a selection redirected inside onChange to observers | navigation-3-70 | 1 | - |
| `native_parity_navigation` | closes a menu picker by trigger or Back without changing the selection | navigation-3-77 | 1 | - |
| `native_parity_navigation` | refuses unknown and duplicate sheet detents and a read-only detent source | navigation-4-45 | 1 | - |
| `native_parity_navigation` | dismisses a sheet dragged below its smallest detent and keeps a 44 pixel grabber | navigation-4-40 | 1 | - |
| `native_parity_navigation` | continues a grab during a detent change from the painted height | navigation-4-48 | 1 | - |
| `native_parity_navigation` | gates callout eligibility on sessions, seen and feature use and refuses a missing onRetire | navigation-1-54, navigation-1-55 | 5 | - |
| `native_parity_navigation` | frees the callout queue slot when the showing callout is disposed | navigation-1-61 | 1 | - |
| `native_parity_navigation` | aligns a callout to the anchor edges, flips it above near the bottom and omits an unrequested tail | navigation-1-40, navigation-1-43 | 4 | - |
| `native_parity_navigation` | keeps device names out of the control sources | navigation-1-63 | 1 | - |
| `native_parity_navigation` | adds a default OK action and keeps an alert open on outside taps and custom content buttons | navigation-1-26, navigation-1-29, navigation-2-61 | 3 | - |
| `native_parity_navigation` | refuses misspelled alert fields, duplicate action ids, two cancel actions and malformed transitions | navigation-1-28, navigation-1-35 | 4 | - |
| `native_parity_navigation` | lays out alert actions in a row with the cancel action first and stacks them for long labels | navigation-1-16, navigation-1-20, navigation-3-31 | 7 | - |
| `native_parity_navigation` | grows an alert message to its content when the card has room and bounds it when it does not | navigation-1-19 | 4 | - |
| `native_parity_navigation` | mounts an alert title only while it has visible text and wraps a long title across the card | navigation-1-38 | 4 | - |
| `native_parity_navigation` | releases an open alert with its owner and returns selection to the opener | navigation-1-25 | 1 | - |
| `native_parity_navigation` | opens each menu scenario card only through its printed routes and runs nothing from the blocked card | navigation-2-51, navigation-2-53, navigation-2-57 | 9 | - |
| `native_parity_navigation` | keeps the callout scenario reset chip on screen at the 44 pixel floor and resets the session | navigation-1-66 | 1 | - |

The cases also assert navigation-3-50, navigation-4-12 and navigation-5-22.
These contracts are in the paint and theming group, and the paint parity
tests close them.

These gaps close only in part. A live Studio check must show the rest:

- apps-163: One physical Return press on a selected Button must reach
  `onActivate` once. The Activate InputAction and native `Activated` can both
  see the press.
- apps2-35: A swipe on a playlist row must not also fire `RowHit.Activated`
  and play the track.
- collections-84: Shift+Return on a focused row must open the row menu. The
  focused content Button has an Activate context at priority 5000 on Return.
  RowActionsToggle has priority 300.

navigation-3-84 moved to class c. `api.md` no longer lists the Picker
`valueAlignment` option, and a declared `valueAlignment` causes an error.

## Proposed tests for the largest gaps

Each proposal is headless. Use the fake engine in `tests/lib/native_engine.luau`.

- **Control size.** Mount Button and ShortcutHint with `controlSize = "tiny"`. Expect an error that names compact, regular and large. Bind a cell and set an illegal value. Expect the last legal height.
- **Icons.** For each shipped package, call `checkCoverage` with every icon name that a control requests. Expect no missing name.
- **Tables.** Mount a Table with fixed and flexible columns. Set the viewport size. Expect the header and body column edges to match. Expect no resize grip on a column with `resizable = false`.
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
| apps2-101 | Lifetime and ownership | 3 | Demo cleanup ordering: resources outlive the presented tree; same-frame dispose+dismiss is clean; self-presenting demo disposed once |
| navigation-2-04 | Lifetime and ownership | 2 | Expanded CollapsibleView releases its surface on unmount and across open/close cycles |
| themes-P1-92 | Lifetime and ownership | 1 | Held shared driver released after later construction refuses |
| apps2-192 | Layout and geometry | 3 | Corner/portrait rings keep >=44px buttons inside the surface before falling back |
| apps2-61 | Layout and geometry | 2 | Wrap toggle flips wrapping on the same nodes; Block align moves only the block |
| navigation-1-69 | Layout and geometry | 1 | Nothing on the callout page crosses a lateral edge at swept sizes |
| themes-P1-48 | Layout and geometry | 1 | Icon badge height equals plain caption; icon side respected |
| paint-148 | Text measurement and fit | 9 | Type roles compile to native font rules and tags |
| collections-255 | Focus and selection | 4 | Horizontal list Left/Right steps, Up/Down inert, D-pad parity, scroll into view |
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
| navigation-3-16 | Focus and selection | 1 | Remembered target disabled while away falls back to first selectable |
| apps-163 | Input actions | 5 | Exactly one Activate per press across the InputAction and native Activated paths |
| apps2-208 | Pointer, touch and drag | 1 | Item disabled mid-drag does not fire on release |
| apps2-215 | Pointer, touch and drag | 1 | centerPassThrough leaves the center input-transparent |
| collections-128 | Scrolling | 3 | Snap at the end of the list: the last page settles to the end; a decisive drag back leaves it |
| collections-225 | Scrolling | 3 | The grid anchor holds under line-extent and column-count changes |
| collections-129 | Scrolling | 2 | Snap idle churn guard and snap vocabulary refusal |
| collections-216 | Scrolling | 1 | Shrinking rows at the bottom leaves the list flush |
| collections-250 | Scrolling | 1 | Keep-visible writes X on a horizontal list |
| collections-302 | Scrolling | 1 | Shrinking the end corrects the engine |
| themes-P1-76 | Motion | 6 | Visible-step count and full-vs-reduced write differential for bar/circular/spinner |
| apps2-92 | Motion | 4 | The motion setting survives a demo swap |
| navigation-3-04 | Motion | 3 | NavigationStack fade transition and reduced-motion swap |
| apps-258 | Motion | 2 | Source that moves or is a readable during flight; keeps last origin when it disappears |
| inputs-25 | Motion | 2 | No pop transform without pop; held repeat does not re-kick pop |
| navigation-3-24 | Motion | 2 | Fade transitions retire pages; rapid forward/back leaves one opaque interactive page |
| paint-37 | Motion | 2 | Indeterminate bar sweeping segment stays inside the track |
| inputs-162 | Motion | 1 | Control motion follows the player's reduced-motion preference with no consumer wiring |
| themes-P1-75 | Motion | 1 | Reduced motion sub-tick hold then move: indeterminate bar |
| themes-P1-78 | Motion | 1 | Switching policy mid-cycle steps, never restarts |
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
| paint-60 | Action controls | 1 | Button pointer callbacks |
| inputs-196 | Text input | 6 | Numeric parse/format/validate cannot commit after disabling or disposing the control |
| apps2-29 | Text input | 5 | Temperature converter: numeric field only, live Preview vs committed Result, Enter and focus-loss commit, validate rejects |
| inputs-185 | Text input | 2 | Invalid UTF-8 edits are rejected |
| inputs-188 | Text input | 2 | clearButton=true means always; unknown mode is refused |
| inputs-197 | Text input | 1 | Numeric specs refuse nonfinite bounds and bad callbacks |
| inputs-73 | Text input | 1 | TextInput refuses both enabled and disabled |
| navigation-2-09 | Text input | 1 | ComboBox refuses malformed/missing required fields |
| navigation-2-12 | Text input | 1 | Custom validation that disposes the control cannot commit |
| apps2-212 | Menus and pickers | 1 | launcher=false leaves no built-in trigger |
| navigation-5-47 | Navigation containers | 5 | Scenario behaviors still promised but untested: pill in adaptable nav, badge on unselected tab, 44px floor, shoulders, reveal-once |
| apps2-107 | Navigation containers | 2 | Stepping wraps both ways, a full cycle returns, unknown current id yields a real demo |
| apps2-200 | Navigation containers | 2 | One navigation control per center policy; Close/Back by depth |
| apps2-202 | Navigation containers | 1 | Removing an open ancestor returns to the nearest valid page |
| apps2-46 | Presented surfaces | 6 | Confirm dialog outcomes: Delete opens, Cancel records kept, Confirm changes the screen, Restore repeats, double Delete does not stack |
| inputs-93 | Presented surfaces | 2 | Help plate takes no focus and wraps long text |
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
| apps2-35 | Row actions | 3 | Scrolling the page closes a swiped-open tray; a swipe never plays the track (touch and mouse) |
| apps2-190 | HUD and world targets | 2 | Anchor clearance sizes the hole; follow=fixed keeps opening geometry |
| themes-P1-101 | HUD and world targets | 1 | Camera position/lookAt/fov |
| collections-110 | Adaptive environment | 4 | A short landscape drops the heading; the first row is visible on all surfaces |
| navigation-3-23 | Adaptive environment | 1 | Viewport/theme/input/reduced-motion switches keep the mounted page |
| apps-117 | Public surface | 1 | init.luau re-exports contract types |
| inputs-67 | Public surface | 1 | compactLabel refused on content/icon/image buttons |
| navigation-3-17 | Public surface | 1 | Malformed specs, paths and route entries are refused before creating a page |
| apps2-139 | Performance | 1 | Row count clamped to the declared ceiling |
| apps2-148 | Performance | 1 | Two captures are the same workload only when every identity field agrees |
| apps2-42 | Replication and server state | 7 | Settings sync: every state reachable by on-screen controls, status names next action, reset unanswered, second change refused visibly, idle Deliver explains, bounded newest-first history |
| apps2-128 | Replication and server state | 5 | Unengaged terminal sends nothing and states the objective; ADJUST updates budget line/verdict; an edit retires the last outcome; exit is idempotent |
| apps2-115 | Error handling and refusals | 2 | A demo that cannot build is not reported mounted; the scriptable API answers with what it delivered |
| apps2-83 | Error handling and refusals | 2 | A demo that cannot be mounted is stamped and spoken |
| collections-50 | Error handling and refusals | 2 | A theme metrics snapshot without derived row keys, or with NaN scale, falls back |
| paint-41 | Error handling and refusals | 1 | Unknown ProgressView presentation refused |
| themes-P4-42 | Error handling and refusals | 1 | Self-referential definition terminates (cycles rejected) |

Example and reference-app gaps:

| Group | Contracts | Main cases |
|---|---:|---:|
| Docs, examples and tooling | 10 | 33 |
| Gallery and examples | 14 | 42 |
| Reference apps | 43 | 93 |

## Use the data

- `totals` has the class counts before and after the new tests.
- `contracts` has one record for each contract. A record has the main
  specs, the class, the cited candidate cases and the gap.
- `producers.rows` maps each main `full` producer to its candidate status.
- `bugs` has a failing-test description for each defect. `status` is
  `open` or `fixed`. A fixed defect names the case that shows the fix.
- `totals.uncitableCandidateCases` lists citations that are not suite case
  IDs, such as producers and groups of cases.

When you close a gap, add the candidate case ID to the contract and change
its class to `a`. When you retire a promise, change `api.md` first.
