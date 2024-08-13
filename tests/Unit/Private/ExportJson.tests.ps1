BeforeAll {
    $script:dscModuleName = 'azureTUI'

    Import-Module -Name $script:dscModuleName
}

AfterAll {
    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe ExportJson {
    Context 'When calling the function with string value' {
        It 'true equal true' {
            InModuleScope -ModuleName $dscModuleName {
                $true| Should -Be $true
            }
        }
    }
}

