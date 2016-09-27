[cmdletbinding()]
Param($ServerHostname='.')

process{

	$NetworkInfo	= Get-WMIObject -ComputerName $ServerHostname -Class Win32_NetworkAdapterConfiguration -Filter "IPEnabled='true'" | `
					Select macaddress, WINSPrimaryServer, WINSSecondaryServer, `
					@{n='DNSServers';e={[string]$_.dnsserversearchorder}}, @{n='IPAddress';e={[string]$_.IPAddress}}, `
					@{n='DefaultIPGateway';e={[string]$_.DefaultIPGateway}}, @{n='IPSubnet';e={[string]$_.IPSubnet}}, DHCP

	#Cycle through network cards (only IP enabled cards)
	$Output = foreach ($objNetwork in $NetworkInfo){
        $NetworkInfo = New-Object Object
        $NetworkInfo | Add-Member -MemberType NoteProperty -Name AdapterName -Value $objNetwork.description
        $NetworkInfo | Add-Member -MemberType NoteProperty -Name IP -Value $objNetwork.IPAddress
        $NetworkInfo | Add-Member -MemberType NoteProperty -Name MAC -Value $objNetwork.macaddress
        $NetworkInfo | Add-Member -MemberType NoteProperty -Name DNS -Value $objNetwork.DNSServers
        $NetworkInfo | Add-Member -MemberType NoteProperty -Name Gateway -Value $objNetwork.DefaultIPGateway
        $NetworkInfo | Add-Member -MemberType NoteProperty -Name Subnet -Value $objNetwork.ipsubnet
        $NetworkInfo | Add-Member -MemberType NoteProperty -Name DHCP -Value $objNetwork.dhcpenabled
        $NetworkInfo | Add-Member -MemberType NoteProperty -Name DHCPServer -Value $objNetwork.dhcpserver
        $NetworkInfo
	}

	# Collect errors and return result
    $OperatingSystem = Get-WmiObject -ComputerName $ServerHostname -Class Win32_OperatingSystem
    $ComputerName    = $OperatingSystem.__Server.ToString().ToUpper()
	if($Output) {
		$Output = $Output | Select-Object @{n='Hostname';e={$ComputerName}},*
	}else{
		$Output = $null
	}
	$Result = @{
		Errors = $Error
		Result = $Output
	}

	# Return result as an object
	New-Object PSObject -Property $Result

}