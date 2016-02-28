# 

#Get-AzureVM "myservice" -Name "MyVM" `| Add-AzureDataDisk -CreateNew -DiskSizeInGB 128 -DiskLabel "main" -LUN 0 `| Update-AzureVM

# Bu çalıştırma test için mi yapılacak? evet ise $TRUE, değilse $FALSE
$isTestRun = $FALSE;
# hangi azure subscription üzerinde çalışacak? 
$subscriptionName = "P1M1 Datawarehouse (Enterprise Agreement)";
# cloud service adı
$serviceName = "p1m1azuremssql";
# VM adı
$serverName = "AzureMsSQL01";
# storage adresi
$storagePath = "https://p1m1dbstorage01.blob.core.windows.net/vhds"
# oluşturulacak her bir diskin boyutu
$diskSizeInGb = 1023;
# daha önceden oluşturulmuş additional disk varsa sıradaki index numarasını verin, yoksa 1 verin (bu index 1 den başlar)
$diskStartIndex = 1;
# diskin VM e bağlanacağı LUN indexini verin, daha önce bağlanmış disk yoksa 0 verin (bu index 0 dan başlar)
$lunStartIndex = 0;
# Oluşturulacak disk sayısını girin
$diskCount = 16;

if($isTestRun)
{
	write-host Add-AzureAccount;
	write-host Select-AzureSubscription $subscriptionName;
}
else
{
	# önce login ol
	Add-AzureAccount;
	# subscription seç
	Select-AzureSubscription $subscriptionName;
}

for( $i = $diskStartIndex; $i -le $diskCount; $i++)
{
	$diskNum = "000000000000000000$i";
	$lunNum = $i + $lunStartIndex;
	$diskNum = $diskNum.substring($diskNum.ToString().length - $diskCount.ToString().length, $diskCount.ToString().length);

	
	write-host "";
	write-host "$serverName-datadisk$diskNum diski oluşturulacak...";
	write-host "";
	
	if($isTestRun)
	{
		# for test
		write-host Get-AzureVM -ServiceName $serviceName -Name $serverName "|" Add-AzureDataDisk -CreateNew -DiskSizeInGB $diskSizeInGb -DiskLabel "$serverName-datadisk$diskNum" -LUN $lunNum -MediaLocation "$storagePath/$serverName-datadisk$diskNum.vhd" "|" Update-AzureVM
	}
	else
	{
		Get-AzureVM -ServiceName $serviceName -Name $serverName | Add-AzureDataDisk -CreateNew -DiskSizeInGB $diskSizeInGb -DiskLabel "$serverName-datadisk$diskNum" -LUN $lunNum -MediaLocation "$storagePath/$serverName-datadisk$diskNum.vhd" | Update-AzureVM
	}
	
	write-host "";
	write-host "$serverName-datadisk$diskNum diski oluşturuldu";
	write-host "____________________________________________________________";
	
}
write-host "";
write-host "";
write-host "============================================================";
write-host " 				     İŞLEM TAMAMLANDI                       ";
write-host "============================================================";
write-host "";
write-host "";


