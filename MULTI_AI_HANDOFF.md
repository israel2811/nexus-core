# NEXUS Multi-AI Handoff & Continuity Protocol
**Fecha de actualización:** 2026-10-03
**Repositorio Técnico:** `israel2811/nexus-core` (Rama `main`)
**Master de Contexto Privado:** Google Drive `NEXUS_CONTINUIDAD_MULTI_IA_MASTER`

---

## 1. Visión General de la Arquitectura Multi-IA

NEXUS opera bajo un modelo de **dos capas** diseñado para permitir la colaboración fluida entre **ChatGPT**, **Codex**, **Claude / Claude Code**, **Gemini**, y **Antigravity**:

1. **Capa Técnica Pública (GitHub - `israel2811/nexus-core`):**
   - Contiene contratos de agentes (`AGENTS.md`), manifiestos de capacidad (`configs/nexus-capabilities.public.json`), índices de conectores y scripts de automatización/offload.
   - **Regla Estricta:** Cero credenciales, cero cookies, cero tokens de API, cero sesiones de navegador y cero cuerpos de conversaciones privadas.

2. **Capa de Contexto Privado (Google Drive):**
   - Contiene las transcripciones completas, borradores de investigación (`00_TESIS/02_TESIS`), canteras de fragmentos, matrices DOI/APA7 e inventarios.
   - Es la fuente canónica de verdad de lectura, redacción y trazabilidad.

---

## 2. Guía Específica por Agente

### 🤖 A. ChatGPT (ChatGPT Web / ChatGPT GitHub Connector / Custom GPTs)

- **Indexación en GitHub:**
  1. En ChatGPT: ir a **Settings** -> **Apps** -> **GitHub** -> **Choose / Configure repositories**.
  2. Asegurar que `israel2811/nexus-core` esté seleccionado.
  3. Si la búsqueda rápida falla, ejecutar en GitHub la búsqueda `repo:israel2811/nexus-core import` y aguardar indexación (5-10 min).
- **Lectura Inicial Obligatoria:**
  - Leer primero `CHATGPT_CONNECTOR_INDEX.md`, `NEXUS_MULTI_AI_BRIEF.md` y este archivo (`MULTI_AI_HANDOFF.md`).
- **Protocolo de Economía de Tokens y Trabajo en Lotes:**
  - No intentar volcar bibliotecas completas en una sola interacción.
  - Procesar borradores y textos en bloques delimitados (10-20 archivos o 50-100 páginas por interacción).
- **Rigor Académico y Editorial:**
  - No inventar estadísticas, latencias o porcentajes no verificados (ej. mantener afirmaciones sin fuente etiquetadas como `POR-VALIDAR`).
  - Tratar el modelo CCA como una hipótesis falsable, no como una conclusión causal cerrada.

---

### 💻 B. Codex (OpenAI Codex / Codex Online / Cloud Execution Agents)

- **Contrato de Modificación:**
  - Consultar y respetar siempre `AGENTS.md`.
  - Toda modificación debe realizarse en cambios pequeños, reversibles, sobre la rama `main` o en Pull Requests limpios.
- **Offload y Cómputo:**
  - Usar GitHub Codespaces o GitHub Actions para tareas pesadas mediante los scripts en `scripts/` (`codespace_runtime.sh`, `nexus-cloud-batch.ps1`).
  - No saturar la PC local (Dell 8GB RAM + HDD).
- **Validación:**
  - Validar el bus de capacidades antes y después de cambios ejecutando el script `scripts/validate_nexus_capability_bus.py`.
- **Formato de Cierre Obligatorio:**
  - Al completar un ciclo de trabajo, reportar exactamente: `changes`, `tests`, `evidence`, `risks`, y `next_action`.

---

### 🧠 C. Claude (Claude Code / Claude Desktop / Anthropic Web)

- **Modo Ligero y Gestión de Memoria:**
  - En la PC local (8 GB RAM), mantener la flota MCP y plugins al mínimo imprescindible.
  - Utilizar los comandos integrados recomendados: `/doctor` y `/safe-mode` cuando exista alta carga de memoria.
  - Evitar escaneos recursivos profundos en carpetas locales o volúmenes masivos de Drive.
- **Rutado de Operaciones:**
  - Comandos del sistema / archivos / procesos -> `Desktop Commander` o CLI local.
  - Inspección visual GUI -> `Computer Use` (solo cuando esté activo el servicio nativo).
  - Automatización DOM de navegador -> `Playwright / Chrome DevTools`.
- **Handoff y Trazabilidad:**
  - Registrar marcas de tiempo y referencias a IDs de hilo (`HILO_ID`, `MSG_ID`, `ARTEFACTO_ID`) provistas en las notas de contexto.

---

## 3. Protocolo Unificado de Handoff entre IAs

Cuando cualquier agente (ChatGPT, Codex o Claude) concluya su turno o pase el testigo a otra IA, debe incluir la siguiente **Ficha de Continuidad**:

```markdown
### 🔄 Ficha de Continuidad NEXUS
- **Agente Saliente:** [ChatGPT | Codex | Claude | Antigravity]
- **Objetivo:** [Descripción breve de la tarea realizada]
- **Cambios Realizados:** [Archivos creados o modificados en GitHub/Drive]
- **Evidencia / Pruebas:** [Resultados de validación o verificación]
- **Estado de Trabajo:** [EN PROGRESO | COMPLETADO | BLOQUEADO]
- **Siguiente Acción Sugerida (para la siguiente IA):** [Instrucciones precisas paso a paso]
```

---

## 4. Matriz de Rutado de Capacidades (Capability Routing)

| Recurso / Tarea | Herramienta / Plataforma Recomendada | Notas de Seguridad / Límites |
| :--- | :--- | :--- |
| **Repositorio y Código** | GitHub (`israel2811/nexus-core`) | Fuente de verdad pública y reproducible |
| **Cómputo en Lote / CI** | GitHub Codespaces / Actions | Priorizar sobre procesamiento en PC local |
| **Contexto y Borradores** | Google Drive (`00_TESIS`, `01_CORPUS`) | Fuente privada de lectura y redacción |
| **Shell local y Procesos** | Desktop Commander / CLI | Solo comandos delimitados |
| **Base de Datos Estructurada**| Neon / Supabase | Esquema liviano para índices y metadatos |

---

## 5. Próximos Pasos Directos

1. **Para ChatGPT:** Utilizar este documento para alinear las respuestas con el estado del proyecto sin requerir reconstrucción de contexto.
2. **Para Codex:** Ejecutar y mantener los scripts de orquestación nómada en `scripts/`.
3. **Para Claude:** Mantener la sesión de trabajo liviana y guiarse por las directrices de `AGENTS.md`.
