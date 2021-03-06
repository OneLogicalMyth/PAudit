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
    Write-Verbose "Importing helper $($Helper.Name)"
    . $Helper.FullName
}

# Set root path globally
$Global:PAuditRoot = $PSScriptRoot
Write-Verbose "Set script root path to $($Global:PAuditRoot)"
Write-PAuditLog -EventID 100

# Import configuration file
Write-Verbose "Starting to load configuration"
$Global:Config = . $(Join-Path $Global:PAuditRoot 'Configuration.ps1')
Write-PAuditLog -EventID 105 -Data $Global:PAuditRoot
Write-Verbose "Loaded configuration from $($Global:Config)"

# Load the packges configuration
$Packages = . $(Join-Path $Global:PAuditRoot 'Core\LoadPackages.ps1')
$global:testpackages = $Packages
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
				Write-PAuditLog -EventID 95
				Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value * -Force
			}

			# Enumerate and merge list of computers
			Write-Verbose "Running $(Join-Path $Global:PAuditRoot 'Core\EnumerateComputers.ps1')"
			if($Global:Config.ComputerType -eq 'Both'){
				$ComputerList = &$(Join-Path $Global:PAuditRoot 'Core\EnumerateComputers.ps1')
			}else{
				$ComputerList = &$(Join-Path $Global:PAuditRoot 'Core\EnumerateComputers.ps1') | Where-Object { $_.ComputerType -eq $Global:Config.ComputerType}
			}

			#Write-Verbose $ComputerList

			# Check if any computers have been identified
			if($ComputerList -eq $null)
			{
				Write-Verbose "$ComputerList"
				Write-PAuditLog -EventID 510
				return
			}

			# Disable all checks for session
			$SesOpt = New-PSSessionOption -SkipRevocationCheck -SkipCACheck -SkipCNCheck

			# Create sessions for each of the computers, capture any bad setups
			$NormSession = $ComputerList | Where-Object { $_.Username -eq "" } | Select-Object -ExpandProperty ComputerName
			$AuthSession = $ComputerList | Where-Object { $_.Username -ne "" }
			if($NormSession)
			{
				New-PSSession -ComputerName $NormSession -ErrorVariable SessionErrorsA -ErrorAction SilentlyContinue | ForEach-Object {
					Write-PAuditLog -EventID 120 -Data $_.ComputerName
				}
			}
			foreach($AuthSes IN $AuthSession)
			{
				$SecurePassw = ConvertTo-SecureString $AuthSes.Password -AsPlainText -Force
				$Credentials = New-Object System.Management.Automation.PSCredential ($AuthSes.Username, $SecurePassw)

				New-PSSession -ComputerName $AuthSes.IP -Credential $Credentials -ErrorVariable SessionErrorsB -ErrorAction SilentlyContinue | ForEach-Object {
					Write-PAuditLog -EventID 120 -Data $AuthSes.ComputerName
				}
			}

			Write-PAuditLog -EventID 125

			# Process bad servers for investigation, capture any servers that respond to WMI instead
			$LegacyServers = @()
			Foreach($BadServer IN ($SessionErrorsA + $SessionErrorsB))
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
						Write-PAuditLog  -EventID 9999 -Data "$($BadServer.targetobject.connectioninfo.computername) supports legacy WMI adding to the legacy list"
					}else{
						Write-PAuditLog -EventID 9999 -Data "$($BadServer.targetobject.connectioninfo.computername) does not support legacy WMI due to timeout, is the server accessible on the network?"
					}
					
				}
				catch
				{
					Write-PAuditLog -EventID 9999 -Data "$($BadServer.targetobject.connectioninfo.computername) does not support legacy WMI due to '$_', is the server accessible on the network?"
				}
				
			}
		
			# Grab all open sessions
			$Session = Get-PSSession | Where-Object State -eq Opened

		} # End if for session required

		# Run each master Package and execute objectcommand as per XML
		Foreach($Package IN $Packages)
		{
			Write-PAuditLog -EventID 115 $Package.PackageName

			# Check if we have sessions available
			if($Session){

				# Import global functions into session if required
				if($Package.EnableGlobalFunctions)
				{
					Write-PAuditLog -EventID 1 -Data "Global functions are required for master Package $($Package.PackageName), importing functions"
					Foreach($GlobalFile IN $Package.GlobalFunctions)
					{
						Write-PAuditLog -EventID 1 -Data "Importing global function $GlobalFile"
						Invoke-Command -Session $Session -FilePath (Join-Path $Global:PAuditRoot "Helpers\$GlobalFile")
						$GlobalFile = $null
					}
							
				}

			}

			# Check if there are legacy servers to process
			if($LegacyServers){
				# to do legacy
			}

			# Get all subPackages and execute them
			$Package.RunOrder |
			Foreach {

				$PackageScript = $_

				$SubPackageFile = Join-Path $Package.FullPath "$($PackageScript).ps1"

				if((Test-Path $SubPackageFile)){
					Write-PAuditLog -EventID 1 -Data "Now running package script '$PackageScript' for package '$($Package.PackageName)'"

					# Process getter for session
					$Results = Invoke-Command -Session $Session -FilePath $SubPackageFile -ErrorVariable ComputerGetterError
					
					# Process getter for legacy wmi
					if($LegacyServers -and $Global:Config.EnableLegacy -and $SubPackageConfig.LegacySupport){
						
						# The Packageblock used to execute the legacy Package
						$LegacyPackageBlock = { Invoke-Expression "& `"$($args[0])`" $($args[1])" }

						# Start processing each legacy server
						foreach($LegacyServer IN $LegacyServers) {

							# Limit the amount of jobs that can be run to stop the server from dieing
							while(@(Get-Job -State "Running").Count -ge $Global:Config.MaximumJobs) {

								Write-PAuditLog -EventID 1 -Data "Maximum number of legacy jobs has been reached waiting for timeout or completion"

								# Kill off any long running jobs
								Stop-LongRunningJobs

								# wait a few seconds before trying again
								Start-Sleep -Seconds 2
							
							}

							# Legacy jobs is below threshold start the next job
							Write-PAuditLog -EventID 1 -Data "Starting background legacy job for server '$LegacyServer'"
							$CurrentJob = Start-Job -PackageBlock $LegacyPackageBlock -ArgumentList (Join-Path $_.FullName "Get-$($SubPackageName).ps1"),$LegacyServer -Name $LegacyServer
							Write-PAuditLog -EventID 1 -Data "Legacy job started OK, job ID is $($CurrentJob.Id) for server '$LegacyServer'"

						}

						# All jobs started now waiting for completion
						Write-PAuditLog -EventID 1 -Data "All legacy jobs have been started"

						# While we have a count greater than 0, wait for all jobs to complete
						while(@(Get-Job -State "Running").Count) {

							# Kill off any long running jobs
							Stop-LongRunningJobs

							# wait a few seconds before trying again
							Start-Sleep -Seconds 5
							
						}

						# Grab all the data obtained from the legacy job
						Write-PAuditLog -EventID 1 -Data "All legacy jobs have been completed"
						$Results += Get-Job | Receive-Job

					}
					
					# Process setter
					$OutputFolder = (Join-Path $Global:PAuditRoot "Output\$((Get-Date -Format MMMM).ToString())\$((Get-Date -Format dd).ToString())")

					if($Results.Result)
					{
						if($Global:Config.OutputCliXML)
						{
							Write-PAuditLog -EventID 1 -Data "Outputing XML results to folder $OutputFolder"
							New-RecursivePath (Join-Path $Global:PAuditRoot "Output") -Compress
							New-RecursivePath $OutputFolder
							$Results.Result | Add-CollectionInfo | Export-Clixml (Join-Path $OutputFolder "$($Package.PackageName)_$($PackageScript).xml")
						}
						if($Global:Config.OutputCSV)
						{
							Write-PAuditLog -EventID 1 -Data "Outputing CSV results to folder $OutputFolder"
							New-RecursivePath (Join-Path $Global:PAuditRoot "Output") -Compress
							New-RecursivePath $OutputFolder
							$Results.Result | Add-CollectionInfo | Export-Csv (Join-Path $OutputFolder "$($Package.PackageName)_$($PackageScript).csv") -NoTypeInformation
						}
					}
					else
					{
						Write-PAuditLog -EventID 1 -Data "No results returned for package '$($Package.PackageName)' running script '$PackageScript'"
					}

					Remove-Variable -Name Results -ErrorAction SilentlyContinue
				}else{
					Write-PAuditLog -EventID 9999 -Data "Package script '$SubPackageFile' not found"
				}
			}

		}
    }
    catch
    {
        Write-PAuditLog -EventID 9999 -Data "Unknown Error - $_"
        return
    }
#endregion

#region Final actions

# Close all sessions still open and any old jobs
Write-PAuditLog -EventID 1 -Data "Removing all open PS Remote Sessions and any legacy jobs"
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

Write-PAuditLog -EventID 1 -Data "PAudit has finished running, total time taken $TimeTaken"

#endregion
