

$PAuditPath = Join-Path $PSScriptRoot PAudit.ps1
$Action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument "-File $PAuditPath"
$Trigger = New-ScheduledTaskTrigger -Daily -At (Get-Date -Hour 6 -Minute 0 -Second 0 -Millisecond 0)
$User = Join-Path $ENV:USERDOMAIN 'PAudit-Service'
$Creds = Get-Credential -Message 'Please enter the PAudit service account credentials' -UserName $User
$Setting = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew
$CreatedTask = Register-ScheduledTask -TaskPath PAudit -TaskName 'PAudit Daily Run' -RunLevel Highest -Password $Creds.GetNetworkCredential().Password -User $Creds.GetNetworkCredential().UserName -Trigger $Trigger -Settings $Setting -Description 'PAudit Daily Run' -Action $Action
$CreatedTask | Start-ScheduledTask

Write-Host 'PAudit has been setup and is now doing a first run!' -ForegroundColor Green
