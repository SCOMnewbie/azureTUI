BeforeAll {
    $script:dscModuleName = 'azureTUI'

    Import-Module -Name $script:dscModuleName
}

AfterAll {
    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe Get-AzureResource {
    Context 'When calling the function with string value' {
        It 'Should throw with dummy value' {
            InModuleScope -ModuleName $dscModuleName {
                {Get-AzureResource -AccessToken "fake" -PrimaryFilter 'blah'} | Should -Throw
            }
        }
    }
}

