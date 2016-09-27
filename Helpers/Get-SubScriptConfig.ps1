#
# Get_SubScriptConfig.ps1
#

Function Get-SubScriptConfig {
	Param($FileName)

	if((Test-Path $FileName)) {

		[xml]$ScriptConfigXML = Get-Content $FileName
		$ScriptConfig = $ScriptConfigXML.Configuration

		$Data = @{
			Name          = [string]$ScriptConfig.Name         
			Description   = [string]$ScriptConfig.Description  
			Author        = [string]$ScriptConfig.Author       
			Created       = [datetime]$ScriptConfig.Created      
			Modified      = [datetime]$ScriptConfig.Modified     
			ScriptVersion = [version]$ScriptConfig.ScriptVersion
			TableVersion  = [version]$ScriptConfig.TableVersion 
			LegacySupport = [bool][int]$ScriptConfig.LegacySupport
		}

		New-Object -TypeName psobject -Property $Data


	}

}