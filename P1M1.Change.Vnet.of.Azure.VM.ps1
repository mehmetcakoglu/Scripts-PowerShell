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
#    Change VNET of Azure VM.ps1
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
"    Change VNET of Azure VM.ps1 " | Write-Host -ForegroundColor Yellow
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
�
    param( [Parameter(Mandatory=$true)][System.Security.SecureString] $SecurePassword)
�
    # Create a "password pointer"
    $PasswordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
�
    # Get the plain text version of the password
    $PlainTextPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto($PasswordPointer)
�
    # Free the pointer
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($PasswordPointer)

    # Return the plain text password
    $PlainTextPassword
�
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
If ($ContinueAnswer -eq "Y") 
{ 

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


#Write-Host "`n[SELECTION] - Select the Azure Service." -ForegroundColor Yellow
# Değiştirmek istediğin Cloud Service seç
#$Service = Get-AzureService | Select-Object ServiceName, Label, Location, OperationStatus, Description | Sort-Object -Property ServiceName | Out-GridView -Title "Please select Cloud Service" -PassThru

Write-Host "`n[SELECTION] - Select the Azure Virtual Machine." -ForegroundColor Yellow
# Değiştirmek istediğin Virtual Machine seç
$VM = Get-AzureVM | Select-Object Name, IpAddress, ServiceName, DNSName, InstanceSize, PowerState | Sort-Object -Property Name | Out-GridView -Title "Please select Azure VM do you want to change" -PassThru

Write-Host "`n[SELECTION] - Select the Azure Virtual Network." -ForegroundColor Yellow
# Virtual Network Seç
$VNet = Get-AzureVNetSite | Select-Object Name, Location, AddressSpacePrefixes, Subnets | Sort-Object -Property Name | Out-GridView -Title "Please select Azure Virtual Network" -PassThru

Write-Host "`n[SELECTION] - Select the Azure Virtual Network Subnet." -ForegroundColor Yellow
# Seçtiğin Virtual Network içinden Subnet seç
$VNetSubnet= $VNet.Subnets | Select-Object Name, AddressPrefix, ExtensionData | Sort-Object -Property Name | Out-GridView -Title "Please select Azure Virtual Network Subnet" -PassThru

$VmName = $VM.Name
$ServiceName = $VM.ServiceName

Write-Host "`n[WORKITEM] - Setting up Virtual Network" -ForegroundColor Yellow
$context = Get-AzureVM -ServiceName $ServiceName -Name $VMName
Set-AzureSubnet -SubnetNames $VNetSubnet.Name -VM(Get-AzureVM -ServiceName $ServiceName -Name $VMName) 
#$updateContext = Get-AzureVM -ServiceName $ServiceName -Name $VMName
#Update-AzureVM  -ServiceName $ServiceName -Name $VMName -VM $updateContext
Get-AzureVM -ServiceName  $ServiceName -Name $VMName | Update-AzureVM

$ContinueAnswer = Read-Host "`n`tDo you want to set STATIC IP for Virtual Network? (Y/N)"
If ($ContinueAnswer -eq "Y") 
{ 
	$ipAddress =  Read-Host "`n`tPlease write IP address to set? (Ex: XXX.XXX.XXX.XXX)"
	Set-AzureStaticVNetIP -VM(Get-AzureVM -ServiceName  $ServiceName -Name $VMName) -IPAddress $ipAddress 
	#$updateContext = Get-AzureVM -ServiceName $ServiceName -Name $VMName
	#Update-AzureVM  -ServiceName $ServiceName -Name $VMName -VM $updateContext
	Get-AzureVM -ServiceName  $ServiceName -Name $VMName | Update-AzureVM
}

Write-Host "`n[COMPLETE] - $VMName has been deployed." -ForegroundColor Green
Write-Host "`n Press any key to continue ...`n"
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")


