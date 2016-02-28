# http://fabriccontroller.net/blog/posts/passive-ftp-and-dynamic-ports-in-iis8-and-windows-azure-virtual-machines/
# https://github.com/sandrinodimattia/WindowsAzure-PassiveFTPinVM

$vm = Get-AzureVM -ServiceName "p1m1ftp" -Name "p1m1ftp"
[int]$publicPort = 21
[int]$dynamicPortFirst = 7000
[int]$dynamicPortLast = 7010

Get-ChildItem "${Env:ProgramFiles(x86)}\Microsoft SDKs\Windows Azure\PowerShell\Azure\*.dll" | ForEach-Object {[Reflection.Assembly]::LoadFile($_) | out-null }

$totalPorts = $dynamicPortLast - $dynamicPortFirst + 1
if ($totalPorts -gt 150)
{
	$(throw "You cannot add more than 150 endpoints (this includes the Public FTP Port)")
}

# Add endpoints.
Write-Host -Fore Green "Adding: FTP-Public-$publicPort"
Add-AzureEndpoint -VM $vm -Name "FTP-Public-$publicPort" -Protocol "tcp" -PublicPort $publicPort -LocalPort $publicPort
for ($i = $dynamicPortFirst; $i -le $dynamicPortLast; $i++)
{
	$name = "FTP-Dynamic-" + $i
	Write-Host -Fore Green "Adding: $name"
	Add-AzureEndpoint -VM $vm -Name $name -Protocol "tcp" -PublicPort $i -LocalPort $i
}

# Update VM.
Write-Host -Fore Green "Updating VM..."
$vm | Update-AzureVM 
Write-Host -Fore Green "Done."