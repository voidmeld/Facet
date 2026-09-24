# Verification scope during the native cutover

PR22's native verification is substantially smaller than main's verification.
A passing native `full` run is not evidence of equivalent historical coverage.
It means the commands selected by the current runner passed. Do not infer a
performance improvement from the shorter verification time.

## Measured comparison

The baseline is commit `a8c8895673c0745506908b66dc89f8cead6b66f3`, immediately
before the native cutover. The candidate audited on 2026-09-23 was `e12f9d40`.

| Inventory | Baseline | Candidate before restoring checks |
|---|---:|---:|
| Test cases | 10,848 registered | 593 executed |
| Full-tier producers | 130 | 24 |
| Rows in the historical verification graph | 505 | Historical graph not evaluated |

The baseline case count comes from loading `tests/run.luau` with registration
instrumented and execution suppressed, not a fresh passing baseline test run.
The candidate count comes from `artifacts/verify/native/suite.json`. Case counts
are not equivalent units of behavior, but this reduction needs justification.

The baseline producer counts come from `tools/lune/verify/graph.json` at the
baseline commit, selecting producers with `tiers.full == true`. Their environment
classes are 94 deterministic, 24 Studio, seven device, three external and two
package. Studio and device producers include validators of recorded evidence;
130 does not mean 130 freshly executed runtime suites. The graph also includes
old architecture and historical-project checks that cannot simply be rerun
against the native implementation.

## What the current mapping proves

The candidate coverage inventory classifies 252 historical specs as removed
mechanisms and 249 as behavior replacements. It runs 30 available specs and
tracks 18 gallery parity entries. These are inventory classifications, not a
case-by-case proof that all user-facing contracts survived.

A retirement currently requires nonempty rationale text. A replacement names
specs and passing case IDs, but the checker does not require every original
assertion to be accounted for. Broad retirement rationales can therefore hide
surviving behavior. Only 14 replacement entries contained `caseMappings` in this
audit. The runner also ignores `pendingLiveRisks` when deciding its exit code.

`historicalParity: "not-established"` in the current report is independent of
`ok`. `completeTier` means all selected commands were attempted; it does not
establish historical parity or fresh Studio/device coverage.

## Restored checks

The follow-up restores the existing link checker and its fault-injection
self-test, the source-size guard, and the type and package checker self-tests to
native `full`. Restoring link validation exposed two obsolete API anchors in the
historical changelog; those references now explicitly describe the old API.
These checks retain their existing implementations and failure conditions.

## Unresolved coverage work

Before treating native verification as equivalent protection, account for the
historical producers and original behavioral assertions individually. In
particular:

- Port surviving control contracts, error handling, input/focus behavior,
  collection ownership and teardown assertions; private solver/renderer removal
  alone does not justify retiring those behaviors.
- Audit the lost fuzz, fault, soak and conformance workloads. The native suite
  has some corresponding cases, but their mappings do not prove equivalent
  workload duration, seed coverage, fault injection or invariant strength.
- Audit omitted public-surface, boundary, documentation, registration and
  artifact checks. Restore checks that still apply and replace architecture
  assumptions where necessary.
- Verify all maintained standalone/reference place bootstraps and theme
  distributions. Building the gallery, monitors and performance place does not
  cover all former artifact producers.
- Renew relevant Studio/device evidence. Outstanding recorded risks include
  compact/largest-text collections and settings, live preferred-transparency
  changes, and retained-page transient/haptic/motion lifetime.

The previous Ubuntu CI lane was moved to macOS ARM after host-dependent timing
threshold failures. That is a change of measurement environment, not proof that
the Ubuntu regression was resolved. Preserve this distinction when comparing
performance reports and deciding which platforms CI must cover.

See [Contributing](../../CONTRIBUTING.md) for running the current tier and
[device verification](11-device-verification.md) for the limits of headless
checks. This audit remains open; restoring a handful of checks does not close it.
