Function Get-PAuditLogMessage {
[cmdletbinding()]
param($EventID,[string]$Data=([string]::Empty))

    Write-Verbose "Get-PAuditLogMessage 'Reading messages from $(Join-Path $Global:PAuditRoot 'Helpers\EventMessages.xml')'"
    $Result = ([xml](Get-Content (Join-Path $Global:PAuditRoot 'Helpers\EventMessages.xml'))).Messages.Message |
    Where-Object { $_.EventID -eq $EventID }

    $Out            = '' | Select-Object EntryType, Message
    $Out.EntryType  = [System.Diagnostics.EventLogEntryType]$Result.EntryType
    $Out.Message    = $Result.Text.Replace('{{DATA}}',$Data).Replace('{{BR}}',[System.Environment]::NewLine)
    $Out

}