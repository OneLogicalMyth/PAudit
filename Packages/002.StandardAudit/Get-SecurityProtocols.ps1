# NAME:         Get-SecurityProtocols.ps1
# AUTHOR:       Liam Glanfield
# CREATED DATE: 27/11/2015
# CHANGED DATE: 27/11/2015
# VERSION:      1.0.0
# DESCRIPTION:  Collects security protocol information from the local machine

# Error handling
$ErrorActionPreference = 'SilentlyContinue'
$Errors = @()
$Error.Clear()

#region Start collecting data

$Output = @(
	'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\Multi-Protocol Unified Hello\Server'
	'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\PCT 1.0\Server'
	'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server'
	'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server'
	'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server'
	'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server'
	'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server'
) | Foreach-Object {

	$Protocol = Split-Path $_ | Split-Path -Leaf
	$Values   = '' | Select-Object DisabledByDefault,Enabled

	if((Test-Path $_)){
		$Values = Get-ItemProperty -Path $_
	}else{
		# With the registry key not present this will tell the server it can use the protocol
		# Source: https://technet.microsoft.com/en-gb/library/security/3009008.aspx
		$Values = '' | Select-Object DisabledByDefault,Enabled
		$Values.DisabledByDefault = $false
		$Values.Enabled = $true
	}
	
	$Out                    = '' | Select-Object Protocol, DisabledByDefault, Enabled, RegistryKeyPresent
	$Out.Protocol           = $Protocol
	$Out.DisabledByDefault  = [bool]$Values.DisabledByDefault
	$Out.Enabled            = [bool]$Values.Enabled
	$Out.RegistryKeyPresent = (Test-Path $_)
	$Out
	
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