$ErrorActionPreference = 'Stop'
$docxPath = 'C:\Users\xieke\Desktop\CPU\deliverables\MiniRISC16_PC8_Design_and_Verification_Report_2026-11-05.docx'
$pdfPath = 'C:\Users\xieke\Desktop\CPU\deliverables\report_template_work\MiniRISC16_PC8_Design_and_Verification_Report_2026-11-05-QA.pdf'
$word = $null
$doc = $null
try {
    Write-Output 'START_WORD'
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $word.DisplayAlerts = 0
    Write-Output 'OPEN_DOCUMENT'
    $doc = $word.Documents.Open($docxPath, $false, $false)
    Write-Output 'UPDATE_FIELDS'
    $null = $doc.Fields.Update()
    $doc.Repaginate()
    Write-Output 'SAVE_DOCUMENT'
    $doc.Save()
    Write-Output 'EXPORT_PDF'
    $doc.ExportAsFixedFormat($pdfPath, 17)
    Write-Output ("PAGES=" + $doc.ComputeStatistics(2))
    Write-Output ("WORDS=" + $doc.ComputeStatistics(0))
    Write-Output 'DONE'
}
catch {
    Write-Output ("FAILED=" + $_.Exception.Message)
    throw
}
finally {
    if ($null -ne $doc) {
        try { $doc.Close($false) } catch { Write-Output ("DOC_CLOSE_WARNING=" + $_.Exception.Message) }
    }
    if ($null -ne $word) {
        try { $word.Quit() } catch { Write-Output ("WORD_QUIT_WARNING=" + $_.Exception.Message) }
    }
}
