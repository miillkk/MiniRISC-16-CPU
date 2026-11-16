import json
import sys
from pathlib import Path

from docx import Document
from docx.oxml.ns import qn


def para_record(p, index):
    ppr = p._p.pPr
    page_break_before = bool(ppr is not None and ppr.find(qn("w:pageBreakBefore")) is not None)
    keep_next = bool(ppr is not None and ppr.find(qn("w:keepNext")) is not None)
    runs = []
    for r in p.runs:
        runs.append({
            "text": r.text,
            "bold": r.bold,
            "italic": r.italic,
            "size_pt": r.font.size.pt if r.font.size else None,
            "font": r.font.name,
            "color": str(r.font.color.rgb) if r.font.color and r.font.color.rgb else None,
        })
    return {
        "index": index,
        "text": p.text,
        "style": p.style.name if p.style else None,
        "alignment": str(p.alignment) if p.alignment is not None else None,
        "page_break_before": page_break_before,
        "keep_next": keep_next,
        "runs": runs,
    }


def table_record(table, index):
    return {
        "index": index,
        "rows": len(table.rows),
        "cols": len(table.columns),
        "style": table.style.name if table.style else None,
        "cells": [[cell.text for cell in row.cells] for row in table.rows],
        "grid_twips": [int(col.get(qn("w:w"))) for col in table._tbl.tblGrid.gridCol_lst],
    }


def main():
    source = Path(sys.argv[1])
    output = Path(sys.argv[2])
    doc = Document(source)
    data = {
        "source": str(source),
        "paragraphs": [para_record(p, i) for i, p in enumerate(doc.paragraphs)],
        "tables": [table_record(t, i) for i, t in enumerate(doc.tables)],
        "sections": [],
        "headers": [],
        "footers": [],
        "styles": [],
    }
    for i, section in enumerate(doc.sections):
        data["sections"].append({
            "index": i,
            "width_in": section.page_width.inches,
            "height_in": section.page_height.inches,
            "top_in": section.top_margin.inches,
            "bottom_in": section.bottom_margin.inches,
            "left_in": section.left_margin.inches,
            "right_in": section.right_margin.inches,
            "header_in": section.header_distance.inches,
            "footer_in": section.footer_distance.inches,
            "different_first_page": section.different_first_page_header_footer,
        })
        data["headers"].append({
            "index": i,
            "default": [para_record(p, j) for j, p in enumerate(section.header.paragraphs)],
            "first": [para_record(p, j) for j, p in enumerate(section.first_page_header.paragraphs)],
        })
        data["footers"].append({
            "index": i,
            "default": [para_record(p, j) for j, p in enumerate(section.footer.paragraphs)],
            "first": [para_record(p, j) for j, p in enumerate(section.first_page_footer.paragraphs)],
        })
    for style in doc.styles:
        if style.type == 1:
            data["styles"].append({
                "name": style.name,
                "font": style.font.name,
                "size_pt": style.font.size.pt if style.font.size else None,
                "bold": style.font.bold,
                "italic": style.font.italic,
            })
    output.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
