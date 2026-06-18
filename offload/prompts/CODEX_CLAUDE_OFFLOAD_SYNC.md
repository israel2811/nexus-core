# Codex / Claude offload sync prompt

Use this when another assistant needs to continue the NEXUS offload workflow.

```text
Continue the NEXUS/CCA offload workflow from the existing control points:

- Drive control folder: https://drive.google.com/drive/folders/1wm14_jePx4DnGsqVjTcT6T6YRLRU0wIL
- Native Drive control doc: https://docs.google.com/document/d/1Cp_TAv22I51heJHrSOugQy-6S__VpnUJL0JkSOeJsV4
- Executable repo: https://github.com/israel2811/nexus-core
- Repo control files: offload/README.md, offload/state/STATUS.md, offload/tasks/QUEUE.md

Core rule: Google Drive is the final native reading/drafting surface; GitHub/Codespaces/Actions are for lightweight, reproducible processing; the Windows laptop is only the control cabin.

Do not delete data. Do not touch original Antigravity folders or 99_* folders. Do not push private corpus, browser profiles, credentials, tokens, cookies, or sensitive logs to a public repo. Work in small resumable batches and record evidence.

If asked to process Drive material, first identify the exact source batch and whether it is safe for public GitHub, private staging, or Drive-only connector/API processing. Prefer native Google Docs/Sheets for final readable outputs.
```
