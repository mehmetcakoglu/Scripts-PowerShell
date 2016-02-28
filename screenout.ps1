# http://powershell.org/wp/forums/topic/save-the-output-of-powershell-script/
if ($Host.Name -ne "Windows PowerShell ISE Host")
{
    $TranscriptFile = $ROOT + "LOGS\" + $MyInvocation.MyCommand.Name.Replace(".ps1", "") + "_$now.log"
    Start-Transcript -Path $TranscriptFile
}
else
{
    Write-Host "Powershell ISE Host ortamında çalıştığından LOG oluşturulamıyor"
}



    write-host "get-psdrive öncesi"
    Get-PSDrive 
    write-host "get-psdrive sonrası"


write-host "sonraki yazi"

if($test)
{echo "dolu"
write-host $test}
else
{echo "bos"}


echo $MyInvocation.MyCommand.Name


 if ($Host.Name -ne "Windows PowerShell ISE Host")
{
Stop-Transcript
}


