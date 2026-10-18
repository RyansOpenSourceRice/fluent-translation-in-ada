# fluent-translation-in-ada

[![License](https://img.shields.io/badge/license-Apache--2.0-blue?style=flat-square)](LICENSE)
[![SPARK](https://img.shields.io/badge/SPARK-Silver-blueviolet?style=flat-square)](prove_fluent.gpr)
[![Ada](https://img.shields.io/badge/Ada-2022-green?style=flat-square)](fluent_translation_in_ada.gpr)
[![CI](https://img.shields.io/badge/CI-build%20%7C%20prove%20%7C%20test%20%7C%20sast-orange?style=flat-square)](.github/workflows/ci.yml)

Project Fluent (FTL) translation library in Ada — pure Ada, SPARK Silver,
no host internationalization libraries.

## Install

Requires Alire with GNAT 16. Add the dependency to `alire.toml`:

```toml
[[depends-on]]
fluent_translation_in_ada = "^0.1.0"
```

Then build with `alr -n build`. The only runtime crate dependency is
`vss_text` (Unicode strings at the boundary; see `Fluent.Unicode`).

## Smallest useful example

```ada
with Ada.Text_IO;
with Fluent.Syntax;

procedure Parse is
   Source  : constant String := "hello = Hello, world!" & ASCII.LF;
   Entries : Fluent.Syntax.Entry_Array (1 .. 16);
   Count   : Natural;
   Junks   : Natural;
begin
   Fluent.Syntax.Parse_Resource (Source, Entries, Count, Junks);
   Ada.Text_IO.Put_Line ("entries:" & Count'Image);  -- entries: 1
end Parse;
```

Malformed input never raises: it becomes `Junk` entries and parsing
resumes at the next entry. See `examples/` for runnable programs
(`hello`, `parse`, `fallback`).

## API surface

- `Fluent.Syntax` — entry AST (`Message`, `Term`, `Comment`,
  `Group_Comment`, `Resource_Comment`, `Junk`), identifiers, attributes,
  source spans, and `Parse_Resource`. Patterns are stored as source
  spans; placeable parsing arrives in M1b.
- `Fluent.Bundle` — single-locale message table plus the select-default
  contract (`Resolve_Select`).
- `Fluent.Resource` — multi-bundle fallback chain (`Best_Match`).
- `Fluent.Locale` — BCP-47 tags and plural categories (English-only
  fallback in M0; CLDR tables in M3).
- `Fluent.Unicode` — VSS `Virtual_String` conversions
  (`SPARK_Mode => Off` by design; everything else is Silver).
- `Fluent.Errors` — error kinds as values, never raised.

## Reference

- `SPECIFICATION.md` — behavior contracts, public API, milestones.
- `DESIGN.md` — design decisions, trade-offs, CI skip reasons.
- `ROADMAP.md` — what is planned and what is explicitly not built.
- `MAINTAINERS.md`, `SECURITY.md`, `CONTRIBUTING.md` — ownership,
  disclosure policy, workflow.
- `THIRD_PARTY_NOTICES.md` — open-source license attributions
  (VSS, GNAT runtime, upstream test fixtures).

## Build, prove, test

```sh
alr -n build
gnatprove -P prove_fluent.gpr --mode=silver --level=2 --checks-as-errors=on --warnings=continue
gprbuild -P tests/tests.gpr && ./bin/test_m0 && ./bin/test_m1a
```

License: Apache-2.0.
