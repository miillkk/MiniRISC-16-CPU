import fs from 'node:fs/promises';
import {FileBlob,PresentationFile} from 'file:///C:/Program%20Files/WindowsApps/OpenAI.CodexPrimaryRuntime.v26-1111-570-0_26.1111.570.0_x64__3k8sg7r9htsxt/dependencies/node/node_modules/@oai/artifact-tool/dist/artifact_tool.mjs';
const source='C:/Users/xieke/Desktop/CPU/deliverables/上板展示_三项目_9页图文版_v6.pptx';
const out='C:/Users/xieke/Desktop/CPU/.codex-ppt-build/runtime-arcade-translate-20261112';
await fs.mkdir(out,{recursive:true});
const p=await PresentationFile.importPptx(await FileBlob.load(source));
const r=await p.inspect({select:'$.slides[*]',include:['id','index','elements.id','elements.kind','elements.text','elements.position','notes.text']});
await fs.writeFile(`${out}/content.ndjson`,r.ndjson);
for(let i=0;i<p.slides.items.length;i++){
 const b=await p.export({slide:p.slides.items[i],format:'png',scale:1});
 await fs.writeFile(`${out}/source_${i+1}.png`,new Uint8Array(await b.arrayBuffer()));
}
console.log(JSON.stringify({slides:p.slides.items.length,records:r.recordCount,path:`${out}/content.ndjson`}));
