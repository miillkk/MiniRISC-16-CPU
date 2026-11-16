from __future__ import annotations

import io
import posixpath
import sys
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET

from PIL import Image


P_NS = "http://schemas.openxmlformats.org/presentationml/2006/main"
A_NS = "http://schemas.openxmlformats.org/drawingml/2006/main"
R_NS = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
PKG_REL_NS = "http://schemas.openxmlformats.org/package/2006/relationships"


def inspect(path: Path) -> None:
    with zipfile.ZipFile(path) as zf:
        names = set(zf.namelist())
        slide_names = sorted(
            (n for n in names if n.startswith("ppt/slides/slide") and n.endswith(".xml")),
            key=lambda n: int(Path(n).stem.replace("slide", "")),
        )
        print(f"FILE: {path}")
        print(f"SLIDES: {len(slide_names)}")
        for slide_name in slide_names:
            slide_no = int(Path(slide_name).stem.replace("slide", ""))
            root = ET.fromstring(zf.read(slide_name))
            texts = [node.text or "" for node in root.findall(f".//{{{A_NS}}}t")]
            rel_name = f"ppt/slides/_rels/slide{slide_no}.xml.rels"
            media = []
            if rel_name in names:
                rel_root = ET.fromstring(zf.read(rel_name))
                for rel in rel_root.findall(f"{{{PKG_REL_NS}}}Relationship"):
                    target = rel.attrib.get("Target", "")
                    if "../media/" in target:
                        normalized = posixpath.normpath(posixpath.join("ppt/slides", target))
                        media.append(normalized)
            print(f"\nSLIDE {slide_no}")
            print("TEXT:", " | ".join(t.strip() for t in texts if t.strip()))
            print("MEDIA:", ", ".join(media) if media else "none")

        print("\nMEDIA INVENTORY")
        for name in sorted(n for n in names if n.startswith("ppt/media/")):
            data = zf.read(name)
            dims = "unknown"
            try:
                with Image.open(io.BytesIO(data)) as im:
                    dims = f"{im.width}x{im.height} {im.mode}"
            except Exception:
                pass
            print(f"{name}: {len(data)} bytes, {dims}")


if __name__ == "__main__":
    for arg in sys.argv[1:]:
        inspect(Path(arg))
