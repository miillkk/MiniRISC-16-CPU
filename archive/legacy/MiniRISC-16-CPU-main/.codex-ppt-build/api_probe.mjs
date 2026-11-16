import { Presentation } from "@oai/artifact-tool";

const presentation = Presentation.create({ slideSize: { width: 1280, height: 720 } });
const result = presentation.help("*", {
  search: "slide.delete|slides.delete|shape.delete|slides.remove|slide.remove|presentation.slides",
  include: ["index", "examples", "notes"],
  maxChars: 12000,
});
console.log(result.ndjson);
