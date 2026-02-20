# ADR-009: GitHub Enforcement

## Status

Accepted

## Date

2026-02-20

## Context

PromptOS v0.8.0 completed the governance loop: prompts are structured, versioned, and lint-validated; sessions are recorded with embedded chain hashes; artifacts are tamper-detectable; policy enforcement blocks non-compliant versions; and drift detection verifies integrity. Every mechanism works. But every mechanism is local.

A developer who clones the repository, makes changes, and pushes directly to `main` bypasses all governance. The lint script is powerful but optional. The pre-commit hook is available but opt-in. The CI check script exists but runs only when someone remembers to invoke it. Session recording, artifact export, and hash verification all depend on the developer choosing to use them.

This is the fundamental gap between local tooling and platform enforcement. Local tools provide capability. Platform enforcement provides guarantee. A governance system that relies on developers voluntarily running scripts is advisory governance. A governance system that blocks non-compliant changes at the platform level is enforceable governance.

GitHub provides three enforcement primitives that close this gap: CI workflows (automated checks), PR templates (structured process), and CODEOWNERS (review requirements). PromptOS v0.9.0 integrates all three.

## Decision

### GitHub Actions CI

We introduce a CI workflow (`.github/workflows/promptos_ci.yml`) that runs on every pull request to `main`, every push to `main`, and on manual dispatch. The workflow executes three steps:

1. **Prompt lint** (`./scripts/lint_prompts.sh`): Validates all prompt files for YAML headers, required keys, secret patterns, and absolute paths.
2. **CI check** (`./scripts/ci_check.sh`): Validates registry structure, registry-to-file correspondence, and optionally validates artifacts if `PROMPTOS_ARTIFACTS_DIR` is set.
3. **Version print** (`./bin/promptos version`): Records the exact PromptOS version in the CI log for auditability.

The CI workflow runs the same scripts that developers run locally. There is no separate CI-only validation logic. This means a developer who sees `[PASS]` locally can be confident CI will also pass. The CI environment adds enforcement, not complexity.

The workflow uses `ubuntu-latest` and installs `jq` as its only dependency. It does not require Node.js, Python, or any language-specific tooling. This reflects PromptOS's design principle: governance infrastructure should be lightweight and portable.

Artifact validation in CI is opt-in via environment variable. By default, CI skips artifact validation with an informational message. This prevents CI failures when no artifacts directory exists in the repository itself — artifacts are typically generated per-session and stored in target repositories, not in the PromptOS repo.

### PR Templates as Audit Traceability

The PR template (`.github/pull_request_template.md`) requires contributors to declare:

- **PromptOS version tag** used during development
- **Prompt IDs** invoked during the session
- **Session artifact path** or link
- **Artifact validation status** (validated + hash verified)
- **ADR status** (added if semantic/structural change)
- **CHANGELOG status** (updated)

The template also includes a governance audit snippet section — a pre-formatted block matching the output of `./bin/promptos dev` that the developer fills in with actual session data.

This serves two purposes. First, it creates a permanent audit trail in the PR itself. Every merged PR records which prompts governed the work, at which version, producing which artifacts. This information is preserved in GitHub's PR history indefinitely, even if session logs are rotated or artifacts directories are cleaned up.

Second, it creates social enforcement. A PR with empty governance fields is visibly incomplete. Reviewers can see at a glance whether governance was followed. The template does not technically block merging — GitHub's template system is advisory — but it makes non-compliance conspicuous rather than invisible.

### CODEOWNERS as Separation of Duties

The CODEOWNERS file (`.github/CODEOWNERS`) assigns `@biggietx` as the required reviewer for all files, with explicit ownership of governed directories: `prompts/`, `policy/`, `scripts/`, `integration/`, `session/`, and `adr/`.

In a solo developer context, CODEOWNERS serves as a future-proofing mechanism. When the team grows, CODEOWNERS ensures that:

- No one can modify prompt definitions without review from the governance owner.
- No one can change the policy file without review.
- No one can alter enforcement scripts without review.
- No one can modify integration contracts without review.

This is separation of duties expressed as platform configuration. The person who writes code (builder) cannot merge changes to governance infrastructure without approval from the governance owner (reviewer). Even in a solo context, CODEOWNERS creates a deliberate pause — the developer must explicitly review their own governance changes through the PR process rather than pushing directly.

For teams, CODEOWNERS enables fine-grained duty separation: prompt authors vs. script maintainers vs. policy owners vs. integration engineers. The current configuration is intentionally simple (one owner for all), but the structure supports granular assignment as the team scales.

### ServiceMark Differentiation

These GitHub integrations transform PromptOS from a local governance toolkit into a platform-enforced governance system. This is a meaningful differentiator for ServiceMark.ai:

**Auditability**: Every PR in every repository that uses PromptOS carries a governance record — version, prompts, artifact, hash. This audit trail is queryable, searchable, and permanent. A client or auditor asking "how is your AI usage governed?" can be pointed to the PR history.

**Enforcement**: CI blocks non-compliant changes automatically. This is not a policy document that people may or may not follow — it is a gate that must pass. "We enforce AI governance in CI" is a stronger statement than "we have AI governance documentation."

**Scalability**: CODEOWNERS, CI, and PR templates work identically for 1 developer or 100. Adding a new team member requires no governance onboarding beyond "open a PR and fill in the template." The system teaches its own process.

**Portability**: The CI workflow runs standard bash scripts with no proprietary dependencies. A client using GitHub, GitLab, or any CI system can adapt the workflow. The governance model is not locked to a platform.

## Consequences

- **Positive**: CI provides automated, non-bypassable governance validation on every PR and push.
- **Positive**: PR templates create permanent, searchable audit trails in GitHub's PR history.
- **Positive**: CODEOWNERS prevents unauthorized changes to governance infrastructure.
- **Positive**: All three mechanisms work with standard GitHub features — no third-party tools or paid plans required (CODEOWNERS enforcement requires GitHub Pro/Team for branch protection rules).
- **Positive**: ServiceMark can demonstrate enforceable AI governance to clients and auditors.
- **Negative**: PR template is advisory unless branch protection rules enforce required checks. Mitigation: configure branch protection to require CI pass and CODEOWNERS review before merge.
- **Negative**: CODEOWNERS requires GitHub Pro/Team for automatic reviewer assignment. Mitigation: the file still documents ownership and review expectations even on free plans.
- **Negative**: CI adds latency to every PR (~30-60 seconds for lint + CI check). Mitigation: the checks are lightweight and the latency is acceptable for governance value.
