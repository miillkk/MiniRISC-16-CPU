import fs from "node:fs/promises";
import { Presentation, PresentationFile, FileBlob } from "@oai/artifact-tool";

const p = Presentation.create({ slideSize: { width: 1280, height: 720 } });
const s = p.slides.add();
const t = s.shapes.add({
  geometry: "textbox",
  position: { left: 50, top: 50, width: 400, height: 80 },
  fill: "none",
  line: { style: "solid", fill: "none", width: 0 },
});
t.text = "测试 MiniRISC-16";
t.text.style = { fontSize: 32, typeface: "Microsoft YaHei", color: "#000000", bold: true, lineSpacing: 0.95, autoFit: "shrinkText", alignment: "center", verticalAlignment: "middle" };
const a = s.shapes.add({ geometry: "rightArrow", position: { left: 500, top: 50, width: 80, height: 40 }, fill: "#123456", line: { style: "solid", fill: "none", width: 0 } });
const r = s.shapes.add({ geometry: "roundRect", position: { left: 600, top: 50, width: 120, height: 80 }, fill: "#123456", line: { style: "solid", fill: "#FF0000", width: 2 }, borderRadius: "rounded-xl" });
const ib = await fs.readFile("C:\\Users\\xieke\\Desktop\\CPU\\MiniRISC-16-CPU\\reports\\waveforms\\01_single_cycle_commit.png");
s.images.add({ blob: ib.buffer.slice(ib.byteOffset, ib.byteOffset + ib.byteLength), contentType: "image/png", alt: "wave", fit: "contain", position: { left: 50, top: 180, width: 500, height: 300 } });
await (await PresentationFile.exportPptx(p)).save("tiny.pptx");
const imported = await PresentationFile.importPptx(await FileBlob.load("tiny.pptx"));
console.log(`slides=${imported.slides.items.length}`);
