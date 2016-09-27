Function Add-CollectionInfo {
	<#
	.SYNOPSIS
		Appends the collection details to the end of the object.

	.DESCRIPTION
		Appends the collection details to the end of the object.

	.PARAMETER InputObject
		The object you wish to have the collection details appended to.

	.EXAMPLE
		Get-Process | Add-CollectionInfo

	.NOTES
		Liam Glanfield - 01/06/2016 - v1.0 - First function build

	#>
	[CmdletBinding()]
	param(
		# Parameter help description
		[Parameter(Mandatory=$true,ValueFromPipeline=$true)]
		[psobject]
		$InputObject
	)
	
	process{
		$Sys = Get-WmiObject -Class Win32_ComputerSystem
		$LocalComputer = $Sys.DNSHostName + '.' + $Sys.Domain
		$InputObject | Select-Object *, @{n='CollectedByUser';e={Join-Path $env:USERDOMAIN $env:USERNAME}}, @{n='CollectedByComputer';e={$LocalComputer}},@{n='CollectedOn';e={Get-Date}}	
	}
	
}