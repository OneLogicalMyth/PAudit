# NAME:         Get-NetworkAdapters.ps1
# AUTHOR:       Liam Glanfield
# CREATED DATE: 18/11/2015
# CHANGED DATE: 18/11/2015
# VERSION:      1.0.0
# DESCRIPTION:  Collects network adapters information from WMI

# Error handling
$ErrorActionPreference = 'SilentlyContinue'
$Errors = @()
$Error.Clear()

#region Start collecting data

function ConvertFrom-WMIDate {
	Param($WMIDate)
	([WMI]'').ConvertToDateTime($WMIDate)
}

$Output = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter 'IPEnabled=True' | Select-Object @(
	'Description',
	'macaddress',
	'WINSPrimaryServer',
	'WINSSecondaryServer',
	@{ n = 'DNSServers'; e = { $_.dnsserversearchorder -join ';' } },
	@{ n = 'IPAddress'; e = { $_.IPAddress -join ';' } },
	@{ n = 'DefaultIPGateway'; e = { $_.DefaultIPGateway -join ';' } },
	@{ n = 'IPSubnet'; e = { $_.IPSubnet -join ';' } },
	'DHCPEnabled',
	'DHCPLeaseExpires',
	'DHCPLeaseObtained',
	'DHCPServer',
	@{ n = 'GUID'; e = { $_.SettingID.Trim('{}') } }
) | ForEach-Object {
				
	if ($_.DHCPEnabled)
	{
		$DHCPLeaseExpires = (ConvertFrom-WMIDate $_.DHCPLeaseExpires)
		$DHCPLeaseObtained = (ConvertFrom-WMIDate $_.DHCPLeaseObtained)
	}
	else
	{
		$DHCPLeaseExpires = $Null
		$DHCPLeaseObtained = $Null
	}
				
	$NetworkAdapter = Get-WmiObject -Class win32_networkadapter -Filter "Description = '$($_.Description)'"
				
	if ($NetworkAdapter)
	{
					
		$NetworkDriver = Get-WmiObject -Class Win32_pnpsigneddriver -filter "deviceclass = 'net' AND devicename = '$($_.Description)'"
					
		$NetConnectionID = $NetworkAdapter.NetConnectionID
		$PhysicalAdapter = $NetworkAdapter.PhysicalAdapter
		$AdapterTypeId = $NetworkAdapter.AdapterTypeId
		$Availability = $NetworkAdapter.Availability
		$TimeOfLastReset = (ConvertFrom-WMIDate $NetworkAdapter.TimeOfLastReset)
					
		if ($NetworkDriver)
		{
			$DriverDate = ConvertFrom-WMIDate ($NetworkDriver.DriverDate)
			$IsSigned = $NetworkDriver.IsSigned
			$DriverVersion = $NetworkDriver.DriverVersion
			$DriverProviderName = $NetworkDriver.DriverProviderName
		}
		else
		{
			$IsSigned = $null
			$DriverVersion = $null
			$DriverProviderName = $null
		}
					
	}
	else
	{
		$NetConnectionID = $null
		$PhysicalAdapter = $null
		$AdapterTypeId = $null
		$Availability = $null
		$TimeOfLastReset = $null
		$IsSigned = $null
		$DriverVersion = $null
		$DriverProviderName = $null
	}
				
	$Result = @{
		'Name' = $NetConnectionID
		'Description' = $_.Description.Trim()
		'MACAddress' = $_.MacAddress
		'WINSPrimaryServer' = $_.WINSPrimaryServer
		'WINSSecondaryServer' = $_.WINSSecondaryServer
		'DNSServers' = $_.DNSServers
		'IPAddress' = $_.IPAddress
		'DefaultIPGateway' = $_.DefaultIPGateway
		'IPSubnet' = $_.IPSubnet
		'DHCPEnabled' = $_.DHCPEnabled
		'DHCPLeaseExpires' = $DHCPLeaseExpires
		'DHCPLeaseObtained' = $DHCPLeaseObtained
		'DHCPServer' = $_.DHCPServer
		'GUID' = $_.GUID
		'IsPhysicalAdapter' = $PhysicalAdapter
		'AdapterType' = $AdapterTypeId
		'Availability' = $Availability
		'TimeOfLastReset' = $TimeOfLastReset
		'DriverSigned' = $IsSigned
		'DriverVersion' = $DriverVersion
		'DriverProviderName' = $DriverProviderName
		'DriverDate' = $DriverDate
	}

	#Output the result
	New-Object -TypeName PSObject -Property $Result
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