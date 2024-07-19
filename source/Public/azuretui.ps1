Using namespace Terminal.Gui

function azureTUI {
    <#
    .SYNOPSIS
    This function fetch Azure data through Azure Graph.
    .DESCRIPTION
    This function fetch Azure data through Azure Graph.
    .PARAMETER WAM
        Specify WAM as authentication method to connect Entra
    .PARAMETER ClientId
        Specify ClientId to authenticate to Entra
    .PARAMETER TenantId
        Specify TenantId to authenticate to Entra
    .EXAMPLE
    PS> azureTUI -WAM -clientId 123

    "will fetch all Azure resources you can read"
    .NOTES
    VERSION HISTORY
    1.0 | 2024/07/19 | Francois LEON
        initial version
    POSSIBLE IMPROVEMENT
        -
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingEmptyCatchBlock", "")]
    [cmdletbinding()]
    param (
        [parameter(mandatory)]
        [switch]$WAM,
        [parameter(mandatory)]
        [guid]$ClientId,
        [parameter(mandatory)]
        [guid]$TenantId
    )

    begin {
        $script:moduleversion = (Get-Module azureTUI).version.ToString()

        if ($WAM) {
            $script:ARMToken = Get-EntraToken -WAMFlow -ClientId $ClientId -TenantId $TenantId -Resource ARM -Permissions user_impersonation | ForEach-Object AccessToken
            $script:KeyVaultToken = Get-EntraToken -WAMFlow -ClientId $clientId -TenantId $TenantId -Resource Keyvault -Permissions user_impersonation | ForEach-Object AccessToken
            $script:StorageToken = Get-EntraToken -WAMFlow -ClientId $clientId -TenantId $TenantId -Resource Storage -Permissions user_impersonation | ForEach-Object AccessToken
        }
        else {
            #Auth Code flow
            $script:ARMToken = Get-EntraToken -PublicAuthorizationCodeFlow -ClientId $ClientId -TenantId $TenantId -Resource ARM -Permissions user_impersonation | ForEach-Object AccessToken
            $script:KeyVaultToken = Get-EntraToken -PublicAuthorizationCodeFlow -ClientId $clientId -TenantId $TenantId -Resource Keyvault -Permissions user_impersonation | ForEach-Object AccessToken
            $script:StorageToken = Get-EntraToken -PublicAuthorizationCodeFlow -ClientId $clientId -TenantId $TenantId -Resource Storage -Permissions user_impersonation | ForEach-Object AccessToken
        }
    }
    process {
        #region setup
        If ($host.name -ne 'ConsoleHost') {
            Write-Warning 'This must be run in a console host.'
            Return
        }

        <#
        $dlls = '..\assemblies\NStack.dll', '..\assemblies\Terminal.Gui.dll'
        ForEach ($item in $dlls) {
            Try {
                Add-Type -Path $item -ErrorAction Stop
            }
            Catch [System.IO.FileLoadException] {
                #write-host "already loaded" -ForegroundColor yellow
            }
            Catch {
                Throw $_
            }
        }
        #>
        #$TerminalGuiVersion = [System.Reflection.Assembly]::GetAssembly([application]).GetName().version
        #$NStackVersion = [System.Reflection.Assembly]::GetAssembly([nstack.ustring]).GetName().version

        [Application]::Init()
        [Application]::QuitKey = 27
        #[Key]::Esc
        #endregion

        #region create the main window and status bar
        $window = [Window]@{
            Title = 'Azure browser'
        }

        $StatusBar = [StatusBar]::New(
            @(
                [StatusItem]::New('Unknown', $(Get-Date -Format g), {}),
                [StatusItem]::New('Unknown', 'ESC to quit', {}),
                [StatusItem]::New('Unknown', "$script:moduleversion", {}),
                [StatusItem]::New('Unknown', 'Ready', {})
            )
        )

        [Application]::Top.add($StatusBar)
        #endregion

        [Application]::Top.Add($window)
        [Application]::Run()
    }
    end {
        [Application]::ShutDown()
    }
}