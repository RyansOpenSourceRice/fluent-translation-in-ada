# MAINTAINERS.md

## Ownership

Maintained by Ryan (`RyansOpenSourceRice`). Single maintainer; see
`git log` for history.

## Scope

`fluent-translation-in-ada` is a Project Fluent (FTL) translation library
in Ada: resource parsing, message resolution with locale fallback, and
locale services in pure Ada with SPARK Silver contracts. Upstream EBNF and
fixture conformance is tracked in `SPECIFICATION.md`.

## What this library does not do

- No host FFI for internationalization (no ICU4C, no OS locale calls).
- No code generation, macros, or build-time tooling beyond Alire/GPRbuild.
- No network access, no async runtime, no GUI.
- No SDK or language bindings (per planning rules, an SDK is a decision,
  not a default; none has been approved).
- No end-user application surface; this is a library for developers.

## Becoming a co-maintainer

Sustained, reviewed contributions over at least two milestones (parser,
resolver, or locale work), agreement to the SPARK Silver bar (every merged
change keeps `gnatprove --mode=silver` clean), and a public note of
acceptance from the current maintainer. The file is updated when scope or
ownership changes.
