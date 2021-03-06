<#
    This file is part of PAudit available from https://github.com/OneLogicalMyth/PAudit
    Created by Liam Glanfield @OneLogicalMyth

    PAudit is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    PAudit is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with PAudit.  If not, see <http://www.gnu.org/licenses/>.
#>
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
