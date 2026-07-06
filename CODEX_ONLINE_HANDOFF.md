# Codex Online Handoff

Actualizado: 2026-07-06

## Proposito

Este archivo es el puente curado para que Codex online, ChatGPT con GitHub, Claude u otro agente puedan entender el estado del proyecto sin depender de la PC local, Computer Use, Antigravity, ni acceso directo a `G:\Mi unidad`.

La regla principal no cambia: Google Drive es la superficie final de lectura, continuidad, analisis y redaccion; GitHub solo debe contener indices, handoffs, scripts reproducibles y contexto no sensible.

## Estado GitHub verificado 2026-07-06

Repos bajo `israel2811` verificados por API de GitHub como `visibility: public`, rama `main`, no archivados:

- `israel2811/Cerebro-Unificado-Antigravity` size 5620
- `israel2811/claudio` size 174
- `israel2811/improved-parakeet` size 3669
- `israel2811/antigravity-unified-cloud` size 0, README minimo
- `israel2811/nexus-core` size 85
- `israel2811/nextjs-boilerplate` size 63
- `israel2811/OneDrive` size 68551
- `israel2811/Lenovo` size 17
- `israel2811/9cf95482a90a8fcecb7e530bc8b7e36289fc487046289f6aa3329672a92c21be` size 1

Si ChatGPT muestra repos como "No esta indexado", no es un problema de visibilidad publica. Segun OpenAI Help, hay que usar Settings -> Apps -> GitHub -> Choose/Configure repositories y, si GitHub no los ha indexado, buscar en GitHub `repo:israel2811/<repo> import` y esperar aprox. 5-10 minutos.

## Repos puente preferidos

- `nexus-core`: repo principal para handoffs, indices, scripts de offload, devcontainer y continuidad de Codex online.
- `antigravity-unified-cloud`: repo puente Antigravity, pero hoy esta casi vacio; necesita manifiesto curado si se quiere usar como contexto real.
- `Cerebro-Unificado-Antigravity`: contiene README de migracion/cloud workstation y puede servir como historico tecnico, filtrando secretos y dumps.

No usar ningun Git accidental de `C:/` ni dumps masivos de la PC como fuente de publicacion. Solo artefactos curados.

## Estado Drive verificado 2026-07-06

Raiz de Drive esta organizada en carpetas principales:

- `00_TESIS`
- `01_CORPUS`
- `02_FUENTES`
- `03_DOCS_TRABAJO`
- `_NO_INVESTIGACION`
- `99_PARA_ELIMINAR_2026-07-05`

Tambien quedan documentos sueltos en raiz que conviene reubicar o clasificar, por ejemplo `NEXUS_CORPUS_MASIVO_v5`, `NEXUS_DocumentoMaestro_v3`, varios `CLAUDEWEB_*`, `Notebooklm` y directivas antiguas. No mover automaticamente sin verificar contenido.

## Hallazgos Drive concretos

- `_NO_INVESTIGACION` contiene dos archivos que parecen relevantes y no deberian quedar ahi:
  - `CLAUDEWEB_ALL_44.json` -> mover candidato a `01_CORPUS/01_INVESTIGACION_POR_IA`.
  - `00_MANIFIESTO_LIMPIEZA_20260622_1436.csv` -> mover candidato a `03_DOCS_TRABAJO/00_INVENTARIO`.
- `03_DOCS_TRABAJO/00_INVENTARIO` contiene `inventario_completo.csv` (~26.7 MB), `duplicados_nombre_tamano.csv` (~8.7 MB), `catalogo_por_tipo.csv`, `99_BASURA_CODIGO_carpetas.csv` y manifiesto GDocs.
- `00_TESIS/02_TESIS` contiene el tronco actual: `00_BORRADOR_MAESTRO_UNIFICADO_CCA_AAV_2026-06-28.md` (~528 KB), `00_CANTERA_FRAGMENTOS.md`, `00_CRONOLOGIA_MAESTRA.md`, matrices, verificaciones DOI y manuscritos.
- `99_BASURA_CODIGO_carpetas.csv` marca candidatos regenerables como `node_modules`, `.venv`, `site-packages`, `__pycache__`, caches y `.git` duplicados dentro de respaldos. Se deben mover solo a `99_*`, no borrar permanente.

## Estado herramientas locales 2026-07-06

- Computer Use: no disponible en esta sesion. El descubrimiento no expuso herramientas visuales completas; intentos locales de procesos/comandos se colgaron. No afirmar prueba visual hasta que el servicio nativo responda.
- Antigravity: mantener en banca para tareas criticas hasta que responda a prompt visible y no levante flota MCP innecesaria.
- Claude Desktop/Cowork: priorizar modo ligero y MCP minimo. Las instrucciones oficiales de Claude Code recomiendan `/doctor`, `/safe-mode`, reducir MCP/plugins/hooks y evitar contextos o repos enormes cuando hay alto uso de memoria.
- PC local: tratar como Dell lenta de 8 GB RAM + HDD; evitar escaneos recursivos, navegadores multiples y comandos amplios sobre Drive.

## Offload recomendado

- GitHub Codespaces: usar como estacion remota interactiva. GitHub documenta VMs desde 2 cores/8 GB RAM hasta 32 cores/128 GB RAM. Configurar devcontainer y presupuestos.
- GitHub Actions: usar para lotes reproducibles no interactivos; publico suele ser mas favorable, privado consume cuota/almacenamiento segun plan.
- Google Colab: util para notebooks y analisis puntual, no para estado persistente ni datos sensibles sin control.
- Hugging Face Spaces: util para demo/herramienta web privada/publica; CPU basico documentado como 2 vCPU, 16 GB RAM y 50 GB no persistente.
- Neon: util para indice/metadatos/vector/logs, no para volcar el corpus bruto; Free plan tiene cuotas limitadas y 0.5 GB por branch.

## Prioridad operativa inmediata

1. No insistir con Computer Use/Antigravity mientras la PC este saturada.
2. Usar Drive connector/API para lectura e inventario ligero.
3. Completar `01_GDOCS_CONSOLIDADOS` por lotes pequenos y legibles; faltan ChatGPT partes 10-131 y exports autorizados de Gemini/NotebookLM/Claude-app si el usuario los entrega.
4. Depurar Drive en orden: codigo/cache regenerable -> duplicados exactos con hash -> capturas/media con confirmacion -> documentos por contenido.
5. Para tesis final, trabajar desde `00_TESIS/02_TESIS`: tronco maestro, cantera, cronologia, matriz fuente-modulo-afirmacion y fuentes DOI/APA7.
6. Separar siempre tres capas: academica, operativa tecnica y personal/forense.

## Pendientes editoriales del documento final

- M0: glosario y definiciones operacionales, resolviendo FPI y SPIA.
- M2: diagnostico diferencial medico/academico.
- M13: transparencia editorial, uso de IA y trazabilidad.
- Resolver conflicto de matriz A-E antes de publicar.
- Marcar o reformular afirmaciones POR-VALIDAR; no usar cifras como 70%/150 ms o latencias sin fuente revisada.
- Mantener CCA como pregunta/hipotesis falsable, no como conclusion causal cerrada.

## Seguridad

No subir a GitHub: credenciales, cookies, tokens, `gdrive-credentials.json`, historiales completos de navegador, perfiles de apps, conversaciones privadas completas sin curacion, ni dumps de sistema.
