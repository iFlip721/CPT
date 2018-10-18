Function Convert-ExcelToCsv {
    [CmdLetBinding()]
    Param (
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$FilePath   
    )

    $excelFile = $FilePath
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $excel.DisplayAlerts = $false
    $workBook = $excel.Workbooks.Open($excelFile)
    foreach ($workSheet in $workBook.Worksheets)
    {
        $workSheet.SaveAs("$($FilePath.Split('.')[0])" + ".csv", 6)
    }
    $workBook.Close()
    $Excel.Quit()
    return "$($FilePath.Split('.')[0])" + ".csv"
}