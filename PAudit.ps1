#requires -Version 4.0 -RunAsAdministrator
<#
.SYNOPSIS
	A PowerShell Package that utilises package Packages to perform vaious tasks.

.DEPackageION
	This Package is purely a controller calling all the requried package Packages.
	A package Package for example be creating an inventory for audit purposes.

.EXAMPLE
	.\PAudit.ps1

	Runs the all packages available

.EXAMPLE
	.\PAudit.ps1 -RunPackage 1

	Runs the package starting with 001

.EXAMPLE
	.\PAudit.ps1 -RunPackagePackage 1 -RunSubPackage 1

	Runs the Package package starting with 001 and only the sub Package 1

.NOTES
	Liam Glanfield - 16/06/2016 - v1.0 - First Release

#>
[cmdletbinding()]
Param([int]$RunPackage,[int]$RunSubPackage,[switch]$WorkgroupOnly)

$Script:StopWatch = [system.diagnostics.stopwatch]::startNew()

# Import helpers
Foreach($Helper IN Get-ChildItem (Join-Path $PSScriptRoot 'Helpers\*.ps1'))
{	
    # The fullstop dot sources the PS1 file
    # this imports the PS1 functions to PowerShell
    . $Helper.FullName
}

# Set root path globally
$Global:PAuditRoot = $PSScriptRoot

Write-PAuditLog -EventID 100

# Import configuration file
$Global:Config = . $(Join-Path $Global:PAuditRoot 'Configuration.ps1')
Write-PAuditLog -EventID 105 -Data $Global:PAuditRoot

# Load the packges configuration
$Packages = . $(Join-Path $Global:PAuditRoot 'Core\LoadPackages.ps1')

# No packages found error and stop
if($Packages.Count -eq 0)
{
	Write-PAuditLog -EventID 500
	return
}

#region Process the Packages and run each sub Package against the session
    try
    {

		# See if any PS Remote sessions are requried if so build session ready
		$SessionRequired = ($Packages | Measure-Object -Property SupportsSession -Sum).Sum -gt 0
		if($SessionRequired){

			# For PS Remote sessions to work across workgroup machines you need to trust them
			if((Get-Item -Path WSMan:\localhost\Client\TrustedHosts).Value -ne '*'){
				Write-PAudit -EventID 95
				Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value * -Force
			}

			# Enumerate and merge list of computers
			if($Global:Config.ComputerType -eq 'Both'){
				$ComputerList = . $(Join-Path $Global:PAuditRoot 'Core\EnumerateComputers.ps1')
			}else{
				$ComputerList = . $(Join-Path $Global:PAuditRoot 'Core\EnumerateComputers.ps1') | Where-Object { $_.ComputerType -eq $Global:Config.ComputerType}
			}

			# Check if any computers have been identified
			if(@($ComputerList).Count -gt 0){

				# Disable all checks for session
				$SesOpt = New-PSSessionOption -SkipRevocationCheck -SkipCACheck -SkipCNCheck

				# Create sessions for each of the computers, capture any bad setups
				New-PSSession -ComputerName $ComputerList -ErrorVariable SessionErrors -ErrorAction SilentlyContinue | ForEach-Object {
					Write-PAuditLog -EventID 120 -Data $_.ComputerName
				}
				Write-PAuditLog -EventID 125

				# Process bad servers for investigation, capture any servers that respond to WMI instead
				$LegacyServers = @()
				Foreach($BadServer IN $SessionErrors)
				{
					# Write event log entry so bad server can be investigated
					Write-PAuditLog -EventID 505 -Data $BadServer.targetobject.connectioninfo.computername

					# Check if legacy wmi is possible
					try
					{
						$WMI = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $BadServer.TargetObject.ConnectionInfo.ComputerName -ErrorAction Stop -AsJob
						Wait-Job -Id $WMI.ID -Timeout 30 # Timeout wmi testing after 30 seconds
						if($WMI -ne $null)
						{
							$LegacyServers += $BadServer.TargetObject.ConnectionInfo.ComputerName
							Write-PAuditLog -EventLogSource PAudit -EntryType Information -EventID 1 -Message "$($BadServer.targetobject.connectioninfo.computername) supports legacy WMI adding to the legacy list"
						}else{
							Write-PAuditLog -EventLogSource PAudit -EntryType Error -EventID 9999 -Message "$($BadServer.targetobject.connectioninfo.computername) does not support legacy WMI due to timeout, is the server accessible on the network?"
						}
						
					}
					catch
					{
						Write-PAuditLog -EventLogSource PAudit -EntryType Error -EventID 9999 -Message "$($BadServer.targetobject.connectioninfo.computername) does not support legacy WMI due to '$_', is the server accessible on the network?"
					}
					
				}
			
				# Grab all open sessions
				$Session = Get-PSSession | Where-Object State -eq Opened

			}else{
				Write-PAuditLog -EventID 510
			}

		} # End if for session required

		# Run each master Package and execute objectcommand as per XML
		Foreach($Package IN $Packages)
		{
			Write-PAuditLog -EventID 115 $Package.Name

			# If package is for computer data collection
			if($Package.PackageType -eq 'collect'){

				# Check if we have sessions available
				if($Session){

					# Import global functions into session if required
					if($Package.EnableGlobalFunctions)
					{
						Write-PAuditLog -EventLogSource PAudit -EntryType Information -EventID 1 -Message "Global functions are required for master Package $($Package.Name), importing functions"
						Foreach($GlobalFile IN $Package.GlobalFunctions)
						{
							Write-PAuditLog -EventLogSource PAudit -EntryType Information -EventID 1 -Message "Importing global function $GlobalFile"
							Invoke-Command -Session $Session -FilePath (Join-Path $Global:PAuditRoot "Core\Functions\$GlobalFile")
							$GlobalFile = $null
						}
								
					}

				}

				# Check if there are legacy servers to process
				if($LegacyServers){
					
				}


			} # End if package type collect

			if($Package.PackageType -eq 'custom')
			{
				Write-PAuditLog -EventLogSource PAudit -EntryType Information -EventID 1 -Message "No session required executing Package $($Package.ObjectCommand.Replace('{{PackageROOT}}',$Package.FullPath))"
				Invoke-Expression -Command $Package.ObjectCommand.Replace('{{PackageROOT}}',$Package.FullPath)
			} # End if package type custom




			# Get all subPackages and execute them
			Get-ChildItem $Package.FullPath -Directory | Sort-Object -Property Name |
			Foreach {
				$SubPackageName = $_.Name.Split('.')[1]
				[int]$SubPackageNumber = $_.Name.Split('.')[0]
				$SubPackageConfig = Get-SubPackageConfig -FileName (Join-Path $_.FullName "$($SubPackageName).xml")

				if($RunSubPackage -eq 0 -or $RunSubPackage -eq $SubPackageNumber){
					Write-PAuditLog -EventLogSource PAudit -EntryType Information -EventID 1 -Message "Now running sub Package $SubPackageName for master Package $($Package.Name)"

					# Process getter for session
					$Results = Invoke-Command -Session $Session -FilePath (Join-Path $_.FullName "Get-$($SubPackageName).ps1") -ErrorVariable ComputerGetterError
					
					# Process getter for legacy wmi
					if($LegacyServers -and $Global:Config.EnableLegacy -and $SubPackageConfig.LegacySupport){
						
						# The Packageblock used to execute the legacy Package
						$LegacyPackageBlock = { Invoke-Expression "& `"$($args[0])`" $($args[1])" }

						# Start processing each legacy server
						foreach($LegacyServer IN $LegacyServers) {

							# Limit the amount of jobs that can be run to stop the server from dieing
							while(@(Get-Job -State "Running").Count -ge $Global:Config.MaximumJobs) {

								Write-PAuditLog -EventLogSource PAudit -EntryType Information -EventID 1 -Message "Maximum number of legacy jobs has been reached waiting for timeout or completion"

								# Kill off any long running jobs
								Stop-LongRunningJobs

								# wait a few seconds before trying again
								Start-Sleep -Seconds 2
							
							}

							# Legacy jobs is below threshold start the next job
							Write-PAuditLog -EventLogSource PAudit -EntryType Information -EventID 1 -Message "Starting background legacy job for server '$LegacyServer'"
							$CurrentJob = Start-Job -PackageBlock $LegacyPackageBlock -ArgumentList (Join-Path $_.FullName "Get-$($SubPackageName).ps1"),$LegacyServer -Name $LegacyServer
							Write-PAuditLog -EventLogSource PAudit -EntryType Information -EventID 1 -Message "Legacy job started OK, job ID is $($CurrentJob.Id) for server '$LegacyServer'"

						}

						# All jobs started now waiting for completion
						Write-PAuditLog -EventLogSource PAudit -EntryType Information -EventID 1 -Message "All legacy jobs have been started"

						# While we have a count greater than 0, wait for all jobs to complete
						while(@(Get-Job -State "Running").Count) {

							# Kill off any long running jobs
							Stop-LongRunningJobs

							# wait a few seconds before trying again
							Start-Sleep -Seconds 5
							
						}

						# Grab all the data obtained from the legacy job
						Write-PAuditLog -EventLogSource PAudit -EntryType Information -EventID 1 -Message "All legacy jobs have been completed"
						$Results += Get-Job | Receive-Job

					}
					
					# Process setter
					$OutputFolder = (Join-Path $Global:PAuditRoot "Output\$((Get-Date -Format MMMM).ToString())\$((Get-Date -Format dd).ToString())")

					if($Global:Config.OutputDatabase)
					{
						Write-PAuditLog -EventLogSource PAudit -EntryType Information -EventID 1 -Message "Saving results for $SubPackageName to database"
						if($Results.Result){
							New-SQLTable -Data $Results.Result -TableName "$($Package.Name)_$SubPackageName"
							Add-SQLData -Data ($Results.Result | Add-PAuditCollectionInfo) -TableName "$($Package.Name)_$SubPackageName"
						}
					}
					if($Global:Config.OutputCliXML)
					{
						Write-PAuditLog -EventLogSource PAudit -EntryType Information -EventID 1 -Message "Outputing XML results to folder $OutputFolder"
						New-RecursivePath (Join-Path $Global:PAuditRoot "Output") -Compress
						New-RecursivePath $OutputFolder
						$Results.Result | Add-PAuditCollectionInfo | Export-Clixml (Join-Path $OutputFolder "$($Package.Name)_$($SubPackageName).xml")
					}
					if($Global:Config.OutputCSV)
					{
						Write-PAuditLog -EventLogSource PAudit -EntryType Information -EventID 1 -Message "Outputing CSV results to folder $OutputFolder"
						New-RecursivePath (Join-Path $Global:PAuditRoot "Output") -Compress
						New-RecursivePath $OutputFolder
						$Results.Result | Add-PAuditCollectionInfo | Export-Csv (Join-Path $OutputFolder "$($Package.Name)_$($SubPackageName).csv") -NoTypeInformation
					}

					Remove-Variable -Name Results -ErrorAction SilentlyContinue
				}
			}

		}
    }
    catch
    {
        Write-PAuditLog -EventLogSource PAudit -EntryType Error -EventID 9999 -Message "Unknown Error - $_"
        return
    }
#endregion

#region Final actions

# Close all sessions still open and any old jobs
Write-PAuditLog -EventLogSource PAudit -EntryType Information -EventID 1 -Message "Removing all open PS Remote Sessions and any legacy jobs"
Get-PSSession | Remove-PSSession
Get-Job | Remove-Job -Force

$Script:StopWatch.Stop()
$Mins = [System.Math]::Round($StopWatch.Elapsed.TotalMinutes)
$Secs = [System.Math]::Round($StopWatch.Elapsed.TotalSeconds)

if($Mins -gt 0)
{
	$TimeTaken = "$Mins minutes"
}
else
{
	$TimeTaken = "$Secs seconds"
}

Write-PAuditLog -EventLogSource PAudit -EntryType Information -EventID 9999 -Message "PAudit has finished running, total time taken $TimeTaken"

#endregion