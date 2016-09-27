# NAME:         Get-LocalGroups.ps1
# AUTHOR:       Liam Glanfield
# CREATED DATE: 18/11/2015
# CHANGED DATE: 18/11/2015
# VERSION:      1.0.0
# DESCRIPTION:  Collects local groups and the users contained within them

# Error handling
$ErrorActionPreference = 'SilentlyContinue'
$Errors = @()
$Error.Clear()

#region Start collecting data

# Set the version for 2003 or XP used to alter the collection behaviour
# Set domain role and OS version for later use
$WindowsXP    = [Version]'5.1'
$OS           = Get-WmiObject win32_operatingsystem
$CS           = Get-WmiObject win32_computersystem
$ComputerName = $CS.DNSHostName
$OSVersion    = [Version]$OS.Version
$DomainRole   = $CS.DomainRole

# Stops any domain controller as local groups are not needed
if ($DomainRole -lt 4)
{
			
	# Query is different for Windows 2000 vs. Windows XP and higher
	if ($OSVersion.CompareTo($WindowsXP) -ge 0)
	{
		$WMIProperties = @{
			'Class' = 'Win32_Group'
			'Property' = @('Name', 'Domain')
			'Filter' = 'LocalAccount = True'
		}
	}
	else
	{
		$WMIProperties = @{
			'Class' = 'Win32_Group'
			'Property' = @('Name', 'Domain')
			'Filter' = "(__SERVER = Domain) or (Domain = 'BUILTIN')"
		}
	}

	# Get local groups
	$Output = Get-WmiObject @WMIProperties | Sort-Object -Property Name | ForEach-Object {
					
		$GroupName = $_.Name
	
		# Build WMI filter and query for the group members
		$Filter = "GroupComponent='Win32_Group.Domain="
		$Filter += """$($_.Domain)"",Name=""$($_.Name)""'"
		$WMIProperties = @{
			'Class' = 'Win32_GroupUser'
			'Property' = 'PartComponent'
			'Filter' = $Filter
		}

		# Get group users using filter above				
		Get-WmiObject @WMIProperties | Sort-Object -Property PartComponent | ForEach-Object {

			if (!$_.PartComponent)
			{
				$User = 'UNKNOWN'
			}
			else
			{
				# Could this be done better with a regular expression and matches?
				$PartComponent = $_.PartComponent.Split('"')
				"$($PartComponent[1])\$($PartComponent[3])"
			}
	
		# Foreach user process them				
		} | ForEach-Object {

			$User = $_
							
			$Out = $null
			$Out = New-Object PSObject
			$Out | Add-Member NoteProperty HostName $ComputerName
			$Out | Add-Member NoteProperty Name $GroupName
			$Out | Add-Member NoteProperty Member $User
			$Out
							
		}

	}# End for each group

}# End if domain role

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

