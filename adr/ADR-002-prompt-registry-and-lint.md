# ADR-002: Prompt Registry and Lint Enforcement

## Status

Accepted

## Date

2026-02-19

## Context

With the v0.1.0 scaffold in place, the Prompt OS has a clear gate structure and governed prompts. However, two gaps remain that limit the system's usefulness for teams and its ability to prevent drift over time:

1. **Machine readability**: The prompt set is human-readable (Markdown files with YAML frontmatter), but there is no machine-readable index. Tooling that needs to enumerate prompts, validate coverage, or generate documentation must parse individual files and walk directories. This is fragile and couples tools to directory structure.

2. **Drift prevention**: Nothing enforces that prompt files maintain their required structure. A contributor could remove stop conditions, omit the YAML header, or accidentally introduce secrets or absolute paths. Without automated checks, these issues would only surface during manual review — if at all.

## Decision

### Prompt Registry (`prompts.index.json`)

We introduce a single JSON file at the repository root that serves as the authoritative index of all prompts. Each entry includes the prompt's ID, name, version, phase, gate mapping, file path, owner, and last-updated timestamp.

The registry exists for three reasons:

**Repeatability**: Any tool or script can read `prompts.index.json` to discover which prompts exist, their ordering, and their locations. This decouples tooling from directory-walking and makes the prompt set queryable without parsing Markdown.

**Versioning clarity**: The registry carries its own `prompt_os_version` field. When a team member pins a PR to "prompt-os v0.2.0," the registry provides a snapshot of exactly which prompts and versions were in play.

**Integration readiness**: Future automation — CI checks, prompt loaders, session scaffolders — can consume the registry as a stable contract. The schema version field (`schema_version`) allows the registry format to evolve without breaking existing consumers.

The registry is maintained manually alongside prompt files. This is intentional: automated generation would add tooling complexity that is not justified at this scale. If the prompt set grows significantly, generation can be introduced later without changing the registry format.

### Lint Script (`scripts/lint_prompts.sh`)

We introduce a lightweight Bash script that validates every prompt file under `prompts/`. It checks four categories:

**YAML header presence**: Every prompt file must begin and end its frontmatter with `---` delimiters. This ensures the metadata block is parseable and present.

**Required keys**: The YAML header must contain: `prompt_id`, `name`, `phase`, `maps_to_gate`, `version`, `owner`, `last_updated_utc`, `stop_conditions`, and `constitution_alignment`. These keys are the minimum metadata required for governance. Missing keys indicate an incomplete or malformed prompt.

**Secret detection**: The script scans for common secret patterns (`sk-`, `gho_`, `apikey`, `api_key`, `password=`, `token=`). Prompts must never contain credentials. This check is deliberately simple — it is a tripwire, not a comprehensive secret scanner. Teams with stricter requirements should layer additional tools (e.g., `gitleaks`, `trufflehog`) on top.

**Absolute path detection**: The script flags patterns like `/Users/` or `C:\Users\` that indicate environment-specific paths. Prompts must be portable across machines and operating systems.

The lint script exits with code 1 on any failure, making it suitable for use in pre-commit hooks or CI pipelines. It prints `[FAIL]` for each violation and a `[PASS]` summary when all checks succeed.

### What Constitutes a "Semantic Change" Requiring an ADR

A semantic change is any modification that alters the meaning, structure, or governance behavior of the prompt system. Specifically:

- Adding, removing, or renumbering gates.
- Changing required YAML keys or their semantics.
- Altering the prompt registry schema.
- Modifying escalation rules or stop-condition philosophy.
- Changing the versioning policy.

Wording clarifications, typo fixes, and minor phrasing improvements do not require an ADR. When in doubt, write the ADR — the cost of a short document is lower than the cost of an unrecorded decision.

## Consequences

- **Positive**: Machine-readable registry enables tooling without coupling to directory structure.
- **Positive**: Lint script catches common errors early, before they reach review.
- **Positive**: Secret and path detection prevents accidental credential or environment leakage.
- **Positive**: Clear definition of "semantic change" reduces ambiguity about when ADRs are needed.
- **Negative**: Registry must be manually kept in sync with prompt files. Mitigation: lint could be extended to cross-check registry against files in a future version.
- **Negative**: Lint script uses basic pattern matching, not a full YAML parser. Mitigation: sufficient for current scale; can be upgraded if false positives/negatives become a problem.
