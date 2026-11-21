#!/usr/bin/env python3
"""버튼 효과음(assets/sfx/*.wav)을 만든다: python3 make-sfx.py <출력 폴더>"""
import math, struct, sys, wave
RATE = 44100
def tone(f0, f1, ms, decay=6.0, vol=0.35):
    n = int(RATE * ms / 1000); out = []; ph = 0.0
    for i in range(n):
        t = i / n
        ph += 2 * math.pi * (f0 + (f1 - f0) * t) / RATE
        env = math.exp(-decay * t) * min(1.0, i / (RATE * 0.003))   # 3 ms attack: no click at the start
        out.append(vol * env * (math.sin(ph) + 0.25 * math.sin(2 * ph)))
    return out
SOUNDS = {
    "tap":     tone(1500, 1250, 45, 7),
    "key":     tone(2400, 1500, 22, 9, 0.22),
    "open":    tone(660, 660, 70, 4) + tone(990, 990, 110, 5),
    "close":   tone(990, 990, 70, 4) + tone(660, 660, 110, 5),
    "send":    tone(520, 1250, 110, 3.5),
    "receive": tone(880, 880, 90, 3) + tone(1320, 1320, 260, 5),
    "volume":  tone(1175, 1175, 70, 4, 0.3) + tone(1568, 1568, 260, 5, 0.3),   # 음량 조절 "띠링"
    "error":   tone(330, 300, 120, 3) + tone(247, 220, 200, 4),
}
assert all(max(map(abs, s)) < 1 for s in SOUNDS.values())
for name, s in SOUNDS.items():
    with wave.open(f"{sys.argv[1]}/{name}.wav", "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(v * 32767)) for v in s))
