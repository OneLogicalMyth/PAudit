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
# NAME:         Get-Certificates.ps1
# AUTHOR:       Liam Glanfield
# CREATED DATE: 27/11/2015
# CHANGED DATE: 27/11/2015
# VERSION:      1.0.0
# DESCRIPTION:  Collects certificates from the local machines certificate store

# Error handling
$ErrorActionPreference = 'SilentlyContinue'
$Errors = @()
$Error.Clear()

#region Start collecting data

	$Output = Get-ChildItem Cert:\LocalMachine\My | ForEach-Object {


		# Grab SAN names
		$SANNames = $_.DnsNameList | Select-Object -ExpandProperty Punycode
		$FirstSAN = $SANNames | Select-Object -First 1

		# Split subject into known values
		$SubjectFields = New-Object System.Collections.Hashtable
		if($_.Subject){
			$SubjectArray = $_.Subject.Split(',')
			Foreach($Part IN $SubjectArray){
				$Item = $Part.Split('=')
				$Field = $Item[0].Trim().ToUpper()
				$Value = $Item[1].Trim()
				if($SubjectFields.$Field){
					$Value = "$($SubjectFields.$Field);$Value"
					$SubjectFields.$Field = $Value
				}else{
					$SubjectFields.Add($Field,$Value)
				}
			}
		}else{
			$SubjectFields.Add('CN',$FirstSAN)
		}

		New-Object -TypeName PSObject -Property @{
			FriendlyName         = $_.FriendlyName
			SignatureAlgorithm   = $_.SignatureAlgorithm.FriendlyName
			HasPrivateKey        = $_.HasPrivateKey
			KeySize              = $_.PublicKey.Key.KeySize
			KeyExchangeAlgorithm = $_.PublicKey.Key.KeyExchangeAlgorithm
			SerialNumber         = $_.SerialNumber
			Thumbprint           = $_.Thumbprint
			Issuer               = $_.Issuer
			Version              = $_.Version
			BeginsOn             = $_.NotBefore
			ExpiresOn            = $_.NotAfter
			CommonName           = $SubjectFields.CN
			CountryName          = $SubjectFields.C
			StateOrProvinceName  = $SubjectFields.S
			Locality             = $SubjectFields.L
			Organization         = $SubjectFields.O
			OrganizationalUnit   = $SubjectFields.OU
			IsValid              = $_.Verify()
			DNSNames             = $SANNames -join ';'
		}
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
