Function Write-PAuditLog {
Param([int]$EventID,[string]$Data=([string]::Empty))
 
    # Create the event log in case it does not exist
    New-PAuditLog

	# Get event message
	$EventDetails	= Get-PAuditLogMessage -EventID $EventID -Data $Data
	$Message		= $EventDetails.Message
	$EntryType		= $EventDetails.EntryType

    # Write event to log
    Write-EventLog -LogName PAudit -Source 'PAudit' -EntryType $EntryType -EventId $EventID -Message $Message

    # Output to host
    $DateFormat = 'yyyy-MM-dd HH:mm:ss'
    $LogMessage = "$(Get-Date -Format $DateFormat) - $EntryType - $EventID - $Message"
	$Colours = switch ($EntryType) 
    { 
        'Error' { $Host.PrivateData.ErrorForegroundColor,$Host.PrivateData.ErrorBackgroundColor } 
        'Warning' { $Host.PrivateData.WarningForegroundColor,$Host.PrivateData.WarningBackgroundColor } 
        'Information' { 'White', 'DarkMagenta'} 
        default { 'White', 'DarkMagenta' }
    }
	if($LogMessage.Length -gt 0)
	{
		# Replace any new lines
		$LogMessage = $LogMessage.replace([System.Environment]::NewLine,' ')

		# Build log path
		$LogPathDir = Join-Path $Global:PAuditRoot Logs
		$LogPathFil = Join-Path $LogPathDir $Global:Config.LogFileName

		# Check if outputing to file and do so
		if($Global:Config.UseLogFile)
		{
			if(-not (Test-Path $LogPathDir))
			{
				Write-PAuditLog -EventID 1 -Message "PAudit log directory created at '$LogPathDir'"
				New-Item $LogPathDir -ItemType Directory -Force
			}
			$LogMessage | Out-File -FilePath $LogPathFil -Append -Encoding ascii
		}

		# Trim to fit on console window
		if($LogMessage.Length -gt $host.ui.rawui.WindowSize.Width)
		{
			$LogMessage = "$($LogMessage.Substring(0,$host.ui.rawui.WindowSize.Width - 3))..."
		}

		# Output result
		Write-Host $LogMessage -ForegroundColor $Colours[0] -BackgroundColor $Colours[1]
		
	}
}