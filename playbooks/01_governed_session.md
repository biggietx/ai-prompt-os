# Playbook: Governed Dev Session

**Time:** ~10 minutes setup, then work within gates.
**Prompt OS Version:** v0.2.0

## Pre-Flight

- [ ] Confirm you are on a feature branch (not `main`).
- [ ] Confirm you know which prompt-os version tag you are using (e.g., `v0.2.0`).

## Step-by-Step

### 1. Lock Context (P00)

Open your AI tool and paste the Context Lock prompt:

```
<copy P00 Context Lock prompt from prompts/00_context_lock/P00_context_lock.md>
```

Fill in: PROJECT, DESCRIPTION, STACK, CONSTRAINTS, ROLE, SESSION GOAL.

- [ ] AI confirmed understanding by restating context.

### 2. Declare Scope (P01)

Paste the Scope Declaration prompt:

```
<copy P01 Scope Declaration prompt from prompts/01_scope/P01_scope_declaration.md>
```

Fill in: TASK, ACCEPTANCE CRITERIA, OUT OF SCOPE.

- [ ] AI confirmed scope by restating deliverables and exclusions.

### 3. Design Gate (P03)

Paste the Design Gate prompt:

```
<copy P03 Design Gate prompt from prompts/03_design/P03_design_gate.md>
```

- [ ] AI produced design with components, interfaces, data flow, trade-offs, and risks.
- [ ] You reviewed and approved the design.

### 4. Implement (P05)

Paste the Constrained Builder prompt:

```
<copy P05 Constrained Builder prompt from prompts/05_implementation/P05_constrained_builder.md>
```

- [ ] AI produced implementation code within approved scope and design.
- [ ] You reviewed the implementation output.

### 5. Verify (P06)

Paste the Verify Forensics prompt:

```
<copy P06 Verify Forensics prompt from prompts/06_verification/P06_verify_forensics.md>
```

- [ ] Verification result: APPROVED / APPROVED WITH NOTES / REJECTED.
- [ ] If REJECTED, loop back to P05 and fix issues.

### 6. Adversarial Review (P07)

Paste the Adversarial Review prompt:

```
<copy P07 Adversarial Review prompt from prompts/07_review/P07_adversarial_review.md>
```

- [ ] Findings reviewed and severity assessed.
- [ ] Critical findings addressed before proceeding.

### 7. Escalation (P08 — if needed)

If any gate hits uncertainty, ambiguity, or a constraint violation:

```
<copy P08 Governance Escalation prompt from prompts/08_governance/P08_governance_escalation.md>
```

- [ ] Escalation report filed and human decision recorded.

## PR Checklist

Before opening your pull request:

- [ ] All gate outputs saved or referenced.
- [ ] Lint passes: `./scripts/lint_prompts.sh`
- [ ] Always reference prompt-os version + prompt IDs used in the PR description.
  - Example: "Built using prompt-os v0.2.0, prompts: P00, P01, P03, P05, P06, P07"
- [ ] CHANGELOG updated if prompts were modified.
- [ ] ADR added if structure or meaning changed.

## Quick Reference

| Gate | Prompt | File |
|------|--------|------|
| 00 | Context Lock | `prompts/00_context_lock/P00_context_lock.md` |
| 01 | Scope Declaration | `prompts/01_scope/P01_scope_declaration.md` |
| 03 | Design Gate | `prompts/03_design/P03_design_gate.md` |
| 05 | Constrained Builder | `prompts/05_implementation/P05_constrained_builder.md` |
| 06 | Verify Forensics | `prompts/06_verification/P06_verify_forensics.md` |
| 07 | Adversarial Review | `prompts/07_review/P07_adversarial_review.md` |
| 08 | Governance Escalation | `prompts/08_governance/P08_governance_escalation.md` |
