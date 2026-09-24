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
  still promises, but no candidate case tested it. The parity tests close
  884 of these cases. One case moved to class c, because `api.md`
  no longer makes its promise. 9 cases remain. Only a live Studio check
  can close them. See [Gap list](#gap-list).
- 893 of the 3,367 covered cases have a weaker
  candidate assertion. Usually one candidate case replaces several main
  edge cases.
- 1,440 cases moved to a Roblox Engine or Compose mechanism. For about
  704 of them, no candidate test and no live Studio record show that
  Facet uses the mechanism correctly.
- Of 130 main `full` producers, no producer is a gap and no producer is a
  weaker replacement. Four producers run but wait for live Studio evidence. See
  [Producers](#producers).
- A complete run writes `artifacts/verify/latest-<tier>.json` with release
  gate evidence. `tools/package.sh publish` reads the `release` file and
  refuses anything but a clean, passing run of the same source.
- The audit found 10 defects in `src` and 3 in the examples. All of them
  are fixed. The parity tests found and fixed 18 more defects in `src` and
  7 more in the examples. [Fixed after the audit](#fixed-after-the-audit)
  names the test for each fix.

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
| a | Covered by a candidate case | 1158 | 2,294 | 3,178 |
| b | Retired. The Roblox Engine or Compose owns the mechanism | 306 | 1,581 | 1,581 |
| c | Retired. The feature or code was deleted and is not promised | 823 | 6,079 | 6,080 |
| d | Gap. A promise remains and no candidate case verifies it | 3 | 894 | 9 |

Class c is the largest class. Most of it tested the deleted solver,
renderer, focus graph, input system, presenter, paint layer and their seams.
Those checks cannot run against the native implementation. Their retirement
is correct when the public API no longer makes the promise.

## Contract groups

"Weaker" counts the covered cases with a weaker candidate assertion. The
last column names the candidate specs that the group cites most.

| Group | Main cases | a | Weaker | b | c | d | Candidate coverage |
|---|---:|---:|---:|---:|---:|---:|---|
| Reactive core | 63 | 23 | 0 | 4 | 36 | 0 | `native_compose_contract`, `native_public_surface`, `native_navigation` |
| Lifetime and ownership | 316 | 142 | 6 | 6 | 168 | 0 | `native_conformance`, `native_stress`, `native_themes_media` |
| Layout and geometry | 1,326 | 280 | 211 | 218 | 827 | 1 | `native_inputs`, `native_navigation`, `native_parity_navigation` |
| Text measurement and fit | 497 | 63 | 27 | 232 | 202 | 0 | `native_inputs`, `native_collections`, `native_parity_navigation` |
| Focus and selection | 532 | 103 | 49 | 257 | 172 | 0 | `native_navigation`, `native_collections`, `native_inputs` |
| Input actions | 332 | 101 | 48 | 105 | 121 | 5 | `native_inputs`, `native_navigation`, `native_collections` |
| Pointer, touch and drag | 368 | 63 | 48 | 97 | 208 | 0 | `native_collections`, `native_radial_controls`, `native_virtual_monitors` |
| Scrolling | 330 | 93 | 9 | 100 | 137 | 0 | `native_collections`, `native_gallery_collections`, `native_virtual_monitors` |
| Motion | 581 | 144 | 4 | 33 | 404 | 0 | `native_themes_media`, `native_navigation`, `native_inputs` |
| Paint and theming | 709 | 199 | 6 | 70 | 440 | 0 | `native_themes_media`, `native_inputs`, `native_navigation` |
| Theme packages | 379 | 149 | 3 | 0 | 230 | 0 | `native_themes_media`, `native_inputs`, `native_gallery_shell` |
| Icons and media | 251 | 116 | 0 | 37 | 98 | 0 | `native_themes_media`, `native_stress`, `native_public_surface` |
| Action controls | 394 | 96 | 57 | 1 | 297 | 0 | `native_inputs`, `native_navigation`, `native_themes_media` |
| Value controls | 249 | 221 | 128 | 0 | 28 | 0 | `native_inputs`, `native_parity_controls`, `native_themes_media` |
| Text input | 119 | 70 | 26 | 28 | 21 | 0 | `native_inputs`, `native_navigation`, `native_collections` |
| Menus and pickers | 141 | 103 | 58 | 0 | 38 | 0 | `native_navigation`, `native_parity_navigation`, `radial_geometry` |
| Navigation containers | 72 | 69 | 36 | 1 | 2 | 0 | `native_navigation`, `native_gallery_shell`, `native_radial_controls` |
| Presented surfaces | 287 | 124 | 81 | 5 | 158 | 0 | `native_navigation`, `native_parity_navigation`, `native_gallery_parity` |
| Virtual collections | 214 | 159 | 6 | 3 | 52 | 0 | `native_collections`, `native_gallery_collections`, `native_perf_principles` |
| Tables | 156 | 97 | 1 | 1 | 58 | 0 | `native_collections`, `native_gallery_workflows`, `native_gallery_collections` |
| Row actions | 264 | 149 | 13 | 0 | 112 | 3 | `native_collections`, `native_parity_controls`, `native_gallery_workflows` |
| HUD and world targets | 166 | 46 | 0 | 50 | 70 | 0 | `native_hud`, `native_themes_media`, `native_outpost_terminal` |
| Adaptive environment | 419 | 32 | 17 | 51 | 336 | 0 | `native_navigation`, `native_parity_navigation`, `native_radial_controls` |
| Public surface | 366 | 89 | 0 | 0 | 277 | 0 | `native_conformance`, `native_registration`, `native_parity_gaps` |
| Docs, examples and tooling | 498 | 51 | 0 | 0 | 447 | 0 | `native_documentation`, `native_registration`, `scenario_require_paths` |
| Gallery and examples | 425 | 246 | 51 | 113 | 66 | 0 | `native_gallery`, `native_games`, `native_gallery_collections` |
| Reference apps | 327 | 152 | 2 | 22 | 153 | 0 | `native_reference_apps`, `native_outpost_rules`, `scenario_require_paths` |
| Performance | 792 | 84 | 6 | 4 | 704 | 0 | `native_perf_principles`, `native_themes_media`, `native_perf_lab` |
| Replication and server state | 55 | 31 | 0 | 0 | 24 | 0 | `native_outpost_terminal`, `native_stress`, `native_gallery` |
| Error handling and refusals | 220 | 72 | 0 | 2 | 146 | 0 | `native_navigation`, `native_parity_navigation`, `native_parity_gaps` |

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

`tools/lune/parity_blockers.json` still lists one pending live risk: haptic
motor output on a physical phone and gamepad. The `coverage` producer fails
for this reason. Studio shows only that the controls request the effects.

The live Studio harness in `tools/studio/live` records engine geometry for 34
contracts in the `liveEvidence` field of each contract. The results are in
`artifacts/studio-live`. The runs use the device emulator at 844x369 and
388x824, at the Medium and Largest preferred text sizes. The harness found
four defects, and the branch fixes them:

- The collection toolbar took the whole page on a short landscape phone, so
  the list had no height.
- The gallery shell reserved a fixed 56 px, and a taller Settings button
  overlapped the demo tabs.
- A top callout with no room above covered its anchor.
- A circle Button with a Size on one axis only collapsed to 0x0.

[Device verification](11-device-verification.md#live-assertion-harness)
describes the harness and its limits.

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
| Equivalent candidate producer | 48 |
| Replaced by a different check | 16 |
| Replaced by a weaker check | 0 |
| Producer runs; its live evidence is not recorded | 4 |
| Retired with its subject | 62 |
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

### Former weaker replacements

These four producers were weaker than on `main`. They are now at the
strength of `main`, or their subject is deleted.

| Main producer | Candidate producer | Tier | Note |
|---|---|---|---|
| `check_example_drift_cli` | `example-drift`, `example-drift-selftest` | full, release | `tools/check_example_drift.py` scans the tutorial and reference examples for a literal `TextSize`, a literal paint colour, a raw colour, an unknown `textRole` and an engine reach-around. Each allowed literal has a reason, and a stale entry fails. |
| `faults` | `suite` (`native_stress`) | fast, full, release | Six of the nine main scenarios run at 200 iterations or more: async storms, locale and UTF8 text, preferred input switches, teardown and the covered modal dismissal. The other three tested deleted subjects: the Facet scheduler (now Compose), the Facet resource cache and the Facet environment facts. |
| `fuzz-replication` | `suite` (`native_stress`) | fast, full, release | Retired. `src/replication` is deleted. The example authority model converges under 400 seeded deliveries, the same count as `main`. |
| `soak` | `suite` (`native_stress`) | fast, full, release | The same two fixtures as `main`: 200 modal cycles and 100 structural cycles, each twice, with a census after each cycle. |

### Producers that wait for live evidence

These producers run in `full` and `release`. Each one exits 2 until its
Studio capture of the native performance lab is recorded under
`artifacts/performance-stress-places/studio`. The lab place is
`examples/performance.project.json`, and `workspace.FacetPerfLabAPI` drives
it (`select`, `theme`, `clean`, `run`, `stop`, `capture`). The capture schema
is in `examples/performance/lab/capture.luau`. A capture row records the
theme and the preferred text size.

`perf-gate-evidence-studio` passes with one clean capture. See
[the lab in Roblox Studio](19-paired-performance.md#the-performance-lab-in-roblox-studio).

| Main producer | Candidate producer | Tier | Note |
|---|---|---|---|
| `check_perf_gate_evidence-device-matrix` | `perf-gate-evidence-device-matrix` | full, release | Five emulator-class viewports are not recorded. Set `workspace.Facet_PerfEvidenceClass` to `emulator` for these rows. |
| `check_perf_gate_evidence-large-text` | `perf-gate-evidence-large-text` | full, release | Only the Largest text size is recorded. Scripts cannot set the preference, so each size needs the Roblox menu. |
| `check_perf_gate_evidence-native-reference` | `perf-gate-evidence-native-reference` | full, release | In Studio the lab did not mount the next workload after `dense-scroll-native`. Those captures were discarded. |
| `check_perf_gate_evidence-theme-cost` | `perf-gate-evidence-theme-cost` | full, release | The ornate capture came after the fault above and was discarded. |

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

All audit defects are fixed. [Fixed after the audit](#fixed-after-the-audit)
names the test that covers each one. The table keeps the original
reproductions for reference.

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

### Fixed after the audit

Each fix has a headless test. The test failed before the fix.

| ID | Fix | Test |
|---|---|---|
| B1 | Arrow and D-pad focus wrap at the two ends when `wrapFocus` is set. A list wraps only along its scrolling axis. | native_collections: wraps arrow and D-pad focus at both ends when wrapFocus is set |
| B2 | A full swipe commits or opens a tray only after the row has a measured width. | native_collections: never commits or opens a full swipe on an unmeasured row |
| B3 | When the owner sets `open` after a destructive action, the row restores and accepts input again. | native_collections: restores a kept row after a destructive action so it can commit again |
| B4 | A number commit stops when a callback disables the input. | native_inputs: does not commit a number TextInput that its parse callback disables |
| B5 | `onPointerCancel` alone connects the pointer listeners. | native_inputs: reports a pointer cancel when onPointerCancel is the only pointer option |
| B6 | Control motion follows `GuiService.ReducedMotionEnabled` or the factory option. | native_inputs: follows GuiService.ReducedMotionEnabled for pop, validation pulse and busy dots |
| B7 | A readable `follow` changes the policy. Unknown values cause an error. | native_collections: follows a readable follow policy while the viewport stays at the end |
| B8 | `api.md` states the Frame root of a Label with an icon. | native_themes_media: returns the Label root that api.md states, with and without an icon |
| B9 | The value readout and `endLabel` show together. | native_themes_media: shows the showValue readout beside a ProgressView endLabel |
| B10 | Button `corners` accepts a readable. | native_inputs: accepts a readable Button corners value and follows it |
| E1 | Word-game keys and tiles use theme status tags. An accent outline marks the active row. | native_games: paints key and tile state through theme status tags and outlines the active row |
| E2 | With a selection, one click selects. A double click, Return, a gamepad press or a touch tap activates. | native_gallery: selects a playlist row on one click and plays it on a double click or Return |
| E3 | The ornate gauge and custom control fixtures use the current controls and read the theme package. | native_themes_media: mounts the namespaced control fixtures with the current controls |

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

### Fixed with the reference-app, example and control tests

A test in `tests/native_parity_apps.spec.luau` or
`tests/native_parity_media.spec.luau` shows each of these defects. The same
change fixes it.

| ID | File | Defect |
|---|---|---|
| B1 | `src/ui/collections.luau` | `wrapFocus` did not wrap arrow or D-pad focus. Now it wraps at both ends along the pressed axis. |
| B4 | `src/ui/inputs.luau` | A TextInput committed after its `parse`, `format` or `validate` callback disabled or removed it. Now the commit stops. |
| B5 | `src/ui/inputs.luau` | A Button with only `onPointerCancel` never received the cancel. |
| B6 | `src/ui/inputs.luau` | Button pop, busy dots and the validation pulse ignored `GuiService.ReducedMotionEnabled`. Now they follow it. |
| B7 | `src/ui/collections.luau` | A readable `follow` mounted and acted as `none`. Now it causes an error. |
| AB1 | `src/ui/nav_menu.luau` | ComboBox accepted a value that is not a string and missing `options`. |
| AB2 | `src/ui/inputs.luau` | Button accepted any `imageFraming` value. A table was treated as `crop`. |
| AB3 | `src/ui/collections.luau`, `src/ui/collection_table.luau` | `onActivate` did not receive the native input or click count, so a list could not tell one click from a double click. A double click also turned a multi-select row off again. |
| AB4 | `src/ui/nav_radial.luau` | A ring with `follow = "fixed"` changed its hole when the anchor clearance changed. |
| AB5 | `src/ui/nav_radial.luau` | The list presentation showed two navigation controls for the `root` and `close` centers. The Center button said "Back" where it closes the menu. |
| AB6 | `src/init.luau` | The package did not export the RadialMenu contract types, although `api.md` promises the contract of each control. |
| AB7 | `src/ui/nav_pages.luau` | A NavigationStack built its root page before it refused a malformed transition. |
| AB8 | `src/ui/nav_modal.luau` | Removing an open modal left the selection on its destroyed control. Studio may clear it natively. The fake engine does not. |
| E2 | `examples/gallery/examples/02_playlist_table.luau` | One click played a track. Now a double click, Return or a touch tap plays it. |
| E3 | `examples/themes/ornate_gauge.luau`, `examples/themes/custom_control.luau` | The fixture blueprints called deleted constructors. They now build native nodes. |
| AE1 | `examples/reference/*/init.luau` | Each app gave a native signal connection to `Compose.cleanup`, which refuses it. With a heartbeat or GuiService, the app did not mount. |
| AE2 | `examples/reference/p1_glade/init.luau`, `examples/reference/p4_foyer/init.luau` | The Fresh Start and Invite alerts did not present. Alert calls a function title as a payload factory, and the apps gave a `(use)` readable. |
| AE3 | `examples/reference/p2_cartwheel/init.luau` | A rejected brew command lost its reason, so the player saw the fallback text. |
| AE4 | `examples/reference/p2_cartwheel/init.luau` | The brew actions stayed active while their command was pending. |
| AE5 | `examples/gallery/scenarios/skeleton.luau` | The motion commands called an undefined function. The recipe now drives the gallery motion preference. |
| AE6 | `examples/gallery/scenarios/adaptive_controls.luau` | A grid layout set `LayoutOrder` from an undefined global. |
| AE7 | `examples/gallery/client/init.client.luau` | An empty `Facet_Scenario` with `Facet_Example` loaded the example as a fixture. The boot choice is now `catalogue.boot` in `demo_picker.luau`. |
| AD1 | `docs/guide/README.md` | The guide index linked one of the seven extension playbooks. |

### Fixed with the stronger assertion tests

A case in a `tests/native_parity_weaker_*.spec.luau` file shows each of these
defects. The same change fixes it.

| ID | File | Defect |
|---|---|---|
| `WA1` | `examples/gallery/examples/02_playlist_table.luau` | The Rating column showed a resize grip and took resize keys, but the readout said that Rating is locked. The column now sets `resizable = false`. |
| `WA2` | `src/ui/collection_table.luau` | With editing on and a destructive row action, the row cells moved right by the edit gutter, but the header did not. The Table now adds the widest row edit gutter to the header position and width, the collapse room and the canvas width. |
| `WA3` | `src/ui/collection_snap.luau` | A flick without a pointer press (wheel, trackpad or engine momentum) started from a stale offset. A fast flick up from row 8 went to the top, and a flick down after a snap did not advance. A scroll from rest now starts at the resting offset. |
| `WA4` | `src/ui/collection_row_actions.luau` | A row stayed open and kept the shared open-row claim when the actions of its open side became empty. When the actions came back, the tray opened again without a swipe. The row now closes when its open side has no actions. |
| `WA5` | `examples/gallery/scenarios/action_controls.luau` | The Distant TV preview scales the gallery by 1.5, but the action controls demo read the unscaled viewport width. At 1440 px the Showroom and Race Setup sections stayed side by side under the preview. The gallery now gives demos `ctx.sceneViewport`, the viewport divided by the preview scale, and the demo reads it. |
| `WA6` | `src/ui/collections.luau` | VirtualList and VirtualGrid wrote an equal CanvasSize again on each scroll and on each edit to a row outside the window. Table wrote its outer Size, body Size, body CanvasSize and header Position again on each vertical scroll. These properties now bind to the numeric extent and the horizontal scroll offset, so only a real change writes. |
| `WA7` | `src/ui/media.luau` | AvatarGroup kept the old resource lease and image when the resource of a member changed under the same id. A member with a resource is now keyed by its id and its resource, so only that face mounts again with a new lease. |

### Fixed with the final gap tests

A case in the table of [Final gap tests](#final-gap-tests) shows each of
these defects. The same change fixes it. `bugs` in the data file has each
reproduction.

| ID | File | Defect |
|---|---|---|
| `B22` | `src/ui/context.luau` | A theme metric that was not finite stopped the construction of a control. A metric that is not finite now falls back to the neutral metric, as a missing metric does. |
| `B23` | `src/ui/collection_row_actions.luau` | A destructive commit that removed its row left a heartbeat connection after dispose. The row now settles before it runs the action. |
| `E6` | `examples/gallery/scenarios/collection_demo.luau` | A short landscape kept the collection title. The title is now hidden when the viewport is less than 480 pixels high. |
| `E7` | `examples/gallery/scenarios/demo_tabs.luau` | The shoulders did not page the showcase inner tabs from page content. The inner tab views now set `shoulderNavigation = "content"`. |
| `E8` | `examples/reference/p3_sipworks/init.luau`, `examples/reference/p3_sipworks/content/strings.luau` | Sipworks wrote most player copy as literals, so a locale switch kept it in English. The copy is now in the locale table. |

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
| `native_parity_navigation` | uses a plain native frame and hides the old page immediately when transition is false | navigation-5-25, navigation-5-50 | 2 | - |
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

### Reference app, example and media parity tests

[`tests/native_parity_apps.spec.luau`](../../tests/native_parity_apps.spec.luau)
and [`tests/native_parity_media.spec.luau`](../../tests/native_parity_media.spec.luau)
close these contracts. The data file names the case for each contract.

| Spec | Block | Closes | Main cases |
|---|---|---|---:|
| `native_parity_apps` | Glade | apps-04, apps-06, apps-07, apps-09, apps-12, apps-13, apps-14, apps-15, apps-17, apps-19, apps-23, apps-25, apps-28, apps-31, apps-33 | 34 |
| `native_parity_apps` | Cartwheel | apps-37, apps-39, apps-41, apps-44, apps-47, apps-49, apps-53, apps-55, apps-57, apps-60, apps-64, apps-65, apps-67 | 27 |
| `native_parity_apps` | Sipworks | apps-72, apps-73, apps-75, apps-78, apps-82, apps-83, apps-85, apps-87, apps-94, apps-96 | 21 |
| `native_parity_apps` | Foyer | apps-100, apps-104, apps-108, apps-109 | 10 |
| `native_parity_apps` | Gallery examples | apps2-02, apps2-08, apps2-20, apps2-29, apps2-42, apps2-46, apps2-73, apps2-74 | 28 |
| `native_parity_apps` | Gallery shell | apps2-82, apps2-83, apps2-115, apps2-92, apps2-101, apps2-107 | 18 |
| `native_parity_apps` | Gallery recipes | themes-P1-31, themes-P1-45, themes-P1-52, themes-P1-95, themes-P1-116, inputs-176, apps2-230 | 9 |
| `native_parity_apps` | Gallery layouts | apps2-49, apps2-61 | 3 |
| `native_parity_apps` | Outpost terminal | apps2-128, apps2-132 | 7 |
| `native_parity_apps` | Performance lab | apps2-139, apps2-148 | 2 |
| `native_parity_apps` | Documentation and tooling | apps2-158, apps2-236, apps2-80 | 6 |
| `native_parity_apps` | Table | apps2-167, apps2-179, apps2-177, apps2-178 | 11 |
| `native_parity_apps` | Playlist example | apps2-33, apps2-37, apps2-172, apps2-174 | 9 |
| `native_parity_apps` | RadialMenu | apps2-190, apps2-192, apps2-200, apps2-202, apps2-208, apps2-212, apps2-215 | 11 |
| `native_parity_apps` | Quick actions example | apps2-224, apps2-194 | 13 |
| `native_parity_apps` | Public surface, catalog and theme corpus | apps-117, paint-140, paint-143, mech3-55, themes-P4-43, themes-P4-44, themes-P5-12 | 26 |
| `native_parity_apps` | Menu scenario copy | navigation-2-57 | 1 |
| `native_parity_media` | progress motion | paint-37, themes-P1-75, themes-P1-76, themes-P1-78, paint-41, themes-P1-69 | 21 |
| `native_parity_media` | badge | themes-P1-47, themes-P1-48, themes-P1-49, themes-P1-53 | 4 |
| `native_parity_media` | avatar | themes-P1-23, themes-P1-25, themes-P1-40 | 3 |
| `native_parity_media` | skeleton and status indicator | themes-P1-89, themes-P1-91, themes-P1-92, themes-P1-114 | 4 |
| `native_parity_media` | async image and stage | themes-P1-125, themes-P1-101 | 2 |
| `native_parity_media` | icons | paint-24, themes-P2-48, themes-P2-43, themes-P3-22, paint-79 | 7 |
| `native_parity_media` | refusals | inputs-29, inputs-43, inputs-67, inputs-73, inputs-197, paint-06, navigation-2-09 | 16 |
| `native_parity_media` | controls | inputs-25, inputs-162, inputs-17, inputs-26, paint-16, paint-60, inputs-93, inputs-185, inputs-188, inputs-196, apps-179, apps-146 | 26 |
| `native_parity_media` | icon coverage | paint-53, paint-54, themes-P2-54 | 14 |
| `native_parity_apps` | Collections | collections-21, collections-128, collections-129, collections-134, collections-136, collections-139, collections-184, collections-207, collections-216, collections-302, collections-225, collections-230, collections-232, collections-244, collections-234, collections-245, collections-250, collections-255, collections-253, collections-263, collections-270, mech1-130 | 39 |
| `native_parity_apps` | NavigationStack and CollapsibleView | navigation-3-04, navigation-3-24, navigation-3-15, navigation-3-16, navigation-3-17, navigation-3-23, navigation-2-04 | 12 |

### Stronger assertions for weaker contracts

These specs add sibling cases for covered contracts whose candidate
assertion was weaker than the main assertion. "Equal" lists the
contracts that now assert all that main asserted and that is still
promised. The `weaker` field of these contracts is removed. "Still
weaker" lists the contracts that get more assertions, but that still
need a Roblox layout result from a live Studio check, or that keep a
product difference from main. Their `weaker` field names the missing
assertion. A contract that gets no new case is not in this table. Its
`weaker` field tells why.

| Spec | Group | Equal | Main cases | Still weaker | Main cases |
|---|---|---|---:|---|---:|
| `native_parity_weaker_apps` | Docs, examples and tooling | `apps2-78`, `mech1-76`, `paint-139` | 11 | - | 0 |
| `native_parity_weaker_apps` | Reference apps | `apps-01`, `apps-03`, `apps-34`, `apps-35`, `apps-40`, `apps-43`, `apps-51`, `apps-69`, `apps-77`, `apps-79`, `apps-81`, `apps-85`, `apps-93`, `apps-94`, `apps-97`, `apps-99`, `apps-103`, `apps-106`, `apps-107` | 43 | `apps-82` | 2 |
| `native_parity_weaker_gallery` | Gallery and examples | `apps2-17`, `apps2-66`, `apps2-102`, `apps2-114`, `apps2-195`, `apps2-261`, `apps2-285`, `collections-109`, `mech2-26`, `navigation-2-50`, `navigation-3-32`, `navigation-3-36`, `navigation-5-45`, `paint-47`, `paint-125` | 75 | `apps2-01`, `apps2-86`, `apps-193`, `collections-101`, `inputs-77`, `mech2-25`, `mech3-20`, `navigation-1-65` | 45 |
| `native_parity_weaker_hud` | HUD and world targets | `apps2-130`, `apps-215`, `themes-P1-102` | 4 | `apps-206`, `apps-210`, `apps-214`, `apps-218`, `apps-221`, `apps-234`, `themes-P1-11`, `themes-P1-14` | 30 |
| `native_parity_weaker_hud` | Replication and server state | `apps2-41`, `apps2-127` | 14 | - | 0 |
| `native_parity_weaker_rows` | Row actions | `apps2-38`, `apps2-40`, `apps2-265`, `collections-57`, `collections-61`, `collections-65`, `collections-67`, `collections-76`, `collections-88`, `collections-116`, `collections-120`, `collections-122`, `collections-145`, `collections-168`, `collections-281`, `collections-284`, `inputs-58` | 82 | `apps2-39`, `collections-11`, `collections-53` | 19 |
| `native_parity_weaker_scrolling` | Scrolling | `apps2-267`, `apps-225`, `apps-231`, `collections-03`, `collections-15`, `collections-32`, `collections-125`, `collections-127`, `collections-176`, `collections-183`, `collections-231`, `collections-242`, `navigation-5-05` | 50 | `collections-262`, `navigation-1-18` | 7 |
| `native_parity_weaker_tables` | Tables | `apps2-168`, `apps2-171`, `apps2-173`, `apps-242`, `collections-36`, `collections-37`, `collections-137`, `collections-142`, `collections-144`, `collections-151`, `collections-164`, `inputs-06` | 34 | `apps2-175`, `collections-133`, `collections-134`, `collections-203`, `collections-207` | 9 |
| `native_parity_weaker_virtual` | Virtual collections | `apps2-141`, `apps2-243`, `apps-122`, `collections-07`, `collections-09`, `collections-19`, `collections-20`, `collections-208`, `collections-222`, `collections-223`, `collections-240`, `collections-249`, `collections-258`, `collections-274`, `collections-296`, `collections-299`, `collections-300`, `collections-305`, `mech1-72`, `mech1-96`, `mech2-30`, `mech3-03`, `mech3-97`, `themes-P1-35` | 121 | `apps2-57`, `apps2-231`, `navigation-4-68` | 6 |

### Final gap tests

These cases close 19 of the last 22 gap contracts, with 47 main cases.

| Spec | Candidate case | Closes | Main cases |
|---|---|---|---:|
| `native_parity_themes` | terminates on a self-referential metrics table and rejects it as a cycle | themes-P4-42 | 1 |
| `native_parity_themes` | slices the slider rail and paints a sliced = false thumb as a whole image | themes-P2-23 | 2 |
| `native_parity_paint` | tints framework icons with the content role of each palette and never leaves them white | themes-P2-38, themes-P2-46 | 2 |
| `native_parity_paint` | re-letters the icon on a status plate with the plate partner color as a direct child | themes-P2-47, themes-P2-62 | 2 |
| `native_parity_paint` | compiles every type role to native font rules and tags labels with their role | paint-148 | 9 |
| `native_parity_gaps` | refuses picker selection and disclosure toggling while disabled and resumes when enabled | paint-30 | 2 |
| `native_parity_gaps` | estimates table rows from a regular control height that falls back when the theme metric is missing or not finite | collections-50 | 2 |
| `native_parity_gaps` | keeps the value when custom combo box validation unmounts the control | navigation-2-12 | 1 |
| `native_parity_navigation` | restores VirtualGrid and Table keys across a retained tab switch (three cases) | navigation-4-69 | 3 |
| `native_parity_navigation` | keeps both showcase tab levels at the 44 pixel floor, marks each selection and reveals once | navigation-5-47 | 5 |
| `native_parity_navigation` | pages each showcase tab strip by shoulder, traps the alert and restores its launcher on Back | apps2-232 | 2 |
| `native_gallery_collections` | opens the mail row menu with Shift+Return on a selected row and runs a chosen item | collections-102 | 1 |
| `native_gallery_collections` | reaches the mail table edit minus by selection and swipes a table row open without reordering | collections-106 | 2 |
| `native_gallery_collections` | mounts the virtual mail surface alone and swipes deletes and opens row menus from each input | collections-108 | 6 |
| `native_gallery_collections` | drops the mail heading on a short landscape and keeps the first row on every surface | collections-110 | 4 |
| `native_parity_media` | follows a readable alert source that moves in flight and keeps the last origin when it goes nil | apps-258 | 2 |
| `native_parity_apps` | draws every player-facing string from the locale table and relabels all of them on a locale switch | apps-70 | 1 |

`closeNote` in the data file records what each of these cases does not
prove:

- paint-148: The neutral package sets `strong` to Bold and `numeral` to
  Regular. On `main` they were SemiBold and Bold. A package that sets `body`
  or `control` gets the derivation that `api.md` describes.
- collections-108: The hosted gesture engine was deleted, so its laziness
  is not tested. TabView keeps visited pages, so the list page is hidden,
  not removed.
- collections-110 and apps2-232: The fake engine does no layout and does
  not move the selection. A live check must show that the first row is on
  the screen at 844x390 and that the D-pad reaches both tab strips.
- apps-70: The Sheet close button label "Done" is fixed English and has no
  option. The case skips it.

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

These 3 contracts (9 main cases) still have a promise and no candidate case
that proves all of it. Each has a partial headless case. Only a live Studio
check can prove the rest, because the fake engine does no layout and does
not deliver engine input.

| ID | Group | Main cases | Contract | Live check |
|---|---|---:|---|---|
| apps2-35 | row-actions | 3 | Scrolling the page closes a swiped-open tray; a swipe never plays the track (touch and mouse) | A swipe on a playlist row does not also fire `RowHit.Activated`. |
| apps-163 | input-actions | 5 | Exactly one Activate per press across the InputAction and native Activated paths | One physical Return press on a selected Button reaches `onActivate` once. |
| navigation-1-69 | layout-geometry | 1 | Nothing on the callout page crosses a lateral edge at swept sizes | Nothing on the callout page crosses a lateral edge at 390, 768, 1280 and 1920 pixels. |

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
