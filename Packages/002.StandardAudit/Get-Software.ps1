# NAME:         Get-Software.ps1
# AUTHOR:       Liam Glanfield
# CREATED DATE: 18/11/2015
# CHANGED DATE: 18/11/2015
# VERSION:      1.0.0
# DESCRIPTION:  Collects software information from registry

# Error handling
$ErrorActionPreference = 'SilentlyContinue'
$Errors = @()
$Error.Clear()

#region Start collecting data

function Sort-InstallDate {
param([string]$StringDate)

    $Y = $StringDate.Substring(0,4)
    $M = $StringDate.Substring(4,2)
    $D = $StringDate.Substring(6,2)
    [datetime]"$Y-$M-$D"

}

if((Test-Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall')){
    [string[]]$RootKeys      = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
}else{
    [string[]]$RootKeys      = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
}
$Output = Get-ItemProperty -Path $RootKeys | Where-Object {
	($_.DisplayName -notlike 'Security Update for Windows*' -AND
	$_.DisplayName -notlike 'Hotfix for Windows*' -AND
	$_.DisplayName -notlike 'Update for Windows*' -AND
	$_.DisplayName -notlike 'Update for Microsoft*' -AND
	$_.DisplayName -notlike 'Security Update for Microsoft*' -AND
	$_.DisplayName -notlike 'Hotfix for Microsoft*' -AND
    $_.PSChildName -notlike '*}.KB') } | Where-Object { $_.DisplayName -ne $null -AND $_.DisplayName -ne '' } |
Select-Object Publisher, DisplayName, DisplayVersion, @{n='InstallDate';e={Sort-InstallDate $_.InstallDate}}, InstallLocation, @{n='EstimatedSizeMB';e={[math]::Round($_.EstimatedSize / 1024,2)}}

#endregion

# Collect errors and return result
$System        = Get-WmiObject Win32_ComputerSystem
$LocalComputer = $System.DNSHostName + '.' + $System.Domain
if($Output) {
	$Output = $Output | Select-Object @{n='ComputerName';e={$LocalComputer}},*
}else{
	$Output = $null
}
$Result = @{
	Errors = $Error
	Result = $Output
}

# Return result as an object
New-Object PSObject -Property $Result