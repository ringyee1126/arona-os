# 받아쓴 표(data/<이름>.tsv)에서 학습 목록(data/<이름>.list)을 만든다: 너무 짧은 것(1초 미만)은 빼고 자주 틀리는 낱말을 고친다
import sys, pathlib
name = sys.argv[1]; fix = {"아루나": "아로나", "아르나": "아로나", "시팀": "싯딤", "C팀": "싯딤", "프라나": "프라나", "플라나": "프라나"}
rows = []
for l in pathlib.Path(f"data/{name}.tsv").read_text().splitlines():
    w, n, lang, text, dur = l.split("|")
    for a, b in fix.items(): text = text.replace(a, b)
    if 1.0 <= float(dur) <= 14 and text.strip(): rows.append((w, n, lang, text, float(dur)))
pathlib.Path(f"data/{name}.list").write_text("".join(f"{w}|{n}|{lang}|{t}\n" for w, n, lang, t, d in rows))
print(name, len(rows), "개", round(sum(r[4] for r in rows)), "초")
