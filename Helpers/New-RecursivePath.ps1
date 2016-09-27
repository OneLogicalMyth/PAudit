#
# Create_OutputFolder.ps1
#


Function New-RecursivePath {
Param([string]$RootPath,[switch]$Compress,[switch]$ReturnPaths)

    #Get each path until the root drive
    $NewPath = $RootPath.TrimEnd('\')
    [int]$LeafCount = $NewPath.split('\').count
    $Array = 1..$LeafCount | foreach{
        if($NewPath)
        {
            $NewPath = Split-Path $NewPath -ErrorAction SilentlyContinue
            $NewPath
        }
    }
    $Paths = $Array | Where-Object { $_ -ne '' }
    $Paths = $Paths[$($LeafCount-1)..0]
    $Paths += $RootPath

    #Just return paths if switch is used
    if($ReturnPaths){
        Return $Paths
    }
    
    #Check each leaf and make sure it exists if not then create it
    try
    {
        Foreach($Path IN $Paths){
            if(-not (Test-Path $Path)){
                New-Item -Path $Path -ItemType Directory -ErrorAction Stop | Out-Null
            }
        }

		if($Compress)
		{
			Get-CimInstance -Class Win32_Directory -Filter "Name='$($RootPath.Replace('\','\\'))'" | Invoke-CimMethod -MethodName Compress | Out-Null
		}
    }
    catch
    {
        Write-Warning "Could not create '$Path' - $_"
    }

}


