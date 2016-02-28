#------------------------------------------------------------------------------ 
# 
# Copyright © 2015 Mehmet Çakoğlu.  All rights reserved. 
# 
# THIS CODE AND ANY ASSOCIATED INFORMATION ARE PROVIDED “AS IS” WITHOUT 
# WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT
# LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS 
# FOR A PARTICULAR PURPOSE. THE ENTIRE RISK OF USE, INABILITY TO USE, OR  
# RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER. 
# 
#------------------------------------------------------------------------------ 
# 
# PowerShell Source Code 
# 
# NAME: 
#    P1M1 High_IO VM automaticly.ps1
# 
# VERSION: 
#    1.0
# 
#------------------------------------------------------------------------------ 

"------------------------------------------------------------------------------ " | Write-Host -ForegroundColor Yellow
""  | Write-Host -ForegroundColor Yellow
" Copyright © 2015 Mehmet Çakoğlu.  All rights reserved. " | Write-Host -ForegroundColor Yellow
""  | Write-Host -ForegroundColor Yellow
" THIS CODE AND ANY ASSOCIATED INFORMATION ARE PROVIDED `“AS IS`” WITHOUT " | Write-Host -ForegroundColor Yellow
" WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT " | Write-Host -ForegroundColor Yellow
" LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS " | Write-Host -ForegroundColor Yellow
" FOR A PARTICULAR PURPOSE. THE ENTIRE RISK OF USE, INABILITY TO USE, OR  " | Write-Host -ForegroundColor Yellow
" RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER. " | Write-Host -ForegroundColor Yellow
"------------------------------------------------------------------------------ " | Write-Host -ForegroundColor Yellow
""  | Write-Host -ForegroundColor Yellow
" PowerShell Source Code " | Write-Host -ForegroundColor Yellow
""  | Write-Host -ForegroundColor Yellow
" NAME: " | Write-Host -ForegroundColor Yellow
"    P1M1 High_IO VM automaticly.ps1 " | Write-Host -ForegroundColor Yellow
"" | Write-Host -ForegroundColor Yellow
" VERSION: " | Write-Host -ForegroundColor Yellow
"    1.0" | Write-Host -ForegroundColor Yellow
""  | Write-Host -ForegroundColor Yellow
"------------------------------------------------------------------------------ " | Write-Host -ForegroundColor Yellow
"" | Write-Host -ForegroundColor Yellow
"`n This script SAMPLE is provided and intended only to act as a SAMPLE ONLY," | Write-Host -ForegroundColor Yellow
" and is NOT intended to serve as a solution to any known technical issue."  | Write-Host -ForegroundColor Yellow
"`n By executing this SAMPLE AS-IS, you agree to assume all risks and responsibility associated."  | Write-Host -ForegroundColor Yellow

$ContinueAnswer = Read-Host "`n`tDo you wish to proceed at your own risk? (Y/N)"
If ($ContinueAnswer -ne "Y") { Write-Host "`n Exiting." -ForegroundColor Red;Exit }


function ConvertFrom-SecureToPlain {
    
    param( [Parameter(Mandatory=$true)][System.Security.SecureString] $SecurePassword)
    
    # Create a "password pointer"
    $PasswordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
    
    # Get the plain text version of the password
    $PlainTextPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto($PasswordPointer)
    
    # Free the pointer
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($PasswordPointer)
    
    # Return the plain text password
    $PlainTextPassword
    
}

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
                       #show module not found interaction and bail out
                       Write-Host "[ERROR] - Azure PowerShell module not found. Exiting." -ForegroundColor Red
                       Exit
               }
        }

        Write-Host "`tSuccess"
}
Catch [Exception]
{
        #show module not found interaction and bail out
        Write-Host "[ERROR] - PowerShell module not found. Exiting." -ForegroundColor Red
        Exit
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
   Write-Host "[ERROR] - Azure PowerShell module must be version 0.8.14 or higher. Exiting." -ForegroundColor Red
   Exit
}

$ContinueAnswer = Read-Host "`n`tDo you want to login to AZURE Account? (Y/N)"

If ($ContinueAnswer.ToUpper() -eq "Y") 
{ 

    #If (-not(Get-AzureAccount)) 
    #{ 
	    #Use Add-AzureAccount
	    Write-Host "`n[INFO] - Authenticating Azure account."  -ForegroundColor Yellow
	    Add-AzureAccount | out-null
    

	    #Check to make sure authentication occured
	    If ($?)
	    {
		    Write-Host "`tSuccess"
	    }
	    Else
	    {
		    Write-Host "`tFailed authentication" -ForegroundColor Red
		    Exit
	    }
    
    #}

	#####
	#Azure subscription selection
	#####
	Write-Host "`n[INFO] - Obtaining subscriptions" -ForegroundColor Yellow
	[array] $AllSubs = Get-AzureSubscription 

	If ($AllSubs)
	{
			Write-Host "`tSuccess"

			#$AllSubs | FL 
	}
	Else
	{
			Write-Host "`tNo subscriptions found. Exiting." -ForegroundColor Red
			"`tNo subscriptions found. Exiting." 
			Exit
	}

	Write-Host "`n[SELECTION] - Select the Azure subscription." -ForegroundColor Yellow

	$SelSubName = $AllSubs | Out-GridView -PassThru -Title "Select the Azure subscription"

	If ($SelSubName)
	{
		#Write sub
		Write-Host "`tSelection: $($SelSubName.SubscriptionName)"
        			
			$SelSub = $SelSubName.SubscriptionId
			Select-AzureSubscription -SubscriptionId $SelSub | Out-Null
	}
	Else
	{
			Write-Host "`n[ERROR] - No Azure subscription was selected. Exiting." -ForegroundColor Red
			Exit
	}

}

#####
#Azure VM Name
#####
Write-Host "`n[SELECTION] - Input for Azure Virtual Machine Name." -ForegroundColor Yellow

#get input from user
[string]$cloudSvcName = Read-Host "`n `tWhat do you want your Azure Virtual Machine's cloud service to be named?"
$cloudSvcName=$cloudSvcName.tolower() 

[string]$vmName = Read-Host "`n `tWhat do you want your Azure Virtual Machine to be named?"

#####
# SELECTION INFO SUMMARY
#####
Write-Host "`n[SELECTION INFO SUMMARY]" -ForegroundColor Yellow
Write-Host "`tSubscription `t`t`t: $($SelSubName.SubscriptionName)"
Write-Host "`tCloud Service Name `t`t: $cloudSvcName"
Write-Host "`tVM Name `t`t`t`t: $vmName"

#####
#Azure VM Location
#####
Write-Host "`n[SELECTION] - Select the Azure VM Location." -ForegroundColor Yellow

$SelLocationName = Get-AzureLocation 
$GEOselection = $SelLocationName | select DisplayName | Sort-Object DisplayName | Out-GridView -Title "Select Region" -passthru
$Loc = $SelLocationName | Where {($_.DisplayName -eq $GEOselection.DisplayName)}
$region = $Loc.Name
$StorAccName = "storage$cloudSvcName"

#####
# SELECTION INFO SUMMARY
#####
Write-Host "`n[SELECTION INFO SUMMARY]" -ForegroundColor Yellow
Write-Host "`tSubscription `t`t`t: $($SelSubName.SubscriptionName)"
Write-Host "`tCloud Service Name `t`t: $cloudSvcName"
Write-Host "`tVM Name `t`t`t`t: $vmName"
Write-Host "`tVM Location `t`t`t: $region"

#####
#New Storage or Existing Select
#####
$ContinueAnswer = Read-Host "`n`tDo you want to create new storage? If you choose no, you will select from list (Y/N)"
$StorWillBeNew = $ContinueAnswer.ToUpper()

If ($StorWillBeNew -eq "N") 
{
    Write-Host "`n[SELECTION] - Select the Azure Storage in $region location." -ForegroundColor Yellow
    $StorageAccount = Get-AzureStorageAccount | where {($_.Location -eq $region)} | Select-Object StorageAccountName, Label, Location, AccountType | Sort-Object -Property StorageAccountName | Out-GridView -PassThru -Title "Select the Storage Account in $region location"
    $StorAccName = $StorageAccount.StorageAccountName
}
Else
{
    
    #####
    #Do you want PREMIUM STORAGE?
    #####
    $ContinueAnswer = Read-Host "`n`tDo you want PREMIUM Storage? (Y/N)"
    $StorIsPremium = $ContinueAnswer.ToUpper()

    If ($StorIsPremium -eq "Y") 
    {
        Write-Host "`n[INFO] - Script is creating PREMIUM Virtual Machine storage account in the region $region, Please wait." -ForegroundColor Yellow

        New-AzureStorageAccount -StorageAccountName $StorAccName -Label $vmName -Location $region -Description "PREMIUM Storage Account for $vmName" -Type Premium_LRS -WarningAction SilentlyContinue | out-null
    }
    Else
    {
        Write-Host "`n[INFO] - Script is creating Virtual Machine storage account in the region $region, Please wait." -ForegroundColor Yellow

        New-AzureStorageAccount -StorageAccountName $StorAccName -Label $vmName -Location $region -Description "Storage Account for $vmName" -Type Standard_LRS -WarningAction SilentlyContinue | out-null
    }

    #Check to make sure AzureStorageAccount was created
    $CreatedStorageAccount = Get-AzureStorageAccount -StorageAccountName $StorAccName -WarningAction SilentlyContinue -ErrorAction SilentlyContinue

    If ($CreatedStorageAccount)
    {
	    Write-Host "`tSuccess"
    }
    Else
    {
	    Write-Host "`tFailed to create Storage Account" -ForegroundColor Red
	    Exit
    }
}

#####
# SELECTION INFO SUMMARY
#####
Write-Host "`n[SELECTION INFO SUMMARY]" -ForegroundColor Yellow
Write-Host "`tSubscription `t`t`t: $($SelSubName.SubscriptionName)"
Write-Host "`tCloud Service Name `t`t: $cloudSvcName"
Write-Host "`tVM Name `t`t`t`t: $vmName"
Write-Host "`tVM Location `t`t`t: $region"
Write-Host "`tStorage Account `t`t: $StorAccName"
Write-Host "`tStorage will be new? `t: $StorWillBeNew"
Write-Host "`tStorage is Premium? `t: $StorIsPremium"

#####
#Storage spaces stripe value
#####
Write-Host "`n[SELECTION] - Input for storage spaces stripe value." -ForegroundColor Yellow

$Interleave1 = new-object psobject
Add-Member -InputObject $Interleave1 -MemberType NoteProperty -Name Interleave -Value 65536 -Force
Add-Member -InputObject $Interleave1 -MemberType NoteProperty -Name Workload -Value "Normal" -Force
$Interleave2 = new-object psobject
Add-Member -InputObject $Interleave2 -MemberType NoteProperty -Name Interleave -Value 262144 -Force
Add-Member -InputObject $Interleave2 -MemberType NoteProperty -Name Workload -Value "Data Warehousing" -Force
[array] $Interleave += $Interleave1
[array] $Interleave +=  $Interleave2

$SelStripe = $Interleave | Out-GridView  -Title "Select Storage Spaces Stripe Value" -PassThru
$StripeSize = $SelStripe.Interleave
$Workload = $SelStripe.Workload

If ($StripeSize)
{
	Write-Host "`n[INFO] - Script will create spaces disk with $($Workload.tolower()) stripe value." -ForegroundColor Yellow
	Write-Host "`tSuccess"
}
Else
{
	Write-Host "`tFailed to set stripe setting" -ForegroundColor Red
	Exit
}

#####
# SELECTION INFO SUMMARY
#####
Write-Host "`n[SELECTION INFO SUMMARY]" -ForegroundColor Yellow
Write-Host "`tSubscription `t`t`t: $($SelSubName.SubscriptionName)"
Write-Host "`tCloud Service Name `t`t: $cloudSvcName"
Write-Host "`tVM Name `t`t`t`t: $vmName"
Write-Host "`tVM Location `t`t`t: $region"
Write-Host "`tStorage Account `t`t: $StorAccName"
Write-Host "`tStorage will be new? `t: $StorWillBeNew"
Write-Host "`tStorage is Premium? `t: $StorIsPremium"
Write-Host "`tStorage Stripe Size `t: $StripeSize $Workload"

#####
#VM Administration Credentials
#####
Write-Host "`n[SELECTION] - Input for administrative credentials." -ForegroundColor Yellow

[string]$user = Read-Host "`n `tEnter the local administrator username"

$secpasswd = Read-Host "`n `tEnter the password for $user" -AsSecureString

$password = ConvertFrom-SecureToPlain -SecurePassword $secpasswd

Set-AzureSubscription -SubscriptionName $SelSubName.SubscriptionName -CurrentStorageAccountName $StorAccName

#####
# SELECTION INFO SUMMARY
#####
Write-Host "`n[SELECTION INFO SUMMARY]" -ForegroundColor Yellow
Write-Host "`tSubscription `t`t`t: $($SelSubName.SubscriptionName)"
Write-Host "`tCloud Service Name `t`t: $cloudSvcName"
Write-Host "`tVM Name `t`t`t`t: $vmName"
Write-Host "`tVM Location `t`t`t: $region"
Write-Host "`tStorage Account `t`t: $StorAccName"
Write-Host "`tStorage will be new? `t: $StorWillBeNew"
Write-Host "`tStorage is Premium? `t: $StorIsPremium"
Write-Host "`tStorage Stripe Size `t: $StripeSize $Workload"
Write-Host "`tAdmin Username `t`t`t: $user"
Write-Host "`tAdmin Password `t`t`t: $password"

#####
#VM Size Selection
#####
[array]$AvailLocSize = $Loc.VirtualMachineRoleSizes

$AllVmSizes = Get-AzureRoleSize | where {$AvailLocSize -contains $_.InstanceSize} 
$VMSizeselection = $AllVmSizes | Select-Object InstanceSize,RoleSizeLabel,MaxDataDiskCount,MemoryInMb | Sort-Object -Property MaxDataDiskCount,MemoryInMb -descending | Out-GridView -Title "What size of Azure VM do you want?" -PassThru

$VmSize = $VMSizeselection.InstanceSize
$DiskNumber = $VMSizeselection.MaxDataDiskCount

#####
# SELECTION INFO SUMMARY
#####
Write-Host "`n[SELECTION INFO SUMMARY]" -ForegroundColor Yellow
Write-Host "`tSubscription `t`t`t: $($SelSubName.SubscriptionName)"
Write-Host "`tCloud Service Name `t`t: $cloudSvcName"
Write-Host "`tVM Name `t`t`t`t: $vmName"
Write-Host "`tVM Location `t`t`t: $region"
Write-Host "`tStorage Account `t`t: $StorAccName"
Write-Host "`tStorage will be new? `t: $StorWillBeNew"
Write-Host "`tStorage is Premium? `t: $StorIsPremium"
Write-Host "`tStorage Stripe Size `t: $StripeSize $Workload"
Write-Host "`tAdmin Username `t`t`t: $user"
Write-Host "`tAdmin Password `t`t`t: $password"
Write-Host "`tVM Size `t`t`t`t:" $VMSizeselection.InstanceSize ", " $VMSizeselection.RoleSizeLabel ", Max Data Disk:" $VMSizeselection.MaxDataDiskCount " x HDD, "  $VMSizeselection.MemoryInMb " RAM"

#####
#Virtual Network Selection
#####
$Vnet = $null
$VNetSubnet = $null

$ContinueAnswer = Read-Host "`n`tDo you want to select a Virtual Network to add the new VM? If you choose no, you can't add later(Y/N)"
If ($ContinueAnswer -eq "Y") 
{

    Write-Host "`n[SELECTION] - Select the Azure Virtual Network." -ForegroundColor Yellow
    # Virtual Network Seç
    $VNet = Get-AzureVNetSite | Select-Object Name, Location, AddressSpacePrefixes, Subnets | Sort-Object -Property Name | Out-GridView -Title "Please select Azure Virtual Network" -PassThru

    Write-Host "`n[SELECTION] - Select the Azure Virtual Network Subnet." -ForegroundColor Yellow
    # Seçtiğin Virtual Network içinden Subnet seç
    $VNetSubnet= $VNet.Subnets | Select-Object Name, AddressPrefix, ExtensionData | Sort-Object -Property Name | Out-GridView -Title "Please select Azure Virtual Network Subnet" -PassThru

}

#####
# SELECTION INFO SUMMARY
#####
Write-Host "`n[SELECTION INFO SUMMARY]" -ForegroundColor Yellow
Write-Host "`tSubscription `t`t`t: $($SelSubName.SubscriptionName)"
Write-Host "`tCloud Service Name `t`t: $cloudSvcName"
Write-Host "`tVM Name `t`t`t`t: $vmName"
Write-Host "`tVM Location `t`t`t: $region"
Write-Host "`tStorage Account `t`t: $StorAccName"
Write-Host "`tStorage will be new? `t: $StorWillBeNew"
Write-Host "`tStorage is Premium? `t: $StorIsPremium"
Write-Host "`tStorage Stripe Size `t: $StripeSize $Workload"
Write-Host "`tAdmin Username `t`t`t: $user"
Write-Host "`tAdmin Password `t`t`t: $password"
Write-Host "`tVM Size `t`t`t`t:" $VMSizeselection.InstanceSize ", " $VMSizeselection.RoleSizeLabel ", Max Data Disk:" $VMSizeselection.MaxDataDiskCount " x HDD, "  $VMSizeselection.MemoryInMb " RAM"
Write-Host "`tVirtual Network `t`t:" $VNet.Name " ("$VNet.Location")" 
Write-Host "`tVirtual Network Subnet `t:" $VNetSubnet.Name " (" $VNetSubnet.AddressPrefix ") "

#####
#VM Image Selection
#####

#obtain selection
[array] $AllVmOses = get-azurevmimage | where {($_.Label -notmatch "HPC") -and ($_.Label -notmatch "RDSH") -and ($_.os -eq "Windows") -and ($_.ImageFamily -match "Windows Server 2012")} | where {$_.Location -Match $region} | Sort-Object -Property ImageFamily,PublishedDate -Descending
$currIF="dummy"
$images=$null
$AllVmOses | %{if($_.imagefamily -ne $currif) {$currif=$_.imagefamily;[array]$images+=$_}}
$selection = $images | select imagefamily,publisheddate | Sort-Object imagefamily -descending | Out-GridView -Title "What type of Azure VM do you want to build?" -passthru
$selImage = $allvmoses | Where {($_.ImageFamily -eq $selection.ImageFamily) -and ($_.PublishedDate -eq $selection.PublishedDate)}
$osname = $selImage.ImageFamily
Write-Host "`n[INFO] - Script is creating $osname VM, Please wait." -ForegroundColor Yellow

#####
# SELECTION INFO SUMMARY
#####
Write-Host "`n[SELECTION INFO SUMMARY]" -ForegroundColor Yellow
Write-Host "`tSubscription `t`t`t: $($SelSubName.SubscriptionName)"
Write-Host "`tCloud Service Name `t`t: $cloudSvcName"
Write-Host "`tVM Name `t`t`t`t: $vmName"
Write-Host "`tVM Location `t`t`t: $region"
Write-Host "`tStorage Account `t`t: $StorAccName"
Write-Host "`tStorage will be new? `t: $StorWillBeNew"
Write-Host "`tStorage is Premium? `t: $StorIsPremium"
Write-Host "`tStorage Stripe Size `t: $StripeSize $Workload"
Write-Host "`tAdmin Username `t`t`t: $user"
Write-Host "`tAdmin Password `t`t`t: $password"
Write-Host "`tVM Size `t`t`t`t:" $VMSizeselection.InstanceSize ", " $VMSizeselection.RoleSizeLabel ", Max Data Disk:" $VMSizeselection.MaxDataDiskCount " x HDD, "  $VMSizeselection.MemoryInMb " RAM"
Write-Host "`tVirtual Network `t`t:" $VNet.Name " ("$VNet.Location")" 
Write-Host "`tVirtual Network Subnet `t:" $VNetSubnet.Name " (" $VNetSubnet.AddressPrefix ") "
Write-Host "`tOS Name `t`t`t`t: $osname"

If ($VNet) 
{
    
    #$vm1 = New-AzureVMConfig -DiskName $disk0Name -InstanceSize ExtraSmall -Name $vmName -Label $vmName |
    #Add-AzureDataDisk -DiskName $disk1Name -Import -LUN 0 |
    #Set-AzureSubnet $subNet
    $vm1 = New-AzureVMConfig -Name $vmName -Label $vmName -ImageName $selImage.imagename -InstanceSize $VmSize | Add-AzureProvisioningConfig –Windows -AdminUsername $user –Password $Password -EnableWinRMHttp | Set-AzureSubnet $VNetSubNet.Name 
 
    #New-AzureQuickVM -VNetName $VNet -Windows -ServiceName $cloudSvcName -Name $vmName -ImageName $selImage.imagename -Location $region -Password $Password -AdminUsername $user -InstanceSize $VmSize -EnableWinRMHttp | out-null
    New-AzureVM -ServiceName $cloudSvcName -VMs $vm1 -VNetName $vNet.Name  -Location $region
}
Else
{
    New-AzureQuickVM -Windows -ServiceName $cloudSvcName -Name $vmName -ImageName $selImage.imagename -Location $region -Password $Password -AdminUsername $user -InstanceSize $VmSize -EnableWinRMHttp | out-null
}

#Check to make sure that vm was created
$CreatedVM = Get-AzureVM -ServiceName $cloudSvcName -Name $vmName -ErrorAction SilentlyContinue
If ($CreatedVM)
{
	Write-Host "`tSuccess"
}
Else
{
	Write-Host "`tFailed to create VM" -ForegroundColor Red
	Exit
}

#####
#VM Start
#####
#Echo Vm start
Write-Host "`n[INFO] - Script is starting the VM, ${vmName}, Please wait." -ForegroundColor Yellow

Start-AzureVM -ServiceName $cloudSvcName -Name $vmname | out-null

$vm = Get-AzureVM -Name $vmname -ServiceName $cloudSvcName

If ($vm.PowerState -eq "Started")
{
	Write-Host "`tSuccess"
}
Else
{
	Write-Host "`tFailed to start VM $vmName" -ForegroundColor Red
	Exit
}

#####
#Data Disk Setup
#####
Write-Host "`n[INFO] - Data Disk Setup" -ForegroundColor Yellow

$ContinueAnswer = -1
while($ContinueAnswer -lt 0 -or $ContinueAnswer -gt $DiskNumber)
{
    $ContinueAnswer = Read-Host "`n`tYou can add maximum $DiskNumber data disk to the new VM. Please enter disk count to add"
    if($ContinueAnswer -notmatch "^[\d\.]+$")
    {
        $ContinueAnswer = -1
    }
}

$DiskNumber = $ContinueAnswer

#####
# SELECTION INFO SUMMARY
#####
Write-Host "`n[SELECTION INFO SUMMARY]" -ForegroundColor Yellow
Write-Host "`tSubscription `t`t`t: $($SelSubName.SubscriptionName)"
Write-Host "`tCloud Service Name `t`t: $cloudSvcName"
Write-Host "`tVM Name `t`t`t`t: $vmName"
Write-Host "`tVM Location `t`t`t: $region"
Write-Host "`tStorage Account `t`t: $StorAccName"
Write-Host "`tStorage will be new? `t: $StorWillBeNew"
Write-Host "`tStorage is Premium? `t: $StorIsPremium"
Write-Host "`tStorage Stripe Size `t: $StripeSize $Workload"
Write-Host "`tAdmin Username `t`t`t: $user"
Write-Host "`tAdmin Password `t`t`t: $password"
Write-Host "`tVM Size `t`t`t`t:" $VMSizeselection.InstanceSize ", " $VMSizeselection.RoleSizeLabel ", Max Data Disk:" $VMSizeselection.MaxDataDiskCount " x HDD, "  $VMSizeselection.MemoryInMb " RAM"
Write-Host "`tVirtual Network `t`t:" $VNet.Name " ("$VNet.Location")" 
Write-Host "`tVirtual Network Subnet `t:" $VNetSubnet.Name " (" $VNetSubnet.AddressPrefix ") "
Write-Host "`tOS Name `t`t`t`t: $osname"
Write-Host "`tDisk Number Will be Add : $DiskNumber"

#####
#Size of Data Disks Attaching
#####
Write-Host "`n[INFO] - Please enter size of data disks in GB" -ForegroundColor Yellow
$ContinueAnswer = -1
while($ContinueAnswer -lt 0 -or $ContinueAnswer -gt $DiskNumber)
{
    $ContinueAnswer = Read-Host "`n`tPlease enter disk size (1-1023 Gb): "
    if($ContinueAnswer -notmatch "^[\d\.]+$")
    {
        $ContinueAnswer = -1
    }
}

$DiskSize = $ContinueAnswer

#####
# SELECTION INFO SUMMARY
#####
Write-Host "`n[SELECTION INFO SUMMARY]" -ForegroundColor Yellow
Write-Host "`tSubscription `t`t`t: $($SelSubName.SubscriptionName)"
Write-Host "`tCloud Service Name `t`t: $cloudSvcName"
Write-Host "`tVM Name `t`t`t`t: $vmName"
Write-Host "`tVM Location `t`t`t: $region"
Write-Host "`tStorage Account `t`t: $StorAccName"
Write-Host "`tStorage will be new? `t: $StorWillBeNew"
Write-Host "`tStorage is Premium? `t: $StorIsPremium"
Write-Host "`tStorage Stripe Size `t: $StripeSize $Workload"
Write-Host "`tAdmin Username `t`t`t: $user"
Write-Host "`tAdmin Password `t`t`t: $password"
Write-Host "`tVM Size `t`t`t`t:" $VMSizeselection.InstanceSize ", " $VMSizeselection.RoleSizeLabel ", Max Data Disk:" $VMSizeselection.MaxDataDiskCount " x HDD, "  $VMSizeselection.MemoryInMb " RAM"
Write-Host "`tVirtual Network `t`t:" $VNet.Name " ("$VNet.Location")" 
Write-Host "`tVirtual Network Subnet `t:" $VNetSubnet.Name " (" $VNetSubnet.AddressPrefix ") "
Write-Host "`tOS Name `t`t`t`t: $osname"
Write-Host "`tDisk Number Will be Add : $DiskNumber"
Write-Host "`tDisk Size Will be Add `t:" $DiskSize " GB"

#####
#Data Disks Attaching
#####
Write-Host "`n[INFO] - Script is creating and attaching $DiskNumber x $DiskSize GB data disks, Please wait." -ForegroundColor Yellow

for($i = 0; $i -lt $DiskNumber; $i++) 
{
        $disklabel = "disk$vmName"
    $diskname = $disklabel + $i.ToString() 
    Add-AzureDataDisk -VM $vm -CreateNew -DiskSizeInGB $DiskSize -DiskLabel $diskname -LUN $i -HostCaching None | out-null
}        
$vm | Update-AzureVM | out-null

#get fresh vm data
$vm = Get-AzureVM -Name $vmname -ServiceName $cloudSvcName

#Check for Vm disks and echo 
[array]$CreatedDataDisks = Get-AzureDataDisk -VM $vm
$CreatedDataDisksCount = $CreatedDataDisks.Count

If ($CreatedDataDisksCount -ge $DiskNumber)
{
	Write-Host "`tSuccess. Found $CreatedDataDisksCount data disks."
}
Else
{
	Write-Host "`tFailed to create all data disks. Found $CreatedDataDisksCount data disks." -ForegroundColor Red
	Exit
}

#####
# SELECTION INFO SUMMARY
#####
Write-Host "`n[SELECTION INFO SUMMARY]" -ForegroundColor Yellow
Write-Host "`tSubscription `t`t`t: $($SelSubName.SubscriptionName)"
Write-Host "`tCloud Service Name `t`t: $cloudSvcName"
Write-Host "`tVM Name `t`t`t`t: $vmName"
Write-Host "`tVM Location `t`t`t: $region"
Write-Host "`tStorage Account `t`t: $StorAccName"
Write-Host "`tStorage will be new? `t: $StorWillBeNew"
Write-Host "`tStorage is Premium? `t: $StorIsPremium"
Write-Host "`tStorage Stripe Size `t: $StripeSize $Workload"
Write-Host "`tAdmin Username `t`t`t: $user"
Write-Host "`tAdmin Password `t`t`t: $password"
Write-Host "`tVM Size `t`t`t`t:" $VMSizeselection.InstanceSize ", " $VMSizeselection.RoleSizeLabel ", Max Data Disk:" $VMSizeselection.MaxDataDiskCount " x HDD, "  $VMSizeselection.MemoryInMb " RAM"
Write-Host "`tVirtual Network `t`t:" $VNet.Name " ("$VNet.Location")" 
Write-Host "`tVirtual Network Subnet `t:" $VNetSubnet.Name " (" $VNetSubnet.AddressPrefix ") "
Write-Host "`tOS Name `t`t`t`t: $osname"
Write-Host "`tDisk Number Will be Add : $DiskNumber"
Write-Host "`tDisk Size Will be Add `t:" $DiskSize " GB"
Write-Host "`tAdded Data Disks `t`t:" $CreatedDataDisksCount " Disks (Total " ($CreatedDataDisksCount * $DiskSize) " GB)"

#####
#Checking VM Ready
#####
Write-Host "`n[INFO] - Script is checking to see if VM is ready, Please wait." -ForegroundColor Yellow
# check to make sure vm is done building
$iteration = 0
while($vm.status -ne "ReadyRole" -and $iteration -lt 30)
{
    $vm = Get-AzureVM -Name $vmname -ServiceName $cloudSvcName
    write-host "`tVM status is:" $vm.status
    Start-Sleep -Seconds 15
    $iteration++
}

#make sure azure plat sees all data disks
[array]$datadisks=$vm.vm.DataVirtualHardDisks

If ($datadisks.count -eq $DiskNumber)
{
        #get all vm endpoints
        $allendpoints = get-azureendpoint -vm $vm

        #look for powershell endpoint
        $poshEP = $allendpoints | where {$_.LocalPort -match "5986"}

    if ($poshEP)
    {
       #remote powershell attempt
	   Write-Host "`n[INFO] - Script is connecting with remote powershell, Please wait." -ForegroundColor Yellow
        Try
        {       
        $Vip = $PoShEP.Vip
        $Port = $PoShEP.Port
        $RemotePoShCred = New-Object System.Management.Automation.PSCredential ($user, $secpasswd)
        $s = New-PSSession -ComputerName $Vip -Port $Port -UseSSL –Credential $RemotePoShCred -sessionoption (new-pssessionoption -skipcacheck -skipcncheck)
                       
            If ($s)
            {
                If (($s.Availability -eq "Available") -and ($s.State -eq "Opened"))
                {
					#Echo PS state
					Write-Host "`tSuccess"
									
                    #do stuff on the remote machine
					Write-Host "`n[INFO] - Script is setting up a $DiskNumber TB storage space with remote powershell, Please wait." -ForegroundColor Yellow
                    #Run the below command to list the available disk in the Virtual Machine.
					
						$ScriptBlock = 
						{
						param ([int]$StripeSize)
						$PoolCount = Get-PhysicalDisk -CanPool $True
						$DiskCount = $PoolCount.count
						$PhysicalDisks = Get-StorageSubSystem -FriendlyName "Storage Spaces*" | Get-PhysicalDisk -CanPool $True
						New-StoragePool -FriendlyName "IOData" -StorageSubsystemFriendlyName "Storage Spaces*" -PhysicalDisks $PhysicalDisks |New-VirtualDisk -FriendlyName "DiskIO" -Interleave $StripeSize -NumberOfColumns $DiskCount -ResiliencySettingName simple –UseMaximumSize |Initialize-Disk -PartitionStyle GPT -PassThru |New-Partition -AssignDriveLetter -UseMaximumSize |Format-Volume -FileSystem NTFS -NewFileSystemLabel "IODisk" -AllocationUnitSize 65536 -Confirm:$false
						}
					Invoke-Command -Session $s -ScriptBlock $ScriptBlock -ArgumentList $StripeSize | out-null
                }
				Else
                    {
	                    #pssession created but is not open and available	                    
						Write-Host "`tFailed to open the remote Powershell session" -ForegroundColor Red
						Exit						
                    }

            }
			Else
            {
            	#failed to create pssession            	
				Write-Host "`tFailed to create the remote Powershell session" -ForegroundColor Red
				Exit				
            }
       	}
		Catch [Exception]
    	{
		    #something bad happened in my try block. try writing $_ to see the thrown exception			
			Write-Host "Failed: $_" -ForegroundColor Red
			Exit			
    	}
	}
     Else
        {
        	#no posh endpoint found        	
			Write-Host "Failed remote Powershell: No remote Powershell endpoint was found." -ForegroundColor Red
			Exit			
        }

	}
	else
	{
        #plat doesnt see new data disks        
		Write-Host "Failed: Data disks could not be found." -ForegroundColor Red
		Exit		
	}
 Write-Host "`n[COMPLETE] - $vmName has been deployed with a $DiskNumber TB high I/O disk for your testing.`n" -ForegroundColor Green
 Write-Host "`n Press any key to continue ...`n"
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")