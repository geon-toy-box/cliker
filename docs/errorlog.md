---
project: cliker
created: 2026-06-22
tags: [toybox, errorlog]
---

# cliker — ErrorLog

> The factory's learning record. When the **same** error is hit **twice or
> more**, the cause is not the code — it is a gap in a skill or agent. The
> 2-strike rule (see the `toybox-errorlog` skill) then requires improving the
> skill/agent and running `/reload-skills`, so the factory gets better instead
> of repeating mistakes.
>
> An "error signature" is the stable, deduplicated essence of an error (the
> message minus paths/line-numbers/timestamps), so the same root cause is
> recognized across occurrences.

## How to read the count
- **1st occurrence**: log it, fix it normally.
- **2nd occurrence (2-strike)**: do NOT just patch again. Improve the responsible
  skill/agent so this class of error cannot recur, run `/reload-skills`, then
  retry with the improved version. Record what you changed.

## Log
| date | task | error signature | layer | count | root cause | fix / skill-or-agent improved | reloaded? |
|------|------|-----------------|-------|-------|------------|-------------------------------|-----------|
| 2026-06-22 | T004 | `soundpool …SoundpoolPlugin.kt: Unresolved reference 'Registrar'` → `:soundpool:compileDebugKotlin` failed | Build (apk) | 1 | soundpool 2.4.1 (latest, discontinued) uses the removed v1 Flutter Android embedding (`PluginRegistry.Registrar`/`registerWith`), incompatible with Flutter 3.41.7. No newer version to bump to. | 1st occurrence → normal fix: planner swaps audio package soundpool → **audioplayers** (`AudioPool`, low-latency). Dart already isolates the plugin behind `SoundBackend`, so only the backend impl + provider wiring change; tests unchanged. No skill change yet. | n/a |
