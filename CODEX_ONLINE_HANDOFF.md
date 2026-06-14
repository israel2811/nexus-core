# Codex Online Handoff

Actualizado: 2026-06-14

## Estado GitHub

Todos los repositorios bajo `israel2811` visibles con `gh repo list israel2811 --limit 200` quedaron publicos el 2026-06-14.

Repos publicos detectados:

- `israel2811/Cerebro-Unificado-Antigravity`
- `israel2811/improved-parakeet`
- `israel2811/9cf95482a90a8fcecb7e530bc8b7e36289fc487046289f6aa3329672a92c21be`
- `israel2811/Lenovo`
- `israel2811/OneDrive`
- `israel2811/nexus-core`
- `israel2811/antigravity-unified-cloud`
- `israel2811/claudio`
- `israel2811/nextjs-boilerplate`

## Regla critica

No usar el repositorio Git accidental detectado en `C:/` como fuente para subir a GitHub. En la PC local, `git rev-parse --show-toplevel` desde la carpeta Codex devolvio `C:/`, sin remoto configurado. Eso puede arrastrar carpetas de sistema, basura, caches o material sensible. Codex online debe trabajar desde repos limpios y publicos, especialmente `nexus-core`, no desde un dump de la raiz del disco.

## Objetivo

Hacer que Codex online pueda continuar el trabajo de Codex de PC usando GitHub como superficie legible y sincronizable, sin depender de Computer Use, Antigravity ni acceso directo a `G:\Mi unidad`.

## Estado de corpus y Drive

Google Drive sigue siendo la superficie final de lectura, continuidad y redaccion. Los documentos finales o de control deben existir como Google Docs nativos cuando sea posible. Archivos `.gdoc`, JSON crudo, HTML gigante, screenshots o stubs no cuentan como material final legible.

Estado reciente de consolidacion:

- Claude canonico local convertido a Google Docs nativos.
- Soportes centrales de tesis convertidos a Google Docs nativos.
- Soportes Antigravity de tesis convertidos a Google Docs nativos.
- Codex canonico local `CANONICO_CODEX_Parte01-13` completo en Google Docs nativos.
- ChatGPT canonico `CANONICO_CHATGPT_Parte01-09` convertido a Google Docs nativos como lote 6A.

Siguiente bloque de Drive recomendado:

- Continuar con ChatGPT lote 6B: `CANONICO_CHATGPT_Parte10-18`.
- Despues seguir por sublotes equivalentes hasta `Parte131`.
- Registrar cada lote en manifiesto, checklist y cronologia.

## Protocolo de trabajo

- Trabajar una cosa a la vez; la PC local es lenta y se traba con escaneos amplios.
- Evitar recursivos sobre `G:\Mi unidad`; usar rutas concretas y sublotes pequenos.
- No borrar, mover ni renombrar originales sin hash por contenido y aprobacion explicita.
- No crear documentos nuevos si solo duplican control existente; actualizar manifiesto, checklist y cronologia.
- No publicar secretos, tokens, cookies, historiales de navegador completos ni carpetas de sistema.
- Si se necesita GitHub como puente, subir solo artefactos curados, manifests, indices, prompts limpios y scripts reproducibles.

## Estado herramientas locales

- Antigravity: historicamente actualizado a 2.1.4 y llego a arrancar con DevTools/language server, pero el 2026-06-14 solo arranco proceso sin `language_server.exe` ni DevTools. No contarlo como agente util hasta que responda a un prompt visible.
- Computer Use: bloqueo actual por `Computer Use native pipe path is unavailable`.
- Browser integrado: abre ChatGPT/Gemini; NotebookLM llega a login; Claude requiere reintento controlado.

## Prioridad para Codex online

1. Usar estos repos publicos como lectura base.
2. No intentar reconstruir la PC desde Git.
3. Pedir al usuario o a Codex de PC que suba artefactos curados cuando falten fuentes.
4. Continuar la tesis desde controles canonicos: manifiesto, checklist, cronologia, manuscrito corregido, matriz fuente-modulo-afirmacion y cantera.
5. Mantener separadas tres capas: academica, operativa y personal/forense.
