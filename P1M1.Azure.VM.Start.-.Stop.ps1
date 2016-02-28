[CmdletBinding()]
Param(
   
    [Parameter(Mandatory=$False)]
    [switch]$start
    ,

    [Parameter(Mandatory=$False)]
    [switch]$stop
    ,

    [Parameter(Mandatory=$True)]
    [string]$azureUserName = "evren.atasayar@p1m1.com"
    ,
    [Parameter(Mandatory=$True)]
    [string]$azureUserPassword = "1217g1217"
    ,
	
    [Parameter(Mandatory=$True)]
    [string]$publishSettingsFileFullPath = "P1M1-10-6-2015-credentials.publishsettings"
    ,
    
    [Parameter(Mandatory=$False)]
    [string]$subscriptionName 
    ,
        
    [Parameter(Mandatory=$True)]
    [string]$vmNamePattern = "p1m1cpr*"
    ,
    [Parameter(Mandatory=$False)]
    [switch]$debugScript
)

if($start -and $stop)
{
    Write-Host "[ERROR] -Start veya -Stop parametrelerinden sadece birini belirtmelisiniz" -ForegroundColor red
    Exit
}

if(-not($start) -and -not($stop))
{
    Write-Host "[ERROR] -Start veya -Stop parametrelerinden en az birini belirtmelisiniz" -ForegroundColor Red
    Exit
}







$mailTo = "mehmet.cakoglu@p1m1.com"
$mailFrom = "mehmet.cakoglu@p1m1.com"
$smtpServer = "outlook.office365.com"
$smtpPort = 587

$emailUsername = "mehmet.cakoglu@p1m1.com"
$emailPassword = ConvertTo-SecureString "spider" -AsPlainText -Force
$emailCred = new-object -typename System.Management.Automation.PSCredential($emailUsername, $emailPassword)

if(-not($debug))
{
    $debug = $false
}


$Error.Clear()
$isTerminated = $False



$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$TranscriptFile = ""
$isLogEnabled = ($Host.Name -ne "Windows PowerShell ISE Host")
$now=Get-Date -format "yyyyMMdd_HHmmss"

if ($isLogEnabled)
{
    $logDir = $scriptPath + "\LOGS"
    If (!(Test-Path $logDir)) {
       New-Item -Path $logDir -ItemType Directory
    }

    $TranscriptFile = $logDir + "\" + $MyInvocation.MyCommand.Name.Replace(".ps1", "") + "_$now.log"
    Start-Transcript -Append -Path $TranscriptFile 
}
else
{
    Write-Host "`n[WARNING]`t- Powershell ISE Host ortamında çalıştığından LOG oluşturulamıyor" -ForegroundColor DarkYellow 
}















function CleanOldLogFiles() {
    
    # Clean Old Log Files Older Than 7 Days
    if($(Get-ExecutionPolicy) -ne "RemoteSigned")
    {
        Set-ExecutionPolicy RemoteSigned
    }

    if($(Get-ExecutionPolicy) -eq "RemoteSigned")
    {
        $Now = Get-Date
        $Days = "7"
        $TargetFolder = $scriptPath + "\LOGS"
        $Extension = "*.log"
        $LastWrite = $Now.AddDays(-$Days)
 
        #----- get files based on lastwrite filter and specified folder ---#
        $Files = Get-Childitem $TargetFolder -Include $Extension -Recurse | Where {$_.LastWriteTime -le "$LastWrite"}
 
        foreach ($File in $Files)
        {
            if ($File -ne $NULL)
            {
                Write-Output "Deleting File $File" 
                Remove-Item $File.FullName | out-null
            }
            else
            {
                Write-Output "No more files to delete!"
            }
        }
    }
}


Function Write-Host ($message,$nonewline,$backgroundcolor,$foregroundcolor) {
    $Message | Out-Host
}


function SendMail ($mailSubject, $mailBodyText) {
    Write-Progress -Activity "Working..." -Status "Please wait."
    
    Send-MailMessage `
        -To $mailto `
        -From $mailFrom `        -SmtpServer $smtpServer -Port $smtpPort -UseSsl -Credential $emailCred `        -Subject $mailSubject `
        -Body $mailBodyText `        -BodyAsHtml `        -Encoding ([System.Text.Encoding]::UTF8)

}

function StartVm ( [string] $ComputerName, [string] $ServiceName ) {
    $params = @($computerName, $ServiceName)
    
    Start-Job -ArgumentList $params {
        param($ComputerName, $ServiceName)

        Start-AzureVM -Name $ComputerName -ServiceName $ServiceName -Verbose
    }
}

function StopVm ( [string] $ComputerName, [string] $ServiceName ) {
    $params = @($computerName, $ServiceName)

    Start-Job -ArgumentList $params {
        param($ComputerName, $ServiceName)

        Stop-AzureVM -Name $ComputerName -ServiceName $ServiceName -Force -Verbose
    }
}

function Get-ScriptDirectory {
    Split-Path -parent $PSCommandPath
}

function Import-PowershellModules {
    #import the Azure PowerShell module
    Write-Host "`n[WORKITEM] - Importing Azure PowerShell module" -ForegroundColor Yellow

    If ($ENV:Processor_Architecture -eq "x86")
    {
        $ModulePath = "$Env:ProgramFiles\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Azure.psd1"
    }
    Else
    {
        $ModulePath = "${env:ProgramFiles(x86)}\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Azure.psd1"
    }

    Try
    {
        If (-not(Get-Module -name "Azure")) 
        { 
            If (Test-Path $ModulePath) 
            { 
                Import-Module -Name $ModulePath
            }
            Else
            {
                Write-Host "`n                                                                         " -ForegroundColor white -BackgroundColor Red
                Write-Host "`n   [ERROR] - Azure PowerShell module not found. Script terminating...    " -ForegroundColor white -BackgroundColor Red 
                Write-Host "`n                                                                         " -ForegroundColor white -BackgroundColor Red
                #Exit
                $isTerminated = $True

                #show module not found interaction and bail out
                #Write-Host "[ERROR] - Azure PowerShell module not found. Exiting." -ForegroundColor Red
                #Exit
            }
        }

        Write-Host "`tSuccess"
    }
    Catch [Exception]
    {
        Write-Host "`n                                                                         " -ForegroundColor white -BackgroundColor Red
        Write-Host "`n   [ERROR] - Azure PowerShell module not found. Script terminating...    " -ForegroundColor white -BackgroundColor Red 
        Write-Host "`n                                                                         " -ForegroundColor white -BackgroundColor Red
        #Exit
        $isTerminated = $True
        
        #show module not found interaction and bail out
        #Write-Host "[ERROR] - PowerShell module not found. Exiting." -ForegroundColor Red
        #Exit
    }

    #Check the Azure PowerShell module version
    Write-Host "`n[WORKITEM] - Checking Azure PowerShell module verion" -ForegroundColor Yellow
    $APSMajor =(Get-Module azure).version.Major
    $APSMinor =(Get-Module azure).version.Minor
    $APSBuild =(Get-Module azure).version.Build
    $APSVersion =("$PSMajor.$PSMinor.$PSBuild")

    If ($APSVersion -ge 0.8.14)
    {
        Write-Host "`tSuccess"
    }
    Else
    {
        Write-Host "`n                                                                                           " -ForegroundColor white -BackgroundColor Red
        Write-Host "`n [ERROR] - Azure PowerShell module must be version 0.8.14 or higher. Script terminating... " -ForegroundColor white -BackgroundColor Red 
        Write-Host "`n                                                                                           " -ForegroundColor white -BackgroundColor Red
        #Exit
        $isTerminated = $True
       
       #Write-Host "[ERROR] - Azure PowerShell module must be version 0.8.14 or higher. Exiting." -ForegroundColor Red
       #Exit
    }
}




#$emailbody = $(



Import-PowershellModules















if(-not($isTerminated))
{
#$emailbody = % {
    Write-Host "`n[INFO] $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`t - Clear all accounts before authentication."  -ForegroundColor Yellow #Remove all accounts

    Get-AzureAccount | %{Remove-AzureAccount -Name $_.Id -Force -WarningAction SilentlyContinue  } 
    Clear-AzureProfile -Force -WarningAction SilentlyContinue

    Write-Host "`t $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Done." -ForegroundColor Gray
#} |Out-String
}






if(-not($isTerminated))
{

    Write-Host "`n[INFO] $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`t - Authenticating Azure account by Publish Settings File."  -ForegroundColor Yellow 

    if($publishSettingsFileFullPath.Contains('\') -eq $False)
    {
        Import-AzurePublishSettingsFile -PublishSettingsFile "$(Get-ScriptDirectory)\$publishSettingsFileFullPath" | Out-Null
    }
    else
    {
        Import-AzurePublishSettingsFile -PublishSettingsFile $publishSettingsFileFullPath | out-null
    }

    Write-Host "`t $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Done." -ForegroundColor Gray

}






if(-not($isTerminated))
{

    Write-Host "`n[INFO] $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`t - Authentication with user credentials."  -ForegroundColor Yellow 

    $user = $azureUserName
    $PWord = ConvertTo-SecureString –String $azureUserPassword –AsPlainText -Force

    $cred =  New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $User, $PWord 
    $credential = Get-Credential -Credential $cred

    Write-Host "`t $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Done." -ForegroundColor Gray

}







if(-not($isTerminated))
{

    #####
    #Azure subscription selection
    #####
    if($subscriptionName.Trim() -eq "")
    {
        Write-Host "`n[INFO] - Obtaining subscriptions" -ForegroundColor Yellow
        [array] $AllSubs = Get-AzureSubscription 

        If ($AllSubs)
        {
		        Write-Host "`tSuccess"
        }
        Else
        {
            Write-Host "`n                                                    " -ForegroundColor white -BackgroundColor Red
            Write-Host "`n   No subscriptions found. Script terminating...    " -ForegroundColor white -BackgroundColor Red 
            Write-Host "`n                                                    " -ForegroundColor white -BackgroundColor Red
            #Exit
            $isTerminated = $True
		    
                #Write-Host "`tNo subscriptions found. Exiting." -ForegroundColor Red
		        #Exit
        }

        $SelectedSubscription = $AllSubs | Out-GridView -PassThru -Title "Select the Azure subscription"

        If ($SelectedSubscription)
        {
	        Write-Host "`t Selection: $($SelectedSubscription.SubscriptionName)"
            $subscriptionName = $SelectedSubscription.SubscriptionName		
		        #$SelSub = $SelSubName.SubscriptionId
		        #Select-AzureSubscription -SubscriptionId $SelSub | Out-Null
        }
        Else
        {
            Write-Host "`n                                                                           " -ForegroundColor white -BackgroundColor Red
            Write-Host "`n   n[ERROR] - No Azure subscription was selected. Script terminating...    " -ForegroundColor white -BackgroundColor Red 
            Write-Host "`n                                                                           " -ForegroundColor white -BackgroundColor Red
            #Exit
            $isTerminated = $True

		        #Write-Host "`n[ERROR] - No Azure subscription was selected. Exiting." -ForegroundColor Red
		        #Exit
        }
    }


    Write-Host "`n[INFO] $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`t - Selecting the Azure subscription to '$subscriptionName'" -ForegroundColor Yellow
    #$SelSubName = $AllSubs | Out-GridView -PassThru -Title "Select the Azure subscription"
    $SelSubName = Get-AzureSubscription -SubscriptionName $subscriptionName

    If ($SelSubName)
    {    			
	    $SelSub = $SelSubName.SubscriptionId
	    Select-AzureSubscription -SubscriptionId $SelSub | Out-Null
        Write-Host "`t $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Done." -ForegroundColor Gray
    }
    Else
    {
        Write-Host "`n                                                                          " -ForegroundColor white -BackgroundColor Red
        Write-Host "`n   [ERROR] - No Azure subscription was selected. Script terminating...    " -ForegroundColor white -BackgroundColor Red 
        Write-Host "`n                                                                          " -ForegroundColor white -BackgroundColor Red
        #Exit
        $isTerminated = $True

	    #Write-Host "`n[ERROR] - No Azure subscription was selected. Exiting." -ForegroundColor Red
	    #Exit
    }



}









if(-not($isTerminated))
{

    if($debugScript)
    {
        Write-Host "`n[DEBUG] - Getting ALL VMs with status."   -ForegroundColor Gray 

        Write-Progress -Activity "Working..." -Status "Please wait." 
        $vms = Get-azurevm 

        foreach ($vm in $vms)
        {
            $msg = "`t - Name: " + $vm.Name + " `t ServiceName : " + $vm.ServiceName + " `tStatus : " + $vm.Status 
            write-host $msg -ForegroundColor Gray
        }

        Write-Host "`t $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Done." -ForegroundColor Gray
    }

}











if(-not($isTerminated))
{


    if($start)
    {
        Write-Host "`n[INFO] $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`t- Getting VMs for START"  -ForegroundColor Yellow 
        if($debugScript)
        {
            write-host "`n[DEBUG] Getting VM List for status START by like 'StoppedDeallocated' or '*Unknown*' and name pattern is '$vmNamePattern'"    -ForegroundColor Gray 
        }
    
        Write-Progress -Activity "Working..." -Status "Please wait."
    
        $vms = Get-azurevm | ?{ ($_.Status -eq "StoppedDeallocated" -or $_.Status -Like "*Unknown*" ) -and $_.Name -like $vmNamePattern} 
    
    }

    if($stop)
    {
        Write-Host "`n[INFO] $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`t- Getting VMs for STOP"  -ForegroundColor Yellow 
        if($debugScript)
        {
            write-host "`n[DEBUG] Getting VM List for STOP by status like 'Ready*' or '*Unknown*' and name pattern is '$vmNamePattern'"    -ForegroundColor Gray 
        }
    
        Write-Progress -Activity "Working..." -Status "Please wait."

        $vms = Get-azurevm | ?{ ($_.Status -Like "Ready*" -or $_.Status -Like "*Unknown*" ) -and $_.Name -like $vmNamePattern} 
    }


    if($vms.Count -eq 0)
    {
        Write-Host "`n                                                                         " -ForegroundColor white -BackgroundColor Red
        Write-Host "`n  [WARNING]   There is no VMs found to process. Script terminating...    " -ForegroundColor white -BackgroundColor Red 
        Write-Host "`n                                                                         " -ForegroundColor white -BackgroundColor Red
        #Exit
        $isTerminated = $True
    }


    if(-not($isTerminated))
    {
        foreach ($vm in $vms)
        {
            $msg = "`t - Name: " + $vm.Name + " `t ServiceName : " + $vm.ServiceName  + " `t Status : " + $vm.Status
            write-host $msg  -ForegroundColor Magenta
        }
        Write-Host "`t $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Done." -ForegroundColor Gray
    }


}












if(-not($isTerminated))
{

    foreach ($vm in $vms)
    {
        if($start)
        {
        
            StartVm -ComputerName $vm.Name -ServiceName $vm.ServiceName
            if($debugScript)
            {
                $msg = "[DEBUG] JOB ADDED for START Name: " + $vm.Name + " `t ServiceName : " + $vm.ServiceName + " `t Status : " + $vm.Status
                write-host $msg -ForegroundColor Gray
            }
        }
            
        if($stop)
        {
            StopVm -ComputerName $vm.Name -ServiceName $vm.ServiceName
            if($debugScript)
            {
                $msg = "[DEBUG] JOB ADDED for STOP Name: " + $vm.Name + " `t ServiceName : " + $vm.ServiceName + " `t Status : " + $vm.Status 
                write-host $msg -ForegroundColor Gray
            }
        }  
    }

    write-host "`n[INFO] $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`t - Wait for all jobs to complete..." -ForegroundColor Yellow

    Write-Progress -Activity "Working..." -Status "Please wait."
    Get-Job | Wait-Job 

    Write-Host "`t $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Done." -ForegroundColor Gray
 

    write-host "`n[INFO] $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`t - Display output from all jobs" -ForegroundColor Yellow

    Write-Progress -Activity "Working..." -Status "Please wait."
    Get-Job | Receive-Job

    Write-Host "`t $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Done." -ForegroundColor Gray

 
    write-host "`n[INFO] $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`t - Cleanup" -ForegroundColor Yellow

    Remove-Job *

    Write-Host "`t $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Done." -ForegroundColor Gray

}
 
# Displays batch completed
write-host "`n[RESULT] - Batch Completed" -ForegroundColor Yellow



if ($isLogEnabled)
{
    Stop-Transcript
}




#} | out-string | Out-file 'C:\temp\output.txt' 
#write-host "emailbody: " $emailbody
#exit


$parameterValues = "
    <li><pre><b>Script Name</b>                 : $($MyInvocation.MyCommand.Name) </pre></li>
    <li><pre><b>Start</b>                       : $($start.ToString()) </pre></li>
    <li><pre><b>Stop</b>                        : $($stop.ToString()) </pre></li>
    <li><pre><b>Debug</b>                       : $($debug.ToString()) </pre></li>
    <li><pre><b>AzureUserName</b>               : $($azureUserName.ToString()) </pre></li>
    <li><pre><b>AzureUserPassword</b>           : $($azureUserPassword.ToString()) </pre></li>
    <li><pre><b>vmNamePattern</b>               : $($vmNamePattern.ToString()) </pre></li>
    <li><pre><b>SubscriptionName</b>            : $($subscriptionName.ToString()) </pre></li>
    <li><pre><b>publishSettingsFileFullPath</b> : $($publishSettingsFileFullPath.ToString()) </pre></li>
    <li><pre><b>smtpServer</b>                  : $($smtpServer.ToString()) </pre></li>
    <li><pre><b>smtpPort</b>                    : $($smtpPort.ToString()) </pre></li>
    <li><pre><b>mailFrom</b>                    : $($mailFrom.ToString()) </pre></li>
    <li><pre><b>mailTo</b>                      : $($mailTo.ToString()) </pre></li>
    <li><pre><b>emailUsername</b>               : $($emailUsername.ToString()) </pre></li>
    <li><pre><b>emailPassword</b>               : $($emailPassword.ToString()) </pre></li>
    "

if($TranscriptFile)
{
    $emailbody = Get-Content -Path $TranscriptFile | Out-String
}

if($Error.Count -gt 0)
{
    
    $errorMessages = ""
    $errorMessages = $error | foreach { 
    '<li><h4>' + $_.ToString() + '</h4>
        <ul>
            <li><pre><b>Error Details</b>       : '+ $error[0].ErrorDetails +'</pre></li>
            <li><pre><b>Script Stack Trace:</b> : '+ $error[0].ScriptStackTrace +'</pre></li>
            <li><pre><b>Exception:</b>          : '+ $error[0].Exception +'</pre></li>
        </ul>
    </li>
    ' 
    }
    
    

    SendMail -mailSubject 'ERROR on Scheduled Powershell Job' `        -mailBodyText "
        <style>
            body,p,div {font-family: arial, helvetica; font-size:.8em;}
            .err {font-family: 'courier new'; font-size:.65em; color:gray;}
        </style>
        <h3>Hata Oluştu!</h3>
        <p>
            Azure üzerindeki sunucuların belirlenen saatlerde kapatılıp açılmasını sağlayan powershell scriptinde hata oluştu.
        </p>
        <p>
            Script Parametreleri
        </p>
        <p>
            <ol type=1 class='err'>
                $parameterValues            </ol>        </p>
        
        <p>
            Lütfen aşağıdaki hatalara göz atınız:
        </p>
        <p>
            <ol type=1 class='err'>
                $errorMessages            </ol>        </p>        <p>            SCREEN OUTPUT        </p>
        <p class=err>
        <pre>$emailbody</pre>
        </p>" 
        #-Attachments $TranscriptFile
     
     write-host "`n[PS] - ERROR Mail Sended to $mailTo" -ForegroundColor DarkRed   
}
else
{

    SendMail -mailSubject 'SUCCESS Scheduled Powershell Job' `        -mailBodyText "
        <style>
            body,p,div {font-family: arial, helvetica; font-size:.8em;}
            .err {font-family: 'courier new'; font-size:.65em; color:gray;}
        </style>
        <h3>İşlem Tamamlandı</h3>
        <p>
            Azure üzerindeki sunucuların belirlenen saatlerde kapatılıp açılmasını sağlayan powershell scriptinde başarıyla çalıştı.
        </p>
        <p>
            Script Parametreleri
        </p>
        <p>
            <ol type=1>
                $parameterValues            </ol>        </p>        <p>            SCREEN OUTPUT        </p>
        <p class=err>
        <pre>$emailbody</pre>
        </p>        " 
        #-Attachments $TranscriptFile
     
     write-host "`n[PS] - INFO Mail Sended to $mailTo" -ForegroundColor DarkYellow   
}


write-host "`n[PS#2]`t - Cleaning old log files..."
CleanOldLogFiles
Write-Host "`t $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Done." -ForegroundColor Gray


<#

#$jobs = @()
foreach ($vm in $vms)
{
    # $params = @($vm.Name, $vm.ServiceName)
    
    # $job = Start-Job -ScriptBlock {
    #     param($ComputerName, $ServiceName)
    $error.Clear();
    $retryCount=0;
            
    try
    {    
        if($start)
        {
            write-host "[DEBUG] STARTING VM Name: " $vm.Name " `t`tServiceName : " $vm.ServiceName   " `t`tStatus : " $vm.Status -ForegroundColor Gray
            Start-AzureVM -Name $vm.Name -ServiceName $vm.ServiceName
            Write-Host "`t`t$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Done." -ForegroundColor Gray
        }
            
        if($stop)
        {
            write-host "[DEBUG] STOPPING VM Name: " $vm.Name " `t`tServiceName : " $vm.ServiceName   " `t`tStatus : " $vm.Status  -ForegroundColor Gray 
            Stop-AzureVM -Name $vm.Name -ServiceName $vm.ServiceName -Force
            Write-Host "`t`t$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Done." -ForegroundColor Gray 
        }    
    }
    catch
    {
                
        while($error[0].Exception.Message.Contains("ConflictError") -and $retryCount -le $maxRetryCount)
        {
            Write-Host "`t`t- Sleeping $sleepSeconds seconds."
            Start-Sleep -Seconds $sleepSeconds

            Write-Host "`t`t- Retry #$retryCount"    
            
            if($start)
            {
                Start-AzureVM -Name $vm.Name -ServiceName $vm.ServiceName
            }

            if($stop)
            {
                Stop-AzureVM -Name $vm.Name -ServiceName $vm.ServiceName -Force
            }
                    
            $retryCount = $retryCount + 1;    
                    
        } 
    }
        
       
        
    
    # } -ArgumentList $params 
    # $jobs = $jobs + $job
}

Write-Host "`t`t$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Done." -ForegroundColor Gray






 

# Wait for it all to complete
# if($jobs)
# {
    # Wait-Job -Job $jobs


    # write-host "`n[INFO] $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`tGetting information back from the jobs..." 
    # Get-Job | Receive-Job

    
    write-host "`n[INFO] $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`tGetting information back from the jobs..." -ForegroundColor Yellow
    
    $vms = Get-azurevm | ?{ $_.Name -like $vmNamePattern} 
    foreach ($vm in $vms)
    {
        write-host "[DEBUG ALL VMs] Name: " $vm.Name " `t`tServiceName : " $vm.ServiceName   " `t`tStatus : " $vm.Status -ForegroundColor Gray
    }
# }
# else
# {
    # Write-Host "İşlenecek Job bulunamadı!"
# }

Write-Host "`t`t$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Done." -ForegroundColor Gray


#>