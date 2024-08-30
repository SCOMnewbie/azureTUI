#requires -version 7.3

<#
Create a Terminal.GUI form that displays service information for
a specified computer.
#>
Using namespace Terminal.Gui

$ClientId = '424cea94-f675-486d-8f0c-46a097c735d5'
$TenantId = 'e01bd386-fa51-4210-a2a4-29e5ab6f7ab1'

. $PSScriptRoot\Get-KeyvaultInstances
. $PSScriptRoot\ConvertTo-DataTable
. $PSScriptRoot\Get-KeyvaultSecrets
. $PSScriptRoot\Get-KeyvaultSecretsValue

$script:ARMToken = Get-EntraToken -WAMFlow -ClientId $ClientId -TenantId $TenantId -Resource ARM -Permissions user_impersonation | ForEach-Object AccessToken
[Environment]::SetEnvironmentVariable('ARMToken', $ARMToken)
$script:KeyVaultToken = Get-EntraToken -WAMFlow -ClientId $ClientId -TenantId $TenantId -Resource Keyvault -Permissions user_impersonation | ForEach-Object AccessToken
[Environment]::SetEnvironmentVariable('KeyVaultToken', $KeyVaultToken)
#endregion

Function resourceForm {
    #Resource
    $Resource_lblFilter.Visible = $true
    $Resource_txtFilter.Visible = $true
    
    # Keyvault
    $Keyvault_Name_Frame.Visible = $false
    $Keyvault_Secret_Frame.Visible = $false
    $Keyvault_Secret_Version_Frame.Visible = $false
    $Keyvault_Secret_Value_Frame.Visible = $false
    $Keyvault_btnQuery.Visible = $false
    $Keyvault_Frame2.visible = $false
    

    $Resource_txtFilter.Text = ' reloaded'
    $Resource_txtFilter.SetFocus()
    [Application]::Refresh()
}

Function keyvaultForm {
    #Resource
    $Resource_lblFilter.Visible = $false
    $Resource_txtFilter.Visible = $false
    
    # Keyvault
    $Keyvault_Name_Frame.Visible = $true
    $Keyvault_Secret_Frame.Visible = $true
    $Keyvault_Secret_Version_Frame.Visible = $true
    $Keyvault_Secret_Value_Frame.Visible = $true
    $Keyvault_btnQuery.Visible = $true
    $Keyvault_Frame2.visible = $true

    #$splat = @{
    #    AccessToken     = $([Environment]::GetEnvironmentVariable('ARMToken'))
    #    ErrorAction     = 'Stop'
    #}
    #$Keyvault_Name_Frame_txtDetail.Text = $(Get-KeyvaultInstances @splat | Select-Object -ExpandProperty Data | Select-Object -ExpandProperty Name | out-string)
    [Application]::Refresh()
}

#region setup

If ($host.name -ne 'ConsoleHost') {
    Write-Warning 'This must be run in a console host.'
    Return
}

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
$scriptVer = '0.8.0'
$TerminalGuiVersion = [System.Reflection.Assembly]::GetAssembly([application]).GetName().version
$NStackVersion = [System.Reflection.Assembly]::GetAssembly([nstack.ustring]).GetName().version

[Application]::Init()
[Application]::QuitKey = 27
#[Key]::Esc

#endregion

#region create the main window and status bar
$window = [Window]@{
    Title = 'Azure browser'
}

#region resource
#region Add a label and text box for the Filter
$Resource_lblFilter = [Label]@{
    X       = 1
    Y       = 4
    Text    = 'Filter:'
    Enabled = $true
    Visible = $true
}
$window.Add($Resource_lblFilter)

$Resource_txtFilter = [TextField]@{
    X        = 10
    Y        = 4
    Width    = 130
    Text     = ''
    TabIndex = 1
    Enabled  = $true
    Visible  = $true
}

$window.Add($Resource_txtFilter)
#endregion

#endregion

#region Keyvault (by default hidden)

$Keyvault_Name_Frame_TableView = [TableView]@{
    X        = 0
    Y        = 2
    Width    = [Dim]::Percent(25)
    Height   = [Dim]::Fill()
    AutoSize = $true
}

$window.Add($Keyvault_Name_Frame_TableView)
#$Keyvault_Name_Frame.Add($Keyvault_Name_Frame_TableView)

$Keyvault_Name_Frame_TableView.Add_SelectedCellChanged({

        try {
            $Keyvault_Secret_Frame_TableView.RemoveAll()
            $Keyvault_Secret_Frame_TableView.Clear()
            $Keyvault_Secret_Frame_TableView.SetNeedsDisplay()
            #$StatusBar.Items[3].Title = $script:resources[$TableView.Table.Rows[$TableView.SelectedRow].Id].Name
            $KV = $script:Keyvault_Resources[$Keyvault_Name_Frame_TableView.Table.Rows[$Keyvault_Name_Frame_TableView.SelectedRow].Name].Name
    
            $splat = @{
                AccessToken  = $(Get-EntraToken -WAMFlow -ClientId $ClientId -TenantId $TenantId -Resource Keyvault -Permissions user_impersonation | ForEach-Object AccessToken)
                KeyvaultName = $KV
                ErrorAction  = 'Stop'
            }

            $script:KeyvaultSecrets = Get-KeyvaultSecrets @splat |
                                        Select-Object Id,
                                            @{Name="Secrets";Expression={$_.Id -split'/' | Select-Object -Last 1}},
                                            @{Name="Enabled";Expression={$_.Attributes.enabled}},
                                            @{Name="Created";Expression={(([System.DateTimeOffset]::FromUnixTimeSeconds($_.Attributes.created)).DateTime).ToString("yyyy/MM/dd")}} |
                                        Group-Object -Property Id -AsHashTable -AsString

            $Keyvault_Secret_Frame_TableView.Table = $script:KeyvaultSecrets.GetEnumerator() |
                                                        ForEach-Object { $_.value |
                                                                Select-Object Secrets,Enabled,Created,Id
                                                            } | ConvertTo-DataTable
        }
        catch {
            [MessageBox]::ErrorQuery('Error!', "Unable to access the Keyvault. $($_.Exception.Message)", 0, @('OK'))
        }
       
        [Application]::Refresh()
        #$Keyvault_Secret_Frame_TableView.SetFocus()
    })

$Keyvault_Secret_Frame_TableView = [TableView]@{
    X        = [Pos]::Right($Keyvault_Name_Frame_TableView)
    Y        = 2
    Width    = [Dim]::Percent(50)
    Height   = [Dim]::Fill()
    AutoSize = $true
    MaxCellWidth = 20
}
$window.Add($Keyvault_Secret_Frame_TableView)

$Keyvault_Secret_Frame_TableView.Add_SelectedCellChanged({

    try {
        #$Keyvault_Secret_Frame_TableView.RemoveAll()
        #$Keyvault_Secret_Frame_TableView.Clear()
        #$Keyvault_Secret_Frame_TableView.SetNeedsDisplay()
        #$StatusBar.Items[3].Title = $script:resources[$TableView.Table.Rows[$TableView.SelectedRow].Id].Name
        
        $SecretSelected = $script:KeyvaultSecrets[$Keyvault_Secret_Frame_TableView.Table.Rows[$Keyvault_Secret_Frame_TableView.SelectedRow].Id].Secrets
        $KV = $script:Keyvault_Resources[$Keyvault_Name_Frame_TableView.Table.Rows[$Keyvault_Name_Frame_TableView.SelectedRow].Name].Name

        $splat = @{
            AccessToken     = $(Get-EntraToken -WAMFlow -ClientId $ClientId -TenantId $TenantId -Resource Keyvault -Permissions user_impersonation | ForEach-Object AccessToken)
            KeyvaultName = $KV
            KeyvaultSecret = $SecretSelected
            ErrorAction     = 'Stop'
        }

        # | Select-Object -ExpandProperty Data
        $Keyvault_Frame2_txtDetail.Text = $(Get-KeyvaultSecretsValue @splat | ConvertTo-Json -Depth 10 | out-string)
    }
    catch {
        [MessageBox]::ErrorQuery('Error!', "Unable to access the Keyvault secrets. $($_.Exception.Message)", 0, @('OK'))
    }
   
    [Application]::Refresh()
    #$Keyvault_Secret_Frame_TableView.SetFocus()
})

$Keyvault_btnQuery = [Button]@{
    X       = 1
    Y       = 1
    Width   = [Terminal.Gui.Dim]::Sized(1)
    Height  = [Terminal.Gui.Dim]::Sized(1)
    Text    = '_Get Info'
    visible = $false
}

$Keyvault_btnQuery.Add_Clicked({
    
        $splat = @{
            AccessToken = $([Environment]::GetEnvironmentVariable('ARMToken'))
            ErrorAction = 'Stop'
        }

        $script:Keyvault_Resources = Get-KeyvaultInstances @splat | 
            Select-Object -ExpandProperty Data |
            Group-Object -Property name -AsHashTable -AsString

        $Keyvault_Name_Frame_TableView.Table = $script:Keyvault_Resources.GetEnumerator() |
            ForEach-Object { $_.value |
                    Select-Object Name
                } | ConvertTo-DataTable
        [Application]::Refresh()
        $Keyvault_Name_Frame_TableView.SetFocus()
    })
$window.Add($Keyvault_btnQuery)

$Keyvault_Frame2 = [FrameView]::New()
$Keyvault_Frame2.Width = [Dim]::Fill()
$Keyvault_Frame2.Height = [Dim]::Fill()
$Keyvault_Frame2.X = [Pos]::Right($Keyvault_Secret_Frame_TableView)
$Keyvault_Frame2.Y = 2
$Keyvault_Frame2.Title = 'Resource information:'
$Keyvault_Frame2.visible = $false

$Keyvault_Frame2_txtDetail = [TextView]::New()
$Keyvault_Frame2_txtDetail.Text = 'Secrets information will be exposed here'
#$Keyvault_Frame2_txtDetail.x = 1
$Keyvault_Frame2_txtDetail.Width = [Dim]::Fill()
$Keyvault_Frame2_txtDetail.Height = [Dim]::Fill()

$Keyvault_Frame2.Add($Keyvault_Frame2_txtDetail)
$Window.Add($Keyvault_Frame2)

#endregion

#region add menus

$MenuItem0 = [MenuItem]::New('_Resources', '', { resourceForm })
$MenuItem1 = [MenuItem]::New('_Quit', '', { [Application]::RequestStop() })
$MenuItem2 = [MenuItem]::New('Keyvault', '', { KeyvaultForm })
$MenuBarItem0 = [MenuBarItem]::New('_Options', @($MenuItem0, $MenuItem2, $MenuItem1))


$MenuBar = [MenuBar]::New(@($MenuBarItem0))
$Window.Add($MenuBar)
#endregion

[Application]::Top.Add($window)
[Application]::Run()
[Application]::ShutDown()

#end of file