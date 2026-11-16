import fs from "node:fs/promises";
import path from "node:path";
import { pathToFileURL } from "node:url";

const workspaceDir = "C:/Users/xieke/Desktop/CPU";
const buildDir = path.join(workspaceDir, ".codex-ppt-build/runtime-arcade-detailed-20261106");
const candidatePath = path.join(buildDir, "MiniRISC16_Runtime_三项目展示_详细版_draft.pptx");
const finalPath = path.join(workspaceDir, "deliverables/MiniRISC16_Runtime_三项目展示_详细版_v2.pptx");
const skillDir = "C:/Users/xieke/.codex/plugins/cache/openai-primary-runtime/presentations/26.1104.12130/skills/presentations";
const pythonExecutable = "C:/Program Files/WindowsApps/OpenAI.CodexPrimaryRuntime.v26-1104-1290-0_26.1104.1290.0_x64__3k8sg7r9htsxt/dependencies/python/python.exe";

const { finalizePresentation } = await import(pathToFileURL(
  path.join(skillDir, "container_tools/artifact_tool_utils.mjs"),
).href);

const stagingDir = path.join(buildDir, "finalizer");
await fs.mkdir(stagingDir, { recursive: true });
await fs.mkdir(path.dirname(finalPath), { recursive: true });

const result = await finalizePresentation({
  explicitTotalSlideCount: 11,
  requiredNativeTableOwnerSlides: [],
  requiredNativeChartOwnerSlides: [],
  workspaceDir,
  candidatePath,
  finalPath,
  pythonExecutable,
  integrityValidatorPath: path.join(skillDir, "container_tools/inspect_presentation_package_integrity.py"),
  layoutValidatorPath: path.join(skillDir, "container_tools/inspect_presentation_layout_geometry.py"),
  layoutArgs: [
    "--expected-slide-size-emu", "12192000,6858000",
    "--validate-bullet-geometry",
    "--validate-heading-fit",
  ],
  requiredNativeTableOwnerSlides: [],
  fontPolicy: { basis: "design", families: ["Arial"] },
  verifyArtifactToolImport: true,
  receiptPath: path.join(stagingDir, "MiniRISC16_Runtime_三项目展示_详细版_v2.validation.json"),
});

console.log(JSON.stringify({ finalPath, result }, null, 2));
