import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';

const workspaceDir='C:/Users/xieke/Desktop/CPU';
const skillDir='C:/Users/xieke/.codex/plugins/cache/openai-primary-runtime/presentations/26.1111.10930/skills/presentations';
const source=path.join(workspaceDir,'deliverables/上板展示_三项目_9页图文版_v6.pptx');
const candidatePath=path.join(workspaceDir,'.codex-ppt-build/runtime-arcade-translate-20261112/On_Board_Demo_English_draft.pptx');
const finalPath=path.join(workspaceDir,'deliverables/On_Board_Demo_English_6_Slides_v1.pptx');
const stagingDir=path.join(workspaceDir,'.codex-ppt-build/runtime-arcade-translate-20261112/finalizer');
await fs.mkdir(stagingDir,{recursive:true});
const referenceSha256=crypto.createHash('sha256').update(await fs.readFile(source)).digest('hex');
const {finalizePresentation}=await import(pathToFileURL(path.join(skillDir,'container_tools/artifact_tool_utils.mjs')).href);
const result=await finalizePresentation({
  workspaceDir,
  candidatePath,
  finalPath,
  pythonExecutable:'C:/Program Files/WindowsApps/OpenAI.CodexPrimaryRuntime.v26-1111-570-0_26.1111.570.0_x64__3k8sg7r9htsxt/dependencies/python/python.exe',
  integrityValidatorPath:path.join(skillDir,'container_tools/inspect_presentation_package_integrity.py'),
  layoutValidatorPath:path.join(skillDir,'container_tools/inspect_presentation_layout_geometry.py'),
  layoutArgs:['--expected-slide-size-emu','12192000,6858000','--validate-bullet-geometry','--validate-heading-fit'],
  explicitTotalSlideCount:6,
  requiredNativeTableOwnerSlides:[],
  requiredNativeChartOwnerSlides:[],
  fontPolicy:{basis:'reference',families:['Arial'],referencePath:source,referenceSha256},
  verifyArtifactToolImport:true,
  receiptPath:path.join(stagingDir,'On_Board_Demo_English_6_Slides_v1.pptx.validation.json'),
});
console.log(JSON.stringify(result));
