


# Enumerate local domain computers
# First check we are on a domain, the package wants domain enumeration and globally its enabled to!
$DomainMember = (Get-WmiObject -Class Win32_ComputerSystem).DomainRole -ge 3
if(($DomainMember -eq $true) -AND ($Package.DiscoverDomain -eq $true) -AND ($Global:Config.DiscoverDomain -eq $true)){

    $LocalDomainComputers = Get-ADComputers

}

# Now enumerate remote domain comptuers
if(($Package.DiscoverDomain -eq $true) -AND ($Global:Config.DomainList -eq $true)){

    $Domains = Get-Content (Join-Path $Global:PAuditRoot 'Lists\Domain.xml')
    $RemoteDomainComputers = foreach($Domain IN ([XML]$Domains).Domains.Domain){
            
            $SecurePassword = $Domain.Password
            $BSTR           = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
            $Password       = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            
            Get-ADComputers -DomainName $Domain.DomainName -Username $Domain.Username -Password $Password

    }

}

# Now read the list of computers and process them
if(($Package.ComputerList -eq $true) -AND ($Global:Config.UseComputerList -eq $true)){

    $Computers = Get-Content (Join-Path $Global:PAuditRoot 'Lists\Computer.xml')
    $ListComputers = foreach($Computer IN ([XML]$Computers).Computers.Computer){
            
            $SecurePassword = $Computer.Password
            $BSTR           = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
            $Password       = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            
            Get-ADComputers -DomainName $Computer.HostName -Username $Computer.Username -Password $Password

    }

}


$LocalDomainComputers
$RemoteDomainComputers
$ListComputers