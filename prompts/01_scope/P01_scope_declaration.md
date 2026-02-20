---
prompt_id: P01
name: Scope Declaration
phase: "01"
maps_to_gate: "01"
version: 0.9.0
owner: ServiceMark.ai
last_updated_utc: "2026-02-21T06:00:00Z"
inputs_required:
  - "Active context lock (P00)"
  - "Feature or task to be scoped"
  - "Acceptance criteria (definition of done)"
  - "Out-of-scope items (explicit exclusions)"
outputs_expected:
  - "Scoped task definition with boundaries"
  - "List of deliverables and acceptance criteria"
  - "Explicit out-of-scope declaration"
stop_conditions:
  - "Scope cannot be stated in under 200 words"
  - "Acceptance criteria are vague or unmeasurable"
  - "AI attempts to expand scope beyond declaration"
constitution_alignment:
  - "Enforces scope discipline — work only on what is declared"
  - "Prevents gold-plating and feature creep"
  - "Forces measurable acceptance criteria"
---

## Purpose

The Scope Declaration constrains the AI to a specific unit of work. It defines what will be done, what "done" looks like, and — critically — what is explicitly excluded. This prevents the AI from expanding scope, adding unrequested features, or drifting into tangential work.

## Prompt

```text
Given the active context lock, declare the scope for the following task.

TASK: [describe the task or feature]
ACCEPTANCE CRITERIA:
  - [criterion 1 — must be measurable/verifiable]
  - [criterion 2]
  - [criterion 3]
OUT OF SCOPE:
  - [explicit exclusion 1]
  - [explicit exclusion 2]

Rules:
- Do not add features, refactoring, or improvements beyond what is listed above.
- If you believe the scope is missing something critical, flag it — do not silently add it.
- If the task cannot be completed within the declared scope, stop and escalate.

Confirm the scope by restating:
1. What you will deliver.
2. What you will not touch.
3. How completion will be verified.
```

## Notes

- Scope should be small enough to complete in a single session.
- If the AI restates scope and adds items not listed, reject and re-prompt.
- Pair with P03 (Design Gate) before any implementation begins.
