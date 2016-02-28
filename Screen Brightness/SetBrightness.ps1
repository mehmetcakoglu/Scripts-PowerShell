Param(
  [int]$percent
)

if(($percent -eq $null) -or ($percent -eq 0))
{
    $percent = 100
}

Write-Host "`n[INFO]`tMonitor Brightness is setting to $percent percent"

$monitor = (Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightnessMethods)
$monitor.WmiSetBrightness(1,$percent)
