---
prompt_id: P00
name: Context Lock
phase: "00"
maps_to_gate: "00"
version: 0.5.0
owner: ServiceMark.ai
last_updated_utc: "2026-02-20T06:00:00Z"
inputs_required:
  - "Project name and one-line description"
  - "Technology stack and constraints"
  - "Session goals (what success looks like)"
  - "Role the AI should adopt"
outputs_expected:
  - "Locked context block the AI will reference throughout the session"
  - "Confirmation that the AI understands scope and constraints"
stop_conditions:
  - "AI cannot confirm understanding of the context"
  - "Ambiguity in project scope remains after one clarification round"
  - "Context exceeds what can be reliably held in a single session"
constitution_alignment:
  - "Establishes determinism by fixing the operating context"
  - "Prevents scope drift by declaring boundaries up front"
  - "No secrets or credentials may appear in the context block"
---

## Purpose

The Context Lock is the foundational prompt. It sets the immutable operating context for an AI session — project identity, stack, constraints, and success criteria. Every subsequent prompt assumes this context is active. Without it, prompts operate without guardrails.

## Prompt

```text
You are operating in governed-prompt mode for the project described below.
Lock this context and reference it for every response in this session.

PROJECT: [project name]
DESCRIPTION: [one-line description]
STACK: [languages, frameworks, services]
CONSTRAINTS:
  - [list hard constraints: no secrets in output, no absolute paths, vendor-neutral, etc.]
ROLE: [e.g., "Senior backend engineer performing code review"]
SESSION GOAL: [what we are trying to accomplish]

Confirm you understand by restating:
1. The project and its purpose.
2. The constraints you will follow.
3. The session goal in your own words.

Do not proceed until confirmation is complete.
```

## Notes

- Run this prompt first in every session. All other prompts depend on it.
- If the AI cannot restate constraints accurately, do not continue — restart with a clearer context block.
- Keep the context block concise; overly long contexts degrade reliability.
