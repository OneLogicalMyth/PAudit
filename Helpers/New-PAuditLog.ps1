Function New-PAuditLog {
Param([string]$EventLogSource = 'PAudit')
 
    $EventLogExists = [System.Diagnostics.EventLog]::Exists($EventLogSource)
    $EventLogSourceExists = [System.Diagnostics.EventLog]::SourceExists($EventLogSource)
 
    if(-not $EventLogExists -or -not $EventLogSourceExists){
        New-EventLog -LogName PAudit -Source $EventLogSource
        Limit-EventLog -LogName PAudit -OverFlowAction OverwriteAsNeeded -MaximumSize 50MB
    }
}