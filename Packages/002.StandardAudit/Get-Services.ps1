# NAME:         Get-Services.ps1
# AUTHOR:       Liam Glanfield
# CREATED DATE: 18/11/2015
# CHANGED DATE: 18/11/2015
# VERSION:      1.0.0
# DESCRIPTION:  Collects service information from WMI

# Error handling
$ErrorActionPreference = 'SilentlyContinue'
$Errors = @()
$Error.Clear()

#region Start collecting data

$ShareType = @(
	'Disk Drive',
	'Print Queue',
	'Device',
	'IPC'
)

# The filter is removing admin shares or default shares, these start at the number of 2147483648 so saying anything high is not allowed ie admin shares
$Output = Get-WmiObject -Class Win32_Service -Filter "NOT StartMode='Disabled'" | Select-Object @(
	'DisplayName',
	'Name',
	'State',
	'StartMode',
	'StartName'
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
