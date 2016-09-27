# NAME:         Get-PageFileInfo.ps1
# AUTHOR:       Liam Glanfield
# CREATED DATE: 18/11/2015
# CHANGED DATE: 18/11/2015
# VERSION:      1.0.0
# DESCRIPTION:  Collects page file information from WMI

# Error handling
$ErrorActionPreference = 'SilentlyContinue'
$Errors = @()
$Error.Clear()

#region Start collecting data

function ConvertFrom-WMIDate {
	Param($WMIDate)
	([WMI]'').ConvertToDateTime($WMIDate)
}

$AutomaticManagedPagefile = (Get-WMIObject -Class Win32_ComputerSystem -Property AutomaticManagedPagefile).AutomaticManagedPagefile

$Output = Get-WmiObject -Class Win32_PageFileUsage | Select-Object @(
	'AllocatedBaseSize'
	'CurrentUsage'
	'Name'
	'PeakUsage'
	'TempPageFile'
	'InstallDate'
) | ForEach-Object {


	$AutoPageProp = @{
		'Namespace' = 'root\CIMV2'
		'Property' = 'MaximumSize'
		'Filter' = "Name = $($_.__Path.Split('=')[1])"
	}
				
	if ($AutomaticManagedPagefile -eq $false)
	{
		if ($CompareVista -ge 0)
		{
			$Win32_PageFileSetting = Get-WmiObject @AutoPageProp -Class Win32_PageFileSetting
			$MaximumSizeMB = $Win32_PageFileSetting.MaximumSize
		}
		else
		{
			$Win32_PageFile = Get-WmiObject @AutoPageProp -Class Win32_PageFile
			$MaximumSizeMB = $Win32_PageFile.MaximumSize
		}
	}
				
	New-Object -TypeName psobject -Property @{
		Drive = $($_.Name).Split('\')[0]
		InitialSizeMB = $_.AllocatedBaseSize
		MaximumSizeMB = $MaximumSizeMB
		CurrentSizeMB = $_.CurrentUsage
		PeakSizeMB = $_.PeakUsage
		IsTemporary = $_.TempPageFile
		InstallDate = (ConvertFrom-WMIDate $_.InstallDate)
	}

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