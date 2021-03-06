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
# NAME:         Get-LocalUsers.ps1
# AUTHOR:       Liam Glanfield
# CREATED DATE: 18/11/2015
# CHANGED DATE: 18/11/2015
# VERSION:      1.0.0
# DESCRIPTION:  Collects local users and information about the account

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


# Windows 2000 doesn't have the LocalAccount property
if ($OSVersion.CompareTo($WindowsXP) -ge 0)
{
	$WMIProperties = @{
		'Class' = 'Win32_UserAccount'
		'Property' = @('Name')
		'Filter' = 'LocalAccount = True'
		'ComputerName' = $ComputerName
	}
}
else
{
	$WMIProperties = @{
		'Class' = 'Win32_UserAccount'
		'Property' = @('Name')
		'Filter' = '__SERVER = Domain'
		'ComputerName' = $ComputerName
	}
}

# Stops any domain controller as local groups are not needed
if ($DomainRole -lt 4)
{

	$Output = Get-WmiObject @WMIProperties | ForEach-Object {

		$User = ([adsi]"WinNT://$env:COMPUTERNAME/$($_.Name),user")

		if($User.LastLogin.Value){
			[datetime]$LastLogin = $User.LastLogin.Value
		}else{
			$LastLogin = $null
		}

		# User flags enumartion values @ https://msdn.microsoft.com/en-us/library/aa772300%28v=vs.85%29.aspx
		New-Object -TypeName PSObject -Property @{ 
			Name                           = $User.Name.Value
			FullName                       = $User.FullName.Value
			Description                    = $User.Description.Value
			DisabledAccount                = [bool]($User.UserFlags.Value -band '0x2')
			LockedOut                      = [bool]($User.UserFlags.Value -band '0x10')
			BadPasswordAttempts            = [int]$User.BadPasswordAttempts.Value
			PasswordNotRequired            = [bool]($User.UserFlags.Value -band '0x20')
			PasswordUserCantChange         = [bool]($User.UserFlags.Value -band '0x40')
			PasswordDoesNotExpire          = [bool]($User.UserFlags.Value -band '0x10000')
			PasswordExpired                = [bool]($User.UserFlags.Value -band '0x800000')
			PasswordAgeDays                = [int][math]::Round((New-TimeSpan -Seconds $User.PasswordAge.Value).TotalDays)
			PasswordLastSet                = (Get-Date).AddSeconds(- $User.PasswordAge.Value)
			LastLogin                      = $LastLogin
			MinPasswordLength              = $User.MinPasswordLength.Value
			MaxPasswordAgeDays             = [int](New-TimeSpan -Seconds $User.MaxPasswordAge.Value).TotalDays
			MinPasswordAgeDays             = [int](New-TimeSpan -Seconds $User.MinPasswordAge.Value).TotalDays
			PasswordHistoryLength          = [int]$User.PasswordHistoryLength.Value
			AutoUnlockIntervalMins         = [int](New-TimeSpan -Seconds $User.AutoUnlockInterval.Value).TotalMinutes
			LockoutObservationIntervalMins = [int](New-TimeSpan -Seconds $User.LockoutObservationInterval.Value).TotalMinutes
			MaxBadPasswordsAllowed         = [int]$User.MaxBadPasswordsAllowed.Value
		}

	}

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
