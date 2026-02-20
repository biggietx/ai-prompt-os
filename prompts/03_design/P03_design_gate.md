---
prompt_id: P03
name: Design Gate
phase: "03"
maps_to_gate: "03"
version: 0.5.0
owner: ServiceMark.ai
last_updated_utc: "2026-02-20T06:00:00Z"
inputs_required:
  - "Active context lock (P00)"
  - "Approved scope declaration (P01)"
  - "Known technical constraints or dependencies"
outputs_expected:
  - "Design proposal with component breakdown"
  - "Interface contracts or data flow description"
  - "Risk flags and open questions"
stop_conditions:
  - "Design introduces components outside declared scope"
  - "No clear interface boundaries between components"
  - "AI cannot articulate trade-offs of the proposed design"
constitution_alignment:
  - "Separation of design from implementation prevents premature coding"
  - "Forces explicit trade-off analysis before commitment"
  - "Ensures design is reviewable before resources are spent"
---

## Purpose

The Design Gate forces a pause between scoping and implementation. The AI must propose a design — components, interfaces, data flow, and trade-offs — before writing any code. This prevents the common failure mode of jumping straight to implementation without architectural consideration.

## Prompt

```text
Based on the active context lock and approved scope, propose a design for the declared task.

Your design must include:
1. COMPONENTS: List each component or module involved and its responsibility.
2. INTERFACES: Describe how components communicate (APIs, function signatures, data contracts).
3. DATA FLOW: Describe how data moves through the system for the primary use case.
4. TRADE-OFFS: List at least two alternatives you considered and why you chose this approach.
5. RISKS: Flag anything uncertain, fragile, or dependent on external factors.

Rules:
- Do not write implementation code. Design only.
- Stay within the declared scope — no speculative components.
- If you cannot design without more information, list your questions and stop.
- If the design requires changes to scope, escalate — do not silently expand.

Present the design for review. Do not proceed to implementation until the design is approved.
```

## Notes

- The human must explicitly approve the design before moving to P05.
- If the AI produces code during this phase, reject the output and re-prompt.
- Complex tasks may require multiple design iterations — that is expected and healthy.
