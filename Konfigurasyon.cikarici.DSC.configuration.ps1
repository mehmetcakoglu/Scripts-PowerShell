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

		{
			Name = 'FileAndStorage-Services'
			Ensure = 'Present'
		}

		{
			Name = 'File-Services'
			Ensure = 'Present'
		}

		{
			Name = 'FS-FileServer'
			Ensure = 'Present'
		}

		{
			Name = 'Storage-Services'
			Ensure = 'Present'
		}

		{
			Name = 'NET-Framework-45-Features'
			Ensure = 'Present'
		}

		{
			Name = 'NET-Framework-45-Core'
			Ensure = 'Present'
		}

		{
			Name = 'NET-WCF-Services45'
			Ensure = 'Present'    DependsOn = '[WindowsFeature]Role-NET-WCF-Services45'
		}

		{
			Name = 'NET-WCF-TCP-PortSharing45'
			Ensure = 'Present'    DependsOn = '[WindowsFeature]Role-NET-WCF-TCP-PortSharing45'
		}

		{
			Name = 'GPMC'
			Ensure = 'Present'
		}

		{
			Name = 'RSAT'
			Ensure = 'Present'
		}

		{
			Name = 'RSAT-Role-Tools'
			Ensure = 'Present'
		}

		{
			Name = 'RSAT-AD-Tools'
			Ensure = 'Present'
		}

		{
			Name = 'RSAT-AD-PowerShell'
			Ensure = 'Present'    DependsOn = '[WindowsFeature]Role-RSAT-AD-PowerShell'
		}

		{
			Name = 'RSAT-ADDS'
			Ensure = 'Present'
		}

		{
			Name = 'RSAT-AD-AdminCenter'
			Ensure = 'Present'    DependsOn = '[WindowsFeature]Role-RSAT-AD-AdminCenter'
		}

		{
			Name = 'RSAT-ADDS-Tools'
			Ensure = 'Present'
		}

		{
			Name = 'RSAT-DNS-Server'
			Ensure = 'Present'
		}

		{
			Name = 'FS-SMB1'
			Ensure = 'Present'
		}

		{
			Name = 'User-Interfaces-Infra'
			Ensure = 'Present'
		}

		{
			Name = 'Server-Gui-Mgmt-Infra'
			Ensure = 'Present'    DependsOn = '[WindowsFeature]Role-Server-Gui-Mgmt-Infra'
		}

		{
			Name = 'Server-Gui-Shell'
			Ensure = 'Present'    DependsOn = '[WindowsFeature]Role-Server-Gui-Shell'
		}

		{
			Name = 'PowerShellRoot'
			Ensure = 'Present'
		}

		{
			Name = 'PowerShell'
			Ensure = 'Present'    DependsOn = '[WindowsFeature]Role-PowerShell'
		}

		{
			Name = 'PowerShell-ISE'
			Ensure = 'Present'    DependsOn = '[WindowsFeature]Role-PowerShell-ISE'
		}

		{
			Name = 'WoW64-Support'
			Ensure = 'Present'
		}

} 
