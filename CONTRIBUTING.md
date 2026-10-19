# Contributing

## Workflow

Work lands on feature branches branched from `dev`; merges to `main`
happen only via reviewed pull request. One PR per change; squash on
merge. CI (`pre-commit`, `build`, `prove`, `test`, `sast`) must pass.

## Bars

- SPARK Silver: `gnatprove -P prove_fluent.gpr --mode=silver --level=2
  --checks-as-errors=on --warnings=continue` is clean. No new warnings
  from `alr -n build`.
- Fixtures: `test_m1a` passes for all active fixtures; newly supported
  syntax re-enables its deferred fixtures with reasons removed.
- Docs sync: behavior changes update `SPECIFICATION.md`, `DESIGN.md`,
  `CHANGELOG.md`, `ROADMAP.md`, and `README.md` in the same change.
- Public API changes require a `SPECIFICATION.md` delta plus a
  `CHANGELOG.md` entry.

## AI use disclosure

Contributions produced with AI assistance name the model family in the
commit trailer (`Assisted-by:`). AI-authored code is held to the same
Silver bar; the prover is the verifier, not the author.

## Style

Ada 2022, `Pascal_Case` types, `Camel_Case` subprograms, explicit
contracts on public specs. First name only in shared artifacts.
