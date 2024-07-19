BeforeAll {
    $script:dscModuleName = 'azureTUI'

    Import-Module -Name $script:dscModuleName
}

AfterAll {
    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe azureTUI {
    #BeforeAll {
    #    Mock -CommandName Get-PrivateFunction -MockWith {
    #        # This return the value passed to the Get-PrivateFunction parameter $PrivateData.
    #        $PrivateData
    #    } -ModuleName $dscModuleName
    #}

    Context 'true equal true' {
        It 'Should call the private function once' {
            $true | Should -Be $true
        }
    }
}

