# NEXUS offload status

Updated: 2026-06-18

## Current objective

Move heavy processing away from the local Windows laptop while keeping Google Drive as the final native-document surface for research reading, continuity, analysis, and drafting.

## Established

- Google Drive connector is available to Codex for Drive/Docs operations.
- Native Drive control doc exists: https://docs.google.com/document/d/1Cp_TAv22I51heJHrSOugQy-6S__VpnUJL0JkSOeJsV4
- Drive control folder exists: https://drive.google.com/drive/folders/1wm14_jePx4DnGsqVjTcT6T6YRLRU0wIL
- Public GitHub repo selected for executable offload scaffolding: https://github.com/israel2811/nexus-core
- Codespaces should be used only for concrete resumable batches, not as a keepalive loop.
- Offload scripts were tested against `offload/sample_input`: manifest, dedupe report, and one Google-Docs-sized chunk generated successfully.

## Active constraints

- Do not delete data.
- Do not touch original Antigravity folders or 99_* folders without explicit instruction.
- Do not commit private corpus material to this public repo.
- Keep local laptop work light: no broad recursive scans unless a small target is specified.
- Treat .gdoc pointers as pointers, not proof of restored full content.

## Next safe steps

1. Confirm which Drive folder or export is the next source batch.
2. Stage only the selected batch into a safe working area.
3. Run manifest/dedupe/split scripts in Codespaces.
4. Publish final readable results back into Google Docs/Sheets native format.
5. Record evidence: input scope, output files, duplicate counts, gaps, and blockers.

## Current blockers

- Claude Desktop has recently opened a window but exposed no readable UI text to Computer Use; do not depend on it until verified.
- Antigravity IDE CLI responds (`Antigravity IDE 1.107.0`) and can open repo-local folders/files.
- Antigravity agent UI remains unstable in this session: Computer Use text is empty, screenshots fail with `0x80004002`, and CDP prompt delivery did not complete reliably.
- The canonical Antigravity prompt is stored at `offload/prompts/ANTIGRAVITY_OFFLOAD_SYNC.md`; use it once the agent panel accepts input again.
