# NAME:         Get-Printers.ps1
# AUTHOR:       Liam Glanfield
# CREATED DATE: 18/11/2015
# CHANGED DATE: 18/11/2015
# VERSION:      1.0.0
# DESCRIPTION:  Collects local printer information from WMI

# Error handling
$ErrorActionPreference = 'SilentlyContinue'
$Errors = @()
$Error.Clear()

#region Start collecting data

$Output = Get-WMIObject Win32_Printer | ForEach-Object {
	$Printer = $_
	$Result = New-Object PSObject
	$Result | Add-Member NoteProperty Name $Printer.Name
	$Result | Add-Member NoteProperty Location $Printer.Location
	$Result | Add-Member NoteProperty Comment $Printer.Comment
	$Result | Add-Member NoteProperty PortName $Printer.PortName
				
	$Ports = Get-WmiObject Win32_TcpIpPrinterPort
	$PResults = @()
	foreach ($Port in $Ports)
	{
		if ($Port.Name -eq $Printer.PortName)
		{
			$PResults += $Port.HostAddress
		}
	}
	$Result | Add-Member NoteProperty HostAddress ($PResults -join ';')
	$Result | Add-Member NoteProperty DriverName $Printer.DriverName
	$Result | Add-Member NoteProperty Shared $Printer.Shared
	$Result | Add-Member NoteProperty ShareName $Printer.ShareName
	$Result
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