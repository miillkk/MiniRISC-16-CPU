import { PresentationFile, FileBlob } from "@oai/artifact-tool";
const target = process.argv[2];
const imported = await PresentationFile.importPptx(await FileBlob.load(target));
console.log(`${target}: slides=${imported.slides.items.length}`);
