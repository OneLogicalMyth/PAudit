# NAME:         Get-BasicInfo.ps1
# AUTHOR:       Liam Glanfield
# CREATED DATE: 02/11/2015
# CHANGED DATE: 02/11/2015
# VERSION:      1.0.0
# DESCRIPTION:  Collects basic information about the computer

# Error handling
$ErrorActionPreference = 'Stop'
$Errors = @()
$Error.Clear()

#region Start collecting data

function ConvertFrom-WMIDate {
	Param($WMIDate)
	([WMI]'').ConvertToDateTime($WMIDate)
}

function Get-ComputerSite
{
	$site = nltest /dsgetsite 2>$null
	if ($LASTEXITCODE -eq 0) { $site[0] }
}

function Get-DomainRole {
	param([int]$DomainRole)
	switch ($DomainRole)
	{
		0 {'Standalone Workstation'}
		1 {'Member Workstation'}
		2 {'Standalone Server'}
		3 {'Member Server'}
		4 {'Backup Domain Controller'}
		5 {'Primary Domain Controller'}
		default {$_}
	}
}

function Get-ChassisTypes {
	Param([int]$ChassisTypes)
	switch ($ChassisTypes)
	{
		1	{'Other'}
		2	{'Unknown'}
		3	{'Desktop'}
		4	{'Low Profile Desktop'}
		5	{'Pizza Box'}
		6	{'Mini Tower'}
		7	{'Tower'}
		8	{'Portable'}
		9	{'Laptop'}
		10	{'Notebook'}
		11	{'Hand Held'}
		12	{'Docking Station'}
		13	{'All in One'}
		14	{'Sub Notebook'}
		15	{'Space-Saving'}
		16	{'Lunch Box'}
		17	{'Main System Chassis'}
		18	{'Expansion Chassis'}
		19	{'SubChassis'}
		20	{'Bus Expansion Chassis'}
		21	{'Peripheral Chassis'}
		22	{'Storage Chassis'}
		23	{'Rack Mount Chassis'}
		24	{'Sealed-Case PC'}
		default {$_}
	}
}

$ADSite = Get-ComputerSite

# Get OS info
$OperatingSystem = Get-WmiObject -Class Win32_OperatingSystem | Select-Object -Property @(
	'Caption',
	'OtherTypeDescription',
	'CSDVersion',
	@{ n = 'InstallDate'; e = { ConvertFrom-WMIDate ($_.InstallDate) } },
	@{ n = 'LastBootUpTime'; e = { ConvertFrom-WMIDate ($_.LastBootUpTime) } },
	'Version',
	'BuildNumber',
	'PAEEnabled',
	'SystemDevice',
	'SystemDrive',
	'SerialNumber',
	'Locale'
)
			
# Get BIOS info
$SystemEnclosure = Get-WmiObject -Class Win32_SystemEnclosure | Select-Object -Property @('SMBIOSAssetTag',@{ n = 'ChassisTypes'; e = { Get-ChassisTypes ($_.ChassisTypes[0]) } })

# Get OS info
$ComputerSystem = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -Property @(
	'Manufacturer',
	'Model',
	'SystemType',
	'TotalPhysicalMemory',
	'Domain',
	@{ n = 'DomainRole'; e = { Get-DomainRole ($_.DomainRole) } },
	'AutomaticManagedPagefile',
	'BootupState',
	'NumberOfLogicalProcessors',
	'NumberOfProcessors',
	'OEMStringArray'
)

$BIOS = Get-WmiObject -Class Win32_Bios | Select-Object -Property @(
	'SMBIOSBIOSVersion',
	'Manufacturer',
	'Name',
	'SerialNumber',
	'Version'
)

$SKU = Get-WmiObject -Namespace root\WMI -Class MS_SystemInformation

$PhysicalMemoryArray = Get-WmiObject -Class Win32_PhysicalMemoryArray
$PhysicalMemoryArray = $PhysicalMemoryArray | Where-Object { $_.Use -eq 3 }
				
$MemProperty = @('MemoryDevices', 'MaxCapacity')
$Totals = $PhysicalMemoryArray | Measure-Object $MemProperty -Sum
$TotalRAMSlots = $Totals[0].Sum
$TotalRAMCapacity = $Totals[1].Sum

# Grab boot enviroment type
$BootEnviroment = (Get-Content C:\Windows\Panther\setupact.log | Select-String 'Callback_BootEnvironmentDetect: Detected boot environment:').ToString().Split(':')[4].Trim()

# Attempt to convert the locale to the display name
try {
	$Locale = [System.Globalization.Cultureinfo]::GetCultureInfo([System.Convert]::ToInt32($OperatingSystem.Locale,16)).DisplayName
}
catch {
	$Locale = $OperatingSystem.Locale
}

$Output = New-CustomObject -TrimStringValues -HashTable @{
	# System enclosure information
	'AssetTag' = $SystemEnclosure.SMBIOSAssetTag
	'ChassisType' = $SystemEnclosure.ChassisTypes
	# Operating system information
	'OS' = $OperatingSystem.Caption
	'OSOther' = $OperatingSystem.OtherTypeDescription
	'ServicePack' = $OperatingSystem.CSDVersion
	'OSInstallDate' = $OperatingSystem.InstallDate
	'LastBootUpTime' = $OperatingSystem.LastBootUpTime
	'OSVersion' = $OperatingSystem.Version
	'OSBuildNumber' = $OperatingSystem.BuildNumber
	'PAEEnabled' = $OperatingSystem.PAEEnabled
	'OSHardDisk' = $OperatingSystem.SystemDevice
	'OSLogicalDrive' = $OperatingSystem.systemDrive
	'ProductID' = $OperatingSystem.SerialNumber
	'Locale' = $Locale
	# Computer system information
	'Manufacturer' = $ComputerSystem.Manufacturer
	'Model' = $ComputerSystem.Model
	'BootEnviroment' = $BootEnviroment
	'SystemType' = $ComputerSystem.SystemType
	'OSTotalMemoryGB' = [math]::Round($ComputerSystem.TotalPhysicalMemory / 1gb)
	'Domain' = $ComputerSystem.Domain
	'DomainRole' = $ComputerSystem.DomainRole
	'AutomaticManagedPagefile' = $ComputerSystem.AutomaticManagedPagefile
	'BootupState' = $ComputerSystem.BootupState
	'NumberOfLogicalProcessors' = $ComputerSystem.NumberOfLogicalProcessors
	'NumberOfProcessors' = $ComputerSystem.NumberOfProcessors
	'ProductNumber' = $SKU.SystemSKU
	# BIOS information
	'SMBIOSVersion' = $BIOS.SMBIOSBIOSVersion
	'BIOSManufacturer' = $BIOS.Manufacturer
	'BIOSName' = $BIOS.Name
	'SerialNumber' = $BIOS.SerialNumber
	'BIOSVersion' = $BIOS.Version
	# Hardware RAM information
	'HardwareRAMCapacityGB' = [math]::Round($TotalRAMCapacity / 1024 / 1024)
	'HardwareRAMSlots' = $TotalRAMSlots
	# AD Site
	'ADSite' = $ADSite
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

