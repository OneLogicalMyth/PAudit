[cmdletbinding()]
Param($ServerHostname='.')

begin{

    Function Get-DriveType {
    Param([int]$DriveType)
        Switch($DriveType)
        {
	        2{'Floppy'}
	        3{'Fixed Disk'}
	        5{'Removable Media'}
	        default{'Undetermined'}
        }
    }

}

process{

	$diskdrive = Get-WMIObject -Class win32_diskdrive -ComputerName $ServerHostname
	$Output = foreach($drive in $diskdrive)
	{	
		$DiskID = $drive.DeviceID.Replace("\", "")
		$DiskID = $DiskID.Replace(".", "")

		$partitions = Get-WMIObject -Query "ASSOCIATORS OF {Win32_DiskDrive.DeviceID=`"$($drive.DeviceID.replace('\','\\'))`"} WHERE AssocClass = Win32_DiskDriveToDiskPartition" -ComputerName $ServerHostname
		 
		foreach($part in $partitions)
		{
			$vols = Get-WMIObject -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID=`"$($part.DeviceID)`"} WHERE AssocClass = Win32_LogicalDiskToPartition" -ComputerName $ServerHostname
			 
			foreach($vol in $vols)
			{
				$LogicalDisk = New-Object System.Object
				$LogicalDisk | Add-Member -type NoteProperty -name PhysicalDisk -value $DiskID
				$LogicalDisk | Add-Member -type NoteProperty -name Size -value $vol.Size
				$LogicalDisk | Add-Member -type NoteProperty -name FreeSpace -value $vol.FreeSpace
				$LogicalDisk | Add-Member -type NoteProperty -name DeviceID -value $vol.DeviceID
				$LogicalDisk | Add-Member -type NoteProperty -name VolumeName -value $vol.VolumeName
				$LogicalDisk | Add-Member -type NoteProperty -name DriveType -value (Get-DriveType -DriveType $vol.DriveType)
				$LogicalDisk
			}
			
		}

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