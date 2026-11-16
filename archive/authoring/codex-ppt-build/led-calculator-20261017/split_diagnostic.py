from pathlib import Path
from pptx import Presentation

src = Path(__file__).with_name("draft.pptx")
out = Path(__file__).with_name("split")
out.mkdir(exist_ok=True)

for keep in range(8):
    prs = Presentation(src)
    ids = list(prs.slides._sldIdLst)
    for index, slide_id in reversed(list(enumerate(ids))):
        if index != keep:
            rel_id = slide_id.rId
            prs.part.drop_rel(rel_id)
            prs.slides._sldIdLst.remove(slide_id)
    prs.save(out / f"slide-{keep + 1:02d}.pptx")
