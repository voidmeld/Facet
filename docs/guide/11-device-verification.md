# Device verification

## What a headless run proves

A headless native engine double verifies bindings, event cleanup and control
policy. It does not run engine layout, hit testing, text shaping, IME or input
routing. Claims about those behaviors need evidence from live Roblox Studio or
from a physical device.

## What to exercise

Build and run the actual gallery and the virtual monitors. Exercise:

- compact and wide sizes,
- keyboard and gamepad selection,
- pointer and touch controls,
- preferred text size,
- reduced motion,
- theme switching,
- modal Back and focus restoration.

For the virtual monitors, also exercise:

- spatial and flat switching,
- Discover sorting and scanning,
- Avatar scene controls,
- streaming Chat while you scroll.

## What to record

Record the build revision, the scenario, the observed interactions and the
engine errors. Keep benchmark evidence and live evidence separate. A pre-cutover
screenshot or a passing subset does not prove the behavior of this
architecture.

The [verification scope](18-verification-scope.md) lists the live evidence
that is still outstanding.
