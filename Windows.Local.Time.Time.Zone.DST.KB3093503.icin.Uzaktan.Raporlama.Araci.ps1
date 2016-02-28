Add-AzureAccount

Get-AzureSubscription | Out-GridView -PassThru | Select-AzureSubscription

$selectedVM = Get-AzureVM | Get-AzureVM | Select-Object Name, ServiceName, IpAddress, DNSName, InstanceSize, PowerState | out-gridview -PassThru

$vm = Get-AzureVM -name $selectedVM.Name -ServiceName $selectedVM.ServiceName










#
#
# Windows Local Time, Time Zone, DST, KB3093503 icin Uzaktan Raporlama Araci
#
# Hazırlayan : Serhat AKINCI
# Geri Bildirim : serhatakinci@gmail.com
# Blog : http://serhatakinci.com
# TW : @serhatakinci
# Oluşturma Tarihi : 24.10.2015
# Sürüm : v01
# Kullanım Klavuzu : http://www.serhatakinci.com/index.php/get-dstinfo-windows-yaz-saati-uygulamasi-icin-kontrol-araci.html
#
#

#[array]$computerList = Get-Content .\bilgisayar-listesi.txt
[array]$computerList = {'p1m1dat.cloudapp.net','p1m1datora.cloudapp.net'}
$outputArray1 = @()
$startDTM = Get-Date
$itemCount = 1
$sCount = $fCount = 0

function Get-DST
{
    param([parameter(Mandatory=$true)][string]$Computer)

    $currentYear = (Get-Date).Year
    $winLocalTime = Get-WmiObject -ComputerName $Computer -Class Win32_LocalTime
    $winTimeZone = Get-WmiObject -Class Win32_TimeZone -ComputerName $Computer

    Switch ($winTimeZone.StandardMonth)
    {
        1 {$stdMonth = "January"}
        2 {$stdMonth = "February"}
        3 {$stdMonth = "March"}
        4 {$stdMonth = "April"}
        5 {$stdMonth = "May"}
        6 {$stdMonth = "June"}
        7 {$stdMonth = "July"}
        8 {$stdMonth = "August"}
        9 {$stdMonth = "September"}
        10 {$stdMonth = "October"}
        11 {$stdMonth = "November"}
        12 {$stdMonth = "December"}
    }

    [DateTime]$stdDate = "$stdMonth 01, $currentYear $($winTimeZone.StandardHour)`:00:00"

    $i = 0
    while ($i -lt $winTimeZone.StandardDay)
    {
        if($stdDate.DayOfWeek -eq $winTimeZone.StandardDayOfWeek)
        {
            $i++
            if($i -eq $winTimeZone.StandardDay)
            {
                $changeDate = $stdDate
            }
            else
            {
                $stdDate = $stdDate.AddDays(1)
            }
        }
        else
        {
            $stdDate = $stdDate.AddDays(1)
        }
    }

    if($changeDate.Month -ne $winTimeZone.StandardMonth)
    {
        $changeDate = $changeDate.AddDays(-7)
    }

    if($winTimeZone.Caption -eq $null)
    {
        $outTimeZone = $winTimeZone.StandardName
    }
    else
    {
        $outTimeZone = ($winTimeZone.Caption).Replace(","," -")
    }

    if($changeDate -eq $null){$changeDate = "Alinamadi"}
    else{$changeDate = $changeDate.DateTime}
    if($outTimeZone -eq $null){$outTimeZone = "Alinamadi"}
    if($winLocalTime -eq $null){$outLocalTime = "Alinamadi"}
    else{$outLocalTime = (Get-Date -Day $winLocalTime.Day -Month $winLocalTime.Month -Year $winLocalTime.Year -Hour $winLocalTime.Hour -Minute $winLocalTime.Minute -Second $winLocalTime.Second).DateTime}

    Return $outLocalTime, $outTimeZone, $changeDate
}

Write-Host ""
Write-Host "###############################################################################" -ForegroundColor Yellow
Write-Host ""
Write-Host "Windows Local Time, Time Zone, DST, KB3093503 icin Uzaktan Raporlama Araci v01" -ForegroundColor Yellow
Write-Host ""
Write-Host "Desteklenen isletim sistemleri:
Windows XP, Vista, 7, 8, 8.1, 10 (32bit/64bit)
Windows Server 2003, 2003 R2, 2008, 2008 R2, 2012, 2012 R2 (32bit/64bit)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Hazirlayan: Serhat AKINCI | Geri bildirim: serhatakinci@gmail.com" -ForegroundColor Yellow
Write-Host ""
Write-Host "###############################################################################" -ForegroundColor Yellow
Write-Host ""
Write-Host "$($computerList.count) bilgisayar icin Local Time, Time Zone, DST ve KB3093503 bilgileri aliniyor…" -ForegroundColor Cyan

foreach($Computer in $computerList)
{
if($osInfo = gwmi -ComputerName $Computer -Class Win32_OperatingSystem -EA SilentlyContinue -ErrorVariable $gwmiERR)
{
# Basarili
$Time = Get-DST -Computer $Computer

$HotFix = Get-HotFix -ComputerName $Computer -EA SilentlyContinue | ?{$_.HotFixID -eq "KB3093503"}

if($HotFix)
{
$outHotFix = "Yuklu"
}
elseif($HotFix -eq $null)
{
$outHotFix = "Yuklu Degil"
}
else
{
$outHotFix = "Bilinmiyor"
}

$charger1 = @{
'Bilgisayar' = $Computer
'Isletim Sistemi' = $osInfo.Caption
'Local Time' = $Time[0]
'Time Zone' = $Time[1]
'DST' = $Time[2]
'KB3093503' = $outHotFix
'Aciklama' = "Getrime islemi basarili."
}

$customObj1 = New-Object PSObject -Property $charger1
$outputArray1 += $customObj1
$sCount++
$itemCount++
$customObj1 | select 'Bilgisayar','Isletim Sistemi','Local Time','Time Zone','DST','KB3093503′

}
else
{
$charger1 = @{
'Bilgisayar' = $Computer
'Isletim Sistemi' = "Alinamadi"
'Local Time' = "Alinamadi"
'Time Zone' = "Alinamadi"
'DST' = "Alinamadi"
'KB3093503' = "Alinamadi"
'Aciklama' = "Getrime islemi basarisiz: $($Error[0].Exception.Message)"
}

$customObj1 = New-Object PSObject -Property $charger1
$outputArray1 += $customObj1
$fCount++
$itemCount++
$customObj1 | select 'Bilgisayar','Isletim Sistemi','Local Time','Time Zone','DST','KB3093503′
}
}

$outputArray1 | select 'Bilgisayar','Isletim Sistemi','Local Time','Time Zone','DST','KB3093503','Aciklama' | Export-Csv operasyon-raporu.csv -NoTypeInformation -Delimiter ";" -Encoding UTF8
$elapsedTime = (Get-Date) – $startDTM

Write-Host ""
Write-Host "Istatistik:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Toplam Bilgisayar : $($computerList.count)" -ForegroundColor Yellow
Write-Host "Erisilen : $($sCount)" -ForegroundColor Yellow
Write-Host "Erisilemeyen : $($fCount)" -ForegroundColor Yellow
Write-Host "Operasyon Raporu : $(Get-Location)\operasyon-kaydi.csv" -ForegroundColor Yellow
Write-Host "Script Calisma Suresi : $($elapsedTime.Hours)h $($elapsedTime.Minutes)m $($elapsedTime.Seconds)s" -ForegroundColor Yellow
Write-Host ""
