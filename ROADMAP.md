# ROADMAP — fluent-translation-in-ada

## Done

- **M0 (0.1.0)** — SPARK Silver contracts for all units, VSS boundary,
  repo floor, CI shape, M0 executable tests, hello example.

## In progress

- **M1a** — entry-level parser (`Fluent.Syntax` + `Parse_Resource`):
  message/term/comment/blank/junk lines, identifiers, attributes, source
  spans, brace-depth-aware raw value spans. Fixture driver asserts
  entry-kind + identifier sequences for 21 all-valid fixtures; 18
  pattern-semantic fixtures deferred with reasons, re-enabled in M1b.

## Planned

- **M1b** — pattern parsing (text elements, placeables, expressions,
  select/variant structure) with full structural AST-vs-JSON fixture
  comparison; invalid patterns become Junk with entry-level recovery;
  discontinued variant-list syntax explicitly rejected.
- **M2** — resolver: literals, variables, message/term references,
  attributes, `NUMBER`/`DATETIME`, select evaluation, fallback rendering;
  `fluent-bundle` parity; resolver fixture behavior checks.
- **M3** — CLDR plural subset per locale behind `Fluent.Locale.Plural_Of`,
  validated against `Intl.*` goldens; prefix locale fallback
  (`fr-CA → fr → en-US`); resource loading.

## Explicitly not being built

- ICU4C or any host internationalization FFI (pure-Ada requirement).
- `localize` extraction tooling and WebAssembly interface-type bindings (revisit after M3).
- Container image, hosted service, or runtime to probe (Nyx stays
  skipped with reason; Trivy stays skipped with reason).
- SDK or cross-language bindings (unapproved; see `MAINTAINERS.md`).
- End-user application or UI around the library.

This file is updated as part of the change that shifts direction.
