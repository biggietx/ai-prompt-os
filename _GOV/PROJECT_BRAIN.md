# PROJECT_BRAIN_TEMPLATE.md
# PROJECT BRAIN — LIVING STATE DOCUMENT
**Usage:** Copy to `_GOV/PROJECT_BRAIN.md` in each project repo. Fill in every field.
Update at every session start, every merge, every major decision.
**Recovery:** Paste this document to any agent to reconstruct full project context instantly.
**Commands:**
- `COMPRESS` — Reduce to minimal recovery state (Section 15)
- `RECONSTRUCT` — Rebuild full context from this document
- `AUDIT` — Deep system review for weaknesses and debt
- `OPTIMIZE` — Performance and efficiency improvement mode
- `SECURITY` — Security review mode

---

# PROJECT BRAIN: [PROJECT NAME]
**Last Updated:** YYYY-MM-DD HH:MM UTC
**Updated By:** [Agent ID or human]
**Constitution Version:** 1.0
**Brain Version:** [increment each update, e.g., v1.0, v1.1]

---

## 1. PROJECT IDENTITY

| Field | Value |
|-------|-------|
| Project Name | |
| Repo URL | |
| Primary Branch | main |
| Baseline Tag | |
| Core Objective | |
| Target Users | |
| Business Goal | |
| Success Criteria | |
| Current Phase | `PLANNING` / `ACTIVE DEVELOPMENT` / `STABILIZATION` / `PRODUCTION` |
| Gate Tier | `FULL` — 13-gate pipeline |
| Domain Prefixes | [list: CORE, API, UI, INFRA, DATA, AUTH — define per project] |

---

## 2. SYSTEM ARCHITECTURE

| Layer | Detail |
|-------|--------|
| Frontend | |
| Backend | |
| Database | |
| Internal APIs | |
| External APIs | |
| Hosting / Infrastructure | |
| Authentication | |
| Environments | dev / staging / prod |
| Control Plane | [Telegram bot / CLI / manual — describe activation surface] |
| Feature Flags Active | [list flags and ON/OFF status] |

---

## 3. TECH STACK

| Category | Detail |
|----------|--------|
| Languages | |
| Frameworks | |
| Key Libraries | |
| Package Manager | |
| CI/CD | |
| Testing Strategy | |
| Local Test Command | |
| CI Test Command | |
| Lint Command | |
| Schema Validation Command | |
| Smoke Test Command | |

---

## 4. ACTIVE OBJECTIVES REGISTRY

> Source of truth for all in-flight work. One row per active objective.

| Objective ID | Description | Agent | Branch | Status | Merge Order |
|--------------|-------------|-------|--------|--------|-------------|
| | | | | `PLANNED`/`IN PROGRESS`/`BLOCKED`/`PR READY`/`MERGED` | |

**Status Definitions:**
- `PLANNED` — Defined, not started
- `IN PROGRESS` — Agent actively working
- `BLOCKED` — Waiting on dependency or decision
- `PR READY` — Branch pushed, awaiting merge authority review
- `MERGED` — Complete, in main

---

## 5. CURRENT FEATURES

| Feature | Status | Notes |
|---------|--------|-------|
| | `LIVE` / `IN DEV` / `PLANNED` | |

---

## 6. IN-PROGRESS WORK

**Current Active Task:**

**Blockers:**

**Assumptions in play:**

**Decisions pending:**

---

## 7. KNOWN ISSUES & BUGS

| ID | Description | Reproduction Steps | Suspected Cause | Attempted Fixes | Status |
|----|-------------|-------------------|-----------------|-----------------|--------|
| | | | | | `OPEN` / `IN PROGRESS` / `RESOLVED` |

---

## 8. DECISIONS LOG

> Institutional memory. Record every architectural and strategic decision.
> For formal decisions, create an ADR in `_GOV/ADR/` and reference it here.

| Date | Decision | Why | Tradeoffs | ADR Reference |
|------|----------|-----|-----------|--------------|
| | | | | |

---

## 9. TECHNICAL DEBT REGISTER

| Item | Impact | Refactor Plan | Priority | ADR Reference |
|------|--------|---------------|----------|--------------|
| | `HIGH`/`MED`/`LOW` | | | |

---

## 10. SECURITY SNAPSHOT

- **Auth vulnerabilities noted:**
- **Data exposure risks:**
- **Rate limiting status:**
- **Input validation status:**
- **Secrets management method:**
- **Last security review date:**
- **Open security ADRs:**

---

## 11. PERFORMANCE SNAPSHOT

- **Known bottlenecks:**
- **DB optimization status:**
- **Caching strategy:**
- **Scaling plan:**
- **Load tested:** `YES` / `NO` / `PENDING`
- **SLA targets:**

---

## 12. ERROR LOG SNAPSHOT

> Capture live errors here. Remove when resolved.

```
Error:
File:
Line:
Stack trace:
First seen:
Frequency:
Status: OPEN / INVESTIGATING / RESOLVED
```

---

## 13. MERGE ORDER QUEUE

> When multiple PRs are ready, this defines the sequence for human merge authority.

| Position | Objective ID | PR Link | Reason for Order |
|----------|--------------|---------|-----------------|
| 1 | | | Infrastructure first |
| 2 | | | |
| 3 | | | |

---

## 14. NEXT SPRINT ACTION PLAN

> Step-by-step execution plan for the next sprint. Updated after each merge.

1.
2.
3.
4.
5.

---

## 15. COMPRESSED RECOVERY STATE

> Updated when `COMPRESS` command is issued.
> This section is what you paste to reconstruct context after a reset.
> Keep under 30 lines.

```
PROJECT: 
REPO: 
STACK: 
PHASE:
GATE TIER: FULL — 13-gate pipeline
DOMAIN PREFIXES: 
ACTIVE OBJECTIVES: 
LAST MERGED: 
CURRENT BLOCKER: 
NEXT ACTION: 
KEY DECISIONS: 
CRITICAL CONTEXT: 
OPEN BUGS: 
SECURITY NOTES: 
CONSTITUTION VERSION: 1.0
BRAIN VERSION: 
```

---

*This document is the single source of project truth.*
*A stale Project Brain is a liability. Update it every session.*
*If context is ever lost, paste Section 15 to any agent to reconstruct instantly.*
