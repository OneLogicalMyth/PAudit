@{
	# Collection Settings
	UseSession		= $true
	UseLegacy		= $true
	UseDomainList	= $true
	UseComputerList	= $true
	DiscoverDomain	= $true # Discover local AD domain computers
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