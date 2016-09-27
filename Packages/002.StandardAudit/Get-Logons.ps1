# NAME:         Get-Logons.ps1
# AUTHOR:       Liam Glanfield
# CREATED DATE: 18/11/2015
# CHANGED DATE: 18/11/2015
# VERSION:      1.0.0
# DESCRIPTION:  Collects logon information from the security event log

# Error handling
$ErrorActionPreference = 'SilentlyContinue'
$Errors = @()
$Error.Clear()

#region Start collecting data
$WindowsVista = [System.Version]'6.0'
$OS           = Get-WmiObject win32_operatingsystem
$OSVersion    = [Version]$OS.Version

# Collecting logons for anything older than Vista/2008 R1 is too slow
if ($OSVersion.CompareTo($WindowsVista) -ge 0)
{
	# Build filter to only output logon events in the last 24 hours
	$XMLFilter = @"
	<QueryList>
		<Query Id="0" Path="Security">
			<Select Path="Security">
					*[System[(EventID=4624) and TimeCreated[timediff(@SystemTime) &lt;= 86400000]]]
						and
					*[EventData[Data[@Name="WorkstationName"]!='']]
						and
					*[EventData[Data[@Name="LogonType"] ='2']]
				or
					*[System[(EventID=4624) and TimeCreated[timediff(@SystemTime) &lt;= 86400000]]]
						and
					*[EventData[Data[@Name="WorkstationName"]!='']]
						and
					*[EventData[Data[@Name="LogonType"] ='10']]
			</Select>
		</Query>
	</QueryList>
"@

	$Output = Get-WinEvent -FilterXml $XMLFilter | ForEach-Object {

		$Event = $_

		$EventDateTime  = $Event.TimeCreated
		$EventXML       = [XML]$Event.ToXML()
		$EventData      = $EventXML.Event.EventData.Data
						
		$Username       = $EventData[5].'#text'
		$SID            = $EventData[4].'#text'
		$Domain         = $EventData[6].'#text'
		
		if([int]($EventData[8].'#text') -eq 10){
			$LogonType = 'Remote Interactive'
		}elseif([int]($EventData[8].'#text') -eq 2){
			$LogonType = 'Local Interactive'
		}else{
			$LogonType = $EventData[8].'#text'
		}

		$Workstation  = $EventData[11].'#text'
		$IPAddress    = $EventData[18].'#text'
						
						
		$Result = New-Object PSObject
		$Result | Add-Member NoteProperty Username $Username
		$Result | Add-Member NoteProperty Domain $Domain
		$Result | Add-Member NoteProperty SID $SID
		$Result | Add-Member NoteProperty LogonType $LogonType
		$Result | Add-Member NoteProperty Workstation $Workstation
		$Result | Add-Member NoteProperty IPAddress $IPAddress
		$Result | Add-Member NoteProperty DateTime $EventDateTime
		$Result

	} | Select-Object -Unique

}# End if OS is Vista or greater

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