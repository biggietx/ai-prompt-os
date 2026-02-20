# ADR-008: Run Chain Binding

## Status

Accepted

## Date

2026-02-20

## Context

PromptOS v0.7.0 introduced policy-level version enforcement and a verification gate wrapper, closing the governance loop from prompt selection through artifact validation to Orchestrator approval. However, the integrity model has a structural weakness: the relationship between a prompt session artifact and the Orchestrator run that consumed it is implicit, not cryptographic.

In v0.7.0, a session artifact is exported to an artifacts directory and validated by the verification gate. But the validation only confirms that the artifact itself is intact — it does not bind the artifact's identity to the Orchestrator's run record. This creates two exploitable gaps:

**Replay attacks**: A valid session artifact from a previous run can be copied into a new run's artifacts directory. The artifact passes all validation checks — it has correct fields, a valid hash, and matches the policy version. But it does not represent the governance that actually occurred for the current run. It is borrowed legitimacy.

**Drift without detection**: If a prompt session artifact is subtly modified — a field value changed, a prompt ID added — and the sidecar hash is regenerated to match, the sidecar-based integrity check passes. The sidecar hash proves the file matches its hash, but not that the file's content is internally consistent with how it was originally generated.

Both gaps exist because the integrity model treats the artifact as a black box verified from the outside (sidecar hash) rather than an internally self-consistent structure with embedded integrity proofs. Fixing this requires two changes: embedding cryptographic hashes inside the artifact itself, and binding those hashes into the Orchestrator's run record.

## Decision

### Embedded Artifact Hash

The session recording script (`session/record_session.sh`) now produces a two-phase artifact:

1. **Phase 1**: Write the base session JSON containing all governance metadata (timestamp, version, prompts used, developer, target repo, lint status). Compute the SHA-256 hash of this base content. This becomes `artifact_hash`.

2. **Phase 2**: Rewrite the JSON with `artifact_hash` and `chain_hash` appended. Generate the sidecar `.sha256` from the final file.

The `artifact_hash` is the fingerprint of the governance content itself — the fields that describe what happened during the session. Because it is computed from the base content (before hash fields are added), it is stable: the same governance session will always produce the same `artifact_hash` regardless of how the final file is structured.

This design solves the sidecar-only weakness. A sidecar hash proves the file hasn't changed since the hash was generated. The `artifact_hash` proves the governance content hasn't changed since the session was recorded. An attacker who modifies the governance content and regenerates the sidecar hash will still be caught: the embedded `artifact_hash` will not match the recomputed hash of the modified content.

### Chain Hash

The `chain_hash` is computed as:

```
chain_hash = SHA-256(artifact_hash + timestamp_utc)
```

This binds the artifact's identity to its temporal position. Two sessions with identical governance content but different timestamps will produce different chain hashes. This serves two purposes:

**Replay detection**: If an artifact from run A is copied into run B, the chain hash is valid for the original timestamp. But the Orchestrator's run record for run B will have a different timestamp. The temporal mismatch makes the replay detectable during audit, even if the chain hash itself validates correctly within the artifact.

**Determinism**: The chain hash is fully deterministic — given the same base content and timestamp, the same chain hash will always be produced. This means chain hashes can be independently recomputed and verified by any party with access to the artifact, without needing the original recording environment.

The concatenation format (`artifact_hash + timestamp_utc`, no separator) is chosen for simplicity. The `artifact_hash` is always exactly 64 hex characters, so there is no ambiguity in the concatenation boundary.

### Chain Validation

The validation script (`scripts/validate_prompt_artifact.sh`) now includes a chain integrity step after sidecar hash verification:

1. Extract `artifact_hash` and `chain_hash` from the artifact.
2. Recreate the base JSON by removing `artifact_hash` and `chain_hash` fields (using `jq del()`).
3. Compute the SHA-256 of the base JSON and compare to the stored `artifact_hash`.
4. Compute `SHA-256(artifact_hash + timestamp_utc)` and compare to the stored `chain_hash`.

If either computation does not match, validation fails with a chain integrity violation. This is a hard failure — the artifact cannot be trusted and the run cannot proceed.

The policy file now includes `require_chain_validation: true`. When this flag is set, the validation script additionally checks that chain fields are present in the artifact. Artifacts from older PromptOS versions that lack chain fields will fail policy validation, forcing teams to upgrade.

### Run Record Binding

The binding helper (`integration/bind_to_run_record.sh`) extracts `artifact_hash` and `chain_hash` from a prompt session artifact and injects them into the Orchestrator's `run_record.json` under a `governance` key:

```json
{
  "governance": {
    "prompt_artifact_hash": "<artifact_hash>",
    "prompt_chain_hash": "<chain_hash>"
  }
}
```

This creates a cryptographic link between the Orchestrator's run record and the prompt session that governed the run. An auditor examining a run record can:

1. Read the `governance.prompt_artifact_hash`.
2. Locate the corresponding `prompt_session.json` in the evidence directory.
3. Verify that the artifact's embedded `artifact_hash` matches.
4. Verify the `chain_hash` for temporal consistency.

If any step fails, the chain of custody is broken — either the artifact was modified, substituted, or fabricated after the run record was created.

The binding script refuses to overwrite an existing `governance` key. This prevents re-binding — once a run record is bound to a prompt artifact, the binding is permanent. Re-binding would require creating a new run record, which creates its own audit trail.

### Drift Detection

The drift lock check (`integration/drift_lock_check.sh`) consolidates all integrity checks into a single, fast diagnostic:

1. Does `prompt_session.json` exist?
2. Does `prompt_session.sha256` exist?
3. Does the sidecar hash match the file?
4. Does the embedded `artifact_hash` match recomputed content?
5. Does the embedded `chain_hash` match recomputed chain?

If all checks pass: `[DRIFT LOCKED] Artifact integrity intact.`
If any check fails: `[DRIFT DETECTED] Governance artifact invalid.`

This script is designed for integration into monitoring, scheduled checks, or post-deployment verification. It answers a simple question: "Is the governance artifact for this run still intact?" The answer is binary and unambiguous.

### Why Hash-Only Is Insufficient

The v0.6.0 sidecar hash proves that a file has not changed since the hash was generated. But it does not prove:

- That the file's content is internally consistent (fields could be edited and re-hashed).
- That the file belongs to this specific run (it could be copied from another run).
- That the governance content matches what was originally recorded (the sidecar tracks the whole file, not the meaningful content).

The chain binding model addresses all three: embedded hashes prove internal consistency, temporal chain hashes make cross-run replay detectable, and run record binding creates a permanent reference between the Orchestrator's records and the prompt governance that fed them.

## Consequences

- **Positive**: Embedded artifact hash makes content-level tampering detectable even if sidecar hash is regenerated.
- **Positive**: Chain hash binds artifacts to timestamps, making replay from other sessions detectable.
- **Positive**: Run record binding creates a permanent, auditable link between Orchestrator runs and prompt governance.
- **Positive**: Drift lock check provides a single-command integrity diagnostic for monitoring and verification.
- **Positive**: Policy flag `require_chain_validation` forces migration from hash-only to chain-validated artifacts.
- **Negative**: Two-phase artifact generation is more complex than single-write. Mitigation: complexity is contained in the recording script; consumers see a standard JSON file.
- **Negative**: Chain validation depends on `jq` for JSON field extraction. Mitigation: `jq` is already a dependency from v0.5.0; the script fails explicitly if unavailable.
- **Negative**: Base JSON hash computation is sensitive to formatting (whitespace, key order). Mitigation: both recording and validation use the same tools (`cat` heredoc for recording, `jq del()` for validation), producing consistent output.
- **Negative**: Run record binding is one-way (no unbinding). Mitigation: this is by design — governance bindings should be permanent for auditability.
