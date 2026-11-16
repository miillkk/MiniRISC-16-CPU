from pathlib import Path

from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.table import WD_CELL_VERTICAL_ALIGNMENT, WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK, WD_LINE_SPACING, WD_TAB_ALIGNMENT, WD_TAB_LEADER
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor


ROOT = Path(r"C:\Users\xieke\Desktop\CPU")
WORK = ROOT / "deliverables" / "report_template_work"
TEMPLATE = WORK / "template_reference.docx"
OUTPUT = ROOT / "deliverables" / "MiniRISC16_PC8_Design_and_Verification_Report_Board_Results_2026-11-11.docx"
ARCH = WORK / "pc8_architecture.png"
DATAFLOW = WORK / "pc8_dataflow.png"
WAVE_DIR = ROOT / "MiniRISC-16-CPU" / "reports" / "waveforms"
BOARD_PHOTO_DIR = WORK / "board_photo_exports"
RUNNING_LIGHT_PHOTO = BOARD_PHOTO_DIR / "running_light.png"
BOARD_PPT_DIR = WORK / "board_ppt_media"
LAUNCHER_IMAGE = BOARD_PPT_DIR / "image.png"
GAME_2048_RUNNING = BOARD_PPT_DIR / "image2.png"
GAME_2048_OVER = BOARD_PPT_DIR / "image3.png"
SNAKE_START = BOARD_PPT_DIR / "image4.png"
SNAKE_LEVEL3 = BOARD_PPT_DIR / "image5.png"
SNAKE_OVER = BOARD_PPT_DIR / "image6.png"


def set_cell_shading(cell, fill):
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = tc_pr.find(qn("w:shd"))
    if shd is None:
        shd = OxmlElement("w:shd")
        tc_pr.append(shd)
    shd.set(qn("w:fill"), fill)


def set_repeat_table_header(row):
    tr_pr = row._tr.get_or_add_trPr()
    tbl_header = OxmlElement("w:tblHeader")
    tbl_header.set(qn("w:val"), "true")
    tr_pr.append(tbl_header)


def set_row_cant_split(row):
    tr_pr = row._tr.get_or_add_trPr()
    cant_split = OxmlElement("w:cantSplit")
    cant_split.set(qn("w:val"), "true")
    tr_pr.append(cant_split)


def set_cell_margins(cell, top=80, start=90, bottom=80, end=90):
    tc = cell._tc
    tc_pr = tc.get_or_add_tcPr()
    tc_mar = tc_pr.first_child_found_in("w:tcMar")
    if tc_mar is None:
        tc_mar = OxmlElement("w:tcMar")
        tc_pr.append(tc_mar)
    for m, v in (("top", top), ("start", start), ("bottom", bottom), ("end", end)):
        node = tc_mar.find(qn(f"w:{m}"))
        if node is None:
            node = OxmlElement(f"w:{m}")
            tc_mar.append(node)
        node.set(qn("w:w"), str(v))
        node.set(qn("w:type"), "dxa")


def set_run_font(run, name="Times New Roman", size=10.5, bold=None, color=None):
    run.font.name = name
    run._element.rPr.rFonts.set(qn("w:eastAsia"), name)
    run.font.size = Pt(size)
    if bold is not None:
        run.bold = bold
    if color:
        run.font.color.rgb = RGBColor(*color)


def set_paragraph_font(paragraph, name="Times New Roman", size=10.5, bold=None):
    for run in paragraph.runs:
        set_run_font(run, name, size, bold)


def add_field(paragraph, instruction, result_text=""):
    run = paragraph.add_run()
    begin = OxmlElement("w:fldChar")
    begin.set(qn("w:fldCharType"), "begin")
    instr = OxmlElement("w:instrText")
    instr.set(qn("xml:space"), "preserve")
    instr.text = instruction
    separate = OxmlElement("w:fldChar")
    separate.set(qn("w:fldCharType"), "separate")
    text = OxmlElement("w:t")
    text.text = result_text
    end = OxmlElement("w:fldChar")
    end.set(qn("w:fldCharType"), "end")
    run._r.extend([begin, instr, separate, text, end])
    return run


def add_body(doc, text="", style=None, bold_lead=None, align=None, keep=False):
    p = doc.add_paragraph(style=style)
    if bold_lead and text.startswith(bold_lead):
        r1 = p.add_run(bold_lead)
        r1.bold = True
        p.add_run(text[len(bold_lead):])
    else:
        p.add_run(text)
    if align is not None:
        p.alignment = align
    p.paragraph_format.space_after = Pt(5)
    p.paragraph_format.line_spacing = 1.15
    p.paragraph_format.keep_together = keep
    set_paragraph_font(p)
    return p


def add_bullets(doc, items):
    for item in items:
        p = doc.add_paragraph()
        p.add_run("• ")
        p.add_run(item)
        p.paragraph_format.left_indent = Inches(0.25)
        p.paragraph_format.first_line_indent = Inches(-0.16)
        p.paragraph_format.space_after = Pt(2)
        set_paragraph_font(p)


def add_heading(doc, text, level=1):
    p = doc.add_heading(text, level=level) if level <= 3 else doc.add_paragraph()
    if level > 3:
        p.add_run(text)
    p.paragraph_format.keep_with_next = True
    p.paragraph_format.space_before = Pt(10 if level == 1 else 7)
    p.paragraph_format.space_after = Pt(4)
    for r in p.runs:
        set_run_font(r, "Times New Roman", 15 if level == 1 else (12 if level == 2 else 10.5), True, (0, 0, 0))
    return p


def add_index_entry(doc, text, page_number):
    p = doc.add_paragraph()
    p.paragraph_format.tab_stops.add_tab_stop(Inches(6.25), WD_TAB_ALIGNMENT.RIGHT, WD_TAB_LEADER.DOTS)
    p.paragraph_format.space_after = Pt(2)
    p.add_run(text)
    p.add_run("\t" + str(page_number))
    set_paragraph_font(p, "Arial", 9.5)
    return p


def add_table(doc, headers, rows, widths=None, font_size=9):
    table = doc.add_table(rows=1, cols=len(headers))
    table.style = "Table Grid"
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = True
    hdr = table.rows[0]
    set_repeat_table_header(hdr)
    set_row_cant_split(hdr)
    for i, header in enumerate(headers):
        cell = hdr.cells[i]
        set_cell_shading(cell, "D9EAF7")
        cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
        cell.text = str(header)
        set_cell_margins(cell)
        for p in cell.paragraphs:
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            set_paragraph_font(p, size=font_size, bold=True)
    for row in rows:
        new_row = table.add_row()
        set_row_cant_split(new_row)
        cells = new_row.cells
        for i, value in enumerate(row):
            cells[i].vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
            cells[i].text = str(value)
            set_cell_margins(cells[i])
            for p in cells[i].paragraphs:
                if str(headers[i]) in {"Date", "Version", "Student Number", "Name", "Score", "Direction", "Width", "Opcode", "Mnemonic", "Address", "Access", "Stage", "Result", "Assessment"}:
                    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
                else:
                    p.alignment = WD_ALIGN_PARAGRAPH.LEFT
                p.paragraph_format.space_after = Pt(0)
                set_paragraph_font(p, size=font_size)
        if widths:
            for i, width in enumerate(widths):
                cells[i].width = Inches(width)
    doc.add_paragraph().paragraph_format.space_after = Pt(0)
    return table


def add_caption(doc, label, text):
    p = doc.add_paragraph(style="Caption")
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run(label + " ")
    set_run_font(r, "Arial", 9.5)
    field_run = add_field(p, f"SEQ {label} \\* ARABIC", "0")
    set_run_font(field_run, "Arial", 9.5)
    r2 = p.add_run(". " + text)
    set_run_font(r2, "Arial", 9.5)
    p.paragraph_format.space_after = Pt(6)
    return p


def add_figure(doc, path, caption, width=6.25):
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = p.add_run()
    inline = run.add_picture(str(path), width=Inches(width))
    inline._inline.docPr.set("descr", caption)
    p.paragraph_format.space_after = Pt(2)
    add_caption(doc, "Figure", caption)


def add_figure_grid(doc, items, caption, columns=2, image_width=None):
    """Add a borderless inline-image grid with short subfigure labels."""
    if image_width is None:
        image_width = 3.0 if columns == 2 else (5.85 if columns == 1 else 1.95)
    rows = (len(items) + columns - 1) // columns
    table = doc.add_table(rows=rows, cols=columns)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False
    tbl_pr = table._tbl.tblPr
    borders = tbl_pr.first_child_found_in("w:tblBorders")
    if borders is None:
        borders = OxmlElement("w:tblBorders")
        tbl_pr.append(borders)
    for edge in ("top", "left", "bottom", "right", "insideH", "insideV"):
        el = OxmlElement(f"w:{edge}")
        el.set(qn("w:val"), "nil")
        borders.append(el)
    for row in table.rows:
        set_row_cant_split(row)
        for cell in row.cells:
            set_cell_margins(cell, 35, 45, 55, 45)
    if columns == 2 and len(items) % 2 == 1:
        table.cell(rows - 1, 0).merge(table.cell(rows - 1, 1))
    for index, (path, label) in enumerate(items):
        cell = table.cell(index // columns, index % columns)
        cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
        p = cell.paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        inline = p.add_run().add_picture(str(path), width=Inches(image_width))
        inline._inline.docPr.set("descr", label)
        p.paragraph_format.space_after = Pt(2)
        label_p = cell.add_paragraph()
        label_p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        label_p.add_run(label)
        label_p.paragraph_format.space_after = Pt(0)
        set_paragraph_font(label_p, "Arial", 8.3)
    for index in range(len(items), rows * columns):
        table.cell(index // columns, index % columns).text = ""
    add_caption(doc, "Figure", caption)


def add_page_break(doc):
    doc.add_page_break()


def prepare_document():
    doc = Document(str(TEMPLATE))
    body = doc._body._element
    sect_pr = body.sectPr
    for child in list(body):
        if child is not sect_pr:
            body.remove(child)

    section = doc.sections[0]
    section.page_width = Inches(8.27)
    section.page_height = Inches(11.69)
    section.left_margin = Inches(0.95)
    section.right_margin = Inches(0.95)
    section.top_margin = Inches(1.02)
    section.bottom_margin = Inches(0.79)
    section.different_first_page_header_footer = True

    header = section.header
    hp = header.paragraphs[0]
    hp.clear()
    hp.paragraph_format.space_after = Pt(0)
    ht = header.add_table(rows=1, cols=2, width=Inches(6.37))
    ht.autofit = False
    ht.columns[0].width = Inches(4.8)
    ht.columns[1].width = Inches(1.57)
    ht.rows[0].cells[0].text = "MiniRISC-16 CPU"
    ht.rows[0].cells[1].text = "UoG"
    ht.rows[0].cells[0].paragraphs[0].alignment = WD_ALIGN_PARAGRAPH.LEFT
    ht.rows[0].cells[1].paragraphs[0].alignment = WD_ALIGN_PARAGRAPH.RIGHT
    tbl_pr = ht._tbl.tblPr
    borders = OxmlElement("w:tblBorders")
    for edge in ("top", "left", "bottom", "right", "insideH", "insideV"):
        el = OxmlElement(f"w:{edge}")
        el.set(qn("w:val"), "nil")
        borders.append(el)
    tbl_pr.append(borders)
    for cell in ht.rows[0].cells:
        set_cell_margins(cell, 0, 0, 0, 0)
        set_paragraph_font(cell.paragraphs[0], size=9)
    first_hp = section.first_page_header.paragraphs[0]
    first_hp.clear()

    footer = section.footer
    fp = footer.paragraphs[0]
    fp.clear()
    fp.alignment = WD_ALIGN_PARAGRAPH.CENTER
    add_field(fp, "PAGE", "1")
    set_paragraph_font(fp, size=9)
    section.first_page_footer.paragraphs[0].clear()

    for style_name, size, bold in [
        ("Normal", 10.5, False), ("Default Paragraph Font", 10.5, False),
        ("Heading 1", 15, True), ("Heading 2", 12, True),
        ("Heading 3", 10.5, True), ("Title", 20, True), ("Caption", 9.5, False),
    ]:
        try:
            style = doc.styles[style_name]
            style.font.name = "Times New Roman"
            style._element.rPr.rFonts.set(qn("w:eastAsia"), "Times New Roman")
            style.font.size = Pt(size)
            style.font.bold = bold
            style.font.color.rgb = RGBColor(0, 0, 0)
        except KeyError:
            pass
    # The source template links Heading 3 to a multilevel list. The report text
    # already carries explicit section numbers, so remove that inherited link.
    try:
        h3_ppr = doc.styles["Heading 3"]._element.get_or_add_pPr()
        num_pr = h3_ppr.find(qn("w:numPr"))
        if num_pr is not None:
            h3_ppr.remove(num_pr)
    except KeyError:
        pass
    doc.core_properties.title = "MiniRISC-16 8-bit PC Design and Verification Report"
    doc.core_properties.subject = "Pre-board RTL baseline with simulation and board verification"
    doc.core_properties.author = "MiniRISC-16 CPU Team"
    doc.core_properties.keywords = "MiniRISC-16, FPGA, CPU, 8-bit PC, GPIO, Vivado, XSim"
    return doc


def build():
    for required in [
        TEMPLATE, ARCH, DATAFLOW, RUNNING_LIGHT_PHOTO, LAUNCHER_IMAGE,
        GAME_2048_RUNNING, GAME_2048_OVER, SNAKE_START, SNAKE_LEVEL3, SNAKE_OVER,
    ]:
        if not required.exists():
            raise FileNotFoundError(required)

    doc = prepare_document()

    # Cover
    for _ in range(3):
        doc.add_paragraph()
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run("MiniRISC-16 8-bit PC CPU")
    set_run_font(r, "Times New Roman", 22, True, (0, 0, 0))
    p.paragraph_format.space_after = Pt(14)
    p2 = doc.add_paragraph()
    p2.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p2.add_run("Design and Verification Report")
    set_run_font(r, "Times New Roman", 20, True)
    p2.paragraph_format.space_after = Pt(48)
    meta = [
        ("Report target", "Pre-board RTL baseline with 8-bit PC"),
        ("Core configuration", "16-bit single-cycle CPU and 8-bit GPIO"),
        ("Creation date", "2026.11.11"),
        ("Version", "2.2"),
    ]
    t = doc.add_table(rows=0, cols=2)
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    for k, v in meta:
        c = t.add_row().cells
        c[0].text, c[1].text = k, v
        for idx in range(2):
            set_cell_margins(c[idx], 70, 110, 70, 110)
            set_paragraph_font(c[idx].paragraphs[0], size=11, bold=(idx == 0))
    doc.add_paragraph()
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run("University of Electronic Science and Technology of China\nChengdu, Sichuan")
    set_run_font(r, "Times New Roman", 11)

    # Front matter
    add_page_break(doc)
    add_heading(doc, "Document History", 1)
    add_table(doc, ["Date", "Version", "Description", "Author"], [
        ["2026-11-05", "2.0", "Rebased the report on the pre-board 8-bit-PC RTL version and confined all FPGA-board adaptation and acceptance evidence to Section 4.", "MiniRISC-16 CPU Team"],
        ["2026-11-11", "2.1", "Expanded the board-verification plan, operating procedure, observation matrix, and photographic evidence while preserving the PC=8 pre-board baseline.", "MiniRISC-16 CPU Team"],
        ["2026-11-11", "2.2", "Reworked Section 4 around the UART-loaded Runtime platform and the running-light, 2048, and Snake demonstrations presented in the board-showcase materials.", "MiniRISC-16 CPU Team"],
    ], widths=[1.1, 0.75, 3.9, 1.2], font_size=9.5)
    add_body(doc, "Scope note: Sections 1 to 3 and Section 5 describe the pre-board CPU baseline with an 8-bit program counter. Synthesis, implementation, bitstream generation, board-specific I/O, and physical-board observations appear only in Section 4 as verification activities.")

    add_page_break(doc)
    add_heading(doc, "Abbreviation", 1)
    add_table(doc, ["Abbreviation", "Meaning"], [
        ["CPU", "Central Processing Unit"], ["FPGA", "Field-Programmable Gate Array"],
        ["ISA", "Instruction Set Architecture"], ["RTL", "Register-Transfer Level"],
        ["PC", "Program Counter"], ["RAM", "Random-Access Memory"],
        ["UART", "Universal Asynchronous Receiver/Transmitter"], ["I/O", "Input/Output"],
        ["XSim", "Vivado Logic Simulator"], ["WDB", "Vivado Waveform Database"],
    ], widths=[1.5, 5.0], font_size=9.5)

    add_page_break(doc)
    add_heading(doc, "Abstract", 1)
    add_body(doc, "This report describes the pre-board MiniRISC-16 baseline: a 16-bit, non-pipelined, single-cycle soft CPU with four 16-bit general-purpose registers, an 8-bit program counter, a 256 × 16 combinational-read instruction memory, and an independent 8-bit I/O address space. The instruction set contains 13 active opcodes for data transfer, arithmetic, logic, comparison, control flow, input, and output; opcodes D to F are safe reserved operations. The baseline system integrates an 8-bit bidirectional GPIO peripheral with independent output, input, and direction registers.")
    add_body(doc, "Verification is presented in two clearly separated parts. Simulation verification uses six self-checking Vivado XSim testbenches and an end-to-end reference model; all six tests pass with zero regression failures. On-board verification records two later layers: a direct PC=8 wrapper smoke test and an extended Runtime system with a UART program loader, writable program memory, data memory, and board peripherals. The Runtime system loads and runs the running-light, 2048, and Snake programs without regenerating the FPGA hardware. This structure preserves the pre-board design baseline while documenting the complete board demonstration.")
    p = add_body(doc, "Keywords: soft-core CPU; FPGA; single-cycle processor; 8-bit program counter; UART Loader; GPIO; Vivado XSim.")
    p.paragraph_format.space_before = Pt(10)

    add_page_break(doc)
    add_heading(doc, "Contents", 1)
    p = doc.add_paragraph()
    add_field(p, 'TOC \\o "1-3" \\h \\z \\u', "Right-click and update field")
    add_page_break(doc)
    add_heading(doc, "Figures", 1)
    for text, page in [
        ("Figure 1. Pre-board MiniRISC-16 architecture with 8-bit PC and GPIO.", 10),
        ("Figure 2. Single-cycle dataflow of the 8-bit-PC baseline.", 11),
        ("Figure 3. Single-cycle architectural commit.", 16),
        ("Figure 4. Control-flow verification for CMP, JZ, and JUMP.", 16),
        ("Figure 5. Register operands, ALU result, and write-back path.", 16),
        ("Figure 6. GPIO I/O verification through INP and OUP.", 17),
        ("Figure 7. Computer-side launcher for Runtime program selection and UART upload.", 18),
        ("Figure 8. Running-light program executing on the EES331 board.", 19),
        ("Figure 9. 2048 running and game-over states reported by the board program.", 20),
        ("Figure 10. Snake start, level-three, and game-over states reported by the board program.", 21),
    ]:
        add_index_entry(doc, text, page)
    add_page_break(doc)
    add_heading(doc, "Tables", 1)
    for text, page in [
        ("Table 1. Pre-board system_top interface.", 10),
        ("Table 2. Pre-board MiniRISC-16 instruction set.", 11),
        ("Table 3. Baseline GPIO I/O address map.", 12),
        ("Table 4. Simulation testbench plan.", 13),
        ("Table 5. On-board verification plan.", 14),
        ("Table 6. Simulation test cases and results.", 15),
        ("Table 7. Board implementation results.", 17),
        ("Table 8. Physical-board test cases and results.", 17),
        ("Table 9. Runtime application demonstrations and results.", 21),
    ]:
        add_index_entry(doc, text, page)

    # Main report
    add_page_break(doc)
    add_heading(doc, "1 Team Information", 1)
    add_table(doc, ["Student Number", "Name", "Primary Tasks", "Score"], [
        ["To be completed", "To be completed", "CPU microarchitecture and ISA", ""],
        ["To be completed", "To be completed", "Datapath, controller, and instruction memory", ""],
        ["To be completed", "To be completed", "GPIO peripheral and system integration", ""],
        ["To be completed", "To be completed", "Verification, waveform analysis, and documentation", ""],
    ], widths=[1.35, 1.25, 3.5, 0.7], font_size=9)
    add_body(doc, "Team Name: MiniRISC-16 CPU Team", bold_lead="Team Name:")
    add_body(doc, "Identity fields are intentionally left for the submitting team to complete; no names or student numbers have been inferred.")

    add_heading(doc, "2 Specification", 1)
    add_heading(doc, "2.1 Requirements Analysis", 2)
    add_body(doc, "The report target is the RTL version completed before board-specific integration. It is a custom 16-bit soft CPU rather than software running on the Zynq processing system. The processor shall execute one instruction per architectural clock cycle, expose four general-purpose registers, address 256 instruction words with an 8-bit PC, and communicate with external logic through a separate 8-bit I/O address space.")
    add_bullets(doc, [
        "Implement the processor as synthesizable RTL with a deterministic single-cycle architectural commit.",
        "Support 13 active opcodes, three safe reserved opcodes, four 16-bit registers, and an 8-bit program counter.",
        "Provide arithmetic, logic, comparison, conditional and unconditional jumps, and independent-port input/output.",
        "Integrate a direction-configurable 8-bit bidirectional GPIO peripheral without changing the CPU core interface.",
        "Provide self-checking testbenches, reference-model comparison, and reproducible Vivado XSim waveform evidence.",
    ])
    add_heading(doc, "2.2 Application Scenarios", 2)
    add_body(doc, "The baseline supports teaching and experiments in CPU datapaths, instruction decoding, single-cycle timing, direct I/O, and GPIO control. A short ROM program can perform register arithmetic, compare values, execute branches, sample external inputs, and drive external outputs. More elaborate board peripherals are validation wrappers and are therefore discussed only in Section 4.")

    add_heading(doc, "3 Design and Implementation", 1)
    add_heading(doc, "3.1 Overall Design", 2)
    add_heading(doc, "3.1.1 Function", 3)
    add_body(doc, "system_top connects the reset conditioner, instruction memory, CPU core, and GPIO peripheral. The instruction memory returns a 16-bit word selected by the current 8-bit PC. The CPU decodes and executes that word, updates architectural state at the active edge, and exchanges data with GPIO through the independent I/O interface. The GPIO block implements output, synchronized input, and per-bit direction control.")
    add_heading(doc, "3.1.2 Baseline Input and Output", 3)
    add_caption(doc, "Table", "Pre-board system_top interface.")
    add_table(doc, ["Port", "Direction", "Width", "Purpose"], [
        ["clk", "Input", "1", "System clock"],
        ["resetn", "Input", "1", "Active-low external reset"],
        ["gpio", "Bidirectional", "8", "Per-bit input or output under GPIO_DIR control"],
    ], font_size=8.8)
    add_heading(doc, "3.1.3 Architecture", 3)
    add_figure(doc, ARCH, "Pre-board MiniRISC-16 architecture with 8-bit PC and GPIO.", 6.25)
    add_body(doc, "The instruction path and I/O path are separate. The instruction ROM is addressed only by the PC and does not share a bus with the GPIO peripheral. The baseline ISA has no LDR or STR instruction and no general-purpose data memory. INP and OUP are the only external-access instructions and use the 8-bit port field carried in the instruction.")
    add_heading(doc, "3.1.4 Dataflow", 3)
    add_figure(doc, DATAFLOW, "Single-cycle dataflow of the 8-bit-PC baseline.", 6.2)
    add_body(doc, "During a cycle, the current PC selects an instruction, the controller decodes its fields, the register file supplies operands, and the ALU or I/O path produces a candidate write-back value. At the active edge, the PC always advances or jumps; the selected register, Z flag, and GPIO register update only when their corresponding write enables are asserted.")

    add_heading(doc, "3.2 CPU Core", 2)
    add_heading(doc, "3.2.1 Function", 3)
    add_body(doc, "MiniRISC-16 is a 16-bit, four-register, single-cycle processor. R0 to R3 are general-purpose registers and the 8-bit PC directly addresses 256 instruction words. The controller decodes the high opcode nibble and generates combinational datapath and I/O controls. Only CMP updates the stored Z flag; JZ consumes that previously stored value.")
    add_heading(doc, "3.2.2 Instruction Set", 3)
    add_caption(doc, "Table", "Pre-board MiniRISC-16 instruction set.")
    add_table(doc, ["Opcode", "Mnemonic", "Operation", "Opcode", "Mnemonic", "Operation"], [
        ["0", "MOVI", "Immediate to register", "8", "JZ", "Jump to imm8 if Z is set"],
        ["1", "MOVR", "Register move", "9", "OR", "Bitwise OR"],
        ["2", "ADDI", "Add immediate", "A", "JUMP", "Unconditional jump to imm8"],
        ["3", "ADDR", "Add register", "B", "INP", "Read I/O port"],
        ["4", "XOR", "Bitwise exclusive OR", "C", "OUP", "Write memory-mapped output"],
        ["5", "SUB", "Subtract", "D", "Reserved", "Safe operation with no write side effect"],
        ["6", "CMP", "Compare and update Z", "E", "Reserved", "Safe operation with no write side effect"],
        ["7", "AND", "Bitwise AND", "F", "Reserved", "Safe operation with no write side effect"],
    ], font_size=8.2)
    add_heading(doc, "3.2.3 Control-Flow Semantics", 3)
    add_body(doc, "JUMP and a taken JZ load the complete 8-bit imm8 field into the PC. All other instructions, including an untaken JZ and the three reserved opcodes, advance the PC by one modulo 256. CMP computes equality through subtraction, updates Z, and leaves the destination register unchanged.")

    add_heading(doc, "3.3 Instruction Memory and GPIO", 2)
    add_heading(doc, "3.3.1 Instruction Memory", 3)
    add_body(doc, "Instruction memory is a 256 × 16 combinational-read ROM. The 8-bit PC is the word address and the selected instruction is available to the controller and datapath within the same architectural cycle. Because the baseline has no data-memory instructions, ordinary program execution cannot write or corrupt this memory.")
    add_heading(doc, "3.3.2 GPIO Address Map", 3)
    add_caption(doc, "Table", "Baseline GPIO I/O address map.")
    add_table(doc, ["Address", "Register", "Access", "Description"], [
        ["0x10", "GPIO_OUT", "R/W", "Eight-bit output latch; read returns the latched value"],
        ["0x11", "GPIO_IN", "R", "Two-stage synchronized input value, zero-extended to 16 bits"],
        ["0x12", "GPIO_DIR", "R/W", "Per-bit direction: 1 for output and 0 for input"],
    ], font_size=9)
    add_heading(doc, "3.3.3 GPIO Electrical Behaviour", 3)
    add_body(doc, "GPIO_OUT and GPIO_DIR update on valid OUP writes. A direction bit of zero places the corresponding top-level driver in high impedance so an external source can drive the pin; a direction bit of one drives the stored output bit. Inputs pass through two synchronizing registers before GPIO_IN is read. Reset clears both output and direction registers, leaving every GPIO pin in the safer input state.")

    add_heading(doc, "3.4 Clock, Reset, and Initialization", 2)
    add_body(doc, "The baseline RTL is driven by a single clock. The reset conditioner asserts reset immediately when resetn is low and releases it through a two-stage synchronizer. Reset initializes PC to 0, clears R0 to R3 and Z, suppresses register and I/O writes, clears GPIO_OUT, and sets GPIO_DIR to zero. After reset release, the instruction at address 0 begins the first valid architectural cycle.")

    add_heading(doc, "4 Verification & Test", 1)
    add_heading(doc, "4.1 Test Plan & TestBench", 2)
    add_heading(doc, "4.1.1 Simulation Verification", 3)
    add_body(doc, "Simulation verification targets the pre-board RTL baseline directly. Each testbench is self-checking and prints a unique TEST PASS only after all programmed assertions succeed. The regression compiles with xvlog, elaborates with xelab, and runs with XSim. Unit tests isolate the ALU, controller, datapath, reset conditioner, and GPIO; the system test executes a ROM program and compares the CPU and GPIO state against a cycle-accurate reference model.")
    add_caption(doc, "Table", "Simulation testbench plan.")
    add_table(doc, ["TestBench", "Verification Target", "Main Checks"], [
        ["tb_alu", "Six-function ALU", "PASS B, ADD, SUB, AND, OR, XOR, zero result, wraparound, and underflow"],
        ["tb_controller", "Instruction decoder", "13 active opcodes, three safe reserved opcodes, and default control values"],
        ["tb_datapath", "Architectural state", "PC update, register write-back, CMP/Z, JZ, JUMP, and PC wraparound"],
        ["tb_reset_conditioner", "Reset path", "Immediate assertion and two-stage synchronous release"],
        ["tb_gpio8", "GPIO peripheral", "OUT/IN/DIR, invalid addresses, high impedance, and synchronized input"],
        ["tb_system", "Integrated baseline", "ROM execution, all opcode values, taken/untaken branches, I/O, and reference-model state"],
    ], widths=[1.15, 1.65, 4.0], font_size=8.3)
    add_body(doc, "The nominal simulation clock period is 10 ns. This value provides a stable functional test cadence; the testbench plan is concerned with cycle-level correctness, while implementation timing is evaluated separately in the on-board verification plan.")

    add_heading(doc, "4.1.2 On-Board Verification", 3)
    add_body(doc, "On-board verification covers two related configurations. The first is a direct wrapper around the pre-board PC=8 core, used for reset, self-check, switch-input, LED, and seven-segment smoke tests. The second is the extended Runtime system used in the board presentation. It derives from the same processor project but adds a UART Loader, a writable 1K × 16 program memory, data RAM, a timer, a random-number peripheral, and application-oriented I/O. These additions belong to the board-verification version and do not redefine the PC=8 baseline described in Sections 1 to 3.")
    add_body(doc, "Runtime verification objective. The host launcher selects one of three machine-code images and transfers it through UART. In load mode, SW7 is set to 1, the CPU remains in reset, and the Loader writes 16-bit program words into program memory after assembling each high-byte and low-byte pair. After the checksum response reports success, SW7 returns to 0 and the CPU begins execution at program address 0x000. The FPGA hardware remains unchanged while the running-light, 2048, and Snake programs are exchanged.", bold_lead="Runtime verification objective.")
    add_body(doc, "Runtime communication. The board uses the CP2103 USB-to-UART bridge and FPGA-side UART logic configured for 115200 baud, eight data bits, no parity, and one stop bit. During program execution, the host sends key commands and the CPU returns state frames. The computer terminal renders those state values, while the MiniRISC-16 program performs the position updates, game rules, score calculations, memory accesses, and collision checks.", bold_lead="Runtime communication.")
    add_caption(doc, "Table", "On-board verification plan.")
    add_table(doc, ["Stage", "Test Setup", "Pass Criterion"], [
        ["A", "Program the EES331 FPGA and verify reset", "Configuration succeeds; S1 clears visible outputs and restarts the selected system"],
        ["B", "Set SW7 = 1 and upload a program through the launcher", "CPU remains reset; loader status is visible; the host reports UPLOAD PASS"],
        ["C", "Set SW7 = 0 after upload", "CPU starts at 0x000 and the selected application begins without regenerating the bitstream"],
        ["D", "Run the running-light program", "LED0 to LED7 move with wraparound; direction, four speeds, and pause respond to controls"],
        ["E", "Run the 2048 program", "Movement, merge, score, new-tile generation, and game-over detection appear in the terminal"],
        ["F", "Run the Snake program", "Direction, growth, score, level increase, map collision, and game-over behaviour appear correctly"],
        ["G", "Repeat program changes", "All three images load through the same UART path and reuse the same Runtime hardware"],
    ], widths=[0.55, 2.7, 3.55], font_size=8.4)
    add_body(doc, "Board operating procedure. The operator first programs the Runtime bitstream and confirms reset. For each application, SW7 enters load mode, the launcher sends the selected program image, and the operator waits for the upload response. SW7 then returns to run mode. The operator exercises the application controls, records the visible board state and terminal state, and repeats the sequence for the next program.", bold_lead="Board operating procedure.")
    add_body(doc, "Evidence capture. Implementation reports provide the timing, utilization, routing, and bitstream evidence. The presentation screenshots document the launcher, running-light board state, 2048 state frames, and Snake state frames. The direct PC=8 smoke-test observations remain separately identified as team feedback so that presentation evidence for the extended Runtime is not used to overstate the original baseline.", bold_lead="Evidence capture.")

    add_heading(doc, "4.2 TestCase & Result", 2)
    add_heading(doc, "4.2.1 Simulation Verification", 3)
    add_caption(doc, "Table", "Simulation test cases and results.")
    add_table(doc, ["TestCase", "Result", "Key Evidence"], [
        ["tb_alu", "PASS", "All six ALU functions and arithmetic edge cases pass"],
        ["tb_controller", "PASS", "All 16 opcode values produce the expected control outputs"],
        ["tb_datapath", "PASS", "Register, PC, Z, branch, jump, and wraparound checks pass"],
        ["tb_reset_conditioner", "PASS", "Reset assertion and synchronized release pass"],
        ["tb_gpio8", "PASS", "Read/write, direction, high-impedance, and input synchronization checks pass"],
        ["tb_system", "PASS", "29 committed instructions; opcode coverage FFFF; JZ taken 2 and not taken 1"],
        ["Full regression", "6/6 PASS", "Failures: 0"],
    ], widths=[1.45, 1.05, 4.3], font_size=8.4)
    add_body(doc, "The integrated final state matches the reference model: PC = 0x21, Z = 1, R0 to R3 = 0x00A5, GPIO_OUT = 0xA5, GPIO_DIR = 0x0F, and GPIO_IN = 0xA5. Native VCD, WCFG, WDB, log, and PNG artifacts are retained so the automatic result can also be inspected at waveform level.")
    add_body(doc, "The following figures are derived from the same passing tb_system execution and show architectural events from the pre-board 8-bit-PC design.")
    wave_figures = [
        ("01_single_cycle_commit.png", "Single-cycle architectural commit: PC, instruction, register write, and status update align at the active clock edge.", "This view establishes the fundamental timing contract of the processor. Combinational decode and execution settle during the cycle, and the enabled architectural state changes together at the next active edge."),
        ("02_cmp_jz_jump.png", "Control-flow verification for CMP, JZ, and JUMP.", "CMP establishes the stored Z condition used by JZ. Taken and untaken JZ events and the unconditional JUMP demonstrate complete 8-bit target loading and sequential PC behaviour."),
        ("03_registers_alu.png", "Register operands, ALU result, and write-back path.", "The internal traces show source selection, computation, destination write enable, and register-file update, confirming that program behaviour is produced by the CPU datapath."),
        ("04_gpio_io.png", "GPIO I/O verification through INP and OUP.", "The trace relates the I/O address and data signals to GPIO_OUT, GPIO_DIR, synchronized input, and the top-level bidirectional pins."),
    ]
    for name, caption, explanation in wave_figures:
        add_figure(doc, WAVE_DIR / name, caption, 6.25)
        add_body(doc, explanation)

    add_heading(doc, "4.2.2 On-Board Verification", 3)
    add_heading(doc, "4.2.2.1 Implementation and Runtime Loading", 4)
    add_caption(doc, "Table", "Board implementation results.")
    add_table(doc, ["Metric", "Result", "Assessment"], [
        ["Target device", "xc7z020clg484-1", "Matches the EES331 board"],
        ["Clock target", "100 MHz", "10 ns period"],
        ["Setup timing", "WNS +1.513 ns; TNS 0.000 ns", "PASS"],
        ["Logic utilization", "218 LUT; 144 FF", "Fits device"],
        ["I/O utilization", "42 IOB; 1 BUFG", "Fits board interface"],
        ["Routing", "0 unrouted nets", "PASS"],
        ["Bitstream", "MiniRISC16_EES331.bit generated", "PASS"],
    ], font_size=9)
    add_body(doc, "The available implementation report confirms that the EES331 target meets the 100 MHz constraint, completes routing, and produces a bitstream. These measurements establish board readiness for the PC=8 wrapper. The Runtime application results below provide separate behavioural evidence from the later board platform.")
    add_body(doc, "The Runtime loading path allows the three applications to reuse one FPGA configuration. The computer-side launcher selects 01 for Snake, 02 for 2048, or 03 for the running light. With SW7 in load mode, the CPU remains reset while the UART Loader writes the selected 16-bit words into the 1K × 16 program memory and checks the transfer. Returning SW7 to run mode releases the CPU at address 0x000.")
    add_figure(doc, LAUNCHER_IMAGE, "Computer-side launcher for Runtime program selection and UART upload.", 6.0)
    add_body(doc, "The launcher is a host tool rather than code executed by the MiniRISC-16 processor. Its role is limited to program selection, transfer, keyboard input, state-frame reception, and terminal rendering. The board CPU executes one uploaded application at a time.")

    add_heading(doc, "4.2.2.2 PC=8 Wrapper Smoke Test", 4)
    add_caption(doc, "Table", "Physical-board test cases and results.")
    add_table(doc, ["TestCase", "Expected Observation", "Result"], [
        ["Download and reset", "Configuration succeeds; S1 clears and restarts the system", "PASS by team feedback"],
        ["CPU self-check", "LED = A5", "PASS by team feedback"],
        ["Display initialization", "Display high word = C0DE", "PASS by team feedback"],
        ["Switch arithmetic", "00→0001, 01→0002, 0F→0010, 7F→0080, FF→0100", "PASS by team feedback"],
    ], widths=[1.45, 3.75, 1.6], font_size=8.4)
    add_body(doc, "This smoke test remains the direct physical check of the PC=8 baseline. It confirms reset, ROM execution, CPU I/O, synchronized switch input, LED output, and seven-segment output. The results are retained as team feedback because the presentation photographs focus on the richer Runtime demonstrations rather than every vector in this table.")

    add_heading(doc, "4.2.2.3 Running-Light Demonstration", 4)
    add_figure(doc, RUNNING_LIGHT_PHOTO, "Running-light program executing on the EES331 board with one active LED.", 5.9)
    add_body(doc, "The running-light program maintains the current position, direction, frame count, switch state, most recent key, and LED pattern in data RAM. On each timer event, the CPU updates the position and writes the new eight-bit pattern to LED port 0x30. The expected single-hot sequence is 01→02→04→08→10→20→40→80→01, so the two end positions wrap without an additional all-off step.")
    add_body(doc, "The demonstration also exercises interactive control. The left and right commands, including A and D, change direction. SW1 to SW0 select four speed settings, and SW2 pauses movement. These behaviours verify repeated instruction execution, LDR and STR state updates, conditional branches, timer input, UART key input, and OUP output to the LED register.")

    add_heading(doc, "4.2.2.4 2048 Demonstration", 4)
    add_body(doc, "The 2048 program stores its 4 × 4 board in RAM addresses 0x40 to 0x4F. Each cell stores the exponent of two, which lets the CPU merge equal tiles by incrementing the exponent. For every valid move, the program compresses four logical rows, prevents a tile from merging twice, updates the score, and uses the LFSR peripheral to select a free position for a new tile. It also checks for a winning value and for a full board with no remaining merge.")
    add_figure_grid(doc, [
        (GAME_2048_RUNNING, "(a) Running game with score 84"),
        (GAME_2048_OVER, "(b) Game-over state with score 1264"),
    ], "2048 running and game-over states reported by the board program.", columns=2, image_width=3.0)
    add_body(doc, "The terminal images show an active game and a completed game with a recorded score of 1264. The host draws the visible board, but the uploaded MiniRISC-16 program maintains the sixteen cells, performs merge and scoring rules, generates the next tile, and sends the resulting state frame over UART.")
    add_body(doc, "Each board cell stores the exponent of two rather than the displayed number. A value of zero represents an empty cell, one represents 2, and two represents 4. This encoding reduces a merge to an exponent increment. The program builds each moved row in a temporary four-cell buffer and tracks whether the most recent tile already merged, which prevents one tile from merging twice during a single move.")
    add_body(doc, "After processing all four rows, the program compares the new board with the old board. It generates a new tile only when the move changed at least one cell. The 27-byte UART state frame contains the sixteen cells, score, status, and frame information used by the terminal. The running and game-over screenshots therefore represent board-computed state rather than game rules implemented by the computer display.")

    add_page_break(doc)
    add_heading(doc, "4.2.2.5 Snake Demonstration", 4)
    add_body(doc, "The Snake program uses a 16-column by 8-row map. A position value combines row and column, so vertical movement changes the value by 0x10 and horizontal movement changes it by one. The CPU checks boundaries before movement, rejects wall or body collisions, decrements the stored lifetime of each body cell, places the new head, and searches for a new food position after a successful eat event.")
    add_figure_grid(doc, [
        (SNAKE_START, "(a) Initial running state"),
        (SNAKE_LEVEL3, "(b) Level 3 with score 6"),
        (SNAKE_OVER, "(c) Game-over state"),
    ], "Snake start, level-three, and game-over states reported by the board program.", columns=3, image_width=1.95)
    add_body(doc, "The screenshots document the transition from normal execution to Level 3 with score 6 and then to game over. Keyboard commands alter direction, eating increases the stored length and score, the update interval decreases as the level rises, and a boundary, obstacle, or body collision ends the game. The CPU sends the 128 map cells and status fields to the terminal as a state frame; the terminal converts those values into the visible map.")

    add_heading(doc, "4.2.2.6 Overall Board Results", 4)
    add_caption(doc, "Table", "Runtime application demonstrations and results.")
    add_table(doc, ["Verification Item", "Observed Achievement", "Result", "Evidence"], [
        ["FPGA implementation", "Timing passed, routing completed, and bitstream generated", "PASS", "Implementation report"],
        ["UART program loading", "Launcher selects and uploads each program without a new bitstream", "PASS", "Launcher workflow and team demonstration"],
        ["Running light", "Direction, four speeds, pause, single-hot movement, and end wraparound", "PASS", "Board photograph and presentation"],
        ["2048", "Move, merge, score, new-tile generation, and game-over detection", "PASS", "Running and game-over screenshots"],
        ["Snake", "Direction, growth, score, level progression, collision, and game over", "PASS", "Three staged terminal screenshots"],
    ], widths=[1.25, 3.05, 0.75, 1.75], font_size=8.1)
    add_body(doc, "Overall result. The board work demonstrates more than a static peripheral test. The same Runtime hardware accepts different program images through UART and executes three programs with distinct state models and I/O behaviour. The running light proves direct board output and timer-driven control. The two games add RAM-based state, keyboard interaction, rule processing, random input, scoring, and multi-byte UART state frames.", bold_lead="Overall result.")
    add_body(doc, "Version boundary. The Runtime-only features, including the writable 1K × 16 program memory, data RAM, UART Loader, LDR and STR instructions, timer, and LFSR, are evidence of the later board platform. They are not attributed to the pre-board PC=8 architecture in Sections 1 to 3. Table 8 remains the direct board smoke test of that baseline.", bold_lead="Version boundary.")

    add_heading(doc, "5 Conclusion and Future Work", 1)
    add_heading(doc, "5.1 Conclusion", 2)
    add_body(doc, "The MiniRISC-16 pre-board baseline is a coherent 16-bit single-cycle CPU design with four registers, an 8-bit PC, a 256-word instruction ROM, 13 active opcodes, three safe reserved opcodes, and an 8-bit bidirectional GPIO peripheral. Its controller, datapath, reset path, GPIO block, and complete system have been checked by six self-checking simulations, including full opcode coverage and cycle-by-cycle reference-model comparison. This version is therefore the design baseline for the report.")
    add_body(doc, "The later board Runtime demonstrates how the processor project was extended into an application platform. A UART Loader changes the program without regenerating the bitstream, and the same hardware runs the running light, 2048, and Snake. These demonstrations provide visible evidence of program loading, data-memory state, control flow, timed I/O, keyboard interaction, random input, and UART status output while remaining clearly separated from the PC=8 baseline.")
    add_heading(doc, "5.2 Future Work", 2)
    add_bullets(doc, [
        "Extend the regression suite with randomized instruction streams and explicit assertion coverage.",
        "Add automated Runtime regression for the UART Loader, LDR and STR, timer, LFSR, and application state frames.",
        "Evaluate a multicycle or pipelined microarchitecture only as a separately versioned successor to the single-cycle baseline.",
        "Formalize the board Runtime as a separately versioned ISA and system profile before promoting its program-memory and data-memory extensions into a future design baseline.",
    ])

    add_page_break(doc)
    add_heading(doc, "References", 1)
    references = [
        "[1] MiniRISC-16 project source tree, pre-board 8-bit-PC CPU and 8-bit GPIO baseline, 2026-11-05.",
        "[2] AMD, Vivado Design Suite User Guide: Logic Simulation (UG900).",
        "[3] AMD, Vivado Design Suite User Guide: Design Analysis and Closure Techniques (UG906).",
        "[4] IEEE Std 1364-2005, IEEE Standard for Verilog Hardware Description Language.",
        "[5] MiniRISC-16 verification artifacts: six self-checking XSim logs, VCD/WCFG/WDB files, and report waveform figures.",
        "[6] MiniRISC-16 EES331 board verification guide and implementation reports for the 8-bit-PC core wrapper, 2026.",
        "[7] MiniRISC-16 board demonstration presentation and detailed speaker notes, UART Loader, running-light, 2048, and Snake demonstrations, 2026.",
    ]
    for ref in references:
        add_body(doc, ref)

    # Document-wide paragraph safety.
    for p in doc.paragraphs:
        p.paragraph_format.widow_control = True
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    doc.save(str(OUTPUT))
    print(OUTPUT)


if __name__ == "__main__":
    build()
