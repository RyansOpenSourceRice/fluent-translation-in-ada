# marketing.md — audience context for AI agents

## Who this library is for

Ada developers who ship software in another language's locale files and
need Project Fluent semantics without leaving Ada: no C dependencies,
no garbage collector, no exceptions for control flow.

## Skill level assumed

Comfortable reading Ada package specs; no SPARK background required to
USE the library (contracts document preconditions in plain terms).
Contributors are expected to keep the Silver bar green; the prover
messages are the guide, not prior SPARK experience.

## What that implies for the work

- Public specs carry `Pre`/`Post` contracts written as user-facing
  documentation, not just proof artifacts.
- Errors are values (`Fluent.Errors`), never raised exceptions: host
  applications in safety-relevant contexts cannot tolerate exception
  propagation from a localization library.
- Examples are single-file programs a developer reads in under five
  minutes; the README shows install, the smallest useful example, then
  the API surface.
- No marketing register anywhere user-facing: state what changed and
  what it does, plainly.
