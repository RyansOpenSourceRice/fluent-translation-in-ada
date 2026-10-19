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
  non-blank lines); `Parse_Resource` (M1a) is the real entry parser.
- Patterns are stored as source spans, not copied text: entry nodes stay
  small on the stack and M1b parses pattern contents from the spans.
  Removing the copied `Value : Pattern_Text` is a public API change
  recorded here and in `CHANGELOG.md`.
- Entry-boundary rules that go beyond the EBNF text but match reference
  behavior (verified against upstream fixtures): a `{` line at column 0
  continues/starts a value (multi-line placeables); while brace depth is
  open, every line continues except a column-0 `#` comment; string
  literals with `\` escapes do not affect depth and never span lines.
  Lines starting with `[` or `*` at depth 0 never continue a value
  (variants belong to selects, parsed in M1b). Invalid patterns still
  produce entry-boundary mismatches versus the JSON fixtures; those
  fixtures are deferred to M1b, where validation makes boundaries exact.
- Single-`#` comment attachment happens only when the following
  message/term parses successfully; otherwise the group stays standalone
  and the entry attempt becomes Junk (matches fixtures).
- Root-directory budget: the tracked root holds 11 files (required
  planning docs, descriptors, configs) against the 8-file soft budget.
  The overflow is structural — §29 mandates the files — so the reason is
  recorded here rather than worked around.

## CI shape (§29)

- `pre-commit`: codespell + secret scan (Betterleaks `AikidoSec/betterleaks
  @ v1.1.1`, replacing Gitleaks per §8) + whitespace/yaml hooks. The gate
  runs in CI on every push; it cannot run in this dev environment
  (sandboxed git cannot fetch hook repos), so CI is the enforcement point.
- GitHub Actions `ci`: `pre-commit` gate, `build` (Alire), `prove`
  (Silver level 2, checks-as-errors), `test` (M0 + M1a executables),
  `sast` (OpenGrep via `platform-sec/opengrep-action`). No schedules
  (shared-runner capacity); push + PR only. M0 CI never passed
  (wrong `setup-alire` tag, wrong OpenGrep action, missing Alire env in
  `test`/`prove` jobs); fixed in M1a with verified action tags. M1a
  post-merge: exact toolchain pins in `alire.toml` (`gnat_native`,
  `gprbuild`, `gnatprove`, `vss_text`) after the solver preferred
  system gprbuild 2024.1 over the selected 26.0.1, leaving runners
  without an Ada compiler; `Verify pinned toolchain` fail-fast step in
  `build`/`prove`/`test`; duplicate push+PR runs cancelled via
  `concurrency.cancel-in-progress`.
- Skip reasons: Trivy — no container image or deployed service surface;
  Nyx — no runtime to probe (an FTL parser handles untrusted input but
  there is no running service; OpenGrep + Silver + fixtures are the
  verification surface; revisit if a service appears); Plumbline — no
  LLM/agent code; reliability job not applicable. Revisit when surfaces
  appear.

## Public API policy

Public API changes require a `SPECIFICATION.md` delta + `CHANGELOG.md`
entry (see CHANGELOG 0.1.0).
