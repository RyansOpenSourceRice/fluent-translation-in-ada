# Changelog

## Unreleased (M1a — entry-level parser)

- Added `Fluent.Syntax.Parse_Resource`: recursive-descent entry parser
  (messages, terms, attributes, `#`/`##`/`###` comments, Junk recovery)
  with source spans and brace-depth-aware raw value spans.
- Changed `Fluent.Syntax.Entry_Node`: pattern text replaced by `Text_Span`
  source indices; attributes, attached comments, and `Group_Comment` /
  `Resource_Comment` kinds added (public API change per design notes).
- Added `tests/test_m1a.adb` fixture driver: 21 all-valid upstream
  fixtures asserted (entry-kind + identifier sequences); 18
  pattern-semantic fixtures deferred with reasons to M1b.
- Added `examples/parse` and `examples/fallback` (three-example floor).
- Fixed CI: verified action tags, `pre-commit` gate job, Alire env in
  `prove`/`test` jobs (M0 CI never passed).
- Changed pre-commit secret scan from Gitleaks to Betterleaks per §8.
- Added required repo files: `MAINTAINERS.md`, `ROADMAP.md`, `SECURITY.md`,
  `AGENTS.md`, `THIRD_PARTY_NOTICES.md`, `CONTRIBUTING.md`,
  `CODE_OF_CONDUCT.md`, `marketing.md`; shields.io README rework.

## 0.1.0 — 2026-10-17 (M0 bootstrap)

- SPARK Silver contracts for `Fluent(.Errors/.Syntax/.Locale/.Bundle/.Resource/.Unicode)`; 37 checks proved, zero build warnings.
- VSS boundary (`vss_text ^26.2.0`); pure-Ada core, no ICU4C.
- Repo floor: README, SPECIFICATION, DESIGN, pre-commit, CI (build/prove/test/sast), Renovate, M0 tests, hello example.
