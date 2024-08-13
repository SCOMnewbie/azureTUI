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
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '')]
    [cmdletbinding()]
    param (
        [switch]$WAM,
        [parameter(mandatory)]
        [guid]$ClientId,
        [parameter(mandatory)]
        [guid]$TenantId
    )

    begin {
        $script:moduleversion = (Get-Module azureTUI).version.ToString()

        if ($WAM) {
            if ($IsWindows) {
                # Use ThreadJob to avoid waiting several seconds on launch
                Start-ThreadJob {
                    $ARMToken = Get-EntraToken -WAMFlow -ClientId $args[0] -TenantId $args[1] -Resource ARM -Permissions user_impersonation | ForEach-Object AccessToken
                    [Environment]::SetEnvironmentVariable('ARMToken', $ARMToken)
                } -ArgumentList $ClientId, $TenantId | Out-Null

                Start-ThreadJob {
                    $KeyVaultToken = Get-EntraToken -WAMFlow -ClientId $args[0] -TenantId $args[1] -Resource Keyvault -Permissions user_impersonation | ForEach-Object AccessToken
                    [Environment]::SetEnvironmentVariable('KeyVaultToken', $KeyVaultToken)
                } -ArgumentList $ClientId, $TenantId | Out-Null

                Start-ThreadJob {
                    $StorageToken = Get-EntraToken -WAMFlow -ClientId $args[0] -TenantId $args[1] -Resource Storage -Permissions user_impersonation | ForEach-Object AccessToken
                    [Environment]::SetEnvironmentVariable('StorageToken', $StorageToken)
                } -ArgumentList $ClientId, $TenantId | Out-Null

                Start-ThreadJob {
                    $GraphAPIToken = Get-EntraToken -WAMFlow -ClientId $args[0] -TenantId $args[1] -Resource GraphAPI -Permissions @('user.read') | ForEach-Object AccessToken
                    [Environment]::SetEnvironmentVariable('GraphAPIToken', $GraphAPIToken)
                } -ArgumentList $ClientId, $TenantId | Out-Null
            }
            else {
                Throw 'WAM is available on Windows only!'
            }

        }
        else {
            #Auth Code flow
            $script:ARMToken = Get-EntraToken -PublicAuthorizationCodeFlow -ClientId $ClientId -TenantId $TenantId -Resource ARM -Permissions user_impersonation -WithLocalCaching | ForEach-Object AccessToken
            $script:KeyVaultToken = Get-EntraToken -PublicAuthorizationCodeFlow -ClientId $clientId -TenantId $TenantId -Resource Keyvault -Permissions user_impersonation -WithLocalCaching | ForEach-Object AccessToken
            $script:StorageToken = Get-EntraToken -PublicAuthorizationCodeFlow -ClientId $clientId -TenantId $TenantId -Resource Storage -Permissions user_impersonation -WithLocalCaching | ForEach-Object AccessToken
            $script:StorageToken = Get-EntraToken -PublicAuthorizationCodeFlow -ClientId $clientId -TenantId $TenantId -Resource GraphAPI -Permissions user_impersonation -WithLocalCaching | ForEach-Object AccessToken
        }

        Function resourceForm {
            #Resource
            $Resource_txtFilter.Enabled = $true
            $Resource_lblFilter.Enabled = $true
            $Resource_btnQuery.Enabled = $true
            $Resource_RadioGroup.Enabled = $true
            $Resource_txtFilter.Visible = $true
            $Resource_lblFilter.Visible = $true
            $Resource_btnQuery.Visible = $true
            $Resource_RadioGroup.Visible = $true
            $Resource_TableView.Table = $null
            $Resource_txtFilter.Text = ''
            $Resource_radioGroup.SelectedItem = 0
            $StatusBar.Items[0].Title = Get-Date -Format g
            $StatusBar.Items[3].Title = 'Ready'
            $Resource_txtFilter.Text = 'Reloaded'
            $Resource_txtFilter.SetFocus()
            [Application]::Refresh()
        }

        function GetInfo {
            param(
                $PrimaryFilter,
                $SecondaryFilter
            )
            # Get-AzureResources -AccessToken $ARMToken -PrimaryFilter Subcription -SecondaryFilter  "ede55c01-c21c-4aaa-bd47-4e3021a7b938,7c97d68a-0420-42d8-9b3b-761e42ca7db5"

            $splat = @{
                AccessToken     = $([Environment]::GetEnvironmentVariable('ARMToken'))
                PrimaryFilter   = $PrimaryFilter
                SecondaryFilter = $SecondaryFilter
                ErrorAction     = 'Stop'
            }

            Try {
                # In case a user keep the tool open more than an hour
                if ($WAM) {
                    Get-EntraToken -WAMFlow -ClientId $ClientId -TenantId $TenantId -Resource ARM -Permissions user_impersonation | Out-Null
                }
                else{
                    Get-EntraToken -PublicAuthorizationCodeFlow -ClientId $ClientId -TenantId $TenantId -Resource ARM -Permissions user_impersonation -WithLocalCaching
                }

                $script:resources = Get-AzureResource @splat |
                    Select-Object -ExpandProperty Data |
                    Group-Object -Property Id -AsHashTable -AsString
                $Resource_TableView.Table = $script:resources.GetEnumerator() |
                    ForEach-Object { $_.value |
                            Select-Object Name, Location, SubscriptionId, Type, Id
                        } | ConvertTo-DataTable

                $StatusBar.Items[0].Title = "Updated: $(Get-Date -Format g)"
                $StatusBar.Items[3].Title = "$($script:resources.count) resources discovered"
                $Resource_TableView.SetFocus()
            }
            Catch {
                [MessageBox]::ErrorQuery('Error!', "Failed to query Azure Graph services. $($_.Exception.Message)", 0, @('OK'))
                $StatusBar.Items[0].Title = Get-Date -Format g
                $StatusBar.Items[3].Title = 'Ready'
            }
            Finally {
                [Application]::Refresh()
            }
        }

        function authTokenInfo {
            @"
ARM Token: $($([Environment]::GetEnvironmentVariable('ARMToken')) ? 'generated' : 'Not generated')
KeyVault token: $($([Environment]::GetEnvironmentVariable('KeyvaultToken')) ? 'generated' : 'Not generated')
Storage token: $($([Environment]::GetEnvironmentVariable('StorageToken')) ? 'generated' : 'Not generated')
GraphAPI token: $($([Environment]::GetEnvironmentVariable('GraphAPIToken')) ? 'generated' : 'Not generated')
Auth Mode: $($WAM ? 'WAM' : 'AuthCode')
"@
            [Application]::Refresh()
        }

        $TerminalGuiVersion = [System.Reflection.Assembly]::GetAssembly([application]).GetName().version
        $NStackVersion = [System.Reflection.Assembly]::GetAssembly([nstack.ustring]).GetName().version
    }
    process {
        #region setup
        If ($host.name -ne 'ConsoleHost') {
            Write-Warning 'This must be run in a console host.'
            Return
        }

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

        #region help menu
        $about = @"
$($MyInvocation.MyCommand) v$($script:moduleversion)
PSVersion $($PSVersionTable.PSVersion)
Terminal.Gui $TerminalGuiVersion
NStack $NStackVersion
"@

        $MenuItem3 = [MenuItem]::New('A_bout', '', { [MessageBox]::Query('About', $About) })
        #[Terminal.Gui.Application]::MainLoop.AddTimeout([TimeSpan]::FromSeconds(10), { $aboutTokens } );
        $MenuItem4 = [MenuItem]::New('_AuthInfos', '', { [MessageBox]::Query('AuthInfo', $(authTokenInfo)) })
        $MenuBarItem2 = [MenuBarItem]::New('_Help', @($MenuItem3,$MenuItem4))

        #endregion

        #region resource form
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

        #region Add a button to query services
        $Resource_btnQuery = [Button]@{
            X        = 1
            Y        = 2
            Width    = [Terminal.Gui.Dim]::Sized(1)
            Height   = [Terminal.Gui.Dim]::Sized(1)
            Text     = 'Get Info'
            TabIndex = 0
            Enabled  = $true
            Visible  = $true
        }

        $Resource_btnQuery.Add_Clicked({
                Switch ($Resource_radioGroup.SelectedItem) {
                    0 { $select = 'All' }
                    1 { $select = 'Subscription' }
                    2 { $select = 'Type' }
                    3 { $select = 'Location' }
                }

                $StatusBar.Items[3].Title = "Getting Azure resources group by $select and filter eq $($Resource_txtFilter.Text.Tostring())"
                $StatusBar.SetNeedsDisplay()
                $Resource_tableView.RemoveAll()
                $Resource_tableView.Clear()
                $Resource_tableView.SetNeedsDisplay()
                [Application]::Refresh()
                if ($null -eq $($Resource_txtFilter.Text.Tostring())) {
                    GetInfo -PrimaryFilter $select
                }
                else {
                    GetInfo -PrimaryFilter $select -SecondaryFilter $($Resource_txtFilter.Text.Tostring())
                }
            })
        $window.Add($Resource_btnQuery)
        #endregion

        #region add radio group
        $Resource_RadioGroup = [RadioGroup]::New(15, 3, @('All', 'Sub', 'Type', 'Location'), 0)
        $Resource_RadioGroup.Width = 1
        $Resource_RadioGroup.Height = 1
        $Resource_RadioGroup.DisplayMode = 'Horizontal'
        $Resource_RadioGroup.TabIndex = 2
        $Resource_RadioGroup.Enabled = $true
        $Resource_RadioGroup.Visible = $true
        #put the radio group next to the Get Info button
        $Resource_RadioGroup.y = $Resource_btnQuery.y
        $Window.Add($Resource_RadioGroup)
        #endregion
        #endregion

        #region Add a table view to display the results
        # https://gui-cs.github.io/Terminal.Gui/articles/tableview.html
        $Resource_TableView = [TableView]@{
            X            = 1
            Y            = 5
            Width        = [Dim]::Percent(60)
            Height       = [Dim]::Fill()
            MaxCellWidth = 23
            AutoSize     = $True
        }
        #Keep table headers always in view
        $Resource_TableView.Style.AlwaysShowHeaders = $True

        $Resource_TableView.Add_SelectedCellChanged({
                $StatusBar.Items[3].Title = $script:resources[$Resource_TableView.Table.Rows[$Resource_TableView.SelectedRow].Id].Name

                $splat = @{
                    AccessToken     = $([Environment]::GetEnvironmentVariable('ARMToken'))
                    ResourceId      = $($script:resources[$Resource_TableView.Table.Rows[$Resource_TableView.SelectedRow].Id].Id)
                    ErrorAction     = 'Stop'
                }

                $Resource_Frame2_txtDetail.Text = $(Get-AzureResourceInfo @splat | Select-Object -ExpandProperty Data | ConvertTo-Json -Depth 10 | out-string)

                # Send logs on the file system
                "" | Out-File -FilePath $(Join-Path $PSScriptRoot azureTUI.txt) -Encoding UTF8 -Append
                $Resource_Frame2_txtDetail.Text.ToString() | Out-File -FilePath $(Join-Path $PSScriptRoot azureTUI.txt) -Encoding UTF8 -Append
            })

        $window.Add($Resource_TableView)

        $Resource_Frame2 = [FrameView]::New()
        $Resource_Frame2.Width = [Dim]::Fill()
        $Resource_Frame2.Height = [Dim]::Fill()

        # Set position relative to frame1
        $Resource_Frame2.X = [Pos]::Right($Resource_TableView)
        $Resource_Frame2.Y = 5
        $Resource_Frame2.Title = 'Resource information:'

        $Resource_Frame2_txtDetail = [TextView]::New()
        $Resource_Frame2_txtDetail.Text = 'Select a resource and details will appear here'
        #$Resource_Frame2_txtDetail.ReadOnly = $True
        $Resource_Frame2_txtDetail.x = 1
        $Resource_Frame2_txtDetail.Width = [Dim]::Fill()
        $Resource_Frame2_txtDetail.Height = [Dim]::Fill()

        $Resource_Frame2.Add($Resource_Frame2_txtDetail)
        $Window.Add($Resource_Frame2)
        #endregion

        #region add menus

        $MenuItem0 = [MenuItem]::New('_Resources', '', { resourceForm })
        $MenuItem1 = [MenuItem]::New('_Quit', '', { [Application]::RequestStop() })
        #$MenuItem2 = [MenuItem]::New('Keyvault', '', { KeyvaultForm })
        $MenuBarItem0 = [MenuBarItem]::New('_Options', @($MenuItem0, $MenuItem1))

        $ExportJsonMenuItem = [MenuItem]::New('as JSON', '', { ExportJson })
        $MenuBarItem1 = [MenuBarItem]::New('_Export', @($ExportJsonMenuItem))


        $MenuBar = [MenuBar]::New(@($MenuBarItem0,$MenuBarItem1,$MenuBarItem2))
        $Window.Add($MenuBar)
        #endregion

        [Application]::Top.Add($window)

        $Green = [Color]::Green
        $Black = [Color]::Black
        [Colors]::Base.Normal = [Application]::Driver.MakeAttribute($Green,$Black)
        [Colors]::Base.hotNormal = [Application]::Driver.MakeAttribute($Green,$Black)
        [Colors]::Base.Focus = [Application]::Driver.MakeAttribute($Green,$Black)

        [Application]::Run()
    }
    end {
        [Environment]::SetEnvironmentVariable('ARMToken','')
        [Environment]::SetEnvironmentVariable('KeyVaultToken', '')
        [Environment]::SetEnvironmentVariable('StorageToken', '')
        [Environment]::SetEnvironmentVariable('GraphAPIToken', '')
        [Application]::ShutDown()
    }
}