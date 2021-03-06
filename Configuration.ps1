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
@{
	# Collection Settings
	UseSession		= $true
	UseLegacy		= $true
	DomainList   	= $false
	UseComputerList	= $true
	DiscoverDomain	= $false # Discover local AD domain computers
	ComputerType	= 'Both' # Can be either Server, ClientDevice or Both

	# For AD enumeration what type of computers do you want?
	ReturnClusters		= $false # This is the cluster virtual names
	ReturnServers		= $true
	ReturnClients		= $true
	ReturnUnknown		= $false # Return computers which haven't matched any criteria, these are often linux machines

	# Log file config
	UseLogFile = $true
	LogFileName = (Get-Date).ToString('yyyy-MM-dd HH-mm-ss') + ' PAudit.log'

	# Output options
	OutputCliXML   = $true
	OutputCSV      = $true

	# Legacy configuration
	MaximumJobs  = 20
	JobTimeOut   = (New-TimeSpan -Minutes 15)

}
