<#
Get-WindowsFeature -ComputerName AzureDC01 | 
? installed |
% {$t = ''} { $t += @"

WindowsFeature "Role-$($_.Name)"
{
    Name = '$($_.Name)'
    Ensure = 'Present'
"@ 
    if ($_.dependson)
    {
        $t += @"
    DependsOn = '[WindowsFeature]Role-$($_.Name)'
"@
    }

    $t += @'

}
'@
} {$t} >> "C:\test.txt"
#>

Configuration MyDCConfig
{
	Node "AzureDC01"
	{

		WindowsFeature "Role-AD-Domain-Services"
		{
			Name = 'AD-Domain-Services'
			Ensure = 'Present'    DependsOn = '[WindowsFeature]Role-AD-Domain-Services'
		}

		WindowsFeature "Role-DNS"
		{
			Name = 'DNS'
			Ensure = 'Present'
		}
		WindowsFeature "Role-FileAndStorage-Services"
		{
			Name = 'FileAndStorage-Services'
			Ensure = 'Present'
		}
		WindowsFeature "Role-File-Services"
		{
			Name = 'File-Services'
			Ensure = 'Present'
		}
		WindowsFeature "Role-FS-FileServer"
		{
			Name = 'FS-FileServer'
			Ensure = 'Present'
		}
		WindowsFeature "Role-Storage-Services"
		{
			Name = 'Storage-Services'
			Ensure = 'Present'
		}
		WindowsFeature "Role-NET-Framework-45-Features"
		{
			Name = 'NET-Framework-45-Features'
			Ensure = 'Present'
		}
		WindowsFeature "Role-NET-Framework-45-Core"
		{
			Name = 'NET-Framework-45-Core'
			Ensure = 'Present'
		}
		WindowsFeature "Role-NET-WCF-Services45"
		{
			Name = 'NET-WCF-Services45'
			Ensure = 'Present'    DependsOn = '[WindowsFeature]Role-NET-WCF-Services45'
		}
		WindowsFeature "Role-NET-WCF-TCP-PortSharing45"
		{
			Name = 'NET-WCF-TCP-PortSharing45'
			Ensure = 'Present'    DependsOn = '[WindowsFeature]Role-NET-WCF-TCP-PortSharing45'
		}
		WindowsFeature "Role-GPMC"
		{
			Name = 'GPMC'
			Ensure = 'Present'
		}
		WindowsFeature "Role-RSAT"
		{
			Name = 'RSAT'
			Ensure = 'Present'
		}
		WindowsFeature "Role-RSAT-Role-Tools"
		{
			Name = 'RSAT-Role-Tools'
			Ensure = 'Present'
		}
		WindowsFeature "Role-RSAT-AD-Tools"
		{
			Name = 'RSAT-AD-Tools'
			Ensure = 'Present'
		}
		WindowsFeature "Role-RSAT-AD-PowerShell"
		{
			Name = 'RSAT-AD-PowerShell'
			Ensure = 'Present'    DependsOn = '[WindowsFeature]Role-RSAT-AD-PowerShell'
		}
		WindowsFeature "Role-RSAT-ADDS"
		{
			Name = 'RSAT-ADDS'
			Ensure = 'Present'
		}
		WindowsFeature "Role-RSAT-AD-AdminCenter"
		{
			Name = 'RSAT-AD-AdminCenter'
			Ensure = 'Present'    DependsOn = '[WindowsFeature]Role-RSAT-AD-AdminCenter'
		}
		WindowsFeature "Role-RSAT-ADDS-Tools"
		{
			Name = 'RSAT-ADDS-Tools'
			Ensure = 'Present'
		}
		WindowsFeature "Role-RSAT-DNS-Server"
		{
			Name = 'RSAT-DNS-Server'
			Ensure = 'Present'
		}
		WindowsFeature "Role-FS-SMB1"
		{
			Name = 'FS-SMB1'
			Ensure = 'Present'
		}
		WindowsFeature "Role-User-Interfaces-Infra"
		{
			Name = 'User-Interfaces-Infra'
			Ensure = 'Present'
		}
		WindowsFeature "Role-Server-Gui-Mgmt-Infra"
		{
			Name = 'Server-Gui-Mgmt-Infra'
			Ensure = 'Present'    DependsOn = '[WindowsFeature]Role-Server-Gui-Mgmt-Infra'
		}
		WindowsFeature "Role-Server-Gui-Shell"
		{
			Name = 'Server-Gui-Shell'
			Ensure = 'Present'    DependsOn = '[WindowsFeature]Role-Server-Gui-Shell'
		}
		WindowsFeature "Role-PowerShellRoot"
		{
			Name = 'PowerShellRoot'
			Ensure = 'Present'
		}
		WindowsFeature "Role-PowerShell"
		{
			Name = 'PowerShell'
			Ensure = 'Present'    DependsOn = '[WindowsFeature]Role-PowerShell'
		}
		WindowsFeature "Role-PowerShell-ISE"
		{
			Name = 'PowerShell-ISE'
			Ensure = 'Present'    DependsOn = '[WindowsFeature]Role-PowerShell-ISE'
		}
		WindowsFeature "Role-WoW64-Support"
		{
			Name = 'WoW64-Support'
			Ensure = 'Present'
		}
	}
} 

