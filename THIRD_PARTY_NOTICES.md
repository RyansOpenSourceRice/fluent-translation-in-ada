# Third-party notices

This project bundles no third-party source code. It builds against the
following open-source components, whose licenses require attribution:

## Runtime dependencies (Alire packages)

- **VSS (vss_text 26.2.0)** — AdaCore / contributors.
  Apache License 2.0 with LLVM Exceptions.
  Source: `https://github.com/AdaCore/VSS`.
- **GNAT toolchain and runtime (gnat_native 16.1.0)** — AdaCore / GCC.
  GPLv3 with the GCC Runtime Library Exception (user code linked
  against the runtime is not subject to GPL terms).

## Test data

- **Project Fluent test fixtures** (`tests/fixtures/*.ftl`, generated
  expectations derived from `test/fixtures/*.json`) — Mozilla / Project
  Fluent contributors. Apache License 2.0.
  Source: `https://github.com/projectfluent/fluent`.

## CI / developer tooling (not shipped)

Betterleaks (MIT), Codespell (GPLv2), OpenGrep (LGPLv2.1), Renovate
(AGPLv3), pre-commit hooks (MIT). These run in CI or locally and are
not part of the library artifact.
