# Contributing to PromptOS

## Core Principle

**Prompts are governed artifacts.** They are versioned, reviewed, and changed through the same discipline applied to production code.

## Rules

1. **All changes via pull request.** No direct commits to `main`.
2. **ADR required** for any semantic or structural change (adding/removing gates, changing metadata keys, altering escalation rules, modifying versioning policy).
3. **CHANGELOG required** for every change, no exceptions.
4. **CI must be green.** PRs with failing lint or CI checks will not be merged.
5. **CODEOWNERS enforced.** All changes to governed directories require review.

## Governed Development Workflow

1. Run a governed session using the CLI wrapper:

   ```bash
   ./bin/promptos dev \
     --prompts "P00,P01,P03,P05,P06,P07" \
     --developer "your-name" \
     --target-repo "your-repo" \
     --notes "description of work"
   ```

2. Export the session artifact:

   ```bash
   ./session/export_session_artifact.sh \
     --artifacts-dir "./artifacts/evidence/"
   ```

3. Validate the artifact:

   ```bash
   ./scripts/validate_prompt_artifact.sh \
     --artifacts-dir "./artifacts/evidence/"
   ```

4. Include the governance audit snippet in your PR description.

## What Requires an ADR

- Adding, removing, or renumbering gates
- Changing required YAML metadata keys
- Altering the prompt registry schema
- Modifying escalation rules or stop-condition philosophy
- Changing the versioning policy
- Adding new enforcement mechanisms

When in doubt, write the ADR. The cost of a short document is lower than the cost of an unrecorded decision.

## What Does Not Require an ADR

- Wording clarifications and typo fixes
- Minor phrasing improvements
- Version bumps
- Adding session logs or daily logs
