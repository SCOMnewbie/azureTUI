function Get-KeyvaultSecrets {
    [cmdletbinding()]
    param (
        [parameter(mandatory)]
        [string]$AccessToken,
        [string]$KeyvaultName,
        [string]$APIVersion = '7.4'
    )

    $Headers = @{
        'Content-Type' = 'application/json'
        Authorization  = "Bearer $AccessToken" 
    }

    $Params = @{
        Headers     = $Headers
        uri         = "https://$KeyvaultName.vault.azure.net/secrets?maxresults=25&api-version=$APIVersion"
        Body        = $null
        method      = 'Get'
        ErrorAction = 'Stop'
    }

    $QueryResults = @()
    do {
        $Results = Invoke-RestMethod @Params
        if ($Results.value) {
            $QueryResults += $Results.value
        }
        else {
            $QueryResults += $Results
        }
        $Params.uri = $Results.nextLink
    } until (!($Params.uri))
    
    $QueryResults
    # Return the result. (https://myvault.vault.azure.net/secrets/secret01)
    #$myHashtable = @{
    #    value     = $($QueryResults.ForEach({$_.id -split '/' | Select-Object -Last 1}))
    #}
    #[pscustomobject]$myHashtable
    
}