# NAME:         Get-Partitions.ps1
# AUTHOR:       Liam Glanfield
# CREATED DATE: 18/11/2015
# CHANGED DATE: 18/11/2015
# VERSION:      1.0.0
# DESCRIPTION:  Collects partition information from WMI

# Error handling
$ErrorActionPreference = 'SilentlyContinue'
$Errors = @()
$Error.Clear()

#region Start collecting data

$PartProps = @(
	@{ n = 'PartitionNumber'; e = { $_.index } },
	'BlockSize',
	'Bootable',
	'BootPartition',
	@{ n = 'DiskNumber'; e = { $_.DiskIndex } },
	'NumberOfBlocks',
	'PrimaryPartition',
	'Size',
	'StartingOffset',
	'DeviceID'
)
			
$Partitions = Get-WmiObject -Class Win32_DiskPartition | Select-Object -Property $PartProps
$Output = foreach ($Partition in $Partitions)
{			
	$Volumes = Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID=`"$($Partition.DeviceID)`"} WHERE AssocClass = Win32_LogicalDiskToPartition"			
	$LogicalDrives = $Volumes | Select-Object -ExpandProperty DeviceID				
	$Partition | Select-Object *, @{ n = 'StartSector'; e = { $($_.StartingOffset / $_.BlockSize) } }, @{ n = 'BadAlignment'; e = { ($_.StartingOffset / 1024) -match '\.' } }, @{ n = 'LogicalDrives'; e = { $LogicalDrives -join ' ' } }			
}

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