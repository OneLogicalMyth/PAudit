[cmdletbinding()]
Param($ServerHostname='.')

begin {

	Function Invoke-Trim {
		Param($Value)

		if($Value -is [string]){
			$Value.Trim()
		}else{
			$Value
		}

	}

}

process{

    $diskdrive = Get-WMIObject -Class win32_diskdrive -ComputerName $ServerHostname
	$Output = foreach($drive in $diskdrive)
	{	
		$DiskID = $drive.DeviceID.Replace("\", "")
		$DiskID = $DiskID.Replace(".", "")

		$DiskInfo = New-Object System.Object
		$DiskInfo | Add-Member -type NoteProperty -name DeviceID -value $DiskID.Trim()
		$DiskInfo | Add-Member -type NoteProperty -name Model -value $drive.Model.Trim()
		$DiskInfo | Add-Member -type NoteProperty -name Size -value $drive.Size
		$DiskInfo | Add-Member -type NoteProperty -name Partitions -value $drive.Partitions
		$DiskInfo | Add-Member -type NoteProperty -name SerialNumber -value (Invoke-Trim $drive.SerialNumber)
		$DiskInfo | Add-Member -type NoteProperty -name Status -value $drive.Status
		$DiskInfo | Add-Member -type NoteProperty -name NeedsCleaning -value $drive.NeedsCleaning
		$DiskInfo | Add-Member -type NoteProperty -name MediaType -value $drive.MediaType
		$DiskInfo
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