# NAME:         Get-Processor.ps1
# AUTHOR:       Liam Glanfield
# CREATED DATE: 18/11/2015
# CHANGED DATE: 18/11/2015
# VERSION:      1.0.0
# DESCRIPTION:  Collects processor information from WMI

# Error handling
$ErrorActionPreference = 'SilentlyContinue'
$Errors = @()
$Error.Clear()

#region Start collecting data

# Only need 1 processor all should be the same or the system wouldn't work ;)
$Processors = Get-WmiObject -Class Win32_Processor
$Output = $Processors | Select-Object -First 1 -Property @(
	'DataWidth',
	'Description',
	'ExtClock',
	'Family',
	'L2CacheSize',
	'L2CacheSpeed',
	'L3CacheSize',
	'L3CacheSpeed',
	'Manufacturer',
	'MaxClockSpeed',
	'Name',
	@{n='NumberofProcessors';e={@($Processors).Count}},
	'NumberOfCores',
	'NumberOfLogicalProcessors',
	@{n='Hyperthreading';e={$_.NumberOfLogicalProcessors -gt $_.NumberOfCores}}
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

