# NAME:         Legacy-WSUS.ps1
# AUTHOR:       Liam Glanfield
# CREATED DATE: 10/09/2015
# CHANGED DATE: 14/09/2015
# VERSION:      3.0.0
# DESCRIPTION:  This is the main controller file that calls all the subscripts
[cmdletbinding()]
Param($ComputerName)

$HKLM = 2147483650
$WMI = Get-WmiObject -List StdRegProv -Namespace Root\Default -ComputerName $ComputerName -ErrorAction Stop

$SusClientId = $WMI.GetStringValue($HKLM,'SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate','SusClientId').sValue

$AcceptTrustedPublisherCerts = $WMI.GetStringValue($HKLM,'SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate','AcceptTrustedPublisherCerts').sValue
$DisableWindowsUpdateAccess  = $WMI.GetStringValue($HKLM,'SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate','DisableWindowsUpdateAccess').sValue
$ElevateNonAdmins            = $WMI.GetStringValue($HKLM,'SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate','ElevateNonAdmins').sValue
$TargetGroup                 = $WMI.GetStringValue($HKLM,'SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate','TargetGroup').sValue
$TargetGroupEnabled          = $WMI.GetStringValue($HKLM,'SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate','TargetGroupEnabled').sValue
$WUServer                    = $WMI.GetStringValue($HKLM,'SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate','WUServer').sValue
$WUStatusServer              = $WMI.GetStringValue($HKLM,'SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate','WUStatusServer').sValue

#region Start collecting data
# Get WSUS information from registry
$PolicyWindowsUpdate = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
$AU                  = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
$Detect              = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Detect'
$Download            = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Download'
$Install             = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Install'

# Build object of results to return to setter
$Output = New-Object PSObject -Property @{
	WSUSID                        = $SusClientId
	AcceptTrustedPublisherCerts   = $AcceptTrustedPublisherCerts
	DisableWindowsUpdateAccess    = $DisableWindowsUpdateAccess
	ElevateNonAdmins              = $ElevateNonAdmins
	TargetGroup                   = $TargetGroup
	TargetGroupEnabled            = $TargetGroupEnabled
	WUServer                      = $WUServer
	WUStatusServer                = $WUStatusServer
	AUOptions                     = $AU.AUOptions
	AutoInstallMinorUpdates       = $AU.AutoInstallMinorUpdates
	DetectionFrequency            = $AU.DetectionFrequency
	DetectionFrequencyEnabled     = $AU.DetectionFrequencyEnabled
	NoAutoRebootWithLoggedOnUsers = $AU.NoAutoRebootWithLoggedOnUsers
	NoAutoUpdate                  = $AU.NoAutoUpdate
	RebootRelaunchTimeout         = $AU.RebootRelaunchTimeout
	RebootRelaunchTimeoutEnabled  = $AU.RebootRelaunchTimeoutEnabled
	RebootWarningTimeout          = $AU.RebootWarningTimeout
	RebootWarningTimeoutEnabled   = $AU.RebootWarningTimeoutEnabled
	RescheduleWaitTime            = $AU.RescheduleWaitTime
	RescheduleWaitTimeEnabled     = $AU.RescheduleWaitTimeEnabled
	ScheduledInstallDay           = $AU.ScheduledInstallDay
	ScheduledInstallTime          = $AU.ScheduledInstallTime
	UseWUServer                   = $AU.UseWUServer
	DetectLastSuccessTime         = [datetime]$Detect.LastSuccessTime
	DownloadLastSuccessTime       = [datetime]$Download.LastSuccessTime
	InstallLastSuccessTime        = [datetime]$Install.LastSuccessTime
}
#endregion