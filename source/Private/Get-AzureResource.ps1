function Get-AzureResource {
    <#
    .SYNOPSIS
    This function fetch Azure data through Azure Graph.
    .DESCRIPTION
    This function fetch Azure data through Azure Graph.
    .PARAMETER AccessToken
        Specify the access token to access your Entra tenant
    .PARAMETER APIVersion
        Specify the Azure Graph APIVersion
    .PARAMETER PrimaryFilter
        Specify the primary filter
    .PARAMETER SecondaryFilter
        Specify the Secondary filter
    .EXAMPLE
    PS> Get-AzureResource -AccessToken "ey...."

    "will fetch all Azure resources you can read"
    .NOTES
    VERSION HISTORY
    1.0 | 2024/07/19 | Francois LEON
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
        [ValidateSet('Subscription','Type','Location','All')]
        [string]$PrimaryFilter,
        [string]$SecondaryFilter
    )

    Switch ($PrimaryFilter) {
        'All' {
            $Payload = @{query = "resources | extend  replacedType=replace('microsoft.', '',type) | project id, name, type=replacedType, location, subscriptionId" }
        }
        'Subscription' {
            $Payload = @{
                subscriptions = @($($SecondaryFilter -split ','))
                query         = "resources | extend  replacedType=replace('microsoft.', '',type) | project id, name, type=replacedType, location, subscriptionId"
            }
        }
        'Type' {
            # "microsoft.storage/storageaccounts","microsoft.keyvault/vaults"
            $Payload = @{query = "resources | where ['type'] in ($SecondaryFilter) | extend  replacedType=replace('microsoft.', '',type) | project id, name, type=replacedType, location, subscriptionId" }
        }
        'Location' {
            # "eastus","westeurope"
            $Payload = @{query = "resources | where ['location'] in ($SecondaryFilter) | extend  replacedType=replace('microsoft.', '',type) | project id, name, type=replacedType, location, subscriptionId" }
        }
    }

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
        $splat.Body

        Invoke-RestMethod @Splat
    }
    catch {
        Write-Warning $_.Exception.Message
    }
}