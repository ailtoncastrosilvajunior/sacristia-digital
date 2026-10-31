#!/usr/bin/env python3
"""Extrai parágrafos 1–399 da IGMR CNBB (PDF) para db/fixtures/igmr_paragrafos_cnbb_2002.json."""
import json
import re
import sys
from pathlib import Path

try:
    from pypdf import PdfReader
except ImportError:
    sys.exit("Instale pypdf no venv: python3 -m venv .venv-pdf && .venv-pdf/bin/pip install pypdf")

ROOT = Path(__file__).resolve().parents[1]
PDF = ROOT / "db/fixtures/igmr_cnbb_2002.pdf"
OUT = ROOT / "db/fixtures/igmr_paragrafos_cnbb_2002.json"
EDICAO = "IGMR — tradução oficial CNBB (Brasil)"
FONTE = "db/fixtures/igmr_cnbb_2002.pdf (separata 3ª ed. típica, Roma 2002)"


def clean(txt: str) -> str:
    txt = re.sub(r"\s*\n\s*", " ", txt)
    txt = re.sub(r"www\.pastoraldacrisma\.com\.br\s*\d*", " ", txt, flags=re.I)
    return re.sub(r"  +", " ", txt).strip()


def main() -> None:
    text = "\n".join((p.extract_text() or "") for p in PdfReader(PDF).pages)
    start = text.find("1. Quando Cristo Senhor")
    if start < 0:
        sys.exit("Marcador do parágrafo 1 não encontrado no PDF")
    parts = re.split(r"\n(?=\d+\.)", text[start:])
    rows = []
    for part in parts:
        m = re.match(r"^(\d+)\.\s*(.*)", part.strip(), re.DOTALL)
        if not m:
            continue
        num = int(m.group(1))
        if 1 <= num <= 399:
            rows.append({"numero": num, "texto": clean(m.group(2)), "edicao": EDICAO, "fonte": FONTE})
    rows.sort(key=lambda r: r["numero"])
    if len(rows) != 399:
        sys.exit(f"Esperados 399 parágrafos, obtidos {len(rows)}")
    OUT.write_text(json.dumps(rows, ensure_ascii=False, indent=0), encoding="utf-8")
    print(f"OK: {len(rows)} parágrafos → {OUT}")


if __name__ == "__main__":
    main()
