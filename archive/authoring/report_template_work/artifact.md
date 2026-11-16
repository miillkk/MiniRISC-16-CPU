# Template execution contract

## Reference

- Original retained source: `C:\Users\xieke\Downloads\0 ClassNo.TeamNo._202609XX.doc`.
- Read-only converted reference: `C:\Users\xieke\Desktop\CPU\deliverables\report_template_work\template_reference.docx`.
- Converted-reference SHA-256: `AEA0D9480EFC7CBCD8BFFB584D724FCE43722B1BA978BC077DE45F26DA7F80FD`.
- Reference pages: 12.
- Sections: 1.
- Visual evidence: `template-reference-render/page-01.png` through `page-12.png`.
- Structural evidence: `template-structure.json`, `template-style-evidence.json`, and `template-package-inventory.txt`.

## Page system

- Page size: A4 portrait, 8.268 × 11.69 in.
- Margins: left 0.95 in, right 0.95 in, top 1.02 in, bottom 0.79 in.
- Header distance and footer distance are retained from the reference section.
- First-page header/footer differs from later pages.
- Default header: project name at left and `UoG` at right.
- Default footer: centered PAGE field.
- Final content may increase page count because the supplied body contains placeholders only; page geometry and recurring header/footer remain unchanged.

## Typography and styles

- Body text follows the template's Times New Roman appearance, approximately 10.5 pt.
- `Title`: 16 pt bold source style, centered on cover.
- `Heading 1`: 15 pt bold.
- `Heading 2`: 10.5 pt bold.
- `Heading 3`: source-derived third-level heading pattern used for detailed subsections.
- `Caption`: 10 pt Arial source style, centered.
- Header/footer: 9 pt source styles.
- Headings remain black. Body text is black. Orange placeholder/example text is removed.

## Lists and tables

- Document-history table: four columns with Date, Version, Change, Editor.
- Abbreviation table: two columns with Abbreviation and Full Name.
- Team-information table: team name plus student number, name, task and score fields.
- Technical tables use visible thin borders, a gray header row and source-derived widths.
- Rows expand automatically; no fixed heights that can clip text.
- Tables repeat header rows when they span pages.

## Components and content flow

1. Cover page.
2. Document History.
3. Abbreviation.
4. Abstract and Key Words.
5. Contents.
6. Figures.
7. Tables.
8. Team information.
9. Specification.
10. Design and Implementation.
11. Verification and Test.
12. Conclusion and Future Work.
13. References.

The final report preserves this order. Contents, list of figures and list of tables use Word fields and are refreshed in Microsoft Word before delivery.

## Slot map

- Cover `XXXX`: replace with `MiniRISC-16 8-bit PC CPU`.
- Cover date/version: replace with `2026.11.05` and `1.0`.
- Header `XXXProject name`: replace with `MiniRISC-16 CPU`.
- Document history: replace example row and remove unused placeholder rows where practical.
- Abbreviations: replace SLAM example and fill CPU/ISA/RTL/FPGA/UART/PC/RAM/I/O/XSim.
- Abstract and keywords: describe the pre-board 16-bit single-cycle baseline with an 8-bit PC, 256 × 16 instruction ROM, 13 active opcodes, three reserved opcodes, and 8-bit GPIO.
- Contents/Figures/Tables: rebuild as Word fields and refresh.
- Team table: fill project/team label and technical task roles; student identities remain clearly marked for completion because they were not provided.
- Specification: replace both placeholder paragraphs.
- Design and Implementation: use only the pre-board 8-bit-PC CPU and generic GPIO boundary; do not introduce later Runtime, Loader, data-memory, or video branches.
- `xxx submodule` headings: replace with `CPU Core` and `Instruction Memory and GPIO`.
- Clock/Reset/Initial: describe the single-clock baseline, reset conditioner, PC/register/Z reset, and GPIO safe input state.
- Verification/Test: use the template headings `4.1 Test Plan & TestBench` and `4.2 TestCase & Result`; within each, separate `Simulation Verification` and `On-Board Verification`.
- Board-specific wrappers, constraints, implementation metrics, bitstream generation, and physical observations may appear only in Section 4.
- Conclusion/Future work: summarize and extend the pre-board baseline without redefining the report around the board wrapper.
- References: remove unrelated wireless-mesh citation and replace with project files and AMD Vivado documentation references.

## Figures

- Pre-board 8-bit-PC system architecture.
- Pre-board single-cycle CPU and GPIO dataflow.
- Four English Vivado-style XSim waveform figures from the six-test baseline regression.
- Images must remain readable, centered, proportionally scaled and captioned.

## Package preservation

- Preserve page settings, styles, numbering definitions, theme, header, footer, custom XML and relationships unless a content replacement requires a document-part change.
- `word/document.xml` is editable.
- `word/header1.xml` is editable only for the project-name replacement.
- `word/footer1.xml` and its PAGE field are preserve-only.
- Styles, numbering, theme, font table, custom XML, footnotes and endnotes are preserve-only.
- Baseline part inventory and hashes are recorded in `template-package-inventory.txt`.

## Fidelity gates

- Original `.doc` must remain unchanged.
- Final document must visibly retain the source cover, front-matter order, header/footer system, A4 geometry, Times New Roman report style and numbered section hierarchy.
- Every placeholder and unrelated example citation must be removed.
- All final pages must render without clipping, overlap, broken tables or missing glyphs.
- TOC, list of figures, list of tables, captions and page numbers must be refreshed in Word.
