# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [0.3.0] - 2026-02-19

### Added

- **session/record_session.sh**: CLI session recorder with argument parsing, auto-version detection, and lint-gated JSON output.
- **session/schema_prompt_session.json**: JSON schema for session log artifacts.
- **.git-hooks/pre-commit**: Pre-commit hook that runs prompt lint before allowing commits.
- **scripts/install_hooks.sh**: Installer script for git hooks (manual opt-in, not auto-installed).
- **scripts/ci_check.sh**: CI-ready validation script — runs lint, validates registry structure, confirms all registered prompt files exist.
- **ADR-003**: Documents session recording and enforcement decisions.

### Changed

- All prompt files updated to version 0.3.0 with current timestamps.

## [0.2.0] - 2026-02-19

### Added

- **prompts.index.json**: Machine-readable prompt registry at repo root.
- **scripts/lint_prompts.sh**: Lint script validating YAML headers, required keys, secret patterns, and absolute paths.
- **playbooks/01_governed_session.md**: 10-minute governed dev session checklist with PR requirements.
- **ADR-002**: Documents prompt registry and lint enforcement decisions.

### Changed

- All prompt files updated to version 0.2.0 with current timestamps.
- **README.md**: Added Repo Contract, Automation, and Version Pinning sections.

## [0.1.0] - 2026-02-19

### Added

- **P00 — Context Lock**: Foundational prompt to fix project context and constraints for a session.
- **P01 — Scope Declaration**: Defines task boundaries, acceptance criteria, and explicit exclusions.
- **P03 — Design Gate**: Forces design review before implementation begins.
- **P05 — Constrained Builder**: Governs implementation within approved scope and design.
- **P06 — Verify Forensics**: Independent verification of implementation against scope and design.
- **P07 — Adversarial Review**: Hostile analysis to surface attack vectors, failure modes, and assumptions.
- **P08 — Governance Escalation**: Safety valve for uncertainty, ambiguity, and constraint violations.
- **ADR-001**: Documents initial repository structure decisions.
- **README.md**: Repository overview, usage guide, and contribution rules.
- **LICENSE**: MIT license.
