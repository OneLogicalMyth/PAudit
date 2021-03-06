<#
    This file is part of PAudit available from https://github.com/OneLogicalMyth/PAudit
    Created by Liam Glanfield @OneLogicalMyth

    PAudit is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    PAudit is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with PAudit.  If not, see <http://www.gnu.org/licenses/>.
#>
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
