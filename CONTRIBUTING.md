# Contributing to Facet

Install the pinned toolchain with `rokit install`. Read [AGENTS.md](AGENTS.md)
and [the architecture](docs/guide/02-architecture.md) before you change the
library.

A change must keep one runtime path:

- Compose owns the native Instances and their lifetime.
- Roblox owns the engine mechanisms.
- Facet owns control behavior.

Do not add a second scheduler, scene representation, renderer, solver, input
transport or application facade. Use native datatypes and native property names
as the ordinary authoring vocabulary.

Work in an isolated checkout. Keep control behavior, public types, examples,
documentation and verification aligned. In source, use `Host` for the native
constructors. Source contains no explanatory comments. Keep the required
directives and notices.

## Verification

1. Use a checkout with Git history. Clone without `--depth`, or run
   `git fetch --unshallow` in a shallow clone. The coverage audit reads the
   pinned pre-cutover commit to account for removed and replaced specs. CI also
   fetches this history.
2. While you edit, run the targeted behavioral specs.
3. Run `tools/verify.sh full` for a completed change. Read its report,
   including the unmapped legacy behavioral coverage. A passing subset from a
   new runner is not full parity.

The [verification scope audit](docs/guide/18-verification-scope.md) records the
substantial reduction from main and the unresolved coverage work. At this time,
a native `full` run is a complete run of the candidate's checks. It is not
equivalent to the historical coverage.

Run `tools/bench.sh` when no other verification load runs. Keep the workload
intent and the checked-in baselines. Report changed measurement boundaries and
preexisting threshold failures explicitly. For real layout and input evidence,
exercise the maintained gallery and the virtual monitors in Roblox Studio.

After a source change, run `tools/package.sh build` and
`tools/package.sh status`. Cloud publication is not part of a code change.

## Versioning

`src/init.luau` is the only version authority. Version 0.12.0 is the native
cutover. It removes the former application, scene, layout and compatibility
APIs in one break. Do not add migration shims or a second supported
architecture. Describe the public effects of each later change in the
changelog.
