# NEXUS Invisible Offload

Transparent offload fabric for keeping the Windows UI responsive while moving bounded heavy work to a LAN/cloud worker.

## Design

- Windows keeps the visible workflow: browser, ChatGPT, Codex and editors.
- `nexus-offload-broker` runs on a Linux worker and listens only on `127.0.0.1`.
- A reverse SSH tunnel exposes that broker only as `127.0.0.1:8765` on Windows.
- The Windows client uses a local token as a second authentication layer.
- Automatic execution is allow-listed; arbitrary remote shell commands are not accepted.
- Browser profiles, cookies, credentials, `.env` files, SSH/GPG material and other sensitive paths are excluded from automatic offload.

## Automatic LAN jobs

- `repo-inventory`
- `hash-tree`
- `source-search`
- `health-snapshot`

Tasks that should not run on the LAN worker are only routed conceptually until their remote lane is separately verified:

- builds/tests/compilation -> GitHub Actions or Codespaces
- GPU/ML/scientific batch -> Colab or another verified GPU lane
- browser automation -> verified remote browser lane

## Private runtime configuration

Copy `nexus-offload.conf.example` to `/etc/nexus-offload.conf`, fill in local values and keep it mode `0600`. Generate `/etc/nexus-offload.token` locally with a CSPRNG and keep it mode `0600`.

Never commit either runtime file.

## Security properties

1. Broker bind defaults to localhost.
2. Windows reaches it through encrypted SSH port forwarding.
3. A bearer token is still required for state, route, submit and job endpoints.
4. Submitted work is constrained to an allow-list and a bounded Windows profile root.
5. Jobs have file-count, size, concurrency and execution-time bounds.
6. Generated dependencies and secret-like files are excluded from source control.

## Rollback

Disable the two systemd units, restore the previous Codex `AGENTS.md` backup if desired, and leave the Windows UI/app configuration untouched. The offload layer is additive and does not replace Git, npm, PowerShell, Codex or the browser.
