#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""스위치 타건음 합성기 (deterministic / 표준 라이브러리 전용).

cliker는 외부 음원을 받지 않고 이 스크립트로 모든 타건음을 *합성*해서 번들한다.
저작권/라이선스 리스크를 피하기 위함이며, 고정 시드를 사용하므로 재실행해도
바이트 단위로 동일한 WAV가 나온다.

재생성 방법:
    python3 tools/gen_sounds.py

출력:
    assets/sounds/<id>_down.wav, <id>_up.wav  (id ∈ {blue, brown, red, black})
형식:
    44100 Hz, mono, 16-bit PCM, 60–160 ms.

설계 (실제 기계식 스위치 음에 가깝게):
    실제 타건음 = 스템/하우징이 부딪치는 "딱/탁" 임팩트(광대역, 매우 짧음)
                 + 키캡·하우징·플레이트가 울리는 공명 모드(짧게 감쇠하는 사인 다발)
                 + (다운스트로크 바텀아웃의) 저역 "톡" 무게.
    이를 모델링한다:
        add_impact : 한쪽 극(밝게=하이패스 / 어둡게=로우패스)으로 색을 입힌
                     노이즈 버스트 + 초고속 지수 감쇠 → "딱/탁" 어택.
        add_modes  : 여러 개의 짧게 감쇠하는 사인 = 플라스틱 공명 색(단일 톤 '삐'가
                     아니라 '탁'의 음색). 저역 모드 하나가 바텀아웃 무게가 된다.
    스위치 캐릭터:
        blue  = 밝은 임팩트 + 별도의 날카로운 클릭자켓 "click" 스냅(고역),
        brown = 중역 텍타일 "톡",
        red   = 조용하고 부드러운 리니어(살짝 어둡게),
        black = 묵직·저역 강조 리니어.
    down(바텀아웃)은 길고/낮고/크게, up(탑아웃/릴리스)은 짧고/높고/작게.

표준 라이브러리만 사용한다: wave, struct, math, random, os. (numpy/서드파티 금지)
"""

import math
import os
import random
import struct
import wave

SAMPLE_RATE = 44100
SAMPLE_MAX = 32767  # 16-bit signed PCM peak.

# 모든 무작위성의 단일 시드. 이 값과 생성 순서가 고정인 한 출력은 결정적이다.
RANDOM_SEED = 20260622

# 출력 경로: 이 스크립트(tools/) 기준 상위의 assets/sounds.
_THIS_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_DIR = os.path.normpath(os.path.join(_THIS_DIR, "..", "assets", "sounds"))


def _one_pole_lowpass(samples, a):
    """단순 1-pole 로우패스. a∈(0,1)이 클수록 컷오프가 높다(덜 어둡다)."""
    y = 0.0
    out = [0.0] * len(samples)
    for i, x in enumerate(samples):
        y += a * (x - y)
        out[i] = y
    return out


class Buffer:
    """가산 합성을 위한 부동소수 모노 샘플 버퍼."""

    def __init__(self, duration_s):
        self.length = int(round(SAMPLE_RATE * duration_s))
        self.data = [0.0] * self.length

    def add_impact(self, rng, amp, decay_s, tone, start_s=0.0):
        """색을 입힌 노이즈 버스트(스템/하우징 충돌 "딱/탁")를 더한다.

        tone: 'bright' = 하이패스(밝고 날카롭게), 'dark' = 로우패스(둔탁하게),
              'mid' = 약한 하이패스(중역 위주). decay_s는 매우 짧게(1–6 ms) 줘서
        지속음이 아닌 어택으로 들리게 한다.
        """
        start = int(round(start_s * SAMPLE_RATE))
        if start >= self.length:
            return
        decay = max(1.0, decay_s * SAMPLE_RATE)
        n_len = min(self.length - start, int(decay * 8) + 1)
        noise = [rng.random() * 2.0 - 1.0 for _ in range(n_len)]
        if tone == "bright":
            lp = _one_pole_lowpass(noise, 0.55)
            noise = [n - l for n, l in zip(noise, lp)]  # 하이패스 = 원본-로우패스
        elif tone == "dark":
            noise = _one_pole_lowpass(noise, 0.20)
        elif tone == "mid":
            lp = _one_pole_lowpass(noise, 0.65)
            noise = [n - 0.5 * l for n, l in zip(noise, lp)]
        for i in range(n_len):
            env = math.exp(-i / decay)
            if env < 1e-4:
                break
            self.data[start + i] += amp * env * noise[i]

    def add_modes(self, modes, start_s=0.0):
        """공명 모드(짧게 감쇠하는 사인 다발)를 더한다 — 플라스틱 "탁"의 음색.

        modes: (freq_hz, amp, decay_s) 목록. 임팩트가 t=start에서 모드들을 동시
        여기(excite)시키므로 위상 0에서 시작한다(무작위성 미사용 → 결정성 단순).
        """
        start = int(round(start_s * SAMPLE_RATE))
        for freq, amp, decay_s in modes:
            decay = max(1.0, decay_s * SAMPLE_RATE)
            w = 2.0 * math.pi * freq / SAMPLE_RATE
            for i in range(start, self.length):
                n = i - start
                env = math.exp(-n / decay)
                if env < 1e-4:
                    break
                self.data[i] += amp * env * math.sin(w * n)

    def normalize(self, peak):
        """버퍼를 [-peak, peak]로 스케일한다(클리핑 없이 헤드룸 확보)."""
        current = max((abs(s) for s in self.data), default=0.0)
        if current <= 0.0:
            return
        scale = peak / current
        for i in range(self.length):
            self.data[i] *= scale

    def to_pcm16(self):
        """소프트 리미터를 거쳐 16-bit signed little-endian 바이트로 변환한다."""
        frames = bytearray()
        for s in self.data:
            # tanh 소프트 리밋으로 하드 클립의 거친 잡음을 막는다.
            limited = math.tanh(s)
            value = int(round(limited * SAMPLE_MAX))
            if value > SAMPLE_MAX:
                value = SAMPLE_MAX
            elif value < -SAMPLE_MAX - 1:
                value = -SAMPLE_MAX - 1
            frames += struct.pack("<h", value)
        return bytes(frames)


# 스위치별 합성 파라미터.
#   duration : 클립 길이(초).
#   peak     : 정규화 목표 진폭(0–1). down이 up보다 크다.
#   impacts  : (시작s, 진폭, 감쇠s, tone) 노이즈 임팩트 목록 — "딱/탁" 어택.
#   modes    : (주파수Hz, 진폭, 감쇠s) 공명 모드 목록 — 첫 항목(저역)이 바텀아웃 무게.
SWITCH_PARAMS = {
    "blue": {
        # 밝은 임팩트 + 별도의 날카로운 클릭자켓 스냅(고역) → 또렷한 "딸깍".
        "down": {
            "duration": 0.100,
            "peak": 0.95,
            "impacts": [
                (0.0000, 1.00, 0.0018, "bright"),
                (0.0060, 0.85, 0.0011, "bright"),  # 클릭자켓 스냅
            ],
            "modes": [
                (720.0, 0.10, 0.018),
                (1850.0, 0.12, 0.011),
                (2900.0, 0.10, 0.009),
                (4300.0, 0.06, 0.006),
            ],
        },
        "up": {
            "duration": 0.072,
            "peak": 0.66,
            "impacts": [
                (0.0000, 0.80, 0.0013, "bright"),
                (0.0050, 0.55, 0.0009, "bright"),
            ],
            "modes": [
                (1000.0, 0.08, 0.012),
                (3200.0, 0.10, 0.008),
                (4800.0, 0.06, 0.006),
            ],
        },
    },
    "brown": {
        # 중역 텍타일 "톡": 밝지 않은 임팩트 + 중역 모드 + 가벼운 저역 무게.
        "down": {
            "duration": 0.112,
            "peak": 0.86,
            "impacts": [
                (0.0000, 0.90, 0.0035, "mid"),
            ],
            "modes": [
                (190.0, 0.12, 0.026),
                (520.0, 0.16, 0.024),
                (980.0, 0.11, 0.016),
                (1700.0, 0.06, 0.011),
            ],
        },
        "up": {
            "duration": 0.076,
            "peak": 0.58,
            "impacts": [
                (0.0000, 0.70, 0.0026, "mid"),
            ],
            "modes": [
                (640.0, 0.13, 0.016),
                (1200.0, 0.09, 0.011),
                (2100.0, 0.05, 0.008),
            ],
        },
    },
    "red": {
        # 조용하고 부드러운 리니어(살짝 어둡게): 둔한 임팩트 + 차분한 저·중역 모드.
        "down": {
            "duration": 0.100,
            "peak": 0.60,
            "impacts": [
                (0.0000, 0.70, 0.0042, "dark"),
            ],
            "modes": [
                (160.0, 0.10, 0.022),
                (470.0, 0.14, 0.020),
                (820.0, 0.07, 0.013),
            ],
        },
        "up": {
            "duration": 0.064,
            "peak": 0.42,
            "impacts": [
                (0.0000, 0.55, 0.0032, "dark"),
            ],
            "modes": [
                (560.0, 0.11, 0.013),
                (1000.0, 0.06, 0.009),
            ],
        },
    },
    "black": {
        # 묵직·저역 강조 리니어: 둔하고 긴 임팩트 + 강한 저역 무게.
        "down": {
            "duration": 0.132,
            "peak": 0.82,
            "impacts": [
                (0.0000, 0.78, 0.0058, "dark"),
            ],
            "modes": [
                (110.0, 0.20, 0.046),
                (360.0, 0.15, 0.028),
                (640.0, 0.08, 0.017),
            ],
        },
        "up": {
            "duration": 0.086,
            "peak": 0.56,
            "impacts": [
                (0.0000, 0.62, 0.0040, "dark"),
            ],
            "modes": [
                (420.0, 0.14, 0.020),
                (760.0, 0.07, 0.013),
            ],
        },
    },
}

# 생성 순서: 카탈로그와 동일(blue, brown, red, black), 각 스위치는 down→up.
# 이 순서는 결정성을 위해 고정이다.
SWITCH_ORDER = ["blue", "brown", "red", "black"]
PHASE_ORDER = ["down", "up"]


def synthesize(rng, spec):
    """파라미터 한 세트로 단일 클립을 합성하고 PCM16 바이트를 반환한다."""
    buf = Buffer(spec["duration"])
    for start_s, amp, decay_s, tone in spec["impacts"]:
        buf.add_impact(rng, amp, decay_s, tone, start_s)
    buf.add_modes(spec["modes"])
    buf.normalize(spec["peak"])
    return buf.to_pcm16()


def write_wav(path, pcm_bytes):
    """모노 16-bit PCM 바이트를 표준 WAV 파일로 쓴다."""
    with wave.open(path, "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)  # 16-bit.
        wav.setframerate(SAMPLE_RATE)
        wav.writeframes(pcm_bytes)


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    # 단일 RNG를 한 번만 시드한다. 생성 순서가 고정이므로 출력은 결정적이다.
    rng = random.Random(RANDOM_SEED)
    written = []
    for switch_id in SWITCH_ORDER:
        for phase in PHASE_ORDER:
            spec = SWITCH_PARAMS[switch_id][phase]
            pcm = synthesize(rng, spec)
            filename = "{0}_{1}.wav".format(switch_id, phase)
            path = os.path.join(OUTPUT_DIR, filename)
            write_wav(path, pcm)
            size = os.path.getsize(path)
            written.append((filename, size))
            print("wrote {0} ({1} bytes)".format(path, size))
    print("done: {0} files in {1}".format(len(written), OUTPUT_DIR))


if __name__ == "__main__":
    main()
