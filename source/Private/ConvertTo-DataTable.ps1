Function ConvertTo-DataTable {
    <#
    .SYNOPSIS
    This function convert a collection of objects to a System.Data.Datatable.
    .DESCRIPTION
    This function convert a collection of objects to a System.Data.Datatable. I've took this function from Jeff Hicks https://github.com/jdhitsolutions/PSConfEU2023/tree/main/TUI-Tools
    .PARAMETER InputObject
        Specify the InputObject to convert
    .EXAMPLE
    PS> ConvertTo-DataTable -InputObject $InputObject
    .NOTES
    VERSION HISTORY
    1.0 | 2024/07/19 | Francois LEON
        initial version
    POSSIBLE IMPROVEMENT
        -
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "")]
    [cmdletbinding()]
    [OutputType('System.Data.DataTable')]
    [alias('alias')]
    Param(
        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipeline
        )]
        [ValidateNotNullOrEmpty()]
        [object]$InputObject
    )

    Begin {
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Starting $($MyInvocation.MyCommand)"
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Running under PowerShell version $($PSVersionTable.PSVersion)"
        $data = [System.Collections.Generic.List[object]]::New()
        $Table = [System.Data.DataTable]::New("PSData")
    } #begin

    Process {
        $Data.Add($InputObject)
    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeOfDay) END    ] Building a table of $($data.count) items"
        #define columns
        foreach ($item in $data[0].PSObject.Properties) {
            Write-Verbose "[$((Get-Date).TimeOfDay) END    ] Defining column $($item.name)"
            [void]$table.Columns.Add($item.Name, $item.TypeNameOfValue)
        }
        #add rows
        for ($i = 0; $i -lt $Data.count;$i++) {
            $row = $table.NewRow()
            foreach ($item in $Data[$i].PSObject.Properties) {
                $row.Item($item.name) = $item.Value
            }
            [void]$table.Rows.Add($row)
        }
        #This is a trick to return the table object
        #as the output and not the rows
        ,$table
        Write-Verbose "[$((Get-Date).TimeOfDay) END    ] Ending $($MyInvocation.MyCommand)"
    } #end
}