# NAME:         Get-AntiVirus.ps1
# AUTHOR:       Liam Glanfield
# CREATED DATE: 26/11/2015
# CHANGED DATE: 26/11/2015
# VERSION:      1.0.0
# DESCRIPTION:  Collects anti virus information from the registry, currently only supports Symantec and McAfee

# Error handling
$ErrorActionPreference = 'SilentlyContinue'
$Error.Clear()

#region Start collecting data

$Block = {

		# Check if McAfee AV is installed
		if((Test-Path HKLM:\SOFTWARE\Wow6432Node\McAfee\DesktopProtection)){
			$McAfeePath = '\Wow6432Node\'
		}elseif((Test-Path HKLM:\SOFTWARE\McAfee\DesktopProtection)){
			$McAfeePath = '\'
		}else{
			$McAfeePath = $false
		}
		if($McAfeePath)
		{
			$McAfeeEngineVersion = (Get-ItemProperty -Path HKLM:\SOFTWARE$($McAfeePath)McAfee\DesktopProtection -Name szProductVer -ErrorAction SilentlyContinue).szProductVer
			$McAfeeEngineName    = (Get-ItemProperty -Path HKLM:\SOFTWARE$($McAfeePath)McAfee\DesktopProtection -Name Product -ErrorAction SilentlyContinue).Product
			$McAfeeInstallDate   = (Get-ItemProperty -Path HKLM:\SOFTWARE$($McAfeePath)McAfee\DesktopProtection -Name szInstallDateTime -ErrorAction SilentlyContinue).szInstallDateTime
			$McAfeeDatDate       = (Get-ItemProperty -Path HKLM:\SOFTWARE$($McAfeePath)McAfee\AVEngine -Name AVDatDate -ErrorAction SilentlyContinue).AVDatDate
			if($McAfeeDatDate)
			{
				$McAfeeDatDate = $McAfeeDatDate | Get-Date
			}
			if($McAfeeInstallDate)
			{
				$McAfeeInstallDate = $McAfeeInstallDate | Get-Date
			}
			$McAfeeDatVersion = (Get-ItemProperty -Path HKLM:\SOFTWARE\$($McAfeePath)McAfee\AVEngine -Name AVDatVersion -ErrorAction SilentlyContinue).AVDatVersion

			New-Object -TypeName PSObject -Property @{
				EngineName        = $McAfeeEngineName.Trim()
				EngineVersion     = $McAfeeEngineVersion
				EngineInstallDate = $McAfeeInstallDate
				SignatureDate     = $McAfeeDatDate
				SignatureVersion  = $McAfeeDatVersion
			}
		}

		# Check if Symantec AV is installed
		if((Test-Path 'HKLM:\SOFTWARE\Wow6432Node\Symantec\Symantec Endpoint Protection\CurrentVersion')){
			$SymantecPath = '\Wow6432Node\'
		}elseif((Test-Path 'HKLM:\SOFTWARE\Symantec\Symantec Endpoint Protection\CurrentVersion')){
			$SymantecPath = '\'
		}else{
			$SymantecPath = $false
		}
		if($SymantecPath)
		{
			$SymantecEngineVersion = (Get-ItemProperty -Path "HKLM:\SOFTWARE$($SymantecPath)Symantec\Symantec Endpoint Protection\SMC" -Name ProductVersion -ErrorAction SilentlyContinue).ProductVersion
			$SymantecEngineName    = (Get-ItemProperty -Path "HKLM:\SOFTWARE$($SymantecPath)Symantec\Symantec Endpoint Protection\CurrentVersion" -Name PRODUCTNAME -ErrorAction SilentlyContinue).PRODUCTNAME
			$SymantecInstallDate   = $null
			$SymantecDatDate       = (Get-ItemProperty -Path "HKLM:\SOFTWARE$($SymantecPath)Symantec\Symantec Endpoint Protection\CurrentVersion\public-opstate" -Name LatestVirusDefsDate -ErrorAction SilentlyContinue).LatestVirusDefsDate
			if($SymantecDatDate)
			{
				$SymantecDatDate = $SymantecDatDate | Get-Date
			}
			if($McAfeeInstallDate)
			{
				$McAfeeInstallDate = $McAfeeInstallDate | Get-Date
			}
			$SymantecDatVersion = (Get-ItemProperty -Path "HKLM:\SOFTWARE$($SymantecPath)Symantec\Symantec Endpoint Protection\CurrentVersion\public-opstate" -Name LatestVirusDefsRevision -ErrorAction SilentlyContinue).LatestVirusDefsRevision
			
			New-Object -TypeName PSObject -Property @{
				EngineName        = $SymantecEngineName.Trim()
				EngineVersion     = $SymantecEngineVersion
				EngineInstallDate = $SymantecInstallDate
				SignatureDate     = $SymantecDatDate
				SignatureVersion  = $SymantecDatVersion
			}
		}

	} # End Block

# Execute AV collection
$Output = $Block.Invoke()

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