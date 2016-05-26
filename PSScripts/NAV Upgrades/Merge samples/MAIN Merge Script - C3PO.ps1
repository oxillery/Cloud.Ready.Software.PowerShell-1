﻿#parameters
$CurrentDirectory          = 'C:\_Merge\Comfort14ToNav2016Cu6'
$OriginalFile              = Get-ChildItem 'C:\_Merge\Comfort14ToNav2016Cu6\NAV2015_CU2_AllObjects.txt'
$ModifiedFile              = Get-ChildItem 'C:\_Merge\Comfort14ToNav2016Cu6\Cmfrt2015_14_CU2_AllObjects.txt'
$TargetFile                = Get-ChildItem 'C:\_Merge\Comfort14ToNav2016Cu6\NAV2016_CU6_AllObjects.txt'
$ResultFile                = Join-Path $CurrentDirectory 'Cmfrt2016_Result.txt'
$MergeResultFolder         = Join-Path $CurrentDirectory 'Result'
$LanguageFolder            = Join-Path $CurrentDirectory 'Languages'
$FilteredMergeResultFolder = Join-Path $CurrentDirectory 'Result_Filtered'
$VersionListPrefixes       = 'NAVW1', 'NAVBE', 'Cmfrt'
$RemoveLanguageArr         = 'NLB','FRB'
$MergeServerInstance       = 'Cmfrt2016_Merge'

#enable/disable required functions:
$SplitFiles                   = $false  #This may take a while (depending on the amount of objects)
$CreateDeltas                 = $false
$RemoveLanguages              = $true
$MergeVersions                = $true
$updateVersionList            = $true
$updateDateTime               = $true
$CreateFilteredResultFolder   = $true
$CreateFullResultText         = $true
$DisplayObjectFilters         = $false
$OpenAraxisMergeWhenConflicts = $false
$ImportMergeResultIntoMergeDb = $true
$ImportFilesSeparately        = $true
$CompileDatabase              = $true

#Constants
$ScriptDirectory   = $PSScriptRoot
$MergetoolPath     = 'C:\Program Files\Araxis\Araxis Merge\Merge.exe'
$OriginalFolder  = $OriginalFile.DirectoryName + '\Split_' + $OriginalFile.BaseName
$ModifiedFolder  = $ModifiedFile.DirectoryName + '\Split_' + $ModifiedFile.BaseName
$TargetFolder    = $TargetFile.DirectoryName   + '\Split_' + $TargetFile.BaseName
$DeltaFolderOriginalModified  = $CurrentDirectory  + '\Delta_' + $OriginalFile.BaseName + 'vs' + $ModifiedFile.BaseName
$DeltaFolderOriginalTarget    = $CurrentDirectory  + '\Delta_' + $OriginalFile.BaseName + 'vs' + $TargetFile.BaseName
$DeltaFolderModifiedTarget    = $CurrentDirectory  + '\Delta_' + $ModifiedFile.BaseName + 'vs' + $TargetFile.BaseName
$MergeInfoFolder = "$MergeResultFolder\MergeInfo"
$ImportLogFolder = "$CurrentDirectory\ImportLog"
$CompileLogFolder = "$CurrentDirectory\CompileLog"

#Script Execution
Import-Module "${env:ProgramFiles(x86)}\Microsoft Dynamics NAV\90\RoleTailored Client\Microsoft.Dynamics.Nav.Model.Tools.psd1" -force
import-module "${env:ProgramFiles}\Microsoft Dynamics NAV\90\Service\NavAdminTool.ps1” | Out-Null
Import-module "C:\PowerShell Tools\Cloud.Ready.Software.PowerShell\PSModules\LoadModules.ps1" | Out-Null

cd $CurrentDirectory
Clear-Host
Write-host 'All set.  Starting Script Execution...' -ForegroundColor Green

If ($SplitFiles) {
    Write-Host 'Splitting files' -ForegroundColor Green
    if (-not (Test-Path $OriginalFolder)) {
        Write-Host "Splitting $OriginalFile to folder $OriginalFolder.  Sit back and relax, because this can take a while..." -ForegroundColor White
        New-Item -Path $OriginalFolder -ItemType directory | Out-null
        Split-NAVApplicationObjectFile -Source $OriginalFile -Destination $OriginalFolder
    } 

    if (-not (Test-Path $ModifiedFolder)) {
        Write-Host "Splitting $ModifiedFile to folder $ModifiedFolder.  Sit back and relax, because this can take a while..." -ForegroundColor White
        New-Item -Path $ModifiedFolder -ItemType directory | Out-null
        Split-NAVApplicationObjectFile -Source $ModifiedFile -Destination $ModifiedFolder
    } 

    if (-not (Test-Path $TargetFolder)) {
        Write-Host "Splitting $TargetFile to folder $TargetFolder.  Sit back and relax, because this can take a while..." -ForegroundColor White
        New-Item -Path $TargetFolder -ItemType directory | Out-null
        Split-NAVApplicationObjectFile -Source $TargetFile -Destination $TargetFolder
    }
    
}

if($CreateDeltas){
    Write-host "Creating Delta's..." -ForegroundColor Green
    Write-Host 'Creating delta between Original and Modified ...' -ForegroundColor White
    if(Test-Path $DeltaFolderOriginalModified) {remove-Item $DeltaFolderOriginalModified -Recurse -force | Out-null}
    New-Item -Path $DeltaFolderOriginalModified -ItemType directory
    Compare-NAVApplicationObject -Original $OriginalFile -Modified $ModifiedFile -Delta $DeltaFolderOriginalModified

    Write-Host 'Creating delta between Original and Target ...' -ForegroundColor White
    if(Test-Path $DeltaFolderOriginalTarget) {remove-Item $DeltaFolderOriginalTarget -Recurse -force | Out-null}
    New-Item -Path $DeltaFolderOriginalTarget -ItemType directory
    Compare-NAVApplicationObject -Original $OriginalFile -Modified $TargetFile -Delta $DeltaFolderOriginalTarget
  
    #Write-Host "Creating delta between Modified and Target ..." -ForegroundColor White
    #if(Test-Path $DeltaFolderModifiedTarget) {remove-Item $DeltaFolderModifiedTarget -Recurse -force | Out-null}
    #New-Item -Path $DeltaFolderModifiedTarget -ItemType directory
    #Compare-NAVApplicationObject -Original $ModifiedFile -Modified $TargetFile -Delta $DeltaFolderModifiedTarget
}

if($RemoveLanguages){
    Copy-Item -Path $OriginalFile -Destination "$OriginalFile.backup"
    Copy-Item -Path $ModifiedFile -Destination "$ModifiedFile.backup"
    Copy-Item -Path $TargetFile -Destination "$TargetFile.backup"

    IF (Test-Path $LanguageFolder) {Remove-Item $LanguageFolder -Recurse -Force}
    New-Item -Path $LanguageFolder -ItemType directory | Out-Null

    Export-NAVApplicationObjectLanguage -Source $OriginalFile -Destination (Join-Path $LanguageFolder 'Original_Languages.txt') -LanguageId $RemoveLanguageArr
    Remove-NAVApplicationObjectLanguage -Source $OriginalFile -Destination $OriginalFile -LanguageId $RemoveLanguageArr -DevelopmentLanguageId ENU -RemoveRedundant -Force

    Export-NAVApplicationObjectLanguage -Source $ModifiedFile -Destination (Join-Path $LanguageFolder 'Modified_Languages.txt') -LanguageId $RemoveLanguageArr
    Remove-NAVApplicationObjectLanguage -Source $ModifiedFile -Destination $ModifiedFile -LanguageId $RemoveLanguageArr -DevelopmentLanguageId ENU -RemoveRedundant -Force
        
    Export-NAVApplicationObjectLanguage -Source $TargetFile   -Destination (Join-Path $LanguageFolder 'Target_Languages.txt') -LanguageId $RemoveLanguageArr
    Remove-NAVApplicationObjectLanguage -Source $TargetFile -Destination $TargetFile -LanguageId $RemoveLanguageArr -DevelopmentLanguageId ENU -RemoveRedundant -Force

    #Split-NAVApplicationObjectLanguageFile -Source (Join-Path $LanguageFolder "Original_Languages.txt") -Destination (join-path $LanguageFolder "Original")
    #Split-NAVApplicationObjectLanguageFile -Source (Join-Path $LanguageFolder "Modified_Languages.txt") -Destination (join-path $LanguageFolder "Modified")
    #Split-NAVApplicationObjectLanguageFile -Source (Join-Path $LanguageFolder "Target_Languages.txt") -Destination (join-path $LanguageFolder "Target")
}

if($MergeVersions){
    Write-Host "Merging to $MergeResultFolder ..." -ForegroundColor Green

    if(Test-Path $MergeResultFolder) {remove-Item $MergeResultFolder -Recurse -force}
    New-Item -Path $MergeResultFolder -ItemType directory | Out-null

    $MergeResult = Merge-NAVApplicationObject `
    if(Test-Path $MergeInfoFolder) {Remove-Item -Path $MergeInfoFolder -Recurse -Force} 
    $MergeResult.Summary
}
            Where-Object {$_.MergeResult –eq 'Merged' -or $_.MergeResult –eq 'Conflict'}  |
}

    if($AllObjects){
        for ($i = 1; $i -lt 8; $i++)
        {
            switch ($i)
            {
                1 { Get-NAVObjectFilter -ObjectType 'Table' -ObjectCollection $AllObjects }
                2 { Get-NAVObjectFilter -ObjectType 'Page' -ObjectCollection $AllObjects }
                3 { Get-NAVObjectFilter -ObjectType 'Report' -ObjectCollection $AllObjects }
                4 { Get-NAVObjectFilter -ObjectType 'Codeunit' -ObjectCollection $AllObjects }
                5 { Get-NAVObjectFilter -ObjectType 'Query' -ObjectCollection $AllObjects }
                6 { Get-NAVObjectFilter -ObjectType 'XMLPort' -ObjectCollection $AllObjects }
                7 { Get-NAVObjectFilter -ObjectType 'MenuSuite' -ObjectCollection $AllObjects }
            }
        }
    Move-Item -Path "$ModifiedFile.backup" -Destination $ModifiedFile -Force
    Move-Item -Path "$TargetFile.backup" -Destination $TargetFile  -Force
    
}
            -DatabaseServer $databaseServer `
            -DatabaseName $ServerInstanceObject.DatabaseName `
            -NavServerName ([net.dns]::GetHostName()) `
            -NavServerInstance $MergeServerInstance `
            -NavServerManagementPort $ServerInstanceObject.ManagementServicesPort `
            -LogPath $CompileLogFolder `        
            -SynchronizeSchemaChanges:Force