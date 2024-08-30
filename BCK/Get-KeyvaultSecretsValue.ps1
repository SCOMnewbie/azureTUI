function Get-KeyvaultSecretsValue {
    [cmdletbinding()]
    param (
        [parameter(mandatory)]
        [string]$AccessToken,
        [parameter(mandatory)]
        [string]$KeyvaultName,
        [parameter(mandatory)]
        [string]$KeyvaultSecret,
        [string]$APIVersion = '7.4'
    )

    $Headers = @{
        'Content-Type' = 'application/json'
        Authorization  = "Bearer $AccessToken" 
    }

    $Params = @{
        Headers     = $Headers
        uri         = "https://$KeyvaultName.vault.azure.net/secrets/$KeyvaultSecret`?api-version=$APIVersion"
        Body        = $null
        method      = 'Get'
        ErrorAction = 'Stop'
    }

    $Params.uri

    Invoke-RestMethod @Params
}