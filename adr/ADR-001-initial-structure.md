# ADR-001: Initial Repository Structure

## Status

Accepted

## Date

2026-02-19

## Context

ServiceMark.ai treats AI prompts as governed artifacts — versioned, reviewed, and structured like production code. As AI-assisted development becomes central to our workflow, ungoverned prompting creates risks: scope drift, hallucination, unreviewable outputs, and loss of institutional knowledge.

We need a repository structure that enforces discipline without adding unnecessary process overhead. The structure must work across AI vendors (Claude, GPT, Gemini) and scale from solo use to team adoption.

## Decision

### Gate-Mirrored Directory Structure

Each prompt maps to a numbered gate in a linear workflow: context lock, scope, design, implementation, verification, review, and governance escalation. The directory structure mirrors these gates (`00_context_lock/`, `01_scope/`, etc.) so that the execution order is self-documenting. A developer can read the folder names and understand the workflow without external documentation.

We skip gate numbers (02, 04) intentionally. This reserves space for future gates (e.g., threat modeling at 02, test planning at 04) without renumbering existing prompts and breaking references.

### Separation of Duties

The prompt chain enforces role separation between phases. The builder (P05) writes code. The verifier (P06) audits it against the design. The adversarial reviewer (P07) tries to break it. This mirrors established software engineering practices — the person who writes code should not be the sole reviewer.

When using a single AI session, the prompts force an explicit role switch. When possible, verification and review should run in separate sessions or with separate models to strengthen independence.

### Stop Conditions and Escalation

Every prompt includes explicit stop conditions — situations where the AI must halt and either re-prompt or escalate. This is a direct response to the observed failure mode where AI models silently work around problems, fabricate information, or expand scope rather than admitting uncertainty.

The governance escalation prompt (P08) serves as the system's safety valve. Any gate can invoke it. The escalation format is structured to give humans the information they need to make decisions quickly, without requiring them to reconstruct context from scattered outputs.

### Vendor Neutrality

Prompts are written as plain text instructions, not in any vendor-specific format (no OpenAI function schemas, no Claude XML blocks, no Gemini tool declarations). This ensures the prompt set works across models and survives vendor changes. Platform-specific adaptations, if needed, belong in a separate integration layer — not in the core prompts.

### Versioning and Change Governance

The repository uses Semantic Versioning. Prompts are treated as governed artifacts: changes to structure or meaning require an ADR, all changes require a changelog entry, and modifications come through pull requests. This is intentionally lightweight — no CI/CD, no automated validation — but provides enough structure for auditability and institutional memory.

## Consequences

- **Positive**: Clear execution order, separation of duties, vendor portability, auditability through ADRs and changelog.
- **Positive**: Reserved gate numbers allow non-breaking evolution.
- **Positive**: Stop conditions reduce silent failure modes common in AI-assisted work.
- **Negative**: Linear gate structure may feel heavyweight for trivial tasks. Mitigation: users can skip gates for low-risk work, but must document the skip.
- **Negative**: Vendor neutrality means prompts may not leverage vendor-specific features optimally. Mitigation: platform adapters can be added later without changing core prompts.
- **Negative**: Separation of duties in a single AI session is advisory, not enforced. Mitigation: recommend separate sessions for verification when stakes are high.
