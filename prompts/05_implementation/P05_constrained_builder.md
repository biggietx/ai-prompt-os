---
prompt_id: P05
name: Constrained Builder
phase: "05"
maps_to_gate: "05"
version: 1.0.0
owner: ServiceMark.ai
last_updated_utc: "2026-02-25T00:00:00Z"
inputs_required:
  - "Active context lock (P00)"
  - "Approved scope declaration (P01)"
  - "Approved design (P03)"
outputs_expected:
  - "Implementation code matching the approved design"
  - "No files or components outside declared scope"
  - "Inline comments only where logic is non-obvious"
stop_conditions:
  - "Implementation deviates from approved design"
  - "AI introduces files, dependencies, or features not in scope"
  - "AI cannot implement within constraints — must escalate"
constitution_alignment:
  - "Code must match design — no ad-hoc architecture"
  - "No secrets, credentials, or absolute paths in output"
  - "Vendor-neutral patterns preferred over platform lock-in"
  - "Minimal code — no gold-plating or speculative features"
---

## Purpose

The Constrained Builder translates an approved design into implementation code. The AI operates strictly within the boundaries of the approved scope and design — no creative additions, no speculative features, no deviation. If something doesn't fit, the AI stops and escalates rather than improvising.

## Prompt

```text
Implement the approved design within the declared scope. Follow these rules strictly:

IMPLEMENTATION RULES:
1. Write only what the design specifies. No additional files, helpers, or utilities unless they are in the design.
2. No secrets, credentials, API keys, or absolute paths in any output.
3. No unnecessary abstractions. Write clear, direct code.
4. Add comments only where the logic is non-obvious. Do not add boilerplate comments.
5. Use vendor-neutral patterns. Avoid platform-specific lock-in where the design permits.
6. If you encounter ambiguity in the design, stop and ask — do not guess.
7. If implementation reveals a design flaw, stop and escalate to a design revision — do not patch around it.

OUTPUT FORMAT:
- Present each file with its path and contents.
- After all files, provide a brief summary of what was implemented and any assumptions made.

Do not proceed to verification until implementation is reviewed and approved.
```

## Notes

- The human must review implementation output before moving to P06 (Verification).
- If the AI produces test files not requested in scope, flag it — tests should be explicitly scoped.
- Implementation should be directly copy-paste-able into the project.
