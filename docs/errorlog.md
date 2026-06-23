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
| 2026-06-23 | T004(post-ship) | 클릭 시 소리 안 들림 (사용자 보고). logcat: 매 play마다 `requestAudioFocus(USAGE_MEDIA)` → 직후 `onAudioFocusChange(-1)`(AUDIOFOCUS_LOSS) 폭주 | Runtime (audio) | 1 | `AudioPlayersBackend`가 audioContext 미설정 → 각 play(다운/업 + 풀 4플레이어)가 미디어 오디오 포커스를 요청하며 서로 즉시 뺏어 ~100ms 클릭이 1ms 만에 끊김. T004 dev/QA가 "가청 여부 미검증"으로 정직히 플래그했던 갭. | 1st occ → normal fix: `AudioPool.create(audioContext: AudioContext(android: AudioContextAndroid(audioFocus: none, content/usage: sonification)))`. 포커스 요청 0 → 클립 겹쳐 재생, 사용자 BGM 비방해. logcat 재현으로 포커스 폭주 제거 확인(객관), **가청은 사용자 확인 대기**. 교훈: 오디오 가청은 자동 QA로 검증 불가 → 사용자/실기기 확인 단계 필요. | n/a |
