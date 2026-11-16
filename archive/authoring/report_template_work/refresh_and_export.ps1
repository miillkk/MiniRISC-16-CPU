$ErrorActionPreference = 'Stop'
$docxPath = 'C:\Users\xieke\Desktop\CPU\deliverables\MiniRISC16_PC8_Design_and_Verification_Report_2026-11-05.docx'
$pdfPath = 'C:\Users\xieke\Desktop\CPU\deliverables\report_template_work\MiniRISC16_PC8_Design_and_Verification_Report_2026-11-05-QA.pdf'
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
try {
    $doc = $word.Documents.Open($docxPath, $false, $false)
    $doc.Repaginate()
    for ($pass = 0; $pass -lt 3; $pass++) {
        $null = $doc.Fields.Update()
        foreach ($toc in $doc.TablesOfContents) { $toc.Update() }
        foreach ($tof in $doc.TablesOfFigures) { $tof.Update() }
        $doc.Repaginate()
    }
    $doc.Save()
    $doc.ExportAsFixedFormat($pdfPath, 17)
    $pages = $doc.ComputeStatistics(2)
    $words = $doc.ComputeStatistics(0)
    Write-Output "DOCX=$docxPath"
    Write-Output "PDF=$pdfPath"
    Write-Output "PAGES=$pages"
    Write-Output "WORDS=$words"
    $doc.Close($false)
}
finally {
    $word.Quit()
    [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($word) | Out-Null
}
