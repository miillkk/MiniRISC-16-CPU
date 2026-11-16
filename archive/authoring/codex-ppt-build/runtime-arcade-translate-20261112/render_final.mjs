import fs from 'node:fs/promises';
import path from 'node:path';
import {FileBlob,PresentationFile} from 'file:///C:/Program%20Files/WindowsApps/OpenAI.CodexPrimaryRuntime.v26-1111-570-0_26.1111.570.0_x64__3k8sg7r9htsxt/dependencies/node/node_modules/@oai/artifact-tool/dist/artifact_tool.mjs';
const file='C:/Users/xieke/Desktop/CPU/deliverables/On_Board_Demo_English_6_Slides_v1.pptx';
const dir='C:/Users/xieke/Desktop/CPU/.codex-ppt-build/runtime-arcade-translate-20261112/final_preview';
await fs.mkdir(dir,{recursive:true});
const p=await PresentationFile.importPptx(await FileBlob.load(file));
for(let i=0;i<p.slides.items.length;i++){
 const b=await p.export({slide:p.slides.items[i],format:'png',scale:1});
 await fs.writeFile(path.join(dir,`slide_${i+1}.png`),new Uint8Array(await b.arrayBuffer()));
}
console.log(JSON.stringify({slides:p.slides.items.length,dir}));
