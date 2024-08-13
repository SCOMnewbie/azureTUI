Function ExportJson {
    <#
    .SYNOPSIS
    This function export Azure data into the filesystem.
    .DESCRIPTION
    This function export Azure data into the filesystem.
    .EXAMPLE
    PS> ExportJson

    "will export azure data"
    .NOTES
    VERSION HISTORY
    1.0 | 2024/08/13 | Francois LEON
        initial version
    POSSIBLE IMPROVEMENT
        -
    #>
    if ($script:resources) {
        $ReportDate = Get-Date
        $SaveDialog = [SaveDialog]::New()
        [Application]::Run($SaveDialog)
        if ((-Not $SaveDialog.Canceled) -AND ($SaveDialog.FilePath.ToString() -match 'json$')) {

            $StatusBar.Items[3].Title = "Exported to $($saveDialog.FilePath.ToString())"

            $script:resources.GetEnumerator() |
                ForEach-Object { $_.value |
                        Select-Object Name, Location, SubscriptionId, Type, Id,
                        @{Name = 'ReportDate'; Expression = { $ReportDate } }
                    } | ConvertTo-Json | Out-File -FilePath $SaveDialog.FilePath.ToString()
            [MessageBox]::Query('Export', "Azure resources exported in $($saveDialog.FilePath.ToString())", 0, @('OK'))`

        }
    } #if service data is found
    Else {
        [MessageBox]::ErrorQuery('Alert!', "No Azure resources to export!", 0, @('OK'))
    }
}