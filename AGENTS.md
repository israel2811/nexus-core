# NEXUS Multi-AI Agent Contract

## Mandatory startup
Before changing this repository, every agent must:
1. Read this file.
2. Read `NEXUS_MULTI_AI_BRIEF.md`.
3. Inspect current branch, diff, workflows and tests.
4. Treat GitHub as the technical source of truth and Google Drive as the private context/provenance source.
5. Never assume another AI's partial reconstruction is canonical when an original export exists.

## Safety and provenance
- Never commit passwords, cookies, OAuth tokens, API keys, browser session data or private conversation bodies.
- Prefer small reversible changes on a branch and a pull request.
- Preserve existing working workflows unless a failing test proves a change is necessary.
- Record source, timestamp, HILO_ID/MSG_ID/ARTEFACTO_ID when supplied by the private context layer.
- Do not invent missing timestamps or authorship.
- Do not silently delete duplicates; preserve provenance and mark deduplication decisions.

## Execution routing
Use the minimum-capability worker needed:
- shell/files/processes -> Desktop Commander or local CLI
- GUI -> Computer Use
- browser DOM -> Playwright/Chrome DevTools
- code/repository -> Codex/Claude Code/Gemini/Jules/GitHub
- heavy batch compute -> Actions/Codespaces/Colab
- app prototypes -> Replit/Render
- structured data -> Neon/Supabase

Every completed task must report: changes, tests, evidence, risks, and exact next action.