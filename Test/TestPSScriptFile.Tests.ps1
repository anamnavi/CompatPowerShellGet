# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

$modPath = "$psscriptroot/../PSGetTestUtils.psm1"
Import-Module $modPath -Force -Verbose
Write-Verbose -Verbose -Message "PowerShellGet version currently loaded: $($(Get-Module powershellget).Version)"
$testDir = (get-item $psscriptroot).parent.FullName

Describe "Test CompatPowerShellGet: Test-PSScriptFile" -tags 'CI' {
    BeforeAll {
        $tmpDir1Path = Join-Path -Path $TestDrive -ChildPath "tmpDir1"
        $tmpDirPaths = @($tmpDir1Path)
        Get-NewTestDirs($tmpDirPaths)

        # Path to folder, within our test folder, where we store invalid module and script files used for testing
        $script:testFilesFolderPath = Join-Path $testDir -ChildPath "testFiles"

        # Path to specifically to that invalid test scripts folder
        $script:testScriptsFolderPath = Join-Path $testFilesFolderPath -ChildPath "testScripts"
    }

    It "determine script file with minimal required fields as valid" {    
        $scriptFilePath = Join-Path -Path $tmpDir1Path -ChildPath "testscript.ps1"
        $scriptDescription = "this is a test script"
        $guid = [guid]::NewGuid()
        $author = "Script Author"
        $version = "1.0.0"
        New-PSScriptFile -Path $scriptFilePath -Description $scriptDescription -Guid $guid -Author $author -Version $version
        Test-ScriptFileInfo $scriptFilePath | Should -Be $true
    }

    It "not determine script file with Author field missing as valid" {
        $scriptName = "InvalidScriptMissingAuthor.ps1"
        $scriptFilePath = Join-Path $script:testScriptsFolderPath -ChildPath $scriptName

        Test-ScriptFileInfo $scriptFilePath | Should -Be $false
    }

    It "not determine script file with Description field missing as valid" {
        $scriptName = "InvalidScriptMissingDescription.ps1"
        $scriptFilePath = Join-Path $script:testScriptsFolderPath -ChildPath $scriptName

        Test-ScriptFileInfo $scriptFilePath | Should -Be $false
    }

    It "not determine script that is missing Description block altogether as valid" {
        $scriptName = "InvalidScriptMissingDescriptionCommentBlock.ps1"
        $scriptFilePath = Join-Path $script:testScriptsFolderPath -ChildPath $scriptName

        Test-ScriptFileInfo $scriptFilePath | Should -Be $false
    }

    It "not determine script file Guid as valid" {
        $scriptName = "InvalidScriptMissingGuid.ps1"
        $scriptFilePath = Join-Path $script:testScriptsFolderPath -ChildPath $scriptName

        Test-ScriptFileInfo $scriptFilePath | Should -Be $false
    }

    It "not determine script file missing Version as valid" {
        $scriptName = "InvalidScriptMissingVersion.ps1"
        $scriptFilePath = Join-Path $script:testScriptsFolderPath -ChildPath $scriptName

        Test-ScriptFileInfo $scriptFilePath | Should -Be $false
    }

    It "determine script without empty lines in PSScriptInfo comment content is valid" {
        $scriptName = "ScriptWithoutEmptyLinesInMetadata.ps1"
        $scriptFilePath = Join-Path $script:testScriptsFolderPath -ChildPath $scriptName

        Test-ScriptFileInfo $scriptFilePath | Should -Be $true        
    }

    It "determine script without empty lines between comment blocks is valid" {
        $scriptName = "ScriptWithoutEmptyLinesBetweenCommentBlocks.ps1"
        $scriptFilePath = Join-Path $script:testScriptsFolderPath -ChildPath $scriptName

        Test-ScriptFileInfo $scriptFilePath | Should -Be $true        
    }
}

# Ensure that PSGet v2 was not loaded during the test via command discovery
$PSGetVersionsLoaded = (Get-Module powershellget).Version
Write-Host "PowerShellGet versions currently loaded: $PSGetVersionsLoaded"
if ($PSGetVersionsLoaded.Count -gt 1) {
    throw  "There was more than one version of PowerShellGet imported into the current session. `
        Imported versions include: $PSGetVersionsLoaded"
}