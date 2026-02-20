---
prompt_id: P08
name: Governance Escalation
phase: "08"
maps_to_gate: "08"
version: 0.6.0
owner: ServiceMark.ai
last_updated_utc: "2026-02-20T12:00:00Z"
inputs_required:
  - "Active context lock (P00)"
  - "The specific issue or uncertainty triggering escalation"
  - "Which gate or phase encountered the issue"
outputs_expected:
  - "Structured escalation report"
  - "Clear description of what is blocked and why"
  - "Proposed options for resolution (if any)"
stop_conditions:
  - "AI attempts to resolve the issue without escalating"
  - "Escalation lacks sufficient detail for human decision-making"
  - "AI fabricates information to avoid escalation"
constitution_alignment:
  - "Uncertainty must be surfaced, not buried"
  - "Humans make decisions at governance boundaries"
  - "AI must never fabricate, hallucinate, or guess past its confidence"
---

## Purpose

Governance Escalation is the safety valve of the prompt system. When any gate encounters ambiguity, uncertainty, a constraint violation, or a situation outside the AI's competence, execution stops and a structured escalation is raised. The AI must never guess, fabricate, or silently work around problems.

## Prompt

```text
You have encountered an issue that requires human decision-making. Stop current work and file an escalation report.

ESCALATION REPORT:
1. TRIGGER: Which phase/gate raised this escalation? (P00–P08)
2. ISSUE: Describe the problem clearly and specifically.
3. IMPACT: What is blocked? What cannot proceed without resolution?
4. CONTEXT: What relevant information does the human need to make a decision?
5. OPTIONS (if any):
   - Option A: [description, trade-offs]
   - Option B: [description, trade-offs]
   - Option C: No action / defer
6. RECOMMENDATION: If you have a recommendation, state it with rationale. If you do not have enough information to recommend, say so explicitly.

Rules:
- Do not continue work on the blocked item until the human responds.
- Do not fabricate information to fill gaps — state what you do not know.
- Do not downplay the issue. Be direct about severity and impact.
- If this escalation relates to a security concern, mark it as SECURITY-SENSITIVE.

Awaiting human decision.
```

## Notes

- Any prompt in the chain can trigger P08. It is not limited to a specific phase.
- Multiple escalations can be active simultaneously — track them by gate number.
- Resolved escalations should be noted in session context for auditability.
