# Google Drive Access Guide

Actualizado: 2026-06-14

Este repositorio publico sirve como puente para que Codex online y ChatGPT puedan entender el trabajo sin depender directamente de la PC local.

## Regla principal

No subir credenciales, cookies, tokens, archivos `gdrive-credentials.json`, perfiles de navegador, historiales completos ni carpetas de sistema a GitHub.

## Como debe acceder Codex online

Codex online puede leer:

- Repositorios publicos bajo `israel2811`.
- Handoffs curados en este repo.
- Manifests, indices, tablas de trazabilidad y scripts reproducibles.
- Enlaces a Google Docs nativos cuando el usuario los proporcione o sean publicos/compartibles.

Codex online no puede asumir acceso directo a:

- `G:\Mi unidad` de la PC local.
- Credenciales locales en `C:\Users\Dell\.claude\gdrive-credentials.json`.
- Sesiones web vivas de Claude, ChatGPT, Gemini o NotebookLM.

## Puente recomendado

1. Codex de PC consolida material en Google Docs nativos y actualiza los controles maestros.
2. Codex de PC publica en GitHub solo un indice curado: titulo, ruta canonica, URL del Doc nativo, estado de verificacion y siguiente accion.
3. Codex online lee GitHub y trabaja sobre esos indices.
4. Si hace falta contenido completo, Codex online debe pedir que se suba el fragmento curado o que se comparta el Google Doc correspondiente.

## Controles actuales relevantes

- `CODEX_ONLINE_HANDOFF.md`: estado general para Codex online.
- Manifiesto local Drive: `G:\Mi unidad\01_GDOCS_CONSOLIDADOS\MANIFIESTO_GDOCS_CONSOLIDADOS_2026-06-12.md`.
- Checklist maestro Drive: `G:\Mi unidad\00_CHECKLIST_MAESTRO_PENDIENTES.md`.
- Cronologia maestra Drive: `G:\Mi unidad\02_TESIS\00_CRONOLOGIA_MAESTRA.md`.

## Antigravity y MCP local

El perfil local `Antigravity_STABLE_NEXUS` tiene un `mcp.json` con servidor `google-drive` apuntando a una credencial local. Eso no debe copiarse a GitHub con secretos. Solo puede publicarse una plantilla sin valores sensibles.

## Reduccion sin perdida

Para reducir ruido sin perder informacion:

- Marcar duplicados exactos por SHA-256 antes de mover.
- Mantener originales hasta aprobacion explicita.
- Subir a GitHub solo artefactos curados, no dumps masivos.
- Distinguir corpus canonico, evidencia bruta, operativo temporal y candidatos a archivo reversible.
