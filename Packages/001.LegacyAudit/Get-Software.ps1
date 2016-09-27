[cmdletbinding()]
Param($ServerHostname='.')

begin{

    function Sort-InstallDate {
    param([string]$StringDate)

        $Y = $StringDate.Substring(0,4)
        $M = $StringDate.Substring(4,2)
        $D = $StringDate.Substring(6,2)
        [datetime]"$Y-$M-$D"

    }

}

process{

    if($ServerHostname -eq '.'){

        if((Test-Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall')){
            [string[]]$RootKeys      = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
        }else{
            [string[]]$RootKeys      = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
        }
        $Output = Get-ItemProperty -Path $RootKeys | Where-Object {
	        ($_.DisplayName -notlike 'Security Update for Windows*' -AND
	        $_.DisplayName -notlike 'Hotfix for Windows*' -AND
	        $_.DisplayName -notlike 'Update for Windows*' -AND
	        $_.DisplayName -notlike 'Update for Microsoft*' -AND
	        $_.DisplayName -notlike 'Security Update for Microsoft*' -AND
	        $_.DisplayName -notlike 'Hotfix for Microsoft*' -AND
            $_.PSChildName -notlike '*}.KB') } | Where-Object { $_.DisplayName -ne $null -AND $_.DisplayName -ne '' } |
        Select-Object Publisher, DisplayName, DisplayVersion, @{n='InstallDate';e={Sort-InstallDate $_.InstallDate}}, InstallLocation, EstimatedSize

    }else{

        # Using WMI to get remote registry as more reliable
        $HKLM = 2147483650
        $WMI = Get-WmiObject -List StdRegProv -Namespace Root\Default -ComputerName $ServerHostname -ErrorAction Stop

        $A = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
        $B = 'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'

        $SubKeyNames = $WMI.EnumKey($HKLM,$A).sNames | foreach{ Join-Path $A $_ }
        $SubKeyNames += $WMI.EnumKey($HKLM,'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall').sNames | foreach{ Join-Path $B $_ }
        $SubKeyNames = $SubKeyNames | Where-Object {  $_ -ne $null -AND $_ -ne '' } | Where-Object { $_ -notlike '*}.KB' }

        $Output = $SubKeyNames | Foreach{

            $SubKey = $_

            New-Object -TypeName psobject -Property @{
                Publisher = $WMI.GetStringValue($HKLM,$SubKey,'Publisher').sValue
                DisplayName = $WMI.GetStringValue($HKLM,$SubKey,'DisplayName').sValue
                DisplayVersion = $WMI.GetStringValue($HKLM,$SubKey,'DisplayVersion').sValue
                InstallDate = $WMI.GetStringValue($HKLM,$SubKey,'InstallDate').sValue
                InstallLocation = $WMI.GetStringValue($HKLM,$SubKey,'InstallLocation').sValue
                EstimatedSize = $WMI.GetDWORDValue($HKLM,$SubKey,'EstimatedSize').uValue
            }
            
        } | Where-Object {
	        ($_.DisplayName -notlike 'Security Update for Windows*' -AND
	        $_.DisplayName -notlike 'Hotfix for Windows*' -AND
	        $_.DisplayName -notlike 'Update for Windows*' -AND
	        $_.DisplayName -notlike 'Update for Microsoft*' -AND
	        $_.DisplayName -notlike 'Security Update for Microsoft*' -AND
	        $_.DisplayName -notlike 'Hotfix for Microsoft*' ) } | Where-Object { $_.DisplayName -ne $null -AND $_.DisplayName -ne '' } |
        Select-Object Publisher, DisplayName, DisplayVersion, @{n='InstallDate';e={Sort-InstallDate $_.InstallDate}}, InstallLocation, EstimatedSize


    }

	# Collect errors and return result
    $OperatingSystem = Get-WmiObject -ComputerName $ServerHostname -Class Win32_OperatingSystem
    $ComputerName    = $OperatingSystem.__Server.ToString().ToUpper()
	if($Output) {
		$Output = $Output | Select-Object @{n='Hostname';e={$ComputerName}},*
	}else{
		$Output = $null
	}
	$Result = @{
		Errors = $Error
		Result = $Output
	}

	# Return result as an object
	New-Object PSObject -Property $Result

}