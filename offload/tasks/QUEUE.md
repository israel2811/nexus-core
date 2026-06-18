# NEXUS offload task queue

Use this queue to keep Codex, Antigravity, Claude, and any Codespaces runs aligned.

## Ready

- [ ] Run a tiny sample manifest against `offload/sample_input` to verify the scripts.
- [ ] Choose the next Drive batch for inventory or dedupe.
- [ ] Decide whether that batch is safe for public GitHub, private staging, or Drive-only processing.
- [ ] Convert only final reading material into native Google Docs/Sheets.

## Waiting for source selection

- [ ] Large Google Drive inventory refresh.
- [ ] Full AI conversation consolidation pass.
- [ ] Final-document source matrix: findings, gaps, claims, evidence, contribution, publication target.

## Rules before starting a task

1. State the input scope.
2. State where outputs will be written.
3. Confirm no private/sensitive data will be pushed to this public repo.
4. Keep the batch resumable.
5. Write a short result entry into `offload/state/STATUS.md` or the Drive control doc.
