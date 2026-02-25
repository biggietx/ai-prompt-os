---
prompt_id: P07
name: Adversarial Review
phase: "07"
maps_to_gate: "07"
version: 1.0.1
owner: ServiceMark.ai
last_updated_utc: "2026-02-25T00:00:00Z"
inputs_required:
  - "Active context lock (P00)"
  - "Approved scope declaration (P01)"
  - "Implementation output (P05)"
  - "Verification results (P06)"
outputs_expected:
  - "List of attack vectors and failure modes identified"
  - "Severity rating for each finding (Critical / High / Medium / Low)"
  - "Recommended mitigations"
stop_conditions:
  - "Critical vulnerability found — implementation must be revised"
  - "AI cannot reason about failure modes for the given domain"
  - "Verification (P06) was not completed before this review"
constitution_alignment:
  - "Adversarial thinking is a separate duty from building and verifying"
  - "Forces consideration of what can go wrong, not just what should work"
  - "Escalation required for critical findings"
---

## Purpose

The Adversarial Review asks the AI to attack its own output. It adopts the mindset of a hostile user, a malicious input, or a production failure scenario. The goal is to surface risks that verification alone cannot catch — edge cases, security gaps, implicit assumptions, and failure cascades.

## Prompt

```text
You are now operating as an adversarial reviewer. Assume the implementation is flawed and try to break it.

Given the implementation output and verification results, perform the following analysis:

ADVERSARIAL REVIEW:
1. ATTACK VECTORS: How could a malicious user exploit this code? Consider injection, privilege escalation, data leakage, and abuse scenarios.
2. FAILURE MODES: What happens when inputs are unexpected, missing, or malformed? What happens under load, timeout, or partial failure?
3. IMPLICIT ASSUMPTIONS: What is the code assuming that is not explicitly validated? List every assumption and assess its fragility.
4. DEPENDENCY RISKS: Are there external dependencies that could fail, change, or be compromised?
5. EDGE CASES: List edge cases not covered by the implementation.

For each finding:
- SEVERITY: Critical / High / Medium / Low
- DESCRIPTION: What the issue is.
- EXPLOIT SCENARIO: How it could be triggered.
- MITIGATION: Recommended fix or safeguard.

If any Critical findings are identified, the implementation must be revised before proceeding. Escalate to the human for decision.

Do not soften findings. Be direct and specific.
```

## Notes

- This prompt works best when run by someone who did not write the implementation.
- Not all findings require immediate fixes — the human decides which mitigations to apply.
- Critical findings block release. High findings should be addressed. Medium/Low are tracked.
