# Maintaining Facet

## Structure

The public root exports Compose, its Roblox host, the control factory, the
themes and the control types. `src/ui` implements the controls directly over
the supplied runtime. `src/vendor/compose` is generated and read-only.

Facet has none of these:

- a client adapter layer,
- a Facet scene,
- a renderer,
- an application,
- a general layout solver,
- a focus graph.

## Controls

A control implementation consumes its behavioral options. It forwards native
properties, event keys, attributes and children unchanged. The common private
helpers only make native components or observe native properties. They do not
own a runtime, a frame loop or an application lifetime.

## Themes

Theme definitions compile to native StyleSheets. The callers own the
StyleLinks. Do not write explicit default paint properties that hide the
stylesheet rules.

## Evidence

Control policy tests use a native engine double. Geometry, hit testing, IME,
scrolling and input eligibility need live Studio evidence. When you retire tests
of removed mechanisms, keep the behavior coverage of each control family. The
verification report must identify each remaining coverage gap. The
[verification scope](guide/18-verification-scope.md) records the known gaps.

Read the [contributor workflow](../CONTRIBUTING.md), the
[API reference](reference/api.md) and the
[control playbook](extending/new-control.md).
