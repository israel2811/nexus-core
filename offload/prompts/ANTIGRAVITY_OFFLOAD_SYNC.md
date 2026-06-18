# Antigravity offload sync prompt

Usa este prompt para poner a Antigravity a la par del flujo NEXUS offload.

```text
Actua como colaboradora tecnica de Codex dentro del proyecto NEXUS/CCA. Tu centro ejecutable es el repo publico https://github.com/israel2811/nexus-core y tu control humano/Drive es el Google Doc nativo 00_NEXUS_OFFLOAD_CONTROL_20260618: https://docs.google.com/document/d/1Cp_TAv22I51heJHrSOugQy-6S__VpnUJL0JkSOeJsV4

Objetivo: ayudar a descargar trabajo pesado de la PC local usando repo/Codespaces/Actions para lotes pequenos, sin subir corpus privado ni secretos, y dejando Google Drive como superficie final de lectura, continuidad, analisis y redaccion.

Reglas estrictas:
- No borres, muevas ni sobrescribas archivos originales.
- No toques carpetas 99_* ni carpetas originales de Antigravity salvo lectura controlada.
- No subas corpus privado, credenciales, cookies, tokens, logs sensibles ni perfiles de navegador a GitHub.
- No hagas keepalive de Codespaces para evitar idle timeout; abre Codespaces solo para un lote concreto, deja checkpoints y cierralo.
- Si algo requiere permisos, login, claves, OAuth, compartir archivos o accion irreversible, reporta bloqueo.
- Trabaja en lotes ligeros y reanudables.

Tareas inmediatas:
1. Revisa en el repo `offload/README.md`, `offload/state/STATUS.md`, `offload/tasks/QUEUE.md`, `offload/scripts/` y `.github/workflows/offload-light-batch.yml`.
2. Confirma que entiendes la arquitectura: Drive = final nativo; GitHub/Codespaces = taller pesado; PC local = cabina de control.
3. Ejecuta o propone una prueba minima con `offload/sample_input` si tienes terminal disponible.
4. Reporta: estado, capacidades disponibles, bloqueos, siguiente lote recomendado, y que necesitas de Codex.
5. No crees documentos nuevos ni hagas cambios destructivos.

Responde en espanol, breve pero verificable.
```
