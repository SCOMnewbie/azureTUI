function Get-KeyvaultInstances {
    [cmdletbinding()]
    param (
        [parameter(mandatory)]
        [string]$AccessToken,
        [string]$APIVersion = '2022-10-01'
    )
    
    $Payload = @{ query = "resources | where type == `"microsoft.keyvault/vaults`" | project name" }

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