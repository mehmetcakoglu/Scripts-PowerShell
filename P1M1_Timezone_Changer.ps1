
# Run Powershell Script from Windows TASK SCHEDULER
# https://community.spiceworks.com/how_to/17736-run-powershell-scripts-from-task-scheduler

function Get-TimeZone { 
 
    tzutil /g
}

function Set-TimeZone { 
 
    param( 
        [parameter(Mandatory=$true)] 
        [string]$TimeZone 
    ) 
     
    $osVersion = (Get-Item "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").GetValue("CurrentVersion") 
    $proc = New-Object System.Diagnostics.Process 
    $proc.StartInfo.WindowStyle = "Hidden" 
    
    if ($osVersion -gt 6.0) 
    { 
        # OS is newer than XP 
        $proc.StartInfo.FileName = "tzutil.exe" 
        $proc.StartInfo.Arguments = "/s `"$TimeZone`"" 
    } 
    else 
    { 
        # XP or earlier 
        $proc.StartInfo.FileName = $env:comspec 
        $proc.StartInfo.Arguments = "/c start /min control.exe TIMEDATE.CPL,,/z $TimeZone" 
    } 
 
    $proc.Start() | Out-Null 
   
 
}


write-output "Current Timezone: " 
Get-TimeZone

Set-TimeZone "Turkey Standard Time"

sleep 1
Write-Output "Timezone changed."
    
sleep 1
write-output "Current Timezone : " 
Get-TimeZone













<#

# OLD EXAMPLES 

function Get-TimeZone($Name)
{
 [system.timezoneinfo]::GetSystemTimeZones() | `
 Where-Object { $_.ID -like "*$Name*" -or $_.DisplayName -like "*$Name*" } 
 #Select-Object -ExpandProperty ID
} 


function Set-TimeZone($Name)
{
 $tz = [system.timezoneinfo]::GetSystemTimeZones() | `
 Where-Object { $_.ID -like "*$Name*" -or $_.DisplayName -like "*$Name*" } | `
 Select-Object -ExpandProperty ID
} 

#write-output ([System.TimeZoneInfo]::Local).DisplayName

<#
Get-TimeZone("istanbul")
Get-TimeZone("Turkey")
Get-TimeZone("bağdat")
Get-TimeZone("Arabic")
#>

#[system.timezoneinfo]::GetSystemTimeZones()

#>
