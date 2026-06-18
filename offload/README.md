# NEXUS offload control

This directory is the lightweight execution layer for moving heavy NEXUS/CCA corpus work away from the local Windows laptop and into GitHub Codespaces or GitHub Actions.

## Boundaries

- Do not commit private corpus exports, browser profiles, tokens, cookies, API keys, logs with secrets, or full personal chat dumps to this public repository.
- Use Google Drive as the final reading and drafting surface.
- Use this repository for scripts, queue files, prompts, manifests, and small non-sensitive outputs.
- Prefer small resumable batches over one large run.
- Never keep a Codespace alive just to avoid idle timeout; start it for a concrete batch, write checkpoints, then stop it.

## Established Drive control

- Drive folder: NEXUS_OFFLOAD_CONTROL_20260618
- Folder URL: https://drive.google.com/drive/folders/1wm14_jePx4DnGsqVjTcT6T6YRLRU0wIL
- Native Google Doc: 00_NEXUS_OFFLOAD_CONTROL_20260618
- Doc URL: https://docs.google.com/document/d/1Cp_TAv22I51heJHrSOugQy-6S__VpnUJL0JkSOeJsV4

## Recommended workflow

1. Choose a small input batch from Drive or a local export.
2. Stage only non-sensitive or explicitly approved data into a private working area or a temporary local folder.
3. Run one of the scripts in `offload/scripts/` inside Codespaces.
4. Save outputs under `offload/outputs/` only if they are safe for a public repo.
5. Move final human-readable material back into native Google Docs or Sheets through the Drive connector/API.
6. Update `offload/state/STATUS.md` and `offload/tasks/QUEUE.md`.

## Quick commands

Create a manifest:

```bash
python offload/scripts/manifest.py --input offload/sample_input --output offload/outputs/manifest.jsonl
```

Find duplicates from a manifest:

```bash
python offload/scripts/dedupe_manifest.py --manifest offload/outputs/manifest.jsonl --output offload/outputs/duplicates.md
```

Split text files into Google-Docs-sized chunks:

```bash
python offload/scripts/split_text_for_gdocs.py --input offload/sample_input --output offload/outputs/chunks --max-chars 180000
```

## Roles

- Codex: orchestrates repo, Drive connector, scripts, verification, and final reporting.
- Antigravity: helps inspect local IDE/agent capabilities, proposes batches, and runs safe repo-local tasks.
- Claude: helps read and synthesize conversations once its Desktop/UI is stable.
- Google Drive: source of truth for native docs and final research material.
