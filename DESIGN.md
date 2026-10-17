# DESIGN — fluent-translation-in-ada

## Choices

- Strings: VSS `Virtual_String` (`vss_text ^26.2.0`). Core logic stays in
  SPARK-compatible fixed `String` buffers; all VSS conversions are isolated
  in `Fluent.Unicode` (`SPARK_Mode => Off` by design) so Silver covers the
  rest. `vss ^25.0.0` was rejected: it fails to build on GNAT 16.1
  (`vss-strings-cursors-iterators-characters.adb:76:43: actual for aliased
  formal "Position" has wrong accessibility`).
- SPARK Silver everywhere except the Unicode edge adapter. Proof project
  `prove_fluent.gpr` excludes `fluent-unicode.*` because GNATprove 16.1
  crashes generating representations for VSS UCD
  (`Storage_Error` at `vss-implementation-ucd_core.ads:771`); adapter is
  verified by build + review. Revisit when the prover handles VSS 26.
- Reference posture: Pony port
  (`ftl-fluent-runtime-in-pony-rg`) informed lenient entry recovery and
  errors-as-values only; no code ported.
- Runtime shape mirrors `fluent-rs` (`fluent-syntax` / `fluent-bundle` /
  `fluent-resource` + `langneg`/`fallback`) and upstream EBNF.
- `Make_Tag` uses a bounded `1 .. Len` copy loop with a `Text'First`
  precondition so the `Text'First + K - 1` indexing is provably
  overflow-free.
- `Count_Entries` is an M0 entry-candidate heuristic (non-indented,
  non-blank lines); the real EBNF parser lands in M1.

## CI shape (§29)

- `pre-commit`: codespell + secret scan (gitleaks; satisfies the Betterleaks
  gate) + whitespace/yaml hooks.
- GitHub Actions `ci`: `build` (Alire), `prove` (Silver level 2,
  checks-as-errors), `test` (M0 executable). No schedules (shared-runner
  capacity); push + PR only.
- `sast`: OpenGrep job included in CI.
- Skip reasons: Trivy — no container image or deployed service surface;
  Nyx — no release/publish pipeline in M0; Plumbline — no Python/data
  pipeline surface. Revisit when surfaces appear.

## Public API policy

Public API changes require a `SPECIFICATION.md` delta + `CHANGELOG.md`
entry (see CHANGELOG 0.1.0).
