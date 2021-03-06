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
Function New-PAuditLog {
Param([string]$EventLogSource = 'PAudit')
 
    $EventLogExists = [System.Diagnostics.EventLog]::Exists($EventLogSource)
    $EventLogSourceExists = [System.Diagnostics.EventLog]::SourceExists($EventLogSource)
 
    if(-not $EventLogExists -or -not $EventLogSourceExists){
        New-EventLog -LogName PAudit -Source $EventLogSource
        Limit-EventLog -LogName PAudit -OverFlowAction OverwriteAsNeeded -MaximumSize 50MB
    }
}
