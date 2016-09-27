# NAME:         Get-WSUS.ps1
# AUTHOR:       Liam Glanfield
# CREATED DATE: 10/09/2015
# CHANGED DATE: 14/09/2015
# VERSION:      1.0.0
# DESCRIPTION:  Collects WSUS information from the registry

# Error handling
$ErrorActionPreference = 'SilentlyContinue'
$Errors = @()
$Error.Clear()

#region Start collecting data
# Get WSUS information from registry
if((Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate')) {
	$WindowsUpdate       = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate'
}
if((Test-Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate')) {
	$PolicyWindowsUpdate = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
}
if((Test-Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU')) {
	$AU                  = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
}
if((Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Detect')) {
	$Detect              = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Detect'
}
if((Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Download')) {
	$Download            = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Download'
}
if((Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Install')) {
	$Install             = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Install'
}

Function Test-DateNull {
param($GivenDate)

	if($GivenDate){
		[datetime]$GivenDate
	}

}

Function Get-AUOption {
param($AUOption)

	switch($AUOption) {
		(2) { 'Notify before download' }
		(3) { 'Automatically download and notify of installation' }
		(4) { 'Automatic download and scheduled installation' }
		(5) { 'Automatic Updates is required, but end users can configure it' }
		default {$_}
	}
	
}

Function Get-InstallDay {
param($Day)

	switch($Day) {
		(0) { 'Every Day' }
		(1) { 'Monday' }
		(2) { 'Tuesday' }
		(3) { 'Wednesday' }
		(4) { 'Thursday' }
		(5) { 'Friday' }
		(6) { 'Saturday' }
		(7) { 'Sunday' }
		default {$_}
	}
	
}

# Check for updates and classify them into categories
$UpdateSession         = New-Object -ComObject Microsoft.Update.Session
$UpdateSearcher        = $UpdateSession.CreateUpdateSearcher()
$SearchResult          = $UpdateSearcher.Search("IsInstalled=0")
[int]$ImportantUpdates = ($SearchResult.Updates | Group-Object BrowseOnly | Where-Object { $_.Name -eq $false }).'Count'
[int]$OptionalUpdates  = ($SearchResult.Updates | Group-Object BrowseOnly | Where-Object { $_.Name -eq $true  }).'Count'

# Build object of results to return to setter
$Output = New-Object PSObject -Property @{
	WSUSID                        = [string]$WindowsUpdate.SusClientId
	AcceptTrustedPublisherCerts   = [bool][int]$PolicyWindowsUpdate.AcceptTrustedPublisherCerts
	DisableWindowsUpdateAccess    = [bool][int]$PolicyWindowsUpdate.DisableWindowsUpdateAccess
	ElevateNonAdmins              = [bool][int]$PolicyWindowsUpdate.ElevateNonAdmins
	TargetGroup                   = [string]$PolicyWindowsUpdate.TargetGroup
	TargetGroupEnabled            = [bool][int]$PolicyWindowsUpdate.TargetGroupEnabled
	WUServer                      = [string]$PolicyWindowsUpdate.WUServer
	WUStatusServer                = [string]$PolicyWindowsUpdate.WUStatusServer
	AUOptions                     = (Get-AUOption ([int]$AU.AUOptions))
	AutoInstallMinorUpdates       = [bool][int]$AU.AutoInstallMinorUpdates
	DetectionFrequency            = [int]$AU.DetectionFrequency
	DetectionFrequencyEnabled     = [bool][int]$AU.DetectionFrequencyEnabled
	NoAutoRebootWithLoggedOnUsers = [bool][int]$AU.NoAutoRebootWithLoggedOnUsers
	NoAutoUpdate                  = [bool][int]$AU.NoAutoUpdate
	RebootRelaunchTimeout         = [int]$AU.RebootRelaunchTimeout
	RebootRelaunchTimeoutEnabled  = [bool][int]$AU.RebootRelaunchTimeoutEnabled
	RebootWarningTimeout          = $AU.RebootWarningTimeout
	RebootWarningTimeoutEnabled   = [bool][int]$AU.RebootWarningTimeoutEnabled
	RescheduleWaitTime            = $AU.RescheduleWaitTime
	RescheduleWaitTimeEnabled     = [bool][int]$AU.RescheduleWaitTimeEnabled
	ScheduledInstallDay           = (Get-InstallDay ([int]$AU.ScheduledInstallDay))
	ScheduledInstallTime          = [int]$AU.ScheduledInstallTime
	UseWUServer                   = [bool][int]$AU.UseWUServer
	DetectLastSuccessTime         = (Test-DateNull $Detect.LastSuccessTime)
	DownloadLastSuccessTime       = (Test-DateNull $Download.LastSuccessTime)
	InstallLastSuccessTime        = (Test-DateNull $Install.LastSuccessTime)
	PendingImportantUpdates       = [int]$ImportantUpdates
	PendingOptionalUpdates        = [int]$OptionalUpdates
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