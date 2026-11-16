import fs from 'node:fs/promises';
import path from 'node:path';
import {pathToFileURL} from 'node:url';

const workspaceDir='C:/Users/xieke/Desktop/CPU';
const buildDir=path.join(workspaceDir,'.codex-ppt-build/runtime-arcade-talk-20261110');
const skillDir='C:/Users/xieke/.codex/plugins/cache/openai-primary-runtime/presentations/26.1105.12137/skills/presentations';
const candidatePath=path.join(buildDir,'上板展示_10分钟讲解_draft.pptx');
const finalPath=path.join(workspaceDir,'deliverables/上板展示_三项目_9页图文版_v6.pptx');
const pythonExecutable='C:/Program Files/WindowsApps/OpenAI.CodexPrimaryRuntime.v26-1105-1297-0_26.1105.1297.0_x64__3k8sg7r9htsxt/dependencies/python/python.exe';
const {finalizePresentation}=await import(pathToFileURL(path.join(skillDir,'container_tools/artifact_tool_utils.mjs')).href);
const stagingDir=path.join(buildDir,'finalizer');
await fs.mkdir(stagingDir,{recursive:true});
await fs.mkdir(path.dirname(finalPath),{recursive:true});
const result=await finalizePresentation({
  explicitTotalSlideCount:9,
  requiredNativeTableOwnerSlides:[],
  requiredNativeChartOwnerSlides:[],
  workspaceDir,candidatePath,finalPath,pythonExecutable,
  integrityValidatorPath:path.join(skillDir,'container_tools/inspect_presentation_package_integrity.py'),
  layoutValidatorPath:path.join(skillDir,'container_tools/inspect_presentation_layout_geometry.py'),
  layoutArgs:['--expected-slide-size-emu','12192000,6858000','--validate-bullet-geometry','--validate-heading-fit'],
  fontPolicy:{basis:'design',families:['Arial']},
  verifyArtifactToolImport:true,
  receiptPath:path.join(stagingDir,'上板展示_三项目_9页图文版_v6.validation.json'),
});
console.log(JSON.stringify({finalPath,sha256:result.finalSha256,slideCount:result.packageIntegrity.slide_count,findings:result.presentationLayout.finding_count},null,2));
