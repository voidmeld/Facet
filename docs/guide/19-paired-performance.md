# Paired performance comparison

This page compares the headless controlled scenes and the microbenchmarks of
three commits on one host. The runs are paired and interleaved. Read the ratios.
Do not read the absolute numbers as budgets or as device timings.

| Label | Commit | Description |
|---|---|---|
| base | `a8c8895673c0745506908b66dc89f8cead6b66f3` | `main` before the native cutover |
| cand | `7c1c295091c4e08d44725da57f2ea5bb2cfa3549` | `codex/compose-ui-simplification` (draft PR josha/Facet#22) |
| opt | `23949109` | `cand` plus the three optimizations on this page |

The commits after `23949109` on this branch add only this page and the
comparison tools. They do not change runtime code.

The candidate branch moved twice during this work. The work started on
`095c0a04`. The main tables use `7c1c2950`. The branch is now rebased on
`4afc156926c036f0f46413cf493c6bd732806107`, where the same three optimizations
are `956b7419`, `38a4a449` and `dd9d9640`.
[Earlier runs on 095c0a04](#earlier-runs-on-095c0a04) summarizes the runs on
the first head. [Latest head 4afc1569](#latest-head-4afc1569) has a shorter
confirmation run on the current head, and a harness change that affects all
candidate numbers there.

## Host

- CPU: Apple M2 Max, 12 cores (`sysctl machdep.cpu.brand_string hw.ncpu`).
- Memory: 32 GB.
- OS: macOS 27.0, build 26A428. Lune 0.10.4, StyLua 2.5.2 (pinned by
  `rokit.toml`).
- This host is a shared developer workstation, not an isolated virtual machine.
  Roblox Studio and other agents' processes ran during all measurements. The
  1-minute load average was 11.8-34.7 during the main run. The yardstick
  drift columns below show the effect. Interleaving and pairing reduce the
  effect of this load on the ratios. They do not remove it. The spread columns
  show single rounds that ran more than 10 times slower than the median.
- `bench/perf_budgets.json` was recorded on a different Apple-silicon Mac.
  Budget pass or fail on this host is not evidence. This page does not use the
  budgets.

## Method

1. Each commit has its own git worktree.
2. Each round runs `base`, then `cand`, then `opt`. The main run has 10 rounds.
3. In each round, each of the 27 controlled scenes runs in a fresh Lune
   process: `lune run tools/lune/perf_paired_scene <scene>`. The runner calls
   the commit's own unmodified `perf_runner.runScene` with the commit's own
   scene, warm-up and sample counts, at the reference profile (`floorAndroid`).
   `main` cannot run its full `tools/perf.sh` matrix because three scenes fail
   setup. A fresh process for each scene isolates that failure. The same method
   runs on all three commits.
4. After the scenes, the round runs the commit's own `tools/bench.sh`.
5. `tools/perf_paired.py report` computes these values:
   - `p50` and `p95`: the median over rounds of each run's p50 and p95, in ms.
   - `ratio`: the median of the second commit divided by the median of the first
     commit. A ratio below 1 means that the second commit is faster.
   - `paired range`: the minimum and maximum of the ratio of the two runs in the
     same round.
   - `spread`: the minimum and maximum p95 over rounds.
   - `Flag`: the ratio is more than 1.05 and every paired ratio is more than 1.
     That is, the second commit is slower by more than 5% in the same direction
     in every round.

Both commits use the same scene names. `bench/workload_fidelity.json` on the
candidate records how each native workload keeps the population, trigger and
cadence of the original scene. The headless candidate numbers omit native
engine layout, text measurement, selection routing, StyleSheet resolution,
asset loading and paint. The baseline numbers include the Facet solver and
renderer that the candidate removed. Thus a ratio compares the Luau work that
each commit does. It is not a frame-time comparison.

### Unavailable baseline scenes

`alert-present-dismiss`, `picker-menu-open-close` and `radial-menu-open-close`
fail setup on `main` in every round with
`Compose[owner/no-active-owner]: cleanup has no owner to register with`. These
rows have no baseline number. This page does not estimate one.

## Summary

| Scene | p50 base to cand | p50 base to opt | p50 cand to opt | p95 base to cand | p95 base to opt | Status |
|---|---:|---:|---:|---:|---:|---|
| theme-swap-metrics | 2.045 | 1.144 | 0.559 | 1.433 | 0.758 | Flag removed. The p50 median stays 14% above base, without a consistent direction (paired range 0.73-1.45). |
| theme-swap-assets | 2.001 | 1.172 | 0.586 | 1.868 | 0.858 | Flag removed. The p50 median stays 17% above base, without a consistent direction (paired range 0.65-1.96). |
| scroll-focus-traversal | 1.242 | 1.001 | 0.806 | 1.008 | 0.826 | Fixed. |
| lab-dense-scroll | 2.890 | 2.548 | 0.882 | 0.452 | 0.414 | Not fixed. Work moved between steps; total work is lower. See below. |
| theme-swap-flat | 0.876 | 0.332 | 0.379 | 0.804 | 0.318 | Not flagged; faster. |

No microbenchmark is flagged in the main run.

## Before: base compared with cand (10 rounds)

| Scene | base p50 | cand p50 | p50 ratio | p50 paired range | base p95 | cand p95 | p95 ratio | p95 paired range | base p95 spread | cand p95 spread | Flag |
|---|---:|---:|---:|---|---:|---:|---:|---|---|---|---|
| hud-binding-storm | 0.3071 | 0.0418 | 0.136 | 0.09-0.16 | 0.8647 | 0.1454 | 0.168 | 0.03-0.22 | 0.5550-7.2252 | 0.0937-0.3444 |  |
| settings-churn | 2.9447 | 1.4641 | 0.497 | 0.23-0.66 | 5.3631 | 3.7739 | 0.704 | 0.06-0.88 | 4.1729-115.0250 | 2.5737-24.6875 |  |
| scroll-focus-traversal | 0.0810 | 0.1006 | 1.242 | 1.21-1.41 | 0.3240 | 0.3266 | 1.008 | 0.59-2.52 | 0.1867-0.9342 | 0.2055-1.0440 | cand slower (p50) |
| collection-mutation | 1.9898 | 0.5613 | 0.282 | 0.17-0.50 | 5.7032 | 1.5673 | 0.275 | 0.06-0.89 | 2.6887-31.1643 | 1.0693-7.4087 |  |
| animation-interruption | 0.4459 | 0.0053 | 0.012 | 0.00-0.01 | 1.7493 | 0.0102 | 0.006 | 0.00-0.04 | 0.9794-8.8425 | 0.0054-0.0530 |  |
| locale-textsize-change | 0.2991 | 0.0037 | 0.012 | 0.01-0.01 | 0.8775 | 0.0063 | 0.007 | 0.00-0.06 | 0.6980-7.2708 | 0.0038-0.0435 |  |
| async-image-burst | 0.0509 | 0.0067 | 0.132 | 0.12-0.16 | 0.1956 | 0.0118 | 0.060 | 0.01-0.14 | 0.1140-0.9116 | 0.0080-0.0512 |  |
| shadow-storm | 0.0109 | 0.0001 | 0.011 | 0.01-0.03 | 0.0328 | 0.0002 | 0.005 | 0.00-0.01 | 0.0149-0.4480 | 0.0002-0.0005 |  |
| virtual-list-scroll | 2.1566 | 0.6960 | 0.323 | 0.15-0.41 | 4.7118 | 2.3847 | 0.506 | 0.13-0.68 | 2.6597-22.1778 | 1.2029-8.9425 |  |
| native-scroll-drag | 0.0061 | 0.0056 | 0.908 | 0.77-0.96 | 0.0297 | 0.0115 | 0.389 | 0.12-4.80 | 0.0090-0.0704 | 0.0069-0.0546 |  |
| dense-hud | 0.9214 | 0.0242 | 0.026 | 0.01-0.04 | 2.8760 | 0.0804 | 0.028 | 0.00-0.09 | 1.4129-15.5938 | 0.0342-0.1626 |  |
| stylesheet-state-churn | 0.1276 | 0.0258 | 0.202 | 0.18-0.24 | 0.5237 | 0.1013 | 0.193 | 0.10-0.44 | 0.2649-0.8741 | 0.0353-0.1916 |  |
| async-image-grid | 4.0489 | 1.0579 | 0.261 | 0.18-0.39 | 7.8893 | 2.5425 | 0.322 | 0.18-0.75 | 4.2756-22.9800 | 1.7621-17.1377 |  |
| screen-lifecycle-churn | 8.4887 | 4.0000 | 0.471 | 0.41-0.82 | 12.9415 | 6.9105 | 0.534 | 0.38-2.33 | 8.9211-30.7098 | 5.3672-64.6494 |  |
| theme-swap-flat | 0.2379 | 0.2085 | 0.876 | 0.58-1.03 | 0.7233 | 0.5816 | 0.804 | 0.15-1.01 | 0.5120-8.7313 | 0.3775-1.2997 |  |
| theme-swap-metrics | 0.2486 | 0.5085 | 2.045 | 1.34-2.21 | 0.9473 | 1.3572 | 1.433 | 0.89-2.17 | 0.5933-3.8042 | 0.7810-3.7545 | cand slower (p50) |
| dense-motion | 1.5157 | 0.1982 | 0.131 | 0.07-0.15 | 3.3131 | 0.6263 | 0.189 | 0.14-0.35 | 2.6654-14.1368 | 0.3848-2.8257 |  |
| control-motion | 0.1789 | 0.0252 | 0.141 | 0.11-0.16 | 1.2511 | 0.2057 | 0.164 | 0.04-0.30 | 0.7036-7.5179 | 0.0723-0.7337 |  |
| theme-swap-assets | 0.2548 | 0.5098 | 2.001 | 1.61-2.78 | 0.8275 | 1.5458 | 1.868 | 0.92-3.53 | 0.5261-2.8995 | 0.8410-3.3372 | cand slower (p50) |
| lab-dense-scroll | 0.0922 | 0.2665 | 2.890 | 1.57-4.43 | 4.3755 | 1.9794 | 0.452 | 0.21-0.56 | 3.8495-13.7335 | 1.3438-3.8174 | cand slower (p50) |
| lab-collection-churn | 0.1460 | 0.1045 | 0.716 | 0.46-0.87 | 0.5488 | 0.3280 | 0.598 | 0.23-1.17 | 0.2775-1.8340 | 0.2188-0.9113 |  |
| adaptive-navigation-images | 0.2996 | 0.1085 | 0.362 | 0.23-0.43 | 0.9334 | 0.3216 | 0.345 | 0.15-0.47 | 0.5607-2.8070 | 0.2290-0.8992 |  |
| navigation-customization | 2.6470 | 0.0042 | 0.002 | 0.00-0.00 | 4.9858 | 0.0080 | 0.002 | 0.00-0.01 | 4.1207-25.0640 | 0.0051-0.0320 |  |
| alert-present-dismiss | n/a | 0.8044 | n/a | n/a | n/a | 2.1592 | n/a | n/a | n/a | 1.4633-4.5270 | base unavailable (failed) |
| picker-menu-open-close | n/a | 2.3207 | n/a | n/a | n/a | 4.2846 | n/a | n/a | n/a | 3.8159-10.5248 | base unavailable (failed) |
| picker-segmented-textsize | 0.7696 | 0.0023 | 0.003 | 0.00-0.01 | 2.3146 | 0.0028 | 0.001 | 0.00-0.01 | 1.5841-7.0078 | 0.0024-0.0175 |  |
| radial-menu-open-close | n/a | 0.0819 | n/a | n/a | n/a | 0.3639 | n/a | n/a | n/a | 0.1598-0.6579 | base unavailable (failed) |

| Microbenchmark | base p50 | cand p50 | p50 ratio | p50 paired range | base p95 | cand p95 | p95 ratio | Flag |
|---|---:|---:|---:|---|---:|---:|---:|---|
| billboard-nameplate-storm | 0.2426 | 0.0182 | 0.075 | 0.05-0.08 | 0.7176 | 0.0524 | 0.073 |  |
| collection-mutation | 0.0072 | 0.0076 | 1.055 | 0.88-1.18 | 0.0292 | 0.0213 | 0.730 |  |
| hud-binding-storm | 0.1990 | 0.1308 | 0.657 | 0.55-0.68 | 0.5292 | 0.3562 | 0.673 |  |
| motion-declarative | 4.9680 | 0.2321 | 0.047 | 0.02-0.05 | 7.3263 | 0.6645 | 0.091 |  |
| motion-explicit | 5.0889 | 0.2307 | 0.045 | 0.02-0.05 | 9.4765 | 0.7164 | 0.076 |  |
| mount-ramp | 176.4738 | 90.2646 | 0.511 | 0.23-0.84 | 288.7514 | 118.8219 | 0.412 |  |
| mount-ramp-inherited | 191.2280 | 90.7934 | 0.475 | 0.39-0.89 | 227.1378 | 170.7712 | 0.752 |  |
| mounted-slice-update-storm | 0.3567 | 0.0453 | 0.127 | 0.11-0.17 | 1.4559 | 0.1700 | 0.117 |  |
| settings-churn | 0.0079 | 0.0113 | 1.430 | 0.57-1.98 | 0.0374 | 0.0440 | 1.175 |  |
| sparse-update-under-load | 0.0012 | 0.0007 | 0.552 | 0.55-0.57 | 0.0023 | 0.0008 | 0.333 |  |
| table-mutation | 1.4134 | 0.5182 | 0.367 | 0.26-0.60 | 3.1843 | 1.8321 | 0.575 |  |
| table-resize-drag | 4.2090 | 0.7918 | 0.188 | 0.13-0.29 | 8.5975 | 2.0046 | 0.233 |  |
| textinput-typing-storm | 0.3792 | 0.0325 | 0.086 | 0.05-0.10 | 1.2098 | 0.1181 | 0.098 |  |
| zz-yardstick-cpu-after | 0.2980 | 0.2908 | 0.976 | 0.93-1.38 | 0.7519 | 0.7808 | 1.038 |  |
| zz-yardstick-cpu-before | 0.2840 | 0.2884 | 1.016 | 0.65-1.05 | 0.6917 | 0.6851 | 0.990 |  |

| Bench run | Yardstick p95 ms | Yardstick drift % |
|---|---:|---:|
| base-1 | 1.3535 | 5.3 |
| base-2 | 1.7009 | 1.9 |
| base-3 | 1.9280 | 47.2 |
| base-4 | 0.5855 | 4.4 |
| base-5 | 0.7171 | 50.5 |
| base-6 | 2.0127 | 122.7 |
| base-7 | 0.5611 | 1.4 |
| base-8 | 0.5095 | 11.4 |
| base-9 | 0.6348 | 24.9 |
| base-10 | 0.6979 | 8.0 |
| cand-1 | 2.7084 | 90.0 |
| cand-2 | 1.7857 | 22.6 |
| cand-3 | 1.1251 | 42.8 |
| cand-4 | 0.7541 | 48.7 |
| cand-5 | 0.9902 | 73.7 |
| cand-6 | 0.6820 | 31.6 |
| cand-7 | 0.5041 | 20.7 |
| cand-8 | 0.6843 | 17.7 |
| cand-9 | 0.5433 | 9.9 |
| cand-10 | 0.5677 | 5.3 |

## After: base compared with opt (10 rounds)

| Scene | base p50 | opt p50 | p50 ratio | p50 paired range | base p95 | opt p95 | p95 ratio | p95 paired range | base p95 spread | opt p95 spread | Flag |
|---|---:|---:|---:|---|---:|---:|---:|---|---|---|---|
| hud-binding-storm | 0.3071 | 0.0419 | 0.136 | 0.09-0.17 | 0.8647 | 0.1365 | 0.158 | 0.03-0.67 | 0.5550-7.2252 | 0.0767-0.5281 |  |
| settings-churn | 2.9447 | 1.4351 | 0.487 | 0.19-0.84 | 5.3631 | 3.2336 | 0.603 | 0.06-1.38 | 4.1729-115.0250 | 2.3515-14.2737 |  |
| scroll-focus-traversal | 0.0810 | 0.0811 | 1.001 | 0.96-1.36 | 0.3240 | 0.2677 | 0.826 | 0.47-4.10 | 0.1867-0.9342 | 0.1778-1.0016 |  |
| collection-mutation | 1.9898 | 0.5749 | 0.289 | 0.16-0.65 | 5.7032 | 1.6480 | 0.289 | 0.08-1.55 | 2.6887-31.1643 | 0.9411-4.3281 |  |
| animation-interruption | 0.4459 | 0.0053 | 0.012 | 0.01-0.01 | 1.7493 | 0.0106 | 0.006 | 0.00-0.04 | 0.9794-8.8425 | 0.0056-0.0489 |  |
| locale-textsize-change | 0.2991 | 0.0037 | 0.012 | 0.01-0.01 | 0.8775 | 0.0053 | 0.006 | 0.00-0.01 | 0.6980-7.2708 | 0.0038-0.0109 |  |
| async-image-burst | 0.0509 | 0.0067 | 0.132 | 0.12-0.14 | 0.1956 | 0.0108 | 0.055 | 0.01-0.15 | 0.1140-0.9116 | 0.0095-0.0557 |  |
| shadow-storm | 0.0109 | 0.0001 | 0.011 | 0.01-0.02 | 0.0328 | 0.0002 | 0.005 | 0.00-0.01 | 0.0149-0.4480 | 0.0002-0.0005 |  |
| virtual-list-scroll | 2.1566 | 0.5845 | 0.271 | 0.13-0.67 | 4.7118 | 1.5929 | 0.338 | 0.08-2.23 | 2.6597-22.1778 | 1.2200-12.8227 |  |
| native-scroll-drag | 0.0061 | 0.0056 | 0.908 | 0.77-1.94 | 0.0297 | 0.0085 | 0.287 | 0.10-3.71 | 0.0090-0.0704 | 0.0070-0.0480 |  |
| dense-hud | 0.9214 | 0.0245 | 0.027 | 0.01-0.04 | 2.8760 | 0.0992 | 0.034 | 0.00-0.11 | 1.4129-15.5938 | 0.0432-0.3811 |  |
| stylesheet-state-churn | 0.1276 | 0.0260 | 0.203 | 0.18-0.25 | 0.5237 | 0.0988 | 0.189 | 0.05-0.53 | 0.2649-0.8741 | 0.0463-0.2842 |  |
| async-image-grid | 4.0489 | 1.0747 | 0.265 | 0.13-0.51 | 7.8893 | 2.3400 | 0.297 | 0.10-0.98 | 4.2756-22.9800 | 1.8560-9.2519 |  |
| screen-lifecycle-churn | 8.4887 | 4.3614 | 0.514 | 0.29-2.08 | 12.9415 | 8.2400 | 0.637 | 0.30-9.82 | 8.9211-30.7098 | 5.1533-87.6206 |  |
| theme-swap-flat | 0.2379 | 0.0790 | 0.332 | 0.21-0.44 | 0.7233 | 0.2302 | 0.318 | 0.03-0.83 | 0.5120-8.7313 | 0.1247-1.0318 |  |
| theme-swap-metrics | 0.2486 | 0.2843 | 1.144 | 0.73-1.45 | 0.9473 | 0.7180 | 0.758 | 0.20-4.04 | 0.5933-3.8042 | 0.5171-3.8182 |  |
| dense-motion | 1.5157 | 0.1967 | 0.130 | 0.06-0.18 | 3.3131 | 0.5247 | 0.158 | 0.04-0.81 | 2.6654-14.1368 | 0.3532-4.4802 |  |
| control-motion | 0.1789 | 0.0244 | 0.136 | 0.10-0.18 | 1.2511 | 0.1880 | 0.150 | 0.03-2.29 | 0.7036-7.5179 | 0.0635-5.0115 |  |
| theme-swap-assets | 0.2548 | 0.2986 | 1.172 | 0.65-1.96 | 0.8275 | 0.7097 | 0.858 | 0.24-14.34 | 0.5261-2.8995 | 0.5361-7.5439 |  |
| lab-dense-scroll | 0.0922 | 0.2350 | 2.548 | 1.11-6.80 | 4.3755 | 1.8135 | 0.414 | 0.13-0.96 | 3.8495-13.7335 | 1.4801-5.2141 | opt slower (p50) |
| lab-collection-churn | 0.1460 | 0.1022 | 0.700 | 0.41-0.81 | 0.5488 | 0.3184 | 0.580 | 0.19-2.75 | 0.2775-1.8340 | 0.1705-2.1755 |  |
| adaptive-navigation-images | 0.2996 | 0.1081 | 0.361 | 0.20-0.39 | 0.9334 | 0.4155 | 0.445 | 0.17-0.73 | 0.5607-2.8070 | 0.2930-1.0396 |  |
| navigation-customization | 2.6470 | 0.0041 | 0.002 | 0.00-0.00 | 4.9858 | 0.0082 | 0.002 | 0.00-0.05 | 4.1207-25.0640 | 0.0052-0.2274 |  |
| alert-present-dismiss | n/a | 0.8192 | n/a | n/a | n/a | 2.1980 | n/a | n/a | n/a | 1.5891-20.6503 | base unavailable (failed) |
| picker-menu-open-close | n/a | 2.5707 | n/a | n/a | n/a | 4.3707 | n/a | n/a | n/a | 3.6211-46.1454 | base unavailable (failed) |
| picker-segmented-textsize | 0.7696 | 0.0023 | 0.003 | 0.00-0.00 | 2.3146 | 0.0035 | 0.002 | 0.00-0.00 | 1.5841-7.0078 | 0.0024-0.0161 |  |
| radial-menu-open-close | n/a | 0.0762 | n/a | n/a | n/a | 0.2537 | n/a | n/a | n/a | 0.1635-2.0701 | base unavailable (failed) |

| Microbenchmark | base p50 | opt p50 | p50 ratio | p50 paired range | base p95 | opt p95 | p95 ratio | Flag |
|---|---:|---:|---:|---|---:|---:|---:|---|
| billboard-nameplate-storm | 0.2426 | 0.0183 | 0.075 | 0.05-0.08 | 0.7176 | 0.0548 | 0.076 |  |
| collection-mutation | 0.0072 | 0.0081 | 1.115 | 0.92-1.29 | 0.0292 | 0.0301 | 1.032 |  |
| hud-binding-storm | 0.1990 | 0.1298 | 0.652 | 0.53-0.69 | 0.5292 | 0.3656 | 0.691 |  |
| motion-declarative | 4.9680 | 0.2310 | 0.046 | 0.02-0.06 | 7.3263 | 0.7296 | 0.100 |  |
| motion-explicit | 5.0889 | 0.2314 | 0.045 | 0.02-0.06 | 9.4765 | 0.7203 | 0.076 |  |
| mount-ramp | 176.4738 | 91.2281 | 0.517 | 0.18-0.95 | 288.7514 | 148.8588 | 0.516 |  |
| mount-ramp-inherited | 191.2280 | 91.7054 | 0.480 | 0.29-0.93 | 227.1378 | 116.2245 | 0.512 |  |
| mounted-slice-update-storm | 0.3567 | 0.0439 | 0.123 | 0.11-0.16 | 1.4559 | 0.1373 | 0.094 |  |
| settings-churn | 0.0079 | 0.0097 | 1.230 | 0.84-2.24 | 0.0374 | 0.0392 | 1.046 |  |
| sparse-update-under-load | 0.0012 | 0.0006 | 0.534 | 0.52-0.59 | 0.0023 | 0.0008 | 0.352 |  |
| table-mutation | 1.4134 | 0.4747 | 0.336 | 0.20-0.48 | 3.1843 | 1.5365 | 0.483 |  |
| table-resize-drag | 4.2090 | 0.7661 | 0.182 | 0.11-0.26 | 8.5975 | 1.9523 | 0.227 |  |
| textinput-typing-storm | 0.3792 | 0.0333 | 0.088 | 0.06-0.10 | 1.2098 | 0.1100 | 0.091 |  |
| zz-yardstick-cpu-after | 0.2980 | 0.2849 | 0.956 | 0.86-1.82 | 0.7519 | 0.6935 | 0.922 |  |
| zz-yardstick-cpu-before | 0.2840 | 0.2898 | 1.020 | 0.66-1.47 | 0.6917 | 0.6797 | 0.983 |  |

| Bench run | Yardstick p95 ms | Yardstick drift % |
|---|---:|---:|
| base-1 | 1.3535 | 5.3 |
| base-2 | 1.7009 | 1.9 |
| base-3 | 1.9280 | 47.2 |
| base-4 | 0.5855 | 4.4 |
| base-5 | 0.7171 | 50.5 |
| base-6 | 2.0127 | 122.7 |
| base-7 | 0.5611 | 1.4 |
| base-8 | 0.5095 | 11.4 |
| base-9 | 0.6348 | 24.9 |
| base-10 | 0.6979 | 8.0 |
| opt-1 | 3.4140 | 4.4 |
| opt-2 | 7.3645 | 163.3 |
| opt-3 | 0.6289 | 0.9 |
| opt-4 | 1.2224 | 72.9 |
| opt-5 | 1.4470 | 28.3 |
| opt-6 | 0.7106 | 6.4 |
| opt-7 | 0.5280 | 21.2 |
| opt-8 | 0.6360 | 19.8 |
| opt-9 | 0.5567 | 13.8 |
| opt-10 | 0.5104 | 15.7 |

## Effect of the optimizations: cand compared with opt (10 rounds)

| Scene | cand p50 | opt p50 | p50 ratio | p50 paired range | cand p95 | opt p95 | p95 ratio | p95 paired range | cand p95 spread | opt p95 spread | Flag |
|---|---:|---:|---:|---|---:|---:|---:|---|---|---|---|
| hud-binding-storm | 0.0418 | 0.0419 | 1.002 | 0.91-1.12 | 0.1454 | 0.1365 | 0.939 | 0.48-3.33 | 0.0937-0.3444 | 0.0767-0.5281 |  |
| settings-churn | 1.4641 | 1.4351 | 0.980 | 0.49-1.71 | 3.7739 | 3.2336 | 0.857 | 0.15-2.22 | 2.5737-24.6875 | 2.3515-14.2737 |  |
| scroll-focus-traversal | 0.1006 | 0.0811 | 0.806 | 0.73-0.99 | 0.3266 | 0.2677 | 0.820 | 0.28-4.54 | 0.2055-1.0440 | 0.1778-1.0016 |  |
| collection-mutation | 0.5613 | 0.5749 | 1.024 | 0.67-1.76 | 1.5673 | 1.6480 | 1.052 | 0.33-3.88 | 1.0693-7.4087 | 0.9411-4.3281 |  |
| animation-interruption | 0.0053 | 0.0053 | 0.996 | 0.93-1.04 | 0.0102 | 0.0106 | 1.039 | 0.12-3.64 | 0.0054-0.0530 | 0.0056-0.0489 |  |
| locale-textsize-change | 0.0037 | 0.0037 | 0.994 | 0.95-1.02 | 0.0063 | 0.0053 | 0.841 | 0.10-2.72 | 0.0038-0.0435 | 0.0038-0.0109 |  |
| async-image-burst | 0.0067 | 0.0067 | 1.003 | 0.90-1.09 | 0.0118 | 0.0108 | 0.917 | 0.34-2.54 | 0.0080-0.0512 | 0.0095-0.0557 |  |
| shadow-storm | 0.0001 | 0.0001 | 1.000 | 0.33-1.33 | 0.0002 | 0.0002 | 1.000 | 0.36-2.75 | 0.0002-0.0005 | 0.0002-0.0005 |  |
| virtual-list-scroll | 0.6960 | 0.5845 | 0.840 | 0.47-2.41 | 2.3847 | 1.5929 | 0.668 | 0.22-4.78 | 1.2029-8.9425 | 1.2200-12.8227 |  |
| native-scroll-drag | 0.0056 | 0.0056 | 1.000 | 0.98-2.11 | 0.0115 | 0.0085 | 0.738 | 0.22-6.98 | 0.0069-0.0546 | 0.0070-0.0480 |  |
| dense-hud | 0.0242 | 0.0245 | 1.016 | 0.99-1.26 | 0.0804 | 0.0992 | 1.234 | 0.59-2.47 | 0.0342-0.1626 | 0.0432-0.3811 |  |
| stylesheet-state-churn | 0.0258 | 0.0260 | 1.008 | 0.87-1.11 | 0.1013 | 0.0988 | 0.975 | 0.24-2.39 | 0.0353-0.1916 | 0.0463-0.2842 |  |
| async-image-grid | 1.0579 | 1.0747 | 1.016 | 0.60-1.65 | 2.5425 | 2.3400 | 0.920 | 0.13-2.12 | 1.7621-17.1377 | 1.8560-9.2519 |  |
| screen-lifecycle-churn | 4.0000 | 4.3614 | 1.090 | 0.35-4.48 | 6.9105 | 8.2400 | 1.192 | 0.13-16.01 | 5.3672-64.6494 | 5.1533-87.6206 |  |
| theme-swap-flat | 0.2085 | 0.0790 | 0.379 | 0.33-0.42 | 0.5816 | 0.2302 | 0.396 | 0.18-1.03 | 0.3775-1.2997 | 0.1247-1.0318 |  |
| theme-swap-metrics | 0.5085 | 0.2843 | 0.559 | 0.38-0.94 | 1.3572 | 0.7180 | 0.529 | 0.20-3.07 | 0.7810-3.7545 | 0.5171-3.8182 |  |
| dense-motion | 0.1982 | 0.1967 | 0.992 | 0.73-1.68 | 0.6263 | 0.5247 | 0.838 | 0.20-2.46 | 0.3848-2.8257 | 0.3532-4.4802 |  |
| control-motion | 0.0252 | 0.0244 | 0.967 | 0.78-1.35 | 0.2057 | 0.1880 | 0.914 | 0.32-32.93 | 0.0723-0.7337 | 0.0635-5.0115 |  |
| theme-swap-assets | 0.5098 | 0.2986 | 0.586 | 0.40-0.78 | 1.5458 | 0.7097 | 0.459 | 0.21-4.06 | 0.8410-3.3372 | 0.5361-7.5439 |  |
| lab-dense-scroll | 0.2665 | 0.2350 | 0.882 | 0.44-1.80 | 1.9794 | 1.8135 | 0.916 | 0.62-2.23 | 1.3438-3.8174 | 1.4801-5.2141 |  |
| lab-collection-churn | 0.1045 | 0.1022 | 0.977 | 0.86-1.18 | 0.3280 | 0.3184 | 0.971 | 0.32-2.93 | 0.2188-0.9113 | 0.1705-2.1755 |  |
| adaptive-navigation-images | 0.1085 | 0.1081 | 0.997 | 0.58-1.28 | 0.3216 | 0.4155 | 1.292 | 0.69-1.94 | 0.2290-0.8992 | 0.2930-1.0396 |  |
| navigation-customization | 0.0042 | 0.0041 | 0.975 | 0.83-1.06 | 0.0080 | 0.0082 | 1.034 | 0.25-28.13 | 0.0051-0.0320 | 0.0052-0.2274 |  |
| alert-present-dismiss | 0.8044 | 0.8192 | 1.018 | 0.87-3.03 | 2.1592 | 2.1980 | 1.018 | 0.83-9.72 | 1.4633-4.5270 | 1.5891-20.6503 |  |
| picker-menu-open-close | 2.3207 | 2.5707 | 1.108 | 0.80-2.54 | 4.2846 | 4.3707 | 1.020 | 0.73-12.09 | 3.8159-10.5248 | 3.6211-46.1454 |  |
| picker-segmented-textsize | 0.0023 | 0.0023 | 1.000 | 0.41-1.04 | 0.0028 | 0.0035 | 1.259 | 0.23-3.28 | 0.0024-0.0175 | 0.0024-0.0161 |  |
| radial-menu-open-close | 0.0819 | 0.0762 | 0.930 | 0.77-1.04 | 0.3639 | 0.2537 | 0.697 | 0.26-9.47 | 0.1598-0.6579 | 0.1635-2.0701 |  |

| Microbenchmark | cand p50 | opt p50 | p50 ratio | p50 paired range | cand p95 | opt p95 | p95 ratio | Flag |
|---|---:|---:|---:|---|---:|---:|---:|---|
| billboard-nameplate-storm | 0.0182 | 0.0183 | 1.003 | 1.00-1.02 | 0.0524 | 0.0548 | 1.045 |  |
| collection-mutation | 0.0076 | 0.0081 | 1.057 | 0.91-1.15 | 0.0213 | 0.0301 | 1.414 |  |
| hud-binding-storm | 0.1308 | 0.1298 | 0.992 | 0.97-1.06 | 0.3562 | 0.3656 | 1.026 |  |
| motion-declarative | 0.2321 | 0.2310 | 0.995 | 0.83-1.26 | 0.6645 | 0.7296 | 1.098 |  |
| motion-explicit | 0.2307 | 0.2314 | 1.003 | 0.85-1.36 | 0.7164 | 0.7203 | 1.005 |  |
| mount-ramp | 90.2646 | 91.2281 | 1.011 | 0.82-1.96 | 118.8219 | 148.8588 | 1.253 |  |
| mount-ramp-inherited | 90.7934 | 91.7054 | 1.010 | 0.69-1.65 | 170.7712 | 116.2245 | 0.681 |  |
| mounted-slice-update-storm | 0.0453 | 0.0439 | 0.971 | 0.94-1.05 | 0.1700 | 0.1373 | 0.808 |  |
| settings-churn | 0.0113 | 0.0097 | 0.860 | 0.49-1.82 | 0.0440 | 0.0392 | 0.890 |  |
| sparse-update-under-load | 0.0007 | 0.0006 | 0.969 | 0.94-1.06 | 0.0008 | 0.0008 | 1.056 |  |
| table-mutation | 0.5182 | 0.4747 | 0.916 | 0.64-1.38 | 1.8321 | 1.5365 | 0.839 |  |
| table-resize-drag | 0.7918 | 0.7661 | 0.968 | 0.61-1.50 | 2.0046 | 1.9523 | 0.974 |  |
| textinput-typing-storm | 0.0325 | 0.0333 | 1.024 | 0.90-1.08 | 0.1181 | 0.1100 | 0.931 |  |
| zz-yardstick-cpu-after | 0.2908 | 0.2849 | 0.980 | 0.81-1.45 | 0.7808 | 0.6935 | 0.888 |  |
| zz-yardstick-cpu-before | 0.2884 | 0.2898 | 1.005 | 0.92-1.40 | 0.6851 | 0.6797 | 0.992 |  |

| Bench run | Yardstick p95 ms | Yardstick drift % |
|---|---:|---:|
| cand-1 | 2.7084 | 90.0 |
| cand-2 | 1.7857 | 22.6 |
| cand-3 | 1.1251 | 42.8 |
| cand-4 | 0.7541 | 48.7 |
| cand-5 | 0.9902 | 73.7 |
| cand-6 | 0.6820 | 31.6 |
| cand-7 | 0.5041 | 20.7 |
| cand-8 | 0.6843 | 17.7 |
| cand-9 | 0.5433 | 9.9 |
| cand-10 | 0.5677 | 5.3 |
| opt-1 | 3.4140 | 4.4 |
| opt-2 | 7.3645 | 163.3 |
| opt-3 | 0.6289 | 0.9 |
| opt-4 | 1.2224 | 72.9 |
| opt-5 | 1.4470 | 28.3 |
| opt-6 | 0.7106 | 6.4 |
| opt-7 | 0.5280 | 21.2 |
| opt-8 | 0.6360 | 19.8 |
| opt-9 | 0.5567 | 13.8 |
| opt-10 | 0.5104 | 15.7 |

The `cand` to `opt` table has no flag. Two scenes had a p50 median above 1.05
without a consistent direction: picker-menu-open-close and
screen-lifecycle-churn. A second paired run of 12 rounds checked them, with
alert-present-dismiss and theme-swap-metrics, and `--skip-bench`. The 1-minute
load average was 30.3-47.0 during this run, so its spreads are wide. No scene
has a consistent direction. A diagnostic run of screen-lifecycle-churn, six
interleaved pairs of 1500 steps in one process, gave `opt`/`cand` p50 ratios of
0.74-1.07 (median 0.98).

| Scene | cand p50 | opt p50 | p50 ratio | p50 paired range | cand p95 | opt p95 | p95 ratio | p95 paired range | cand p95 spread | opt p95 spread | Flag |
|---|---:|---:|---:|---|---:|---:|---:|---|---|---|---|
| picker-menu-open-close | 3.1404 | 3.0704 | 0.978 | 0.62-1.60 | 7.5951 | 6.3281 | 0.833 | 0.18-5.49 | 4.1494-59.9894 | 3.3847-50.7178 |  |
| screen-lifecycle-churn | 4.8156 | 6.4257 | 1.334 | 0.47-2.52 | 10.0814 | 12.1156 | 1.202 | 0.14-8.95 | 5.0538-73.4005 | 5.3389-72.5135 |  |
| alert-present-dismiss | 0.9385 | 1.0188 | 1.086 | 0.61-1.75 | 2.6965 | 3.5128 | 1.303 | 0.34-8.25 | 1.5791-15.7565 | 2.1774-14.0545 |  |
| theme-swap-metrics | 0.5531 | 0.3366 | 0.608 | 0.29-1.06 | 1.4802 | 1.4754 | 0.997 | 0.23-5.09 | 0.8280-16.5335 | 0.7098-8.2753 |  |

## Flagged regressions

### theme-swap-metrics and theme-swap-assets

Measured cause: the style sheet kept only the last theme duration. The two
packages in each scene have different `metrics.motion.normal` values. Each swap
thus made a new `TweenInfo`. All native rules then looked retimed. For each
rule, `apply` built a new transitions table and compared it key by key with the
previous one. It also compared the rule's property tables key by key, on every
swap, for the same pairs of tables. On `7c1c2950` the style sheet has 161 rules.
One swap changes the properties of 126 rules in theme-swap-metrics, 139 in
theme-swap-assets and 104 in theme-swap-flat. On `095c0a04` it had 97 rules, and
one swap changed 81, 88 and 57.

Fix, in two commits:

1. `Reuse rule transition tables across theme swaps`: keep one `TweenInfo` for
   each duration, and build the transitions table of a rule once for each pair
   of compiled properties and timing.
2. `Remember rule property comparisons across theme swaps`: remember the result
   of each comparison of two property tables in weak tables. The style sheet
   never changes a property table after it compiles it. A new or unfrozen
   package makes new tables, which get a full comparison.

The rules still get the same `SetProperties` and `SetPropertyTransitions` calls.
The test "leaves unchanged native rules and running paint transitions untouched
during theme updates" still passes. It counts those calls.

Residual: the p50 median of both scenes stays 14-17% above base. Each swap
still writes every changed rule: 126 or 139 `SetProperties` calls and the
matching transitions. The candidate compiles resolved values into each rule.
A swap that writes fewer engine objects needs a different paint design, for
example StyleSheet tokens. This branch does not change the paint design.

### scroll-focus-traversal

Measured cause: the `Enabled` binding of each `InputContext` walked the node's
ancestors and read the modal scopes before it read the action's own condition.
For a `Button`, the condition is "this button is selected". It is false for 15
of the 16 buttons. Each of the 32 selection events in a step thus paid for an
ancestry walk that could not change the result.

Fix: `Check an action's own condition before walking its ancestry`. The binding
reads the condition first. The value of the binding does not change. When
`GuiService` exists, as in Studio, every binding also reads
`GuiService.SelectedObject`. There, the change also stops the walk for every
button that is not selected. The live Studio effect was not measured.

### lab-dense-scroll (not fixed)

The p50 ratio stays above 2. The p95 ratio is 0.45 for `cand` and 0.41 for
`opt`. The work moved between steps. The total work did not increase.

- The official runner does not record a mean. A diagnostic harness
  (`profile_scene`, not part of this branch) ran 3000 steps in one process, in
  four interleaved triplets. The mean step time was 1.84-4.61 ms on `base`,
  0.53-2.00 ms on `095c0a04` and 0.57-2.58 ms on `7c1c2950`. The ratio of the
  `7c1c2950` mean to the `base` mean in the same triplet was 0.22-0.56.
- A row is 156 px high and a step scrolls 61 px. In 3000 steps on `095c0a04`,
  1173 steps built a row, 1173 steps removed a row, and 654 steps (22%) changed
  nothing. A row removal cost about 0.12 ms. That cost sets the p50. `base` has
  a lower p50 and much more expensive slow steps (p95 4.4 ms against 1.8-2.0 ms).
- About 55% of the removal cost is the `Destroy` of the headless engine double
  (`tests/lib/native_engine.luau`). The rest is owner teardown in the vendored
  Compose snapshot. Facet watches and cleanups on this path cost less than
  0.01 ms for each step.

A fix would need a change to the vendored Compose snapshot, to the engine double,
or to the workload. This branch changes none of them.

### Microbenchmarks

No microbenchmark is flagged in the main run. A preliminary run on `095c0a04`
flagged `collection-mutation` at p50 (1.103, paired range 1.04-1.24). Later runs
did not confirm it: 1.048 (0.81-1.18) on `095c0a04` and 1.055 (0.88-1.18) on
`7c1c2950`. That benchmark does not call Facet code. The candidate version
creates each cell inside `Compose.withOwner`. The baseline version does not.
`src/` cannot change that difference.

## Latest head 4afc1569

This run used 6 rounds, all 27 scenes and `--skip-bench`. `cand` is `4afc1569`
and `opt` is `dd9d9640`. The 1-minute load average was 12.6-18.9.

The optimizations keep their effect: `cand` to `opt` p50 is 0.754 for
theme-swap-metrics, 0.607 for theme-swap-assets, 0.395 for theme-swap-flat and
0.853 for scroll-focus-traversal, with no flag in the `cand` to `opt` table.
But `4afc1569` has new flags against `main` that `7c1c2950` did not have, and
`opt` does not remove all of them.

| Scene | cand p50 | opt p50 | p50 ratio | p50 paired range | cand p95 | opt p95 | p95 ratio | p95 paired range | cand p95 spread | opt p95 spread | Flag |
|---|---:|---:|---:|---|---:|---:|---:|---|---|---|---|
| hud-binding-storm | 0.0912 | 0.0906 | 0.993 | 0.97-1.01 | 0.2373 | 0.2350 | 0.990 | 0.76-1.50 | 0.1869-0.3390 | 0.2103-0.3512 |  |
| settings-churn | 1.7318 | 1.7422 | 1.006 | 0.93-1.61 | 3.2240 | 3.4335 | 1.065 | 0.93-2.13 | 2.7050-3.6723 | 3.1018-7.8255 |  |
| scroll-focus-traversal | 0.1319 | 0.1125 | 0.853 | 0.84-0.88 | 0.3255 | 0.3127 | 0.961 | 0.66-1.29 | 0.2313-0.3775 | 0.2500-0.4642 |  |
| collection-mutation | 0.6209 | 0.6107 | 0.984 | 0.82-1.14 | 1.4179 | 1.3478 | 0.951 | 0.83-1.38 | 0.9365-1.6562 | 1.1163-2.2892 |  |
| animation-interruption | 0.0112 | 0.0113 | 1.006 | 0.99-1.05 | 0.0195 | 0.0251 | 1.292 | 0.52-5.87 | 0.0128-0.0303 | 0.0149-0.0754 |  |
| locale-textsize-change | 0.0099 | 0.0102 | 1.032 | 0.99-1.10 | 0.0154 | 0.0263 | 1.700 | 0.50-2.76 | 0.0129-0.0387 | 0.0145-0.0597 |  |
| async-image-burst | 0.5355 | 0.4823 | 0.901 | 0.60-2.04 | 1.1201 | 1.0206 | 0.911 | 0.12-4.94 | 0.9625-7.3064 | 0.8182-4.9222 |  |
| shadow-storm | 0.0001 | 0.0001 | 1.000 | 0.75-1.00 | 0.0002 | 0.0002 | 1.000 | 0.40-1.50 | 0.0002-0.0004 | 0.0002-0.0002 |  |
| virtual-list-scroll | 0.7846 | 0.8060 | 1.027 | 0.99-3.97 | 1.7894 | 2.0016 | 1.119 | 0.92-7.72 | 1.6537-2.2829 | 1.6352-13.9311 |  |
| native-scroll-drag | 0.0070 | 0.0069 | 0.994 | 0.86-1.22 | 0.0146 | 0.0123 | 0.846 | 0.48-2.80 | 0.0081-0.0428 | 0.0083-0.0549 |  |
| dense-hud | 0.0511 | 0.0509 | 0.996 | 0.96-1.10 | 0.1551 | 0.1396 | 0.900 | 0.57-8.14 | 0.1295-0.2417 | 0.1038-1.2339 |  |
| stylesheet-state-churn | 0.0286 | 0.0276 | 0.966 | 0.92-1.24 | 0.0613 | 0.0596 | 0.971 | 0.24-4.84 | 0.0518-0.1242 | 0.0303-0.2553 |  |
| async-image-grid | 2.9517 | 2.7983 | 0.948 | 0.79-2.74 | 4.5844 | 4.4212 | 0.964 | 0.24-3.94 | 4.3070-16.6406 | 3.9195-17.5320 |  |
| screen-lifecycle-churn | 5.0419 | 5.0855 | 1.009 | 0.59-2.96 | 7.1579 | 7.8018 | 1.090 | 0.19-4.92 | 6.7067-35.2241 | 6.6763-33.4173 |  |
| theme-swap-flat | 0.2775 | 0.1095 | 0.395 | 0.36-0.73 | 0.6625 | 0.2864 | 0.432 | 0.30-2.91 | 0.4719-0.8251 | 0.2344-1.6679 |  |
| theme-swap-metrics | 1.0289 | 0.7758 | 0.754 | 0.68-1.75 | 2.1334 | 2.2022 | 1.032 | 0.65-2.83 | 1.8915-2.3276 | 1.2780-5.3470 |  |
| dense-motion | 0.2878 | 0.2780 | 0.966 | 0.86-1.37 | 0.7225 | 0.6256 | 0.866 | 0.46-2.79 | 0.5330-1.1703 | 0.5418-1.8628 |  |
| control-motion | 0.0535 | 0.0528 | 0.987 | 0.88-1.39 | 0.2936 | 0.2626 | 0.894 | 0.28-12.23 | 0.2450-0.8977 | 0.2410-3.8901 |  |
| theme-swap-assets | 0.8309 | 0.5046 | 0.607 | 0.54-1.19 | 1.7606 | 1.1838 | 0.672 | 0.28-2.30 | 1.3943-4.2489 | 0.9212-3.8212 |  |
| lab-dense-scroll | 0.2310 | 0.2156 | 0.933 | 0.87-1.35 | 2.3684 | 2.5631 | 1.082 | 0.89-1.39 | 1.7973-3.0111 | 2.0151-4.1762 |  |
| lab-collection-churn | 0.1031 | 0.1044 | 1.012 | 0.88-1.25 | 0.2860 | 0.2792 | 0.976 | 0.69-2.00 | 0.2164-0.4435 | 0.2008-0.8874 |  |
| adaptive-navigation-images | 0.1584 | 0.1551 | 0.979 | 0.91-1.07 | 0.3896 | 0.3474 | 0.892 | 0.37-2.91 | 0.3158-0.9488 | 0.3145-1.8256 |  |
| navigation-customization | 0.0065 | 0.0067 | 1.026 | 0.94-1.47 | 0.0120 | 0.0146 | 1.223 | 0.47-5.25 | 0.0073-0.0178 | 0.0084-0.0681 |  |
| alert-present-dismiss | 1.0257 | 1.0229 | 0.997 | 0.86-3.71 | 2.2400 | 2.2023 | 0.983 | 0.77-6.66 | 1.9899-3.3485 | 1.7522-22.3105 |  |
| picker-menu-open-close | 3.0591 | 2.8783 | 0.941 | 0.86-3.09 | 4.8259 | 5.2564 | 1.089 | 0.92-2.50 | 4.7407-12.4857 | 4.4692-31.1793 |  |
| picker-segmented-textsize | 0.0062 | 0.0062 | 1.000 | 0.98-1.01 | 0.0090 | 0.0111 | 1.228 | 0.84-2.64 | 0.0075-0.0414 | 0.0063-0.0543 |  |
| radial-menu-open-close | 0.1253 | 0.1184 | 0.945 | 0.91-2.02 | 0.3856 | 0.3148 | 0.816 | 0.65-7.36 | 0.3020-0.6086 | 0.2793-4.4784 |  |

| Scene | base p50 | opt p50 | p50 ratio | p50 paired range | base p95 | opt p95 | p95 ratio | p95 paired range | base p95 spread | opt p95 spread | Flag |
|---|---:|---:|---:|---|---:|---:|---:|---|---|---|---|
| hud-binding-storm | 0.2820 | 0.0906 | 0.321 | 0.31-0.35 | 0.6838 | 0.2350 | 0.344 | 0.30-0.48 | 0.4973-0.8433 | 0.2103-0.3512 |  |
| settings-churn | 2.4078 | 1.7422 | 0.724 | 0.66-1.24 | 4.0189 | 3.4335 | 0.854 | 0.71-1.88 | 2.8538-4.5236 | 3.1018-7.8255 |  |
| scroll-focus-traversal | 0.0792 | 0.1125 | 1.420 | 1.36-1.52 | 0.2204 | 0.3127 | 1.419 | 1.13-3.02 | 0.1046-0.2654 | 0.2500-0.4642 | opt slower (p50, p95) |
| collection-mutation | 1.1745 | 0.6107 | 0.520 | 0.32-0.69 | 2.3967 | 1.3478 | 0.562 | 0.10-0.94 | 1.5155-22.6974 | 1.1163-2.2892 |  |
| animation-interruption | 0.3873 | 0.0113 | 0.029 | 0.02-0.03 | 1.0251 | 0.0251 | 0.025 | 0.00-0.08 | 0.7934-8.3827 | 0.0149-0.0754 |  |
| locale-textsize-change | 0.2765 | 0.0102 | 0.037 | 0.03-0.04 | 0.7432 | 0.0263 | 0.035 | 0.02-0.08 | 0.6108-1.1589 | 0.0145-0.0597 |  |
| async-image-burst | 0.0477 | 0.4823 | 10.106 | 9.79-22.06 | 0.1238 | 1.0206 | 8.242 | 6.83-30.85 | 0.1098-0.1595 | 0.8182-4.9222 | opt slower (p50, p95) |
| shadow-storm | 0.0109 | 0.0001 | 0.011 | 0.01-0.01 | 0.0219 | 0.0002 | 0.010 | 0.00-0.02 | 0.0123-0.0686 | 0.0002-0.0002 |  |
| virtual-list-scroll | 1.3753 | 0.8060 | 0.586 | 0.58-1.23 | 2.5496 | 2.0016 | 0.785 | 0.61-1.91 | 2.3773-22.8962 | 1.6352-13.9311 |  |
| native-scroll-drag | 0.0060 | 0.0069 | 1.161 | 1.11-1.43 | 0.0085 | 0.0123 | 1.451 | 0.59-7.08 | 0.0078-0.0165 | 0.0083-0.0549 | opt slower (p50) |
| dense-hud | 0.6318 | 0.0509 | 0.081 | 0.06-0.09 | 1.3419 | 0.1396 | 0.104 | 0.05-0.14 | 1.2038-9.1427 | 0.1038-1.2339 |  |
| stylesheet-state-churn | 0.1155 | 0.0276 | 0.239 | 0.22-0.29 | 0.3533 | 0.0596 | 0.169 | 0.07-0.74 | 0.1858-0.4269 | 0.0303-0.2553 |  |
| async-image-grid | 2.7014 | 2.7983 | 1.036 | 0.94-1.26 | 4.7815 | 4.4212 | 0.925 | 0.70-1.06 | 3.7663-25.1705 | 3.9195-17.5320 |  |
| screen-lifecycle-churn | 6.5503 | 5.0855 | 0.776 | 0.68-1.82 | 8.8515 | 7.8018 | 0.881 | 0.82-3.98 | 7.7763-22.5851 | 6.6763-33.4173 |  |
| theme-swap-flat | 0.2139 | 0.1095 | 0.512 | 0.45-0.89 | 0.6515 | 0.2864 | 0.440 | 0.35-2.07 | 0.4375-0.8041 | 0.2344-1.6679 |  |
| theme-swap-metrics | 0.2227 | 0.7758 | 3.483 | 3.00-7.91 | 0.5280 | 2.2022 | 4.171 | 2.41-9.20 | 0.4623-0.6713 | 1.2780-5.3470 | opt slower (p50, p95) |
| dense-motion | 1.3152 | 0.2780 | 0.211 | 0.18-0.30 | 2.3034 | 0.6256 | 0.272 | 0.18-0.81 | 1.7972-2.9605 | 0.5418-1.8628 |  |
| control-motion | 0.1646 | 0.0528 | 0.321 | 0.31-0.44 | 1.1826 | 0.2626 | 0.222 | 0.20-2.78 | 0.8681-1.3968 | 0.2410-3.8901 |  |
| theme-swap-assets | 0.2144 | 0.5046 | 2.354 | 1.97-4.75 | 0.6004 | 1.1838 | 1.972 | 1.42-6.84 | 0.4542-0.8307 | 0.9212-3.8212 | opt slower (p50, p95) |
| lab-dense-scroll | 0.0700 | 0.2156 | 3.081 | 2.03-6.08 | 3.8262 | 2.5631 | 0.670 | 0.50-1.11 | 3.2351-4.1307 | 2.0151-4.1762 | opt slower (p50) |
| lab-collection-churn | 0.1378 | 0.1044 | 0.757 | 0.67-0.94 | 0.4291 | 0.2792 | 0.651 | 0.42-1.88 | 0.2495-0.8468 | 0.2008-0.8874 |  |
| adaptive-navigation-images | 0.2764 | 0.1551 | 0.561 | 0.37-0.65 | 0.7128 | 0.3474 | 0.487 | 0.04-2.10 | 0.6407-9.2076 | 0.3145-1.8256 |  |
| navigation-customization | 2.5410 | 0.0067 | 0.003 | 0.00-0.00 | 4.0439 | 0.0146 | 0.004 | 0.00-0.02 | 3.1578-4.8237 | 0.0084-0.0681 |  |
| alert-present-dismiss | n/a | 1.0229 | n/a | n/a | n/a | 2.2023 | n/a | n/a | n/a | 1.7522-22.3105 | base unavailable (failed) |
| picker-menu-open-close | n/a | 2.8783 | n/a | n/a | n/a | 5.2564 | n/a | n/a | n/a | 4.4692-31.1793 | base unavailable (failed) |
| picker-segmented-textsize | 0.7882 | 0.0062 | 0.008 | 0.01-0.01 | 1.7127 | 0.0111 | 0.006 | 0.00-0.03 | 1.4431-1.9564 | 0.0063-0.0543 |  |
| radial-menu-open-close | n/a | 0.1184 | n/a | n/a | n/a | 0.3148 | n/a | n/a | n/a | 0.2793-4.4784 | base unavailable (failed) |

Measured causes of the new flags:

- `4afc1569` changed the headless engine double. `tests/lib/native_engine.luau`
  now calls `pcall` to read the class default of the property on every property
  write, to check the value type. This is test-harness cost, not Facet or
  engine cost. With `profile_scene`, 2000 steps in one process, two alternating
  rounds on `4afc1569`, the double from `7c1c2950` against the double from
  `4afc1569` gave these p50 values: async-image-burst 0.0074 ms against
  0.80-0.96 ms, hud-binding-storm 0.047 ms against 0.10-0.11 ms,
  scroll-focus-traversal 0.11-0.12 ms against 0.18-0.21 ms,
  native-scroll-drag 0.0062-0.0064 ms against 0.0080-0.0082 ms. The
  async-image-burst flag (p50 ratio 11.2 to `main`) and most of the other new
  flags come from this change. A cache of the default value type for each class
  and property would keep the same check. This branch does not change the
  harness, because that would change the measurement.
- The style sheet grew from 161 to 210 rules. One swap now changes 161 rules in
  theme-swap-metrics, 186 in theme-swap-assets and 149 in theme-swap-flat. Each
  swap writes each changed rule. The optimizations remove the comparison
  overhead, but not these writes.

A 10-round run with bench on `4afc1569` was not done. The branch moved during
this work, and the host was heavily loaded.

## Earlier runs on 095c0a04

These runs used the same method. `opt` was the same three optimizations on
`095c0a04`.

| Run | Scene | p50 base to cand | p50 base to opt | p50 cand to opt |
|---|---|---:|---:|---:|
| 6 rounds, base and cand | theme-swap-metrics | 1.564 (flag) | n/a | n/a |
| 6 rounds, base and cand | theme-swap-assets | 1.646 (flag, also p95 1.164) | n/a | n/a |
| 6 rounds, base and cand | scroll-focus-traversal | 1.250 (flag) | n/a | n/a |
| 6 rounds, base and cand | lab-dense-scroll | 3.007 (flag) | n/a | n/a |
| 10 rounds, three commits | theme-swap-metrics | 1.524 (flag) | 0.965 | 0.633 |
| 10 rounds, three commits | theme-swap-assets | 1.551 (flag) | 0.981 | 0.632 |
| 10 rounds, three commits | theme-swap-flat | 0.571 | 0.238 | 0.418 |
| 10 rounds, three commits | scroll-focus-traversal | 1.267 (flag) | 1.015 | 0.801 |
| 10 rounds, three commits | lab-dense-scroll | 2.393 (flag) | 2.336 (flag) | 0.976 |

A 12-round check on `095c0a04` compared `cand` and `opt` for
alert-present-dismiss (1.008), dense-motion (1.004), picker-menu-open-close
(0.966) and scroll-focus-traversal (0.799). None had a consistent direction
except the faster scroll-focus-traversal.

## Verification

| Check | `7c1c2950` | opt on `7c1c2950` | `4afc1569` | opt on `4afc1569` (this branch) |
|---|---|---|---|---|
| `tools/verify.sh fast`, suite | 651 passed | 651 passed | 653 passed | 653 passed |
| `tools/verify.sh fast`, coverage producer | FAIL: 3 pending live Studio risks | FAIL: the same 3 | FAIL: the same 3 | FAIL: the same 3 |
| `tools/verify.sh fast`, other producers | PASS | PASS | PASS | PASS |
| `python3 tools/check_types.py` | PASS | PASS | PASS | PASS |
| `stylua --check src tests tools bench examples` | PASS | PASS | PASS | PASS |
| `tools/package.sh build` and `status` | not run | build PASS; status reports the existing drift since release 0.10.0 | not run | build PASS; status reports the same drift |

The three pending live risks are the collection toolbar under phone and
largest text, the shell reservation under themes and largest text, and haptic
motor output on physical devices. This branch does not change them.

## Reproduce

```sh
rokit install
git worktree add --detach ../facet-base a8c8895673c0745506908b66dc89f8cead6b66f3
git worktree add --detach ../facet-cand 7c1c295091c4e08d44725da57f2ea5bb2cfa3549
python3 tools/perf_paired.py run --out /tmp/paired --rounds 10 \
  base=../facet-base cand=../facet-cand opt=.
python3 tools/perf_paired.py report /tmp/paired base cand
python3 tools/perf_paired.py report /tmp/paired base opt
python3 tools/perf_paired.py report /tmp/paired cand opt
```

`run` copies `tools/lune/perf_paired_scene.luau` into each worktree as an
untracked file, because `main` does not have it. Close Roblox Studio and other
heavy processes before a run.
