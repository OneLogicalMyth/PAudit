# NAME:         Get-PatchInformation.ps1
# AUTHOR:       Liam Glanfield
# CREATED DATE: 18/11/2015
# CHANGED DATE: 18/11/2015
# VERSION:      1.0.0
# DESCRIPTION:  Collects hot fix information from WMI

# Error handling
$ErrorActionPreference = 'SilentlyContinue'
$Errors = @()
$Error.Clear()

#region Start collecting data

$PatchInformation = @()
$Patch = $null
			
$Output = Get-HotFix | Where-Object {
	($_.HotfixID.StartsWith('KB'))
} |
ForEach-Object {
				
	$Patch = New-Object -TypeName psobject -Property @{
		Caption = $_.Caption
		Description = $_.Description
		HotFixID = $_.HotFixID
		InstalledBy = $_.InstalledBy
		InstallDateUTC = if (
		(
		$_.psbase.Properties['InstalledOn'].Value -ne [String]::Empty
		) -and (
		$_.InstalledOn -ne $null
		)
		)
		{
			$_.InstalledOn.ToUniversalTime()
		}
		else
		{
			$null
		}
	}
				
	#Return patch info
	$Patch
				
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