# NAME:         New-CustomObject.ps1
# AUTHOR:       Liam Glanfield
# CREATED DATE: 26/11/2015
# CHANGED DATE: 26/11/2015
# VERSION:      1.0.0
# DESCRIPTION:  Creates a new custom object from hash table and optionally trims white space from values if asked

Function Global:New-CustomObject {
	Param([System.Collections.Hashtable]$HashTable,[switch]$TrimStringValues)

	# Create a new hash table
	$CleanHash = New-Object -TypeName System.Collections.Hashtable

	# Check if given hash table has results
	if($HashTable.Count -gt 0) {

		# Loop through each hash table key/name
		Foreach($Key IN $HashTable.Keys){

			# if the value is a string and trim is enabled trim leading and trailing space
			if($TrimStringValues -eq $true -and $HashTable[$Key] -is [string]){
				$CleanHash.Add($Key,$HashTable[$Key].Trim())
			}else{
				$CleanHash.Add($Key,$HashTable[$Key])
			}

		}

		# Take cleaned hash table and pass to object for output
		New-Object -TypeName psobject -Property $CleanHash

	}else{
		# No values in the hash table return null
		return $null
	}

}