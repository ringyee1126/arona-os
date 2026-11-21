#!/usr/bin/env python3
"""블루 아카이브 음성 묶음(.molru) 안의 Ogg 파일을 꺼낸다:  molru-extract.py X.molru 나올폴더
묶음은 [머리말][Ogg]... 이 이어진 것이라, Ogg 페이지를 따라가며 한 흐름(BOS~EOS)씩 잘라 낸다."""
import sys, pathlib
src, out = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
out.mkdir(parents=True, exist_ok=True)
d, i, n = src.read_bytes(), 0, 0
while (i := d.find(b"OggS\x00\x02", i)) >= 0:
    j = i
    while d[j:j + 4] == b"OggS":
        eos = d[j + 5] & 4
        nseg = d[j + 26]
        j += 27 + nseg + sum(d[j + 27:j + 27 + nseg])
        if eos: break
    n += 1
    (out / f"{src.stem}_{n:04d}.ogg").write_bytes(d[i:j])
    i = j
assert n, "Ogg 흐름을 찾지 못함"
print(src.name, n)
