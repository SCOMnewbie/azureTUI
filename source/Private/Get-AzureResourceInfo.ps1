function Get-AzureResourceInfo {
    <#
    .SYNOPSIS
    This function fetch Azure information for a specific resource through Azure Graph.
    .DESCRIPTION
    This function fetch Azure information for a specific resource through Azure Graph.
    .PARAMETER AccessToken
        Specify the access token to access your Entra tenant
    .PARAMETER APIVersion
        Specify the Azure Graph APIVersion
    .PARAMETER ResourceId
        Specify the Azure resource id
    .EXAMPLE
    PS> Get-AzureResourceInfo -AccessToken "ey...." -ResourceId "/subscriptions/1234/resourceGroups/myRG/providers/Microsoft.Network/..."

    "will fetch all information related to a specific Azure resource"
    .NOTES
    VERSION HISTORY
    1.0 | 2024/08/09 | Francois LEON
        initial version
    POSSIBLE IMPROVEMENT
        -
    #>
    [cmdletbinding()]
    param (
        [parameter(mandatory)]
        [string]$AccessToken,
        [string]$APIVersion = '2022-10-01',
        [parameter(mandatory)]
        [string]$ResourceId
    )

    $Payload = @{ query = "resources | where ['id'] == `'$ResourceId`'" }

    try {

        $Splat = @{
            Method  = 'Post'
            Uri     = 'https://management.azure.com/providers/Microsoft.ResourceGraph/resources?api-version={0}' -f $APIVersion
            Headers = @{
                'Content-Type' = 'application/json'
                Authorization  = "Bearer $AccessToken"
            }
        }

        #$splat['Body'] = @{query = "resources | extend  replacedType=replace('microsoft.', '',type) | project id, name, type=replacedType, location, subscriptionId "} | ConvertTo-Json
        $splat['Body'] = $Payload | ConvertTo-Json

        Invoke-RestMethod @Splat
    }
    catch {
        Write-Warning $_.Exception.Message
    }
}