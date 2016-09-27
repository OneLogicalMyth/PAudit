[cmdletbinding()]
Param($ServerHostname='.')

process{

	$Services	= Get-WmiObject -Class win32_service -computername $ServerHostname -Filter "NOT StartMode='Disabled'" -Property "DisplayName,Description,Name,State,StartMode,StartName" | `
					select DisplayName,Description,Name,State,StartMode,StartName

	$Output = foreach($Service in $Services){
        $ServiceInfo = New-Object Object
        $ServiceInfo | Add-Member -MemberType NoteProperty -Name DisplayName -Value $Service.DisplayName
        $ServiceInfo | Add-Member -MemberType NoteProperty -Name Description -Value $Service.Description
        $ServiceInfo | Add-Member -MemberType NoteProperty -Name Name -Value $Service.Name
        $ServiceInfo | Add-Member -MemberType NoteProperty -Name State -Value $Service.State
        $ServiceInfo | Add-Member -MemberType NoteProperty -Name StartMode -Value $Service.StartMode
        $ServiceInfo | Add-Member -MemberType NoteProperty -Name StartName -Value $Service.StartName
        $ServiceInfo
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