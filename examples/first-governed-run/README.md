# First Governed Run

Run a complete PromptOS governed session in one command. This example executes, exports, and validates prompt artifacts end-to-end.

## Prerequisites

- Bash 3.2+
- `jq` installed (`brew install jq` / `apt-get install jq`)
- Git (for version tagging)

## Run It (2 Minutes)

```bash
cd examples/first-governed-run
./run.sh
```

## What Happens

1. **Governed session** — Runs `bin/promptos dev` with prompts P00, P01, P03, P05
2. **Export** — Copies the session artifact + SHA-256 sidecar to `artifacts/`
3. **Validate** — Checks schema, required fields, hash integrity, and policy compliance
4. **Drift lock** — Verifies artifact immutability via sidecar hash comparison

## Output

On success you will see:

```
[PASS] first governed run complete
Artifact dir: ./examples/first-governed-run/artifacts/
```

The `artifacts/` directory will contain:

- `prompt_session.json` — The governed session record
- `prompt_session.sha256` — SHA-256 hash sidecar for tamper detection

## Cleanup

Generated artifacts are gitignored. To remove them manually:

```bash
rm -rf artifacts/
```
