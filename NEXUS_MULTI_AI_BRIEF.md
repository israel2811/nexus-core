# NEXUS Multi-AI Capability Bus

This repository is the shared technical control plane for NEXUS.
The private operational/context master is maintained in Google Drive as `NEXUS_CONTINUIDAD_MULTI_IA_MASTER`.

## Goal
Allow ChatGPT, Codex, Claude/Claude Code, Gemini, Antigravity, Jules and connected services to continue the same work without restarting context.

## Two-layer model
**Public technical layer (this repository):** reusable code, schemas, workflows, agent contracts, tests and sanitized capability manifests.

**Private context layer (Google Drive):** complete conversations, exports, browser-history indexes, account/profile mappings, generated documents, timestamps, hashes and provenance.

Never copy authentication material or private browser/session databases into this repository.

## Continuity protocol
1. Resolve the current HILO_ID(s) from the private master.
2. Retrieve only the required canonical sources.
3. Re-run incomplete historical prompts using later corrections and evidence.
4. Produce a bounded artifact/commit/analysis.
5. Write a checkpoint back to the private master.

## Capability routing
- Desktop Commander: remote shell, filesystem, processes and local analysis.
- Computer Use: visual GUI interaction when required.
- Playwright/Chrome DevTools: browser DOM automation.
- GitHub/Actions/Codespaces: code, CI, batch jobs and reproducible environments.
- Drive: private corpus and provenance.
- Linear: task ledger.
- Replit/Render: deployable prototypes/services.
- Neon/Supabase: structured state/data when needed.

See `configs/nexus-capabilities.public.json` for the sanitized machine-readable registry.