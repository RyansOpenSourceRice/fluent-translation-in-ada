# SECURITY.md

## Reporting a vulnerability

Open a GitHub issue titled `[security]` with a minimal reproducer, or
contact the maintainer through the profile email on
`https://github.com/RyansOpenSourceRice`. Do not open a public issue with
exploit details for an unpatched defect; describe impact and reproducer
privately first.

## Fix SLA

Target: fix within 1 month of report. Hard ceiling: 100 days. Exceeding
the ceiling is treated as a breach of this policy. Security fixes ship as
patch releases with a `CHANGELOG.md` `Security` entry.

## Scope

This is a parsing and formatting library. The relevant threat surface is
malformed or adversarial `.ftl` input: the parser must never raise,
never hang, and never write outside caller-provided buffers. Fuzzing
harnesses and fixture corpora are the primary verification tools;
OpenGrep runs in CI; Nyx is skipped with reason in `DESIGN.md` (no
runtime to probe).

## AI use and model disclosure

Development is assisted by AI coding agents. Substantive AI-authored
changes are noted in commit trailers (`Assisted-by:` with model name).
Model families used in this project: GLM (Z.ai) via the operator coding
plan, Muse Spark (Meta). AI-generated code is held to the same
SPARK Silver bar as hand-written code: `gnatprove --mode=silver
--level=2 --checks-as-errors=on` must pass before merge.
