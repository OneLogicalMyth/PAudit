# NAME:         Get-MountPoints.ps1
# AUTHOR:       Liam Glanfield
# CREATED DATE: 18/11/2015
# CHANGED DATE: 18/11/2015
# VERSION:      1.0.0
# DESCRIPTION:  Collects mount point information from WMI

# Error handling
$ErrorActionPreference = 'SilentlyContinue'
$Errors = @()
$Error.Clear()

#region Start collecting data

$Output = Get-WmiObject -Class Win32_Volume -Filter 'driveletter=NULL AND Capacity != NULL AND Label != "System Reserved"' | Select-Object @(
	'Name',
	'Label',
	@{n='SizeGB';e={[math]::Round($_.Capacity / 1gb,2)}},
	@{n='FreeSpaceGB';e={[math]::Round($_.FreeSpace / 1gb,2)}}
)

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