from __future__ import annotations

import re
import sys
import zipfile
from pathlib import Path

from docx import Document


def summarize(path: Path) -> None:
    doc = Document(path)
    paragraphs = [p for p in doc.paragraphs if p.text.strip()]
    headings = [
        (p.style.name if p.style else "", p.text.strip())
        for p in paragraphs
        if p.style and ("Heading" in p.style.name or p.style.name in {"Title", "Subtitle"})
    ]
    text = "\n".join(p.text for p in paragraphs)
    with zipfile.ZipFile(path) as zf:
        names = zf.namelist()
        images = [n for n in names if n.startswith("word/media/")]
        comments = [n for n in names if n == "word/comments.xml"]
        tracked = 0
        for name in names:
            if name.startswith("word/") and name.endswith(".xml"):
                data = zf.read(name)
                tracked += data.count(b"<w:ins") + data.count(b"<w:del")
    print(f"\n=== {path.name} ===")
    print(f"paragraphs={len(paragraphs)} tables={len(doc.tables)} images={len(images)} sections={len(doc.sections)} comments={bool(comments)} tracked_markers={tracked}")
    print(f"characters={len(text)} approx_words={len(re.findall(r'\\b\\w+\\b', text))}")
    print("HEADINGS")
    for style, heading in headings:
        print(f"  [{style}] {heading}")
    print("TABLES")
    for idx, table in enumerate(doc.tables, 1):
        rows = []
        for row in table.rows[:3]:
            rows.append(" | ".join(" ".join(cell.text.split()) for cell in row.cells))
        print(f"  T{idx}: {len(table.rows)}x{len(table.columns)} :: " + " || ".join(rows))
    markers = [
        "Verification & Test", "Test Plan & TestBench", "TestCase & Result",
        "Simulation Verification", "On-Board Verification", "8-bit PC", "10-bit PC",
        "UART", "Snake", "2048", "PASS by team feedback", "Failures: 0",
    ]
    print("MARKERS")
    for marker in markers:
        print(f"  {marker!r}: {text.lower().count(marker.lower())}")


if __name__ == "__main__":
    for arg in sys.argv[1:]:
        summarize(Path(arg))
