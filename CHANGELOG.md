# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [0.5.0] - 2026-02-20

### Added

- **scripts/validate_prompt_artifact.sh**: Validates `prompt_session.json` artifacts against the session schema using jq. Blocks approval if artifact is missing or invalid.
- **integration/ENFORCEMENT_GATE_SNIPPET.md**: Ready-to-use bash snippet for enforcing PromptOS governance in Orchestrator Gate 06 or CI pipelines.
- **ADR-005**: Documents prompt artifact enforcement rationale and integration with separation of duties.

### Changed

- **scripts/ci_check.sh**: Added Step 4 — optional prompt artifact enforcement via `PROMPTOS_ARTIFACTS_DIR` environment variable.
- All prompt files updated to version 0.5.0 with current timestamps.

## [0.4.0] - 2026-02-20

### Added

- **bin/promptos**: One-command CLI wrapper with subcommands: `version`, `lint`, `ci`, `hooks install`, and `dev` (governed session workflow).
- **session/export_session_artifact.sh**: Exports session JSON into an orchestrator artifacts directory for governed run integration.
- **integration/AI_ORCHESTRATOR_INTEGRATION.md**: Integration contract documenting how PromptOS feeds the AI Orchestrator Constitution pipeline.
- **ADR-004**: Documents PromptOS-to-Orchestrator integration, one-command wrapper rationale, and audit trail design.

### Changed

- All prompt files updated to version 0.4.0 with current timestamps.
- **README.md**: Added Orchestrator Integration section.

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
