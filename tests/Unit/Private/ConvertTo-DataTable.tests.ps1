BeforeAll {
    $script:dscModuleName = 'azureTUI'

    Import-Module -Name $script:dscModuleName
}

AfterAll {
    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe ConvertTo-DataTable {
    Context 'dummy test' {
        It 'dummy test' {
            InModuleScope -ModuleName $dscModuleName {
                $true| Should -Be $true
            }
        }
    }
}

