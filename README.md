# fluent-translation-in-ada

Project Fluent (FTL) translation library in Ada — pure Ada, SPARK Silver.

- Syntax: FTL entry-level AST + lenient recovery scaffold (`Fluent.Syntax`)
- Bundle: single-locale message table + select-default contract (`Fluent.Bundle`)
- Resource: multi-bundle fallback chain (`Fluent.Resource`)
- Locale: BCP-47 tag + plural interface, English-only fallback in M0 (`Fluent.Locale`)
- Unicode: VSS `Virtual_String` boundary, SPARK_Mode Off by design (`Fluent.Unicode`)
- Errors as values, never raised (`Fluent.Errors`)

## Toolchain

- `alr 2.1.1`, `gnat_native 16.1.0`, `gprbuild 26.0.1`, `gnatprove 16.1.0`
- Dependency: `vss_text ^26.2.0` (note: `vss ^25.0.0` does not build on GNAT 16 — accessibility error in `vss-strings-cursors-iterators-characters.adb`)

## Build / Prove / Test

```sh
alr -n build
gnatprove -P prove_fluent.gpr --mode=silver --level=2 --checks-as-errors=on --warnings=continue
gprbuild -P tests/tests.gpr && ./bin/test_m0
```

`prove_fluent.gpr` excludes the VSS adapter (`Fluent.Unicode`, SPARK_Mode Off).
GNATprove 16.1 crashes analyzing VSS UCD tables (`Storage_Error` in
`vss-implementation-ucd_core.ads`), so Silver covers every unit except that
explicitly documented edge adapter.

## Milestones

- M0 (this): contracts + provable skeletons, repo floor, CI green
- M1: EBNF recursive-descent parser vs upstream `test/fixtures`
- M2: resolver (references, variables, select, fallback rendering)
- M3: CLDR plural subset validated against Node `Intl.*` goldens

License: Apache-2.0. See `SPECIFICATION.md`, `DESIGN.md`, `CHANGELOG.md`.
