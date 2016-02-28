$UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session

Set-ExecutionPolicy RemoteSigned

Set-DistributionGroup "support@p1m1.com" -ReportToOriginatorEnabled $true
Set-DistributionGroup "support@p1m1.com" -ReportToManagerEnabled $true

Remove-PSSession $Session