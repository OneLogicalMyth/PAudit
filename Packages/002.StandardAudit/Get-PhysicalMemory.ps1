# NAME:         Get-PhysicalMemory.ps1
# AUTHOR:       Liam Glanfield
# CREATED DATE: 18/11/2015
# CHANGED DATE: 18/11/2015
# VERSION:      1.0.0
# DESCRIPTION:  Collects physical memory information from WMI

# Error handling
$ErrorActionPreference = 'SilentlyContinue'
$Errors = @()
$Error.Clear()

#region Start collecting data

$MemoryType = @(
	'Unknown'
	'Other'
	'DRAM'
	'Synchronous DRAM'
	'Cache DRAM'
	'EDO'
	'EDRAM'
	'VRAM'
	'SRAM'
	'RAM'
	'ROM'
	'Flash'
	'EEPROM'
	'FEPROM'
	'EPROM'
	'CDRAM'
	'3DRAM'
	'SDRAM'
	'SGRAM'
	'RDRAM'
	'DDR'
	'DDR2'
	'DDR2'
	'DDR2 FB-DIMM'
	'DDR3'
	'FBD2'
)

$FormFactor = @(
	'Unknown'
	'Other'
	'SIP'
	'DIP'
	'ZIP'
	'SOJ'
	'Proprietary'
	'SIMM'
	'DIMM'
	'TSOP'
	'PGA'
	'RIMM'
	'SODIMM'
	'SRIMM'
	'SMD'
	'SSMP'
	'QFP'
	'TQFP'
	'SOIC'
	'LCC'
	'PLCC'
	'BGA'
	'FPBGA'
	'LGA'
)

$Output = Get-WmiObject -Class Win32_PhysicalMemory | Select-Object @(
	'BankLabel',
	@{n='CapacityGB';e={$_.Capacity / 1GB}},
	'DeviceLocator',
	@{n='FormFactor';e={$FormFactor[$_.FormFactor]}},
	'HotSwappable',
	'Manufacturer',
	@{n='MemoryType';e={$MemoryType[$_.MemoryType]}},
	'PartNumber',
	'SerialNumber',
	'Speed',
	'TypeDetail'
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
