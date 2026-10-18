# AGENTS.md — fluent-translation-in-ada

Per-project AI-guidance: the validated subset of Ryan's preferences that
applies to this repo, plus how agents behave here. Design and contracts
live in `DESIGN.md` and `SPECIFICATION.md`; this file is behavior.

## Stack and bars

- Ada 2022, SPARK Silver (`SPARK_Mode => On`, GNATprove Silver level 2,
  checks-as-errors). `Fluent.Unicode` is `SPARK_Mode => Off` by design
  (VSS boundary); do not "fix" that.
- Alire + GPRbuild. Toolchain paths come from `alr printenv`; never
  hard-code them.
- Zero build warnings. `test_m0` and `test_m1a` green. Docs sync in the
  same change (SPEC, DESIGN, CHANGELOG, ROADMAP, README).

## Workflow

- Branch from `dev`; PR into `dev`; merge to `main` only via reviewed PR.
  After code work, push the branch (GitHub MCP; CLI git has no
  credentials here) and create or update the PR, then verify CI.
- Verify by execution: build, prove, run tests. Do not claim green
  without running.
- Fixture driver: `tests/generate_expectations.py` regenerates
  `fixture_expectations.*` from upstream JSON; deferred fixtures carry
  reasons and return in M1b.

## Boundaries

- Pure Ada: no ICU4C, no host FFI, no new crates without a `DESIGN.md`
  entry. No containers (Podman-only rule applies if that ever changes).
- No SDK, bindings, or network code without explicit operator approval.
- Destructive operations (repo deletion, history rewrites on shared
  branches) are operator-only; ask first.
- Secrets: subscription credentials power the coding tool only and never
  enter project files, configs, or CI. No real credentials in tests.

## Voice

- Neutral, factual register in committed text. No personhood claims.
  First name only. Name the model family in `Assisted-by:` trailers.

## References

- Upstream EBNF/fixtures: shallow-clone `projectfluent/fluent` next to
  this repo when needed (a local `../upstream-fluent` copy is used in
  this environment; it is not a submodule). Clone, don't hammer the
  forge API.
- Preferences: local clone under `Documents/Default Project/ontologies/`.
