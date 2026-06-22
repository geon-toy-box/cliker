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

설계:
    각 클립 = 짧은 노이즈 트랜지언트(클릭) × 빠른 지수 감쇠 엔벨로프
             + 감쇠 사인파 "바디" 공명(들).
    스위치별 파라미터로 음색을 구분한다:
        blue  = 밝고 날카로운 더블 틱(클릭),
        brown = 중역 텍타일 "톡",
        red   = 조용한 리니어,
        black = 저역 묵직.
    down은 up보다 약간 크고 낮게, 릴리스(up)는 더 짧고 높게 만든다.

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


class Buffer:
    """가산 합성을 위한 부동소수 모노 샘플 버퍼."""

    def __init__(self, duration_s):
        self.length = int(round(SAMPLE_RATE * duration_s))
        self.data = [0.0] * self.length

    def add_noise_transient(self, rng, amp, decay_s, start_s=0.0):
        """지수 감쇠 엔벨로프를 가진 화이트 노이즈 버스트(클릭)를 더한다."""
        start = int(round(start_s * SAMPLE_RATE))
        decay_samples = max(1.0, decay_s * SAMPLE_RATE)
        for i in range(start, self.length):
            env = math.exp(-(i - start) / decay_samples)
            if env < 1e-4:
                break
            self.data[i] += amp * env * (rng.random() * 2.0 - 1.0)

    def add_sine_body(self, freq, amp, decay_s, start_s=0.0):
        """감쇠 사인파 공명("바디")을 더한다."""
        start = int(round(start_s * SAMPLE_RATE))
        decay_samples = max(1.0, decay_s * SAMPLE_RATE)
        two_pi_f = 2.0 * math.pi * freq
        for i in range(start, self.length):
            n = i - start
            env = math.exp(-n / decay_samples)
            if env < 1e-4:
                break
            self.data[i] += amp * env * math.sin(two_pi_f * n / SAMPLE_RATE)

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
#   duration       : 클립 길이(초). down/up 각각.
#   peak           : 정규화 목표 진폭(0–1). down이 up보다 크다.
#   clicks         : (시작시각s, 노이즈진폭, 노이즈감쇠s) 트랜지언트 목록.
#   bodies         : (주파수Hz, 진폭, 감쇠s, 시작시각s) 사인 바디 공명 목록.
# down은 약간 길고/낮고/크게, up은 짧고/높고/작게.
SWITCH_PARAMS = {
    "blue": {
        # 밝고 날카로운 더블 틱: 두 번의 노이즈 클릭 + 고역 바디.
        "down": {
            "duration": 0.110,
            "peak": 0.92,
            "clicks": [
                (0.000, 1.0, 0.0016),
                (0.012, 0.7, 0.0012),
            ],
            "bodies": [
                (2600.0, 0.30, 0.020, 0.000),
                (4200.0, 0.18, 0.012, 0.012),
            ],
        },
        "up": {
            "duration": 0.075,
            "peak": 0.70,
            "clicks": [
                (0.000, 0.85, 0.0011),
                (0.009, 0.55, 0.0009),
            ],
            "bodies": [
                (3200.0, 0.22, 0.013, 0.000),
                (5000.0, 0.14, 0.009, 0.009),
            ],
        },
    },
    "brown": {
        # 중역 텍타일 "톡": 단일 클릭 + 중역 바디.
        "down": {
            "duration": 0.120,
            "peak": 0.85,
            "clicks": [
                (0.000, 0.85, 0.0028),
            ],
            "bodies": [
                (900.0, 0.45, 0.038, 0.000),
                (1500.0, 0.22, 0.022, 0.000),
            ],
        },
        "up": {
            "duration": 0.080,
            "peak": 0.62,
            "clicks": [
                (0.000, 0.70, 0.0020),
            ],
            "bodies": [
                (1200.0, 0.34, 0.022, 0.000),
                (1900.0, 0.16, 0.014, 0.000),
            ],
        },
    },
    "red": {
        # 조용한 리니어: 부드러운 트랜지언트, 차분한 중역 바디.
        "down": {
            "duration": 0.105,
            "peak": 0.62,
            "clicks": [
                (0.000, 0.55, 0.0040),
            ],
            "bodies": [
                (820.0, 0.40, 0.034, 0.000),
                (1300.0, 0.16, 0.020, 0.000),
            ],
        },
        "up": {
            "duration": 0.070,
            "peak": 0.46,
            "clicks": [
                (0.000, 0.45, 0.0030),
            ],
            "bodies": [
                (1050.0, 0.30, 0.020, 0.000),
                (1600.0, 0.12, 0.013, 0.000),
            ],
        },
    },
    "black": {
        # 저역 묵직 리니어: 길고 부드러운 트랜지언트, 저역 바디 강조.
        "down": {
            "duration": 0.155,
            "peak": 0.80,
            "clicks": [
                (0.000, 0.65, 0.0055),
            ],
            "bodies": [
                (520.0, 0.55, 0.055, 0.000),
                (820.0, 0.20, 0.030, 0.000),
            ],
        },
        "up": {
            "duration": 0.095,
            "peak": 0.58,
            "clicks": [
                (0.000, 0.55, 0.0040),
            ],
            "bodies": [
                (680.0, 0.42, 0.030, 0.000),
                (1050.0, 0.16, 0.018, 0.000),
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
    for start_s, amp, decay_s in spec["clicks"]:
        buf.add_noise_transient(rng, amp, decay_s, start_s)
    for freq, amp, decay_s, start_s in spec["bodies"]:
        buf.add_sine_body(freq, amp, decay_s, start_s)
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
