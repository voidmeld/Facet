# Verification parity with main

This page compares the verification of the native cutover with the
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
  still promises, but no candidate case tested it. This audit and the later
  fixes add tests for 59 of these cases. 835 cases remain.
- 1,679 of the 2,353 covered cases have a weaker
  candidate assertion. Usually one candidate case replaces several main
  edge cases.
- 1,581 cases moved to a Roblox Engine or Compose mechanism. For about
  845 of them, no candidate test and no live Studio record show that
  Facet uses the mechanism correctly.
- Of 130 main `full` producers, no producer is a gap. Five producers run
  but wait for live Studio evidence, and four are weaker replacements. See
  [Producers](#producers).
- A complete run writes `artifacts/verify/latest-<tier>.json` with release
  gate evidence. `tools/package.sh publish` reads the `release` file and
  refuses anything but a clean, passing run of the same source.
- The audit found 10 open defects in `src` and 3 in the examples. One
  example defect is fixed.

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
| a | Covered by a candidate case | 806 | 2,294 | 2,353 |
| b | Retired. The Roblox Engine or Compose owns the mechanism | 306 | 1,581 | 1,581 |
| c | Retired. The feature or code was deleted and is not promised | 822 | 6,079 | 6,079 |
| d | Gap. A promise remains and no candidate case verifies it | 356 | 894 | 835 |

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
| Docs, examples and tooling | 498 | 20 | 11 | 0 | 447 | 31 | `native_documentation`, `native_registration`, `scenario_require_paths` |
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
| Accessibility and localization corpus | Corpus CLI and fixtures | `native_a11y_l10n_corpus`: accessible names of 36 controls and every gallery demo; 14 strings through 20 text controls |

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

Main ran 130 producers in its `full` tier. The table below gives the status
of each one after the producer restoration. The data is in `producers.rows`.

| Status | Main `full` producers |
|---|---:|
| Equivalent candidate producer | 45 |
| Replaced by a different check | 15 |
| Replaced by a weaker check | 4 |
| Producer runs; its live evidence is not recorded | 5 |
| Retired with its subject | 61 |
| Total | 130 |

No main producer is a gap now. Each main producer is equivalent, replaced,
retired with its subject, or has a candidate producer that waits for live
evidence.

### How the candidate runs its producers

`tools/verify.sh <tier>` runs every producer whose tiers include that tier.
Use `--explain` to see each selected producer, its environment, its tiers and
the main producers that it replaces.

- A producer that exits 0 passes.
- A studio or device producer that exits 2 reports `FAIL_ENVIRONMENT`. Its
  live evidence is not recorded in this checkout.
- A perf producer that exits 2 reports `FAIL_ENVIRONMENT`. A host timing
  budget failed. With `--reference-host`, the same result is `FAIL`.
- Any other exit code is `FAIL`.
- The `full` tier reports `FAIL_ENVIRONMENT` and continues. The `release`
  tier stops on it.

Main put `perf` and `bench` in the `release` tier only, and its `full` tier
read a recorded report. The candidate runs `perf` and `bench` in `full`, and
then checks the report of the same run.

At the producer recheck, `tools/verify.sh full --explain` selected 71
producers: 61 passed, 9 reported `FAIL_ENVIRONMENT` and 1 failed. The failure
is `coverage`, because `tools/lune/parity_blockers.json` lists three pending
live risks. The `FAIL_ENVIRONMENT` results are the five Studio evidence modes,
the missing cited artifacts of `live-evidence`, and the host timing results of
`perf`, `bench` and the `perf-gate` evidence mode. The host ran several Roblox
Studio sessions during the run, so its timings are not reference timings.

### Equivalent producers

| Main producer | Candidate producer | Tier | Note |
|---|---|---|---|
| `check_public_surface` | `public-surface` | full, release | Snapshot of the public surface in tools/public_surface.txt, including the controls table and exported types. |
| `build_model` | `model-build` | full, release | Moved from a CI-only step into the full tier. |
| `build_places` | `standalone-builds` | full, release |  |
| `build_reference_places` | `reference-builds` | full, release |  |
| `build_themes` | `theme-builds` | full, release |  |
| `build_word_lists-check` | `word-data` | full, release |  |
| `build_word_lists-selftest` | `word-data-selftest` | full, release |  |
| `check_experiment_markers` | `experiment-markers` | fast, full, release |  |
| `check_brand_drift` | `brand-drift` | full, release | Old-brand and vendor-name rules; the sibling game and studio trees are skipped when absent. |
| `check_brand_drift-selftest` | `brand-drift-selftest` | full, release |  |
| `check_brand_drift-skip-builds` | `brand-drift-skip-builds` | full, release |  |
| `check_call_shape_drift` | `call-shape-drift` | full, release | Refuses calls to constructors and scaffolding that the native API removed, in examples, bench, tests and doc snippets. |
| `check_call_shape_drift-selftest` | `call-shape-drift-selftest` | full, release |  |
| `check_doc_style` | `doc-style` | full, release | Scans docs/guide, docs/extending, README.md and docs/MAINTAINERS.md. |
| `check_doc_style-selftest` | `doc-style-selftest` | full, release | See check_doc_style. |
| `check_library_purity` | `package-purity` | full, release |  |
| `check_links_cli` | `links` | full, release |  |
| `check_links_cli-selftest` | `links-selftest` | full, release |  |
| `check_maintainer_map_cli` | `maintainer-map` | full, release | Checks the native module areas, the proof table and the repository table. |
| `check_maintainer_map_cli-selftest` | `maintainer-map-selftest` | full, release | See check_maintainer_map_cli. |
| `check_no_fusion` | `no-fusion` | fast, full, release |  |
| `check_no_fusion-selftest` | `no-fusion-selftest` | fast, full, release | Tool exists and passes; not run. |
| `check_no_screen_key_bindings` | `screen-key-bindings` | fast, full, release | Refuses raw key handling in example screens and doc snippets. |
| `check_no_screen_key_bindings-selftest` | `screen-key-bindings-selftest` | fast, full, release |  |
| `check_perf_budgets` | `perf-budgets` | full, release |  |
| `check_perf_captures` | `perf-captures` | full, release | Reads the lab capture schema and versions from examples/performance/lab. No capture row is recorded yet. |
| `check_perf_gate_evidence-budgets` | `perf-gate-evidence-budgets` | full, release |  |
| `check_perf_gate_evidence-falsifiable` | `perf-gate-evidence-falsifiable` | release | Release tier, after prove-perf-gate injects an 8x regression into lab-dense-scroll. |
| `check_perf_gate_evidence-headless-linkage` | `perf-gate-evidence-headless-linkage` | full, release | Checks linkage; the timing verdict belongs to the perf-gate mode. |
| `check_perf_gate_evidence-perf-gate` | `perf-gate-evidence-perf-gate` | full, release | A host timing failure is FAIL_ENVIRONMENT except on the reference host. |
| `check_perf_metrics` | `perf-metrics` | full, release |  |
| `check_perf_place` | `perf-place` | full, release | Checks the native performance place and that its workloads are byte-identical to the headless bench. |
| `check_perf_scenes` | `perf-scenes` | full, release | Native workload counters: the radial opens six sectors and settles closed each sample; dense-motion moves every spring; control-motion reports each trigger. |
| `check_perf_scenes-themes` | `perf-scenes-themes` | full, release | Native StyleRule differential replaces the solver movedRects count; Engine geometry is not solved headlessly. |
| `check_public_allowlist` | `public-allowlist` | full, release |  |
| `check_source_size` | `source-size` | full, release |  |
| `check_theme_drift_cli` | `theme-drift` | full, release | Refuses theme-owned literals in src/ui controls. |
| `check_types` | `types` | full, release |  |
| `check_types-selftest` | `types-selftest` | full, release |  |
| `doctor` | `doctor` | full, release |  |
| `package-verify` | `package-verify` | full, release | Runs tools/package.sh verify as one producer. |
| `stylua-check-check-src-tests-tools-bench-examples` | `format` | fast, full, release |  |
| `stylua-check-check-src-tests-tools-examples` | `format` | fast, full, release | Subsumed by the wider format producer. |
| `suite` | `suite` | fast, full, release | Runs 33+1 native specs (674 cases) instead of 496 specs (10,848 cases). See the contract table. |
| `package-selftest` | `package-selftest` | full, release |  |

### Replaced producers

| Main producer | Candidate producer | Tier | Note |
|---|---|---|---|
| `check_boundary` | `architecture` | fast, full, release | Private-require scan for examples and bench only; tests may require src/ui directly. |
| `check_comment_codes` | `comments` | fast, full, release | Zero-comment policy replaces comment codes. |
| `check_comment_codes-selftest` | `comments-selftest` | fast, full, release |  |
| `check_device_captures` | `live-evidence` | full, release | check_live_evidence.py validates each record in tools/lune/parity_blockers.json: required fields, cited cases, commits and evidence class. |
| `check_device_sweep-selftest` | `live-evidence-selftest` | full, release | live-evidence-selftest plants malformed records and requires each rule to fail. |
| `check_docs_cli` | `call-shape-drift` | full, release | native_documentation spec plus call-shape-drift, which checks every lua and luau snippet in docs against the native API. |
| `check_eq6_evidence` | `live-evidence` | full, release | See check_device_captures. |
| `check_manifest_integrity` | `replacement-cases` | fast, full, release | The gate manifest is deleted. replacement-cases reads each cited case verdict from the structured suite result, not from a grep. |
| `check_matrix_rows` | `live-evidence` | full, release | See check_device_captures. |
| `check_registration_cli` | `suite` | fast, full, release |  |
| `check_row_actions_matrix` | `live-evidence` | full, release | See check_device_captures. |
| `check_traversal_evidence` | `live-evidence` | full, release | See check_device_captures. |
| `check_xp_matrix` | `live-evidence` | full, release | See check_device_captures. |
| `corpus_cli` | `suite` | fast, full, release | native_a11y_l10n_corpus spec in the suite: accessible names of controls and gallery demos, and a localization string corpus. |
| `verify-selftest` | `verification-selftest` | fast, full, release |  |

### Weaker replacements

These producers run, but they cover less than the main producer.

| Main producer | Candidate producer | Tier | Note |
|---|---|---|---|
| `check_example_drift_cli` | `native_documentation`, `architecture` |  | No guide/example source drift check. |
| `faults` | `native_stress (200 seeded fault storms)` |  | Main ran 9 fault scenarios x 200 iterations. |
| `fuzz-replication` | `native_stress (400 seeded deliveries)` |  | Facet replication module deleted; test covers an example model. |
| `soak` | `native_stress (200 modal cycles, 100 structural cycles)` |  | Main soak ran the full presenter and scene soak fixtures. |

### Producers that wait for live evidence

These producers run in `full` and `release`. Each one exits 2 until a
Studio capture of the native performance lab is recorded under
`artifacts/performance-stress-places/studio`. The lab place is
`examples/performance.project.json`. The capture schema is in
`examples/performance/lab/capture.luau`. The theme-cost and large-text modes
also need a lab change: the lab captures only the neutral theme, and a capture
row has no preferred text size.

| Main producer | Candidate producer | Tier | Note |
|---|---|---|---|
| `check_perf_gate_evidence-device-matrix` | `perf-gate-evidence-device-matrix` | full, release | No emulator-class capture matrix is recorded. The producer runs and reports FAIL_ENVIRONMENT. |
| `check_perf_gate_evidence-large-text` | `perf-gate-evidence-large-text` | full, release | The native lab capture has no preferred text size field. The producer runs and reports FAIL_ENVIRONMENT. |
| `check_perf_gate_evidence-native-reference` | `perf-gate-evidence-native-reference` | full, release | No dense-scroll versus dense-scroll-native Studio pair is recorded. The producer runs and reports FAIL_ENVIRONMENT. |
| `check_perf_gate_evidence-studio` | `perf-gate-evidence-studio` | full, release | No native Studio capture of the performance lab is recorded. The producer runs and reports FAIL_ENVIRONMENT. |
| `check_perf_gate_evidence-theme-cost` | `perf-gate-evidence-theme-cost` | full, release | The native lab captures only the neutral theme; no ornate capture exists. The producer runs and reports FAIL_ENVIRONMENT. |

### Retired producers

| Main producer | Note |
|---|---|
| `check_elision_census` | Adapter elision is deleted. |
| `check_flat_baseline` | Flat baseline of the deleted renderer. |
| `check_input_authority` | Facet input system deleted; Roblox InputAction owns input. |
| `check_input_authority-selftest` |  |
| `check_perf_gate_evidence-prior-gates` | The prior-gate sweep and its gate manifest were deleted with the phase gates. |
| `check_perf_gate_evidence-scopes` | Facet microprofiler scopes (src/core/profile.luau) were deleted. Compose owns its own profile module. |
| `check_prop_parity_cli` | Deleted primitive property table. |
| `check_reuse_ledger` | Deleted instance reuse ledger. |
| `check_reuse_ledger-selftest` |  |
| `check_sf_rows-artifacts-sponsor-framework-gaps-rows-sf-a1-b7f5d0` | Sponsor framework gap rows describe deleted main features. |
| `check_sf_rows-artifacts-sponsor-framework-gaps-rows-sf-a4-478080` | Sponsor framework gap rows describe deleted main features. |
| `check_sf_rows-artifacts-sponsor-framework-gaps-rows-sf-c1-73e76f` | Sponsor framework gap rows describe deleted main features. |
| `check_sf_rows-artifacts-sponsor-framework-gaps-rows-sf-c2-725d54` | Sponsor framework gap rows describe deleted main features. |
| `check_sf_rows-artifacts-sponsor-framework-gaps-rows-sf-d1-1c5ceb` | Sponsor framework gap rows describe deleted main features. |
| `check_sf_rows-artifacts-sponsor-framework-gaps-rows-sf-d3-46e41d` | Sponsor framework gap rows describe deleted main features. |
| `check_sf_rows-artifacts-sponsor-framework-gaps-rows-sf-d4-9a25f3` | Sponsor framework gap rows describe deleted main features. |
| `check_sf_rows-artifacts-sponsor-framework-gaps-rows-sf-d5-329c3e` | Sponsor framework gap rows describe deleted main features. |
| `check_sf_rows-artifacts-sponsor-framework-gaps-rows-sf-f1-d7b43f` | Sponsor framework gap rows describe deleted main features. |
| `check_sf_rows-artifacts-sponsor-framework-gaps-rows-sf-l1-edbdee` | Sponsor framework gap rows describe deleted main features. |
| `check_sf_rows-artifacts-sponsor-framework-gaps-rows-sf-l2-dcc9ef` | Sponsor framework gap rows describe deleted main features. |
| `check_sf_rows-artifacts-sponsor-framework-gaps-rows-sf-l3-fed491` | Sponsor framework gap rows describe deleted main features. |
| `check_sf_rows-artifacts-sponsor-framework-gaps-rows-sf-m1-c62ec7` | Sponsor framework gap rows describe deleted main features. |
| `check_sf_rows-artifacts-sponsor-framework-gaps-rows-sf-m2-5a0768` | Sponsor framework gap rows describe deleted main features. |
| `check_sf_rows-artifacts-sponsor-framework-gaps-rows-sf-m4-9a0448` | Sponsor framework gap rows describe deleted main features. |
| `check_sf_rows-artifacts-sponsor-framework-gaps-rows-sf-m5-8cdae7` | Sponsor framework gap rows describe deleted main features. |
| `check_sf_rows-artifacts-sponsor-framework-gaps-rows-sf-m6-a9c408` | Sponsor framework gap rows describe deleted main features. |
| `check_sf_rows-artifacts-sponsor-framework-gaps-rows-sf-m7-c31a70` | Sponsor framework gap rows describe deleted main features. |
| `check_sf_rows-artifacts-sponsor-framework-gaps-rows-sf-m8-45ab23` | Sponsor framework gap rows describe deleted main features. |
| `check_sf_rows-artifacts-sponsor-framework-gaps-rows-sf-p1-71afb8` | Sponsor framework gap rows describe deleted main features. |
| `check_sf_rows-artifacts-sponsor-framework-gaps-rows-sf-p2-a5c718` | Sponsor framework gap rows describe deleted main features. |
| `check_sf_rows-artifacts-sponsor-framework-gaps-rows-sf-p3-1a56dc` | Sponsor framework gap rows describe deleted main features. |
| `check_sf_rows-artifacts-sponsor-framework-gaps-rows-sf-p4-d3903b` | Sponsor framework gap rows describe deleted main features. |
| `check_sf_rows-artifacts-sponsor-framework-gaps-rows-sf-p5-f34f1a` | Sponsor framework gap rows describe deleted main features. |
| `check_sf_rows-artifacts-sponsor-framework-gaps-rows-sf-t1-006c64` | Sponsor framework gap rows describe deleted main features. |
| `check_sf_rows-artifacts-sponsor-framework-gaps-rows-sf-t2-1fee50` | Sponsor framework gap rows describe deleted main features. |
| `check_sf_rows-artifacts-sponsor-framework-gaps-rows-sf-t3-b16b62` | Sponsor framework gap rows describe deleted main features. |
| `check_sf_rows-artifacts-sponsor-framework-gaps-rows-sf-w1-e07115` | Sponsor framework gap rows describe deleted main features. |
| `check_spike-artifacts-declarative-3d-architecture-costs-61165b` | Historical Studio spike receipts for the deleted architecture. |
| `check_spike-artifacts-declarative-3d-architecture-studio-694f2a` | Historical Studio spike receipts for the deleted architecture. |
| `check_spike-artifacts-studio-expansion-textinput-probe-j-378ee4` | Historical Studio spike receipts for the deleted architecture. |
| `check_spike-artifacts-studio-ias-spike-json-api-surface-c265ac` | Historical Studio spike receipts for the deleted architecture. |
| `check_spike-artifacts-studio-part2-table-phaseb-json-pla-c5d328` | Historical Studio spike receipts for the deleted architecture. |
| `check_spike-artifacts-studio-phase1-gallery-json-engine-4934a9` | Historical Studio spike receipts for the deleted architecture. |
| `check_spike-artifacts-studio-phase2-port-drive-json-flag-f8d169` | Historical Studio spike receipts for the deleted architecture. |
| `check_spike-artifacts-studio-phase2-port-drive-json-real-9df8e9` | Historical Studio spike receipts for the deleted architecture. |
| `check_spike-artifacts-studio-property-authority-spike-js-0120ab` | Historical Studio spike receipts for the deleted architecture. |
| `check_surface_ledger` | Deleted surface ledger. |
| `check_verdicts-artifacts-expansion-textinput-platform-resea-b2e918` | Historical phase verdict receipts. |
| `check_verdicts-artifacts-part-2-opus-verification-json-PASS-1ef0c4` | Historical phase verdict receipts. |
| `check_verdicts-artifacts-phase-0-opus-verification-json-PAS-86d658` | Historical phase verdict receipts. |
| `check_verdicts-artifacts-phase-1-opus-verification-json-PAS-0becfb` | Historical phase verdict receipts. |
| `check_verdicts-artifacts-phase-2-opus-verification-json-PAS-6c97e1` | Historical phase verdict receipts. |
| `check_verdicts-artifacts-phase-3-opus-verification-json-PAS-0bd394` | Historical phase verdict receipts. |
| `check_verdicts-artifacts-phase-4-opus-verification-json-ALL-6c8acd` | Historical phase verdict receipts. |
| `fuzz-layout` | The Facet solver no longer exists; Roblox layout is not fuzzed headlessly. |
| `fuzz-scheduler` | Compose owns the scheduler; the vendored snapshot is hash-checked (vendor) but its own tests are not run here. |
| `rascalrally-suite` | Downstream game suite; maintainer lockstep, external. |
| `suite_cache_selftest` | The native runner has no result cache. |
| `theme_sync_cli-dump-artifacts-theme-packages-and-skinning-t-6f81a3` | Deleted theme sync tool. |
| `archive-integrity` | External private archive; environment-specific. |
| `studio-specialist-docs` | External studio tree check. |

### Release evidence

A complete `full` or `release` run writes `artifacts/verify/latest-<tier>.json`.
Its `gateEvidence` object holds the tier, the status, the commit, whether the
tree was dirty when the run started, and the package source hash.
`tools/package.sh publish` reads `artifacts/verify/latest-release.json`. It
refuses a missing file, another tier, a failed status, a dirty tree and a
different source hash. Only a clean, passing `release` run allows a publish.
The `release` tier adds `prove-perf-gate` and the `falsifiable` evidence mode.

### CI

CI runs the `fast` and `full` tiers on `ubuntu-latest` and on the pinned
`macos-15` runner. The `macos-15` lane uses `--reference-host`, so a timing budget
failure fails that lane. On Ubuntu, a timing budget failure is
`FAIL_ENVIRONMENT`. Both lanes then build the distributable model and check
its purity.

## Defects found

Each item describes a test that failed at the recheck. The audit did not fix
them. `E3` is fixed; see [Fixed after the audit](#fixed-after-the-audit).

| ID | File | Defect | Failing test |
|---|---|---|---|
| `B1` | `src/ui/collections.luau` | wrapFocus does not wrap arrow or D-pad navigation | Mount a VirtualList of 5 rows with wrapFocus = true and focus = {}. Set AbsoluteWindowSize to (200, 100). Call focus.focus(5). Fire FacetCollectionDown.CollectionDown.Pressed. Expect focus.current to be 1. Actual: 5. The arrow actions call focusScope.move, which ignores wrap; only focus.next wraps. |
| `B2` | `src/ui/collection_row_actions.luau` | Full swipe runs an action on an unmeasured row | Mount RowActions with one trailing action and do not set AbsoluteSize. Fire DragStart (100, 0), DragContinue (85, 0), DragEnd. Expect no action. Actual: the action runs, because abs(0) >= 0 * 0.7. |
| `B3` | `src/ui/collection_row_actions.luau` | A kept row stays collapsed after a destructive action | Mount RowActions with open = "trailing", a destructive Delete action and reducedMotion = true. Set AbsoluteSize (300, 40). Activate Delete and keep the row (the server refuses). Set open to "trailing" and activate Delete again. Expect a second commit and a usable row. Actual: committing is never cleared, the UIDragDetector stays disabled and the second commit does not run. |
| `B4` | `src/ui/inputs.luau` | A number TextInput commits after its parse callback disables it | Mount TextInput with presentation = "number", enabled cell true, and parse that sets enabled to false. Capture focus, set Text to "5", release focus with submit. Expect no onCommit and numericValue 2. Actual: onCommit runs and numericValue becomes 5. |
| `B5` | `src/ui/inputs.luau` | onPointerCancel alone never fires | Mount Button with only onPointerCancel. Fire InputBegan (MouseButton1) and MouseLeave. Expect one call. Actual: zero. The listeners connect only when repeatDelay, repeatInterval, onPointerDown or onPointerUp is present. |
| `B6` | `src/ui/inputs.luau` | Input controls ignore GuiService.ReducedMotionEnabled | Set GuiService.ReducedMotionEnabled = true and do not pass the reducedMotion factory option. Mount Button with pop = true, fire Activated and heartbeat 0.1. Expect UIScale.Scale 1. Actual: the pop animates. The StyleSheet and the navigation surfaces follow GuiService; Button pop, the validation pulse and the busy dots do not. |
| `B7` | `src/ui/collections.luau` | A readable follow option is accepted and ignored | Mount VirtualList with follow = Compose.cell("end"). Expect an error, because api.md says follow is static and an unsupported option causes an error. Actual: it mounts and behaves as follow = "none". |
| `B8` | `src/ui/media.luau` | Label with an icon returns a Frame | Mount Label with text and icon. Expect a TextLabel root, as api.md says. Actual: a Frame. |
| `B9` | `src/ui/media.luau` | ProgressView endLabel hides the showValue readout | Mount ProgressView with value 0.5, showValue = true and endLabel = "End". Expect a "50%" text. Actual: no text shows the value. |
| `B10` | `src/ui/inputs.luau` | Button corners rejects a readable, but Badge corners accepts one | Mount Button with corners = Compose.cell("square"). Expect it to mount, the same as Badge. Actual: an error. api.md does not say that corners is static. Low severity. |
| `E1` | `examples/gallery/examples/05_word_game.luau` | Word-game keys and the active row no longer show state by paint | Mount the word game and guess RULES against REACT. Expect key_R and key_U to carry different surfaces, and the active row to carry an outline. Actual: the surface formulas are computed and never applied. |
| `E2` | `examples/gallery/examples/02_playlist_table.luau` | Playlist plays a track on one click; its hint says double-click | Mount the playlist and fire one RowHit.Activated with MouseButton1. Expect selection only. Actual: nowPlaying changes. |

### Fixed during the audit

The concurrent session fixed these reported defects before the recheck:

- `91702428`: Transparent tap-away catchers became opaque at PreferredTransparency 0; the theme scrim did not reach the modal scrim.
- `f2929ef1`: Picker valueAlignment was inert; Stepper used text glyphs; Badge corners did not follow a readable.
- `8781d9f8`: define accepted malformed type roles and unknown shadow presets; unreadable selected-label contrast passed.
- `8b19bba9`: corners layers ignored layer.asset; derived packages kept stale state art; skinned toggle fills were outranked.
- `3aa388a5`: Alert shortcut "cancelAction" and non-table transitions were silently ignored.

### Fixed after the audit

The producer restoration fixed these defects:

- `E3`: the theme fixtures `examples/themes/ornate_gauge.luau` and
  `examples/themes/custom_control.luau` called deleted constructors. They now
  use `Host` frames and native layouts. The `call-shape-drift` producer found
  the defect. The case "mounts the namespaced control fixtures with the
  current constructors" in `native_themes_media` covers it.
- Badge `corners` used the fixed radii 8 and 999 for `rounded` and
  `capsule`. It now reads the `radii.control` and `radii.pill` package
  metrics. The `theme-drift` producer found the defect.
- The Table column resize grip and the Slider track were selectable and had
  no accessible name. Each now sets `AccessibleLabel`. The
  `native_a11y_l10n_corpus` spec found the defect.

### Open accessibility gaps

The `native_a11y_l10n_corpus` spec found controls that have no option for an
accessible name. The spec records each one. When a fix closes a gap, the spec
fails until you remove the record.

| Control | Gap | Gallery case |
|---|---|---|
| LevelPicker | No label or name option. | Five pickers on the LevelPicker page. |
| Rating | No label or name option. Its only text is the star glyphs. | None. |
| Slider | No name option. A Slider without a visible label has no name. | The progress ring adjust slider. |
| TextInput | No label or name option. An empty field without a placeholder has no name. | The search field on the text controls page. |

## Gaps closed by this audit

[`tests/native_parity_gaps.spec.luau`](../../tests/native_parity_gaps.spec.luau)
adds these cases:

| Candidate case | Closes | Main cases | Also partly covers |
|---|---|---:|---|
| keeps the changelog release heading equal to Facet.VERSION | `apps-115` | 1 | - |
| refuses an unknown lower-case option on every public constructor | `collections-221`, `mech1-26`, `mech3-44`, `themes-P1-97` | 33 | - |
| shows button help when gamepad selection rests on the button and hides it on deselection | `inputs-91`, `mech3-70` | 4 | - |
| disables a stepper direction at its bound and refuses the step | `inputs-214` | 2 | - |
| reports a failed alert body to the onError factory option and dismisses once | `mech1-114` | 1 | - |
| tags a disabled button for the theme disabled rule and lets a package retune it | `mech2-24` | 3 | - |
| keeps at most the documented number of pooled row hosts | `mech2-31` | 2 | - |
| fills the controls table with indexOfKey, placementOf and offsetOf | `mech2-86` | 2 | - |
| refuses malformed documented options with a named error | `navigation-2-24`, `navigation-3-45`, `navigation-4-10`, `navigation-5-28` | 8 | `apps-198`, `collections-129`, `inputs-43`, `inputs-104`, `inputs-150`, `inputs-188`, `navigation-3-81`, `navigation-4-45` |
| delivers onActivate with the item and key and skips disabled rows | - | 0 | `collections-184` |
| wraps rating activation to zero only when allowZero and ignores a disabled rating | - | 0 | `inputs-156` |

The producer restoration adds one more case, in `native_themes_media`:

| Candidate case | Closes | Main cases | Also partly covers |
|---|---|---:|---|
| mounts the namespaced control fixtures with the current constructors | `themes-P5-12` | 3 | - |

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
| `navigation-3-70` | Reactive core | 1 | Redirect inside onChange never reaches observers |
| `navigation-5-18` | Lifetime and ownership | 5 | retention='top' disposes departing pages, rebuilds on return, stays memory-neutral |
| `apps2-101` | Lifetime and ownership | 3 | Demo cleanup ordering: resources outlive the presented tree; same-frame dispose+dismiss is clean; self-presenting demo disposed once |
| `navigation-2-04` | Lifetime and ownership | 2 | Expanded CollapsibleView releases its surface on unmount and across open/close cycles |
| `navigation-2-38` | Lifetime and ownership | 2 | Open menus release every level on repeated enter/back and on dispose |
| `navigation-2-72` | Lifetime and ownership | 2 | Nested menu and forced sheet content toggle checked state and release with the trigger |
| `collections-86` | Lifetime and ownership | 1 | Disposing while the menu is open dismisses the menu surface |
| `navigation-1-25` | Lifetime and ownership | 1 | Disposing an open alert restores ownership |
| `navigation-1-61` | Lifetime and ownership | 1 | Dispose takes the plate down and frees the queue slot |
| `navigation-5-17` | Lifetime and ownership | 1 | Unvisited tabs are never built (lazy) |
| `themes-P1-92` | Lifetime and ownership | 1 | Held shared driver released after later construction refuses |
| `navigation-3-63` | Layout and geometry | 4 | sizing hug/fill, unequal widths, reactive, unknown refused |
| `apps2-192` | Layout and geometry | 3 | Corner/portrait rings keep >=44px buttons inside the surface before falling back |
| `navigation-1-40` | Layout and geometry | 3 | Callout align leading/trailing and automatic flip to the opposite edge |
| `navigation-5-35` | Layout and geometry | 3 | Foot pinned to rail bottom; strip between head and foot; factory receives placement |
| `navigation-5-38` | Layout and geometry | 3 | aboveBar dock sits between content and band with no gap (portrait and landscape) |
| `apps2-61` | Layout and geometry | 2 | Wrap toggle flips wrapping on the same nodes; Block align moves only the block |
| `navigation-5-36` | Layout and geometry | 2 | Trailing accessory at the band's trailing edge, clear of tabs |
| `navigation-1-43` | Layout and geometry | 1 | No tail requested means no tail |
| `navigation-1-69` | Layout and geometry | 1 | Nothing on the callout page crosses a lateral edge at swept sizes |
| `navigation-5-31` | Layout and geometry | 1 | Sidebar rail width: default and declared |
| `themes-P1-48` | Layout and geometry | 1 | Icon badge height equals plain caption; icon side respected |
| `paint-148` | Text measurement and fit | 9 | Type roles compile to native font rules and tags |
| `navigation-1-20` | Text measurement and fit | 4 | Measured action-label rung decides row vs stack; nothing is cut |
| `navigation-1-38` | Text measurement and fit | 4 | Blank or readable titles mount nothing; long titles wrap full width |
| `navigation-5-30` | Text measurement and fit | 2 | Bound textSize reaches the tabs and re-reads |
| `collections-255` | Focus and selection | 4 | Horizontal list Left/Right steps, Up/Down inert, D-pad parity, scroll into view |
| `navigation-2-31` | Focus and selection | 4 | Cancel/ButtonB and Left close one level; Right enters a focused submenu only |
| `collections-245` | Focus and selection | 3 | Transposed horizontal grid navigation and scroll-into-view |
| `apps-179` | Focus and selection | 2 | Disabled control leaves navigation |
| `apps2-179` | Focus and selection | 2 | A selected column is released on Cancel, second Activate, or when focus leaves the table |
| `apps2-232` | Focus and selection | 2 | D-pad reaches both tab strips and an alert, traps focus, restores its launcher; shoulders route to inner tabs and Back through the journey |
| `mech1-130` | Focus and selection | 2 | Collection wrapFocus/autoFocus |
| `navigation-3-15` | Focus and selection | 2 | Pop restores remembered focus even when surviving shell chrome holds selection |
| `apps-146` | Focus and selection | 1 | Nested modals restore focus in LIFO order |
| `collections-230` | Focus and selection | 1 | Cells get a focus readable that follows the ring |
| `collections-234` | Focus and selection | 1 | Grid Left/Right steps cell by cell |
| `collections-270` | Focus and selection | 1 | wrapFocus wraps the ring at both ends |
| `navigation-2-37` | Focus and selection | 1 | Back restores selection to the row that led into the left level |
| `navigation-3-16` | Focus and selection | 1 | Remembered target disabled while away falls back to first selectable |
| `collections-287` | Input actions | 7 | Pad focus traversal into the tray and back, leading entry, menu closes with the row, sibling during commit, ButtonX, both key spellings |
| `collections-84` | Input actions | 7 | Shift+Return menu toggle |
| `apps-163` | Input actions | 5 | Exactly one Activate per press across the InputAction and native Activated paths |
| `inputs-101` | Input actions | 5 | Modifier-gated shortcut bindings |
| `navigation-2-27` | Input actions | 5 | Secondary click, keyboard chord, gamepad button open the menu; only declared triggers are honoured (tap is not long-press) |
| `navigation-5-13` | Input actions | 3 | Shoulder paging (L1/R1) and its focus gating |
| `apps2-184` | Input actions | 2 | D-pad step moves selection and candidate together; stick release returns d-pad |
| `collections-187` | Input actions | 2 | Revealed trailing and leading trays are reachable by pad |
| `collections-40` | Input actions | 2 | Losing the keyboard and gamepad capabilities cancels an armed grab; the grab continues when a pointer arrives |
| `navigation-4-63` | Input actions | 1 | Shoulder paging from content only when opted in; value controls keep shoulder adjustment |
| `navigation-4-65` | Input actions | 1 | Nested content paging clamps at the inner boundary and never pages outer tabs |
| `collections-114` | Pointer, touch and drag | 2 | An unmeasured row (width <= 0) never full-swipe commits |
| `apps2-208` | Pointer, touch and drag | 1 | Item disabled mid-drag does not fire on release |
| `apps2-215` | Pointer, touch and drag | 1 | centerPassThrough leaves the center input-transparent |
| `navigation-4-40` | Pointer, touch and drag | 1 | Dragging down past the smallest detent dismisses; touch targets meet 44px |
| `navigation-4-48` | Pointer, touch and drag | 1 | Grabbing during resize motion continues from the painted height |
| `navigation-1-19` | Scrolling | 4 | A card with room grows to fit and does not scroll |
| `collections-128` | Scrolling | 3 | Snap at the end of the list: the last page settles to the end; a decisive drag back leaves it |
| `collections-225` | Scrolling | 3 | The grid anchor holds under line-extent and column-count changes |
| `collections-129` | Scrolling | 2 | Snap idle churn guard and snap vocabulary refusal |
| `navigation-5-06` | Scrolling | 2 | A visible selection issues no scroll, repeatedly |
| `collections-216` | Scrolling | 1 | Shrinking rows at the bottom leaves the list flush |
| `collections-250` | Scrolling | 1 | Keep-visible writes X on a horizontal list |
| `collections-302` | Scrolling | 1 | Shrinking the end corrects the engine |
| `navigation-4-67` | Scrolling | 1 | Returning to a tab restores its scroll position (keyed anchor after reorder, page not retained) |
| `themes-P1-76` | Motion | 6 | Visible-step count and full-vs-reduced write differential for bar/circular/spinner |
| `apps2-92` | Motion | 4 | The motion setting survives a demo swap |
| `navigation-3-04` | Motion | 3 | NavigationStack fade transition and reduced-motion swap |
| `apps-258` | Motion | 2 | Source that moves or is a readable during flight; keeps last origin when it disappears |
| `inputs-25` | Motion | 2 | No pop transform without pop; held repeat does not re-kick pop |
| `navigation-3-24` | Motion | 2 | Fade transitions retire pages; rapid forward/back leaves one opaque interactive page |
| `paint-37` | Motion | 2 | Indeterminate bar sweeping segment stays inside the track |
| `inputs-162` | Motion | 1 | Control motion follows the player's reduced-motion preference with no consumer wiring |
| `navigation-5-25` | Motion | 1 | No transition declared means no fade layer |
| `navigation-5-50` | Motion | 1 | No declaration leaves no transition |
| `themes-P1-75` | Motion | 1 | Reduced motion sub-tick hold then move: indeterminate bar |
| `themes-P1-78` | Motion | 1 | Switching policy mid-cycle steps, never restarts |
| `themes-P5-41` | Paint and theming | 9 | Every tag the framework emits is selected by a rule in every sheet |
| `navigation-3-50` | Paint and theming | 8 | Current-option paint follows selection and indicator choice (none/underline/inline) |
| `themes-P5-49` | Paint and theming | 8 | Preference touches only backdrops, never hairlines, disabled dim or authored opacity |
| `paint-08` | Paint and theming | 7 | Role/appearance/corners vocabulary paint and state precedence |
| `themes-P3-10` | Paint and theming | 5 | Typography roles compile into native rules (.facet-type-<role>, .facet-button, captions) and follow package edits; Label textRole reaches them |
| `apps2-26` | Paint and theming | 4 | Active row cue is not a colour: outlined plate follows the active row, next-letter mark |
| `themes-P2-16` | Paint and theming | 4 | Badge chrome slot: an ornate package skins the badge seal with its insets |
| `themes-P2-25` | Paint and theming | 4 | A per-view image overrides the theme skin for one node (Slider thumbImage and trackImage) |
| `themes-P5-23` | Paint and theming | 4 | Selected label contrast holds against the selection ART (plate samples) |
| `navigation-4-12` | Paint and theming | 3 | A Picker/Menu popup catcher is invisible (resolves to fully transparent) |
| `paint-114` | Paint and theming | 3 | Accent/control corner radius follows package radii live |
| `paint-75` | Paint and theming | 3 | Value-control own-paint tags independent of skinning |
| `themes-P2-32` | Paint and theming | 3 | Slider thumb and rail paint opaque on every package, and badge and accent fills stay solid |
| `themes-P5-13` | Paint and theming | 3 | Gradient packages stay readable and reach ::UIGradient rules |
| `themes-P5-46` | Paint and theming | 3 | Selected label on controlSelected clears 4.5:1 in every shipped theme |
| `apps2-19` | Paint and theming | 2 | Committed vs uncommitted is not a colour: solid vs outline plate, ASCII mark |
| `paint-02` | Paint and theming | 2 | Content text/icon colors per role and appearance rule |
| `paint-106` | Paint and theming | 2 | Every value-control own-paint slot gets a solid fill with corner/hairline |
| `paint-119` | Paint and theming | 2 | onIndicator caption role tag and rule |
| `themes-P2-09` | Paint and theming | 2 | Palette chrome gradients compile to ::UIGradient rules per palette |
| `themes-P2-11` | Paint and theming | 2 | Cascade order: StyleRule Priority follows declaration order (resting before states, contributions last) |
| `themes-P2-21` | Paint and theming | 2 | Metric changes (radii, strokes, typography) repaint live |
| `themes-P5-48` | Paint and theming | 2 | Garbage preference is the identity |
| `apps2-221` | Paint and theming | 1 | Divider edges honour leading/trailing insets and heavy thickness under each theme |
| `navigation-5-22` | Paint and theming | 1 | Selection indicator default (underline on top band) |
| `paint-110` | Paint and theming | 1 | Parent-role caption variants |
| `paint-29` | Paint and theming | 1 | Picker selection rides the style tag |
| `themes-P1-125` | Paint and theming | 1 | Bound dimmed blends image and back |
| `themes-P1-47` | Paint and theming | 1 | Icon badge keeps its icon through reactive status paint |
| `themes-P1-49` | Paint and theming | 1 | Utility plateless and status leading dot appearances |
| `themes-P2-34` | Paint and theming | 1 | The toggle's ON track uses that theme's accent |
| `themes-P2-39` | Paint and theming | 1 | A skinned role button keeps its role text colours |
| `themes-P2-63` | Paint and theming | 1 | Icons carry no instance paint; the tint comes from the sheet |
| `themes-P3-12` | Paint and theming | 1 | Package chromeGradient paints the chrome slots via native UIGradient rules |
| `themes-P4-25` | Paint and theming | 1 | Bar family owns solid native paint (track/fill rules) when unskinned |
| `themes-P5-28` | Paint and theming | 1 | Suppression outranks each value slot's own paint rule |
| `themes-P5-42` | Paint and theming | 1 | Themed corner radii follow the installed package |
| `themes-P5-03` | Theme packages | 13 | Declared theme classes (palette/metric/font/asset) are real, corpus covers all four |
| `themes-P1-69` | Theme packages | 10 | Every shipped package authors its own circular/spinner metrics and the corpus spans 2x |
| `themes-P5-04` | Theme packages | 5 | Recipes name declared assets, never raw ids |
| `themes-P5-22` | Theme packages | 5 | Platform pair: touch vs pointer metrics, hover art, tile stripe |
| `apps2-117` | Theme packages | 3 | Neutral first then sorted by name; re-selecting the installed package is a no-op; selecting a theme within the active package |
| `apps2-118` | Theme packages | 3 | FacetThemes folder: ignores non-packages, excludes testOnly fixtures, lists every shipping package (ornate with two themes) |
| `inputs-227` | Theme packages | 3 | Per-view thumbImage/trackImage override |
| `paint-152` | Theme packages | 3 | Unauthored strong/numeral derive from the package face |
| `themes-P4-37` | Theme packages | 3 | Omitted semantic pairs ride the neutral fallbacks, including derived two-variant packages |
| `themes-P2-01` | Theme packages | 2 | `content` and `contentId` both resolve to the same image |
| `themes-P4-29` | Theme packages | 2 | Derivation from base inherits unrestated values and is gated as strictly |
| `themes-P5-05` | Theme packages | 2 | Bogus art still compiles and skins a full stack (asset failure is runtime) |
| `themes-P5-15` | Theme packages | 2 | Shipped palettes declare their own success/warning, distinct from accent/content |
| `themes-P1-70` | Theme packages | 1 | Package that authors nothing still answers the three metrics |
| `themes-P3-26` | Theme packages | 1 | Unknown typography role is rejected at construction |
| `themes-P4-33` | Theme packages | 1 | Non-finite (NaN) numbers are rejected |
| `themes-P4-46` | Theme packages | 1 | Unstated states fall back to default art (and skin state precedence disabled > pressed > hover > selected) |
| `themes-P4-50` | Theme packages | 1 | A derived package override cannot leave a stale base state |
| `paint-54` | Icons and media | 10 | Every shipped package resolves every framework icon to art |
| `themes-P3-22` | Icons and media | 3 | contentId is an alias of content: both spellings yield the same native Image/rules as plain strings |
| `paint-53` | Icons and media | 2 | Framework icon list matches the names controls request |
| `themes-P2-23` | Icons and media | 2 | Slider rail paints sliced and the thumb paints whole (sliced=false) |
| `themes-P2-54` | Icons and media | 2 | Stepper increment and decrement use semantic icons, not the U+2212 glyph |
| `paint-24` | Icons and media | 1 | Unknown semantic icon refused |
| `paint-79` | Icons and media | 1 | Button imageFraming fit/crop |
| `themes-P1-23` | Icons and media | 1 | presenceMark=false suppresses the mark but keeps presence in the label |
| `themes-P1-25` | Icons and media | 1 | Refuses invalid name/form/presence before acquiring |
| `themes-P1-40` | Icons and media | 1 | Non-string overflowLabel refused and recovered |
| `themes-P2-38` | Icons and media | 1 | A flat package still tints framework icons (with no instance paint) |
| `themes-P2-43` | Icons and media | 1 | Eleven common framework icons (status, calendar, clock, vote, person, chevron ends) resolve to standard art |
| `themes-P2-46` | Icons and media | 1 | Framework icons are tinted by the palette content role, not left white |
| `themes-P2-47` | Icons and media | 1 | A status plate re-letters the picture on it |
| `themes-P2-48` | Icons and media | 1 | An unknown icon name resolves to nothing |
| `themes-P2-62` | Icons and media | 1 | A status plate re-letters the picture: kind tag and direct child |
| `paint-06` | Action controls | 8 | Unknown controlSize refused; live bad rung keeps last legal value |
| `inputs-17` | Action controls | 4 | Busy label and spinner dots stay inside the button plate in every package |
| `inputs-43` | Action controls | 3 | Unknown shape/icon names are refused at construction |
| `collections-184` | Action controls | 2 | Keyboard/gamepad row activation fires onActivate for that row |
| `collections-232` | Action controls | 2 | Pointer, touch and keyboard activation of a grid cell (onActivate) |
| `collections-253` | Action controls | 2 | Pointer and touch tap activate a horizontal item |
| `collections-263` | Action controls | 2 | Row tap activates (pointer and touch) |
| `paint-16` | Action controls | 2 | Chip default shape and leading/trailing accessories |
| `paint-30` | Action controls | 2 | Disabled Picker and DisclosureGroup refuse interaction |
| `apps2-08` | Action controls | 1 | A tap while the board resolves is refused in words and costs nothing |
| `apps2-20` | Action controls | 1 | A spent rack slot is disabled, not a live blank button |
| `apps2-230` | Action controls | 1 | Status and identity recipes reset through their shared commands |
| `collections-244` | Action controls | 1 | Horizontal grid cell tap activates |
| `inputs-26` | Action controls | 1 | Button renders caller children inside the button |
| `inputs-29` | Action controls | 1 | Role vocabulary accepted and unknown roles rejected |
| `navigation-5-23` | Action controls | 1 | Every tab meets the 44px target floor |
| `paint-60` | Action controls | 1 | Button pointer callbacks |
| `inputs-104` | Value controls | 5 | Count, unknown key, segment, segmentSize and glyphs-on-bar refusals |
| `themes-P4-10` | Value controls | 5 | Per-control art override (Slider thumbImage/trackImage) reaches the control and beats the theme ladder; no override stays on theme |
| `themes-P5-35` | Value controls | 5 | Skinned toggle parts drop their pill, restore when unskinned, geometry unchanged |
| `inputs-81` | Value controls | 3 | Slider/Stepper/Rating abandon a held adjustment when a modal owns input |
| `navigation-5-21` | Value controls | 3 | Tab labels: id fallback, icon-only accessible name, badges on unselected tabs |
| `inputs-105` | Value controls | 2 | Value clamped to run and semantic text in range |
| `inputs-109` | Value controls | 2 | Glyph segments and starSize |
| `inputs-150` | Value controls | 2 | Count and starSize refusals |
| `inputs-152` | Value controls | 2 | Value clamped and semantic text in range |
| `inputs-202` | Value controls | 2 | Read-only value/mixed require a request callback |
| `inputs-224` | Value controls | 2 | Disabled Slider refuses drag and Adjust and leaves focus order |
| `inputs-57` | Value controls | 2 | Chip rejects a missing selected/onRemove and read-only selected without onToggle |
| `paint-42` | Value controls | 2 | Bar value readout placement and track thickness |
| `paint-44` | Value controls | 2 | endLabel beside the value and on indeterminate activity |
| `apps2-02` | Value controls | 1 | Consumer Sound toggle carries the screen-owned value |
| `inputs-114` | Value controls | 1 | Disabled picker refuses every input class |
| `inputs-151` | Value controls | 1 | Glyphs fill up to the value and repaint in place |
| `inputs-156` | Value controls | 1 | Disabled rating refuses every input |
| `inputs-55` | Value controls | 1 | Flipping selected repaints in place |
| `inputs-61` | Value controls | 1 | Removable chip respects inherited disabled |
| `inputs-72` | Value controls | 1 | Chip enforces live enabled through mounted activation |
| `themes-P1-114` | Value controls | 1 | Checked rung metrics |
| `themes-P1-53` | Value controls | 1 | Live caption mounts/removes while icon and plate retained |
| `themes-P1-89` | Value controls | 1 | Bound rung validated and recovers to regular |
| `themes-P1-91` | Value controls | 1 | Refuses malformed form-specific declarations without a driver |
| `inputs-196` | Text input | 6 | Numeric parse/format/validate cannot commit after disabling or disposing the control |
| `apps2-29` | Text input | 5 | Temperature converter: numeric field only, live Preview vs committed Result, Enter and focus-loss commit, validate rejects |
| `inputs-185` | Text input | 2 | Invalid UTF-8 edits are rejected |
| `inputs-188` | Text input | 2 | clearButton=true means always; unknown mode is refused |
| `inputs-197` | Text input | 1 | Numeric specs refuse nonfinite bounds and bad callbacks |
| `inputs-73` | Text input | 1 | TextInput refuses both enabled and disabled |
| `navigation-2-09` | Text input | 1 | ComboBox refuses malformed/missing required fields |
| `navigation-2-12` | Text input | 1 | Custom validation that disposes the control cannot commit |
| `navigation-2-36` | Menus and pickers | 4 | presentation option forces menu/sheet reactively, including into automatic and at compact widths |
| `collections-82` | Menus and pickers | 3 | Menu inertness for Delete, full swipe closes the menu, 10 toggles leak nothing |
| `apps-198` | Menus and pickers | 2 | Picker refuses malformed option and callback contracts |
| `navigation-2-29` | Menus and pickers | 2 | A wholly disabled menu still opens; a disabled item is inert and the menu stays |
| `navigation-3-76` | Menus and pickers | 2 | Menu opens anchored to the trigger and fits the viewport |
| `navigation-3-87` | Menus and pickers | 2 | Menu width fits widest row and popover fit at the safe width |
| `navigation-4-18` | Menus and pickers | 2 | Named/sparse option tables and malformed options are refused at construction |
| `apps2-212` | Menus and pickers | 1 | launcher=false leaves no built-in trigger |
| `navigation-2-23` | Menus and pickers | 1 | Controller long choice lists use the larger presentation; short lists stay quick |
| `navigation-2-39` | Menus and pickers | 1 | backLabel reaches the Back row |
| `navigation-2-44` | Menus and pickers | 1 | Submenu row carries a trailing chevron |
| `navigation-3-77` | Menus and pickers | 1 | Re-activating trigger or gamepad B closes without changing selection |
| `navigation-3-84` | Menus and pickers | 1 | valueAlignment moves a labelled menu value |
| `navigation-3-86` | Menus and pickers | 1 | radioGroup style pick |
| `navigation-5-47` | Navigation containers | 5 | Scenario behaviors still promised but untested: pill in adaptable nav, badge on unselected tab, 44px floor, shoulders, reveal-once |
| `navigation-1-02` | Navigation containers | 3 | TabView placement changes keep tab strip, scroller and page owners (no rebuild, no leak) |
| `navigation-5-08` | Navigation containers | 3 | A nested TabView resolves topBar and depth stays balanced when a factory throws |
| `apps2-107` | Navigation containers | 2 | Stepping wraps both ways, a full cycle returns, unknown current id yields a real demo |
| `apps2-200` | Navigation containers | 2 | One navigation control per center policy; Close/Back by depth |
| `navigation-5-40` | Navigation containers | 2 | Re-home between a slot's own homes; nil factory mounts nothing |
| `apps2-202` | Navigation containers | 1 | Removing an open ancestor returns to the nearest valid page |
| `navigation-4-61` | Navigation containers | 1 | Customization ignores stale ids, protects required tabs, reorders without remount, hidden selection falls back |
| `apps2-46` | Presented surfaces | 6 | Confirm dialog outcomes: Delete opens, Cancel records kept, Confirm changes the screen, Restore repeats, double Delete does not stack |
| `navigation-1-54` | Presented surfaces | 3 | Initial seen/featureUsed and afterSessions gate eligibility |
| `inputs-93` | Presented surfaces | 2 | Help plate takes no focus and wraps long text |
| `navigation-1-16` | Presented surfaces | 2 | A live layout flip moves the same mounted actions and keeps selection |
| `navigation-5-54` | Presented surfaces | 2 | Menu/expand catchers never paint an opaque full-viewport node |
| `navigation-1-26` | Presented surfaces | 1 | Default OK action when none authored |
| `navigation-1-29` | Presented surfaces | 1 | Custom content ids are not interpreted as alert actions |
| `navigation-2-61` | Presented surfaces | 1 | Alert (including fullScreen) has no outside-tap dismissal |
| `navigation-3-31` | Presented surfaces | 1 | Desktop confirmation: compact centered card, horizontal actions |
| `navigation-4-69` | Virtual collections | 3 | VirtualGrid and Table keep keyed scroll anchors across insertion while their tab is away (editing on/off) |
| `apps2-177` | Virtual collections | 2 | Column resize on a virtualized 2000-row table remounts only the window at the new width |
| `collections-21` | Virtual collections | 2 | followThreshold and rejoining the tail after returning to the end |
| `apps2-49` | Virtual collections | 1 | A sideways engine scroll slides the card rail window along X |
| `apps2-178` | Tables | 5 | Header column boundaries match the body's, with and without a scrollbar gutter, stable after resize |
| `apps2-37` | Tables | 4 | Double-click plays, single click only selects, slow clicks play nothing, touch first tap plays; Restore clears what was playing |
| `apps2-167` | Tables | 2 | Resizable column grows a grip; a locked (resizable=false) column has none and binds no adjust key |
| `apps2-172` | Tables | 2 | Rating sorts by live signal; Artist sorts by value with source-index tie-break |
| `apps2-174` | Tables | 2 | Top button bakes the sort; removing a row keeps the sort |
| `collections-134` | Tables | 2 | Header offset for the reorder and disclosure gutters keeps columns aligned |
| `apps2-33` | Tables | 1 | Playlist columns align name and rating under their headers |
| `collections-136` | Tables | 1 | Headerless table (header = false) |
| `collections-139` | Tables | 1 | A collapse sum equal to the available room fits |
| `collections-207` | Tables | 1 | Header and body cells span the same columns in every shape and package |
| `collections-170` | Row actions | 10 | Table rowActions behaviors: shared coordinator, reorder coexistence, tray tap, editing minus, disposal, refresh cancel, Delete key, commit collapse, handle plus minus |
| `collections-256` | Row actions | 4 | Horizontal reorder: pointer X slot, release X commit, X autoscroll, Left/Right armed stepping |
| `collections-77` | Row actions | 4 | Close on another row's gesture/menu, on scroll, with the Cancel key, and on unmount |
| `apps2-35` | Row actions | 3 | Scrolling the page closes a swiped-open tray; a swipe never plays the track (touch and mouse) |
| `collections-194` | Row actions | 3 | A rowActions-only table is reachable and Delete/pad fires |
| `collections-89` | Row actions | 2 | A sibling gesture or scroll during a commit does not cancel it |
| `collections-121` | Row actions | 1 | A pinned row cannot be displaced by a movable row |
| `collections-173` | Row actions | 1 | A viewport table closes an open tray on its own body scroll |
| `collections-282` | Row actions | 1 | A row whose actions are nil declines the gesture |
| `collections-303` | Row actions | 1 | The insertion slot snaps on ragged midpoints |
| `collections-72` | Row actions | 1 | A destructive commit recovers when the owner keeps the row |
| `apps2-190` | HUD and world targets | 2 | Anchor clearance sizes the hole; follow=fixed keeps opening geometry |
| `themes-P1-101` | HUD and world targets | 1 | Camera position/lookAt/fov |
| `collections-110` | Adaptive environment | 4 | A short landscape drops the heading; the first row is visible on all surfaces |
| `navigation-3-74` | Adaptive environment | 4 | Automatic count/width/description/query rungs |
| `navigation-2-32` | Adaptive environment | 2 | Touch preferred input resolves the sheet idiom at any width |
| `navigation-1-03` | Adaptive environment | 1 | Gamepad/TV presentation forces top bar tabs |
| `navigation-1-63` | Adaptive environment | 1 | No device branch in the callout source |
| `navigation-3-23` | Adaptive environment | 1 | Viewport/theme/input/reduced-motion switches keep the mounted page |
| `navigation-3-55` | Public surface | 3 | Nameless option, empty bound label and iconOnly without icons are refused |
| `apps-117` | Public surface | 1 | init.luau re-exports contract types |
| `inputs-67` | Public surface | 1 | compactLabel refused on content/icon/image buttons |
| `navigation-3-17` | Public surface | 1 | Malformed specs, paths and route entries are refused before creating a page |
| `navigation-3-52` | Public surface | 1 | Indicator 'automatic' legal; refusal names the set |
| `navigation-3-81` | Public surface | 1 | Declared style bypasses the ladder; unknown style refused |
| `navigation-4-35` | Public surface | 1 | Unknown indicator or axis is rejected naming the legal set |
| `navigation-4-45` | Public surface | 1 | Rejects unknown detents, duplicate ids and a read-only detent cell |
| `apps2-139` | Performance | 1 | Row count clamped to the declared ceiling |
| `apps2-148` | Performance | 1 | Two captures are the same workload only when every identity field agrees |
| `apps2-42` | Replication and server state | 7 | Settings sync: every state reachable by on-screen controls, status names next action, reset unanswered, second change refused visibly, idle Deliver explains, bounded newest-first history |
| `apps2-128` | Replication and server state | 5 | Unengaged terminal sends nothing and states the objective; ADJUST updates budget line/verdict; an edit retires the last outcome; exit is idempotent |
| `navigation-1-35` | Error handling and refusals | 3 | Invalid transition options are refused at build |
| `navigation-5-42` | Error handling and refusals | 3 | Refuse unknown slot, non-function slot, and a slot the declared placement cannot host |
| `apps2-115` | Error handling and refusals | 2 | A demo that cannot build is not reported mounted; the scriptable API answers with what it delivered |
| `apps2-83` | Error handling and refusals | 2 | A demo that cannot be mounted is stamped and spoken |
| `collections-50` | Error handling and refusals | 2 | A theme metrics snapshot without derived row keys, or with NaN scale, falls back |
| `collections-51` | Error handling and refusals | 2 | Unknown RowActions options and unknown action roles are refused |
| `navigation-1-55` | Error handling and refusals | 2 | Missing onRetire and unknown keys are refused |
| `navigation-5-52` | Error handling and refusals | 2 | Refuse unknown transition fields and a string name |
| `navigation-1-28` | Error handling and refusals | 1 | Refuses misspelled fields, duplicate action ids and two cancel roles |
| `navigation-5-26` | Error handling and refusals | 1 | A transition must be a table of tween options |
| `paint-41` | Error handling and refusals | 1 | Unknown ProgressView presentation refused |
| `themes-P4-42` | Error handling and refusals | 1 | Self-referential definition terminates (cycles rejected) |

Example and reference-app gaps:

| Group | Contracts | Main cases |
|---|---:|---:|
| Docs, examples and tooling | 10 | 31 |
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
