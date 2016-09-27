[cmdletbinding()]
Param($ServerHostname='.')

begin{

    function Get-CName {
    param([string]$DN)

    # Split the Distinguished name into separate bits
    #
    $Parts=$DN.Split(",")

    # Figure out how deep the Rabbit Hold goes
    #
    $NumParts=$Parts.Count

    # Although typically 2 DC entries, make sure and figure out the length of the FQDN
    #
    $FQDNPieces=($Parts -match 'DC=').Count

    # Keep track of where the FQDN is (calling it the middle even if it
    # Could be WAY out there somewhere
    #
    $Middle=$NumParts-$FQDNPieces

    # Build the CN.  First part is separated by '.'
    #
    foreach ($x in ($Middle+1)..($NumParts)) {
        $CN+=$Parts[$x-1].SubString(3)+'.'
        }

    # Get rid of that extra Dot
    #
    $CN=$CN.substring(0,($CN.length)-1)

    # Now go BACKWARDS and build the rest of the CN
    #
    foreach ($x in ($Middle-1)..0) {
        #$Parts[$x].substring(3)
        $CN+="/"+$Parts[$x].SubString(3)
        }

    Return $CN
    }

}

process{

	#Grab all information required from WMI
    $OperatingSystem = Get-WmiObject -ComputerName $ServerHostname -Class Win32_OperatingSystem
    $ComputerName    = $OperatingSystem.__Server.ToString().ToUpper()
    
	$AssetTag		= (Get-WMIObject -computername $ServerHostname -Class Win32_SystemEnclosure -Property "SMBIOSAssetTag").SMBIOSAssetTag
	$OScaption		= $OperatingSystem.Caption
	$OSpack			= $OperatingSystem.CSDVersion
	$LastBootUpTime	= $OperatingSystem.LastBootUpTime
	$BuildNumber	= [int]$(Get-WMIObject -ComputerName $ServerHostname -Class Win32_OperatingSystem -Property "BuildNumber").BuildNumber
	$ComputerSys	= Get-WMIObject -ComputerName $ServerHostname -Class Win32_ComputerSystem -Property "Manufacturer,Model,SystemType,TotalPhysicalMemory,DomainRole,Domain" | select Manufacturer, `
						Model, SystemType, TotalPhysicalMemory, DomainRole, Domain
	$SerialNumber	= (Get-WMIObject -Computer $ServerHostname -Class Win32_Bios -Property "SerialNumber").SerialNumber
	$RAMslotsTotal	= 0
	$RAMslotsUsed	= 0
	Get-WMIObject -ComputerName $ServerHostname -Class Win32_PhysicalMemoryArray | foreach {
		$RAMslotsTotal += $_.MemoryDevices
	}
	$RAMslotsUsed	+= $(Get-WMIObject -ComputerName $ServerHostname -Class Win32_PhysicalMemory).count

	#Server 2003 reports incorrect number of processors, this is expected
	#Cast the processor to an array so if only 1 processor is returned a count of 1 is shown
	$Processor				= @(Get-WMIObject -ComputerName $ServerHostname -Class Win32_Processor)
	$ProcessorCount			= $Processor.Count
	$ProcessorCores			= $Processor[0].NumberOfCores
	$LogicalProcessors		= $Processor[0].NumberOfLogicalProcessors
	$ProcessorClockSpeed	= $Processor[0].MaxClockSpeed
	$ProcessorModel			= $Processor[0].Name

	#What role does this server have
	Switch($ComputerSys.DomainRole)
		{
		0{$DomainRole = "Stand Alone Workstation";$ADMachine=$false}
		1{$DomainRole = "Member Workstation";$ADMachine=$true}
		2{$DomainRole = "Stand Alone Server";$ADMachine=$false}
		3{$DomainRole = "Member Server";$ADMachine=$true}
		4{$DomainRole = "Back-up Domain Controller";$ADMachine=$true}
		5{$DomainRole = "Primary Domain Controller";$ADMachine=$true}
		default{$DomainRole = "Undetermined";$ADMachine=$false}
		}

	#Convert last boot up time
	$LastBootUpTime = [System.Management.ManagementDateTimeConverter]::ToDateTime($LastBootUpTime)

    #Grab AD details to add to output
    if($ADMachine){
        # clear old results
        $ADOutput = @{}
        try
        {
            $Filter = "(&(objectCategory=computer)(objectClass=computer)(cn=$ComputerName))"
            $Domain = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$($ComputerSys.Domain)")
            $ADSI = [adsisearcher]$Filter
            $ADSI.SearchRoot = $Domain
            $ADInfo = $ADSI.FindOne().Properties

            $ADOutput = @{
                ou = ($ADInfo.distinguishedname -join '')
                whencreated = ($ADInfo.whencreated -join '')
                description =($ADInfo.description -join '')
                lastlogontimestamp = ($ADInfo.lastlogontimestamp -join '')
                cn = ($ADInfo.cn -join '')
            }

            $ADOutput.lastlogontimestamp = [datetime]::FromFileTime($ADOutput.lastlogontimestamp)
            $ADOutput.ou = (Get-CName $ADOutput.ou).ToString().Replace("/$($ADOutput.cn)",'')
        }
        catch {}
    }

	#Output info
    $ComputerInfo = New-Object Object
    $ComputerInfo | Add-Member -MemberType NoteProperty -Name AssetTag -Value $AssetTag
    $ComputerInfo | Add-Member -MemberType NoteProperty -Name OS -Value $OScaption
    $ComputerInfo | Add-Member -MemberType NoteProperty -Name ServicePack -Value $OSpack
    $ComputerInfo | Add-Member -MemberType NoteProperty -Name DomainRole -Value $DomainRole
    $ComputerInfo | Add-Member -MemberType NoteProperty -Name Manufacturer -Value $ComputerSys.Manufacturer
    $ComputerInfo | Add-Member -MemberType NoteProperty -Name Model -Value $ComputerSys.Model
    $ComputerInfo | Add-Member -MemberType NoteProperty -Name PhysicalMemory -Value $ComputerSys.TotalPhysicalMemory
    $ComputerInfo | Add-Member -MemberType NoteProperty -Name ContainerOU -Value $ADOutput.ou
    $ComputerInfo | Add-Member -MemberType NoteProperty -Name SerialNumber -Value $SerialNumber
    $ComputerInfo | Add-Member -MemberType NoteProperty -Name SystemType -Value $ComputerSys.SystemType
    $ComputerInfo | Add-Member -MemberType NoteProperty -Name RAMslotsTotal -Value $RAMslotsTotal
    $ComputerInfo | Add-Member -MemberType NoteProperty -Name RAMslotsUsed -Value $RAMslotsUsed
    $ComputerInfo | Add-Member -MemberType NoteProperty -Name ADCreatedDate -Value $ADOutput.whencreated
    $ComputerInfo | Add-Member -MemberType NoteProperty -Name ProcessorCount -Value $ProcessorCount
    $ComputerInfo | Add-Member -MemberType NoteProperty -Name ProcessorCores -Value $ProcessorCores
    $ComputerInfo | Add-Member -MemberType NoteProperty -Name LogicalProcessors -Value $LogicalProcessors
    $ComputerInfo | Add-Member -MemberType NoteProperty -Name ProcessorClockSpeed -Value $ProcessorClockSpeed
    $ComputerInfo | Add-Member -MemberType NoteProperty -Name ProcessorModel -Value $ProcessorModel
    $ComputerInfo | Add-Member -MemberType NoteProperty -Name DomainName -Value $ComputerSys.Domain
    $ComputerInfo | Add-Member -MemberType NoteProperty -Name ADDescription -Value $ADOutput.description
    $ComputerInfo | Add-Member -MemberType NoteProperty -Name lastLogonTimestamp -Value $ADOutput.lastlogontimestamp
    $ComputerInfo | Add-Member -MemberType NoteProperty -Name LastBootUpTime -Value $LastBootUpTime
    

	# Collect errors and return result
    $OperatingSystem = Get-WmiObject -ComputerName $ServerHostname -Class Win32_OperatingSystem
    $ComputerName    = $OperatingSystem.__Server.ToString().ToUpper()
	if($ComputerInfo) {
		$ComputerInfo = $ComputerInfo | Select-Object @{n='Hostname';e={$ComputerName}},*
	}else{
		$ComputerInfo = $null
	}
	$Result = @{
		Errors = $Error
		Result = $ComputerInfo
	}

	# Return result as an object
	New-Object PSObject -Property $Result

}