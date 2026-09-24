# Performance verification

## Running the benchmarks

Run `tools/bench.sh` when no verification or build runs at the same time.

When you change the implementation, keep the population, mutation and
lifecycle intent of each workload. Do not compare a removed Facet layout phase
directly to the total native frame time. Engine layout is now outside the
headless CPU measurement.

## Workloads

The benchmarks measure:

- binding storms,
- settings churn,
- keyed collection mutation,
- sparse updates,
- mount ramps,
- table mutation and resizing,
- nameplates,
- typing,
- motion.

Use the native performance scenarios for live geometry and for the work from
input to visible result.

## Baselines and failures

Keep the checked-in baselines. Report preexisting failures separately from
regressions. The old baseline already failed typing-storm on this host. That
fact does not permit you to reset a threshold or to remove the workload.

## CI host

CI runs the full timing gate on the pinned `macos-15` ARM runner. The CPU and
the architecture of the host affect these wall-clock measurements. Compare
captured timings together with their host context. A change of runner does not
prove a runtime speedup.

The budgets and workloads stay checked in. Each full run makes its own
performance report before it validates that report.
