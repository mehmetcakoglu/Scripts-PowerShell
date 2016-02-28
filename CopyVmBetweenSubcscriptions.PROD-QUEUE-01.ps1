#http://blogs.msdn.com/b/microsoft_press/archive/2014/01/29/from-the-mvps-copying-a-virtual-machine-from-one-windows-azure-subscription-to-another-with-powershell.aspx

$OldSubscriptionName = "Windows Azure MSDN - Visual Studio Ultimate"
$NewSubscriptionName = "P1M1 Enterprise Agreement"
$vmName = "PROD-QUEUE-01"
$serviceName = "p1m1-prod-csrv"
$destServiceName = "p1m1-prod-csrv2"

Select-AzureSubscription -SubscriptionName $OldSubscriptionName
#Get-AzureVM
$workingDir = (Get-Location).Path

$sourceVm = Get-AzureVM –ServiceName $serviceName –Name $vmName
$vmConfigurationPath = $workingDir + "\exportedVM.xml"
$sourceVm | Export-AzureVM -Path $vmConfigurationPath

$sourceOSDisk = $sourceVm.VM.OSVirtualHardDisk
$sourceDataDisks = $sourceVm.VM. DataVirtualHardDisks

$sourceStorageName = $sourceOSDisk.MediaLink.Host -split "\." | select -First 1
$sourceStorageAccount = Get-AzureStorageAccount –StorageAccountName $sourceStorageName
$sourceStorageKey = (Get-AzureStorageKey -StorageAccountName $sourceStorageName).Primary

Stop-AzureVM –ServiceName $serviceName –Name $vmName -Force

Select-AzureSubscription -SubscriptionName $NewSubscriptionName

$location = $sourceStorageAccount.Location

$destStorageAccount = Get-AzureStorageAccount | ? {$_.Location -eq $location} | select -first 1
if ($destStorageAccount -eq $null)
{	
	$destStorageName = "p1m1prodstorage01"
New-AzureStorageAccount -StorageAccountName $destStorageName -Location $location
$ destStorageAccount = Get-AzureStorageAccount -StorageAccountName $destStorageName
}
$destStorageName = $destStorageAccount.StorageAccountName
$destStorageKey = (Get-AzureStorageKey -StorageAccountName $destStorageName).Primary

$sourceContext = New-AzureStorageContext  –StorageAccountName $sourceStorageName `
	-StorageAccountKey $sourceStorageKey 
$destContext = New-AzureStorageContext  –StorageAccountName $destStorageName `
	-StorageAccountKey $destStorageKey 

if ((Get-AzureStorageContainer -Context $destContext -Name vhds -ErrorAction SilentlyContinue) -eq $null)
{
    New-AzureStorageContainer -Context $destContext -Name vhds
}

$allDisks = @($sourceOSDisk) + $sourceDataDisks
$destDataDisks = @()
foreach($disk in $allDisks)
{	
	$blobName = $disk.MediaLink.Segments[2]
	$targetBlob = Start-CopyAzureStorageBlob -SrcContainer vhds -SrcBlob $blobName `
	                                        -DestContainer vhds -DestBlob $blobName `
	                                        -Context $sourceContext -DestContext $destContext -Force
	Write-Host "Copying blob $blobName"
	$copyState = $targetBlob | Get-AzureStorageBlobCopyState
	while ($copyState.Status -ne "Success")
	{        	
		$percent = ($copyState.BytesCopied / $copyState.TotalBytes) * 100		
		Write-Host "Completed $('{0:N2}' -f $percent)%"
		sleep -Seconds 5
		$copyState = $targetBlob | Get-AzureStorageBlobCopyState
	}
	If ($disk –eq $sourceOSDisk)
	{
		$destOSDisk = $targetBlob
	}
	Else
	{
		$destDataDisks += $targetBlob
	}
}

Add-AzureDisk -OS $sourceOSDisk.OS -DiskName $sourceOSDisk.DiskName -MediaLocation $destOSDisk.ICloudBlob.Uri
foreach($currenDataDisk in $destDataDisks)
{
    $diskName = ($sourceDataDisks | ? {$_.MediaLink.Segments[2] -eq $currenDataDisk.Name}).DiskName    
    Add-AzureDisk -DiskName $diskName -MediaLocation $currenDataDisk.ICloudBlob.Uri
}

Get-AzureSubscription -Current | Set-AzureSubscription -CurrentStorageAccountName $destStorageName

$vmConfig = Import-AzureVM -Path $vmConfigurationPath
New-AzureVM -ServiceName $destServiceName -Location $location -VMs $vmConfig -WaitForBoot

Get-AzureRemoteDesktopFile -ServiceName $destServiceName -Name $vmConfig.RoleName -LocalPath ($workingDir+"\newVM-"+$vmName+".rdp")