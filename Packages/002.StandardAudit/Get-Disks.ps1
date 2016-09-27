# NAME:         Get-Disks.ps1
# AUTHOR:       Liam Glanfield
# CREATED DATE: 18/11/2015
# CHANGED DATE: 18/11/2015
# VERSION:      1.0.0
# DESCRIPTION:  Collects disk information from WMI

# Error handling
$ErrorActionPreference = 'SilentlyContinue'
$Errors = @()
$Error.Clear()

#region Start collecting data

$Output = Get-WmiObject -Class Win32_DiskDrive | Select-Object @(
	'LastErrorCode',
	'NeedsCleaning',
	'StatusInfo',
	'Partitions',
	'BytesPerSector',
	@{ n = 'DiskNumber'; e = { $_.Index } },
	'InstallDate',
	'InterfaceType',
	'SectorsPerTrack',
	'Size',
	'TotalCylinders',
	'TotalHeads',
	'TotalSectors',
	'TotalTracks',
	'TracksPerCylinder',
	'Caption',
	'Description',
	'FirmwareRevision',
	'Manufacturer',
	'MediaLoaded',
	'MediaType',
	'Model',
	'SerialNumber',
	'Signature',
	'DeviceID'
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