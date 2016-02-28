# MOVE VM BETWEEN SUBSCRIPTIONS

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
If ($ContinueAnswer -eq "Y") 
{ 
    $isAuthenticated = $False
	#Use Add-AzureAccount
	Write-Host "`n[INFO] - Authenticating Azure account."  -ForegroundColor Yellow
	Add-AzureAccount | out-null

	#Check to make sure authentication occured
	If ($?)
	{
        $isAuthenticated = $true
		Write-Host "`tSuccess"
	}
	Else
	{
		Write-Host "`tFailed authentication" -ForegroundColor Red
		Exit
	}
}

if ($isAuthenticated)
{
	#####
	#Azure source subscription selection
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

	Write-Host "`n[SELECTION] - Kaynak Azure Subscription'i seciniz." -ForegroundColor Yellow

	$SelSubName = $AllSubs | Out-GridView -PassThru -Title "Azure subscription Seciniz"

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
Else
{
    Write-Host "`n[ERROR] - No Azure subscription was selected, because user not authenticated. " -ForegroundColor Red
    Write-Host "`n[ERROR] - Please try again with authentication. Exiting. " -ForegroundColor Red
	Exit
}



    # Name of the source Azure subscription
    [string] $SourceSubscription = $SelSubName.SubscriptionName


Write-Host "`n[SELECTION] - Kaynak Cloud Service'i seciniz." -ForegroundColor Yellow
$sourceService = Get-AzureService | Select-Object ServiceName, Label, Location, OperationStatus, Description | Sort-Object -Property ServiceName | Out-GridView -Title "Lutfen Kaynak Cloud Service'i seciniz." -PassThru

    # Name of the source cloud service
    [string] $SourceServiceName = $sourceService.ServiceName
    [string] $SourceServiceLocation = $sourceService.Location
    write-host "`tSelection: $SourceServiceName" 

Write-Host "`n[SELECTION] - Kaynak Azure Virtual Machine'i seciniz." -ForegroundColor Yellow
$sourceVm = Get-AzureVM | Select-Object Name, IpAddress, ServiceName, DNSName, InstanceSize, PowerState | Sort-Object -Property Name | Out-GridView -Title "Lutfen Kaynak Azure VM'i seciniz." -PassThru

    # Name of the VM to migrate
    [string] $VMName = $sourceVm.Name
    write-host "`tSelection: $VMName"






Write-Host "`n[SELECTION] - Hedef Azure Subscription'i seciniz." -ForegroundColor Yellow

$DestSelSubName = $AllSubs | Out-GridView -PassThru -Title "Hedef Azure subscription Seciniz"

If ($DestSelSubName)
{
	#Write sub
	Write-Host "`tSelection: $($DestSelSubName.SubscriptionName)"
			
		$DestSelSub = $DestSelSubName.SubscriptionId
		Select-AzureSubscription -SubscriptionId $DestSelSub | Out-Null
        
}
Else
{
		Write-Host "`n[ERROR] - No Azure subscription was selected. Exiting." -ForegroundColor Red
		Exit
}

    # Name of the destination Azure subscription
    [string] $DestSubscription = $DestSelSubName.SubscriptionName


Write-Host "`n[SELECTION] - Hedef Azure Storage'i seciniz." -ForegroundColor Yellow
$storAcc = Get-AzureStorageAccount| Select-Object Label, Location, StorageAccountName, AccountType, OperationStatus | Sort-Object -Property StorageAccountName | Out-GridView -Title "Lütfen Hedef Azure Storage seciniz" -PassThru

    # Name of the destination storage account
    [string] $DestStorageAccountName = $storAcc.StorageAccountName
    [string] $DestStorageLocation = $storAcc.Location
    write-host "`tSelection: $DestStorageAccountName"


# Write-Host "`n[SELECTION] - Hedef Azure Service'i seciniz." -ForegroundColor Yellow
# $destService = Get-AzureService | Select-Object ServiceName, Label, Location, OperationStatus, Description | Sort-Object -Property ServiceName | Out-GridView -Title "Lutfen Hedef Cloud Service'i seciniz." -PassThru

    # Name of the destination cloud service
    [string] $DestServiceName = $SourceServiceName
    write-host "`tSelection: $DestServiceName"


Write-Host "`n[SELECTION] - Hedef Azure Virtual Network'u seciniz." -ForegroundColor Yellow
# Virtual Network Sec
$destVNet = Get-AzureVNetSite | Select-Object Name, Location, AddressSpacePrefixes, Subnets | Sort-Object -Property Name | Out-GridView -Title "Lutfen Hedef Azure Virtual Network Secin" -PassThru
write-host "`tSelection: $destVNet"

Write-Host "`n[SELECTION] - Hedef Azure Virtual Network Subnet'i seciniz." -ForegroundColor Yellow
# SeÃ§tiÄŸin Virtual Network iÃ§inden Subnet seÃ§
$destVNetSubnet= $destVNet.Subnets | Select-Object Name, AddressPrefix, ExtensionData | Sort-Object -Property Name | Out-GridView -Title "Lutfen Hedef Azure Virtual Network Subnet Secin" -PassThru
[string] $DestVNetSubnetName = $destVNetSubnet.Name
write-host "`tSelection: $DestVNetSubnetName"

#Write-Host "`n[SELECTION] - Hedef Azure Virtual Machine'i seciniz." -ForegroundColor Yellow
#$destVm = Get-AzureVM | Select-Object Name, IpAddress, ServiceName, DNSName, InstanceSize, PowerState | Sort-Object -Property Name | Out-GridView -Title "Lutfen Hedef Azure VM'i seciniz." -PassThru

    # Name of the destination VNET - blank if none used
    [string] $DestVNETName = $destVNet.Name    
    # Indicates if we are copying from the source storage accounts read-only secondary location
    [switch] $IsReadOnlySecondary = $false
    # Indicates if we are overwriting if the VHD already exists
    [switch] $Overwrite = $false
    # Indicates if we remove an Azure Disk if it already exists in the destination repository
    [switch] $RemoveDestAzureDisk = $false


#region ===  Runtime Configuration ===========================================

# Script Path/Directories
$ScriptPath   = (Split-Path ((Get-Variable MyInvocation).Value).MyCommand.Path)

# Date Format
$DateFormat   = Get-Date -Format "yyyyMMdd_HHmmss"

# Zero out errors
$Error.Clear()

# Define collections to keep track of async operations
$copyTasks = @()

# Define storage account context collection so we can reuse these
$storageContexts = @{}

# Show verbose output
$VerbosePreference = "Continue"

# Define Stop/Start Instance Status values
$StoppedStatus = "StoppedDeallocated"
$StartedStatus = "ReadyRole" 

#endregion configuration

#region ===  Functions =======================================================

 <#
.SYNOPSIS
   Write to output including a timestamp and computer name
.EXAMPLE
   Write-Log "message"
.OUTPUTS
   None
#>
function Write-Log
{
	param
	(
		[string] $Message,
		[switch] $IsError = $false
	)

    if($IsError) 
    { 
        Write-Error "$([DateTime]::Now.ToLongTimeString()) - $Message" 
    } 
	else 
    {
        Write-Verbose "$([DateTime]::Now.ToLongTimeString()) - $Message"
    }
}

<#
.SYNOPSIS
   Stops the specified VM and waits until the instance enters the stopped state
.DESCRIPTION
   Checks the state of the VM instance
   Stops the VM
   Loops until the state of the VM equals the stopped state
.EXAMPLE
   Stop-AzureVMAndWait -ServiceName "MyCloudService" -VMName "MyVMName"
.OUTPUTS
   None
#>
function Stop-AzureVMAndWait
{
    param
    (        
        # Name of the service hosting the VM
        [Parameter(Mandatory = $true)]
        [String]
        $ServiceName,

        # Name of the VM
        [Parameter(Mandatory = $true)]
        [String]
        $VMName
    ) 

    Write-Log "Checking current VM state..." 

    # Gather current status of the VM
    $vmStatus = Get-AzureVM -ServiceName $ServiceName -Name $VMName 

	# Check if VM exists
	if ($vmStatus -eq $null) {
        Write-Log "$VMName is not been provisioned" 
		return
	}

	# Attempt to stop VM
    if ($vmStatus.InstanceStatus -ne $StoppedStatus) {

        Write-Log "Stopping $VMName..." 

        # Stop VM
        foreach($retry in (1..3)) {
            Stop-AzureVM -ServiceName $ServiceName -Name $VMName -Force -Verbose -ErrorVariable lastError -ErrorAction SilentlyContinue | Out-Null
            if ($?) { break }   # Success
            else {
                # Failure
                if ($retry -eq 3) { 
                    Write-Log "$VMName failed to stop after $retry retires"
                    return
                }
                # Wait
                Sleep -Seconds 3
            }                     
        }

        # Wait for VM to shutdown
        $vmStatus = Get-AzureVM -ServiceName $ServiceName -Name $VMName 
        While ($vmStatus.InstanceStatus -ne $StoppedStatus)
        {
            # Take a break
            Write-Log "Waiting for VM to enter $StoppedStatus state... Current Status: $($vmStatus.InstanceStatus)"
            Start-Sleep -Seconds 15
 
            # Gather current status
            $vmStatus = Get-AzureVM -ServiceName $ServiceName -Name $VMName 
        }
    }

    Write-Log "$VMName is in the $StoppedStatus state" 
 }

<#
.SYNOPSIS
   Starts the specified VM and waits until the instance enters the ready state
.DESCRIPTION
   Checks the state of the VM instance
   Starts the VM
   Loops until the state of the VM equals the ready state
.EXAMPLE
   Stop-AzureVMAndWait -ServiceName "MyCloudService" -VMName "MyVMName"
.OUTPUTS
   None
#>
function Start-AzureVMAndWait
{
    param
    (        
        # Name of the service hosting the VM
        [Parameter(Mandatory = $true)]
        [String]
        $ServiceName,

        # Name of the VM
        [Parameter(Mandatory = $true)]
        [String]
        $VMName
    ) 

    Write-Log "Checking current VM state..." 

    # Gather current status of the VM
    $vmStatus = Get-AzureVM -ServiceName $ServiceName -Name $VMName 

	# Check if VM exists
	if ($vmStatus -eq $null) {
        Write-Log "$VMName is not been provisioned" 
		return
	}

	# Attempt to stop VM
    if ($vmStatus.InstanceStatus -ne $StoppedStatus) {

        Write-Log "Starting $VMName..." 

        # Stop VM
        foreach($retry in (1..3)) {
            Start-AzureVM -ServiceName $ServiceName -Name $VMName -Verbose -ErrorVariable lastError -ErrorAction SilentlyContinue | Out-Null
            if ($?) { break }   # Success
            else {
                # Failure
                if ($retry -eq 3) { 
                    Write-Log "$VMName failed to start after $retry retires"
                    return
                }
                # Wait
                Sleep -Seconds 3
            }                     
        }

        # Wait for VM to shutdown
        $vmStatus = Get-AzureVM -ServiceName $ServiceName -Name $VMName 
        While ($vmStatus.InstanceStatus -ne $StartedStatus)
        {
            # Take a break
            Write-Log "Waiting for VM to enter $StartedStatus state... Current Status: $($vmStatus.InstanceStatus)"
            Start-Sleep -Seconds 15
 
            # Gather current status
            $vmStatus = Get-AzureVM -ServiceName $ServiceName -Name $VMName 
        }
    }

    Write-Log "$VMName is in the $StartedStatus state" 
 }

 <#
.SYNOPSIS
   Returns a reference to the storage account context
.EXAMPLE
   Get-AzureStorageContext -SubscriptionName "MySub" -StorageAccountName "mystorage"
.OUTPUTS
   [AzureStorageContext]
#>
function Get-AzureStorageContext
{
	param
	(
        [string] $SubscriptionName,
		[string] $StorageAccountName
	)

    # Set subscription context
    Select-AzureSubscription -SubscriptionName $SubscriptionName -Current  

    # Check our collection if we have already generated a storage context for this account
    $context = $storageContexts[$StorageAccountName]
    if ($context -eq $null)
    {
        # Generate context for this storage account
        $storageAccountKey = (Get-AzureStorageKey -StorageAccountName $StorageAccountName).Primary 
        $context = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $storageAccountKey 

        # Add context to collection for next time
        $storageContexts[$StorageAccountName] = $context
    }

    return $context
}

<#
.SYNOPSIS
   Start the async copy of the underlying VHD to the corresponding destination storage account
.EXAMPLE
   Copy-AzureDiskAsync -SourceDisk $disk
.OUTPUTS
   None
#>
function Copy-AzureDiskAsync
{
    param
    (
        # Reference to source Azure disk to copy
        [Parameter(Mandatory = $true)]
        $SourceDisk
    )
    (Get-Process -id $pid).PriorityClass = "High"

    #$sourceDisk = Get-AzureDisk  -DiskName "p1m1ykbbranch-p1m1ykbbranch-0-201410211242510630"

    # Gather container and blob details from the source disk
    $container = ($SourceDisk.MediaLink.Segments[1]).Replace("/","")
    $blobName = $SourceDisk.MediaLink.Segments | Where-Object { $_ -like "*.vhd" } 
    $sourceUri = $SourceDisk.MediaLink.AbsoluteUri

    # Gather storage account details. 
    $srcStorageAccount = $SourceDisk.MediaLink.Host.Replace(".blob.core.windows.net", "")  
    $destStorageAccount = $DestStorageAccountName.ToLower()

    Write-Log "Preparing to copy source disk $($SourceDisk.DiskName) to $destStorageAccount..."

    # Get storage contexts for source and destination
    $srcContext = Get-AzureStorageContext -SubscriptionName $SourceSubscription -StorageAccountName $srcStorageAccount
    $destContext = Get-AzureStorageContext -SubscriptionName $DestSubscription -StorageAccountName $destStorageAccount
    # [BUG: For some reason after we get the destination context we end up with an array of context instead. !?!]
    $srcContext = $storageContexts[$srcStorageAccount]
    $destContext = $storageContexts[$destStorageAccount]
    if ($srcContext -eq $null -or $destContext -eq $null)
    {
        if ($srcContext -eq $null)  { Write-Log "Could not access source storage account $srcStorageAccount" -IsError } 
        if ($destContext -eq $null) { Write-Log "Could not access destination storage account $destStorageAccount" -IsError } 
        throw "Failed to create storage contexts for storage accounts"
    }

    # Create destination container if it doesnt already exist
    if ((Get-AzureStorageContainer -Name $container -Context $destContext -ErrorAction SilentlyContinue) -eq $null) 
    { 
        Write-Log "Creating container $container in destination storage account..." 
        New-AzureStorageContainer -Name $container -Context $destContext 
    } 

    # Check if the VHD already exists in the destination container
    $blob = Get-AzureStorageBlob -Container $container -Blob $blobName -Context $destContext -ErrorAction SilentlyContinue
    if ($blob -ne $null -and $Overwrite -eq $false)
    {
        write-log "A blob with the name $blobName already exists in the destination storage account and overwrite parameter is $overwrite" -IsError $true
        throw "A blob with the name $blobName already exists in the destination storage account"
    } 

    Write-Log "Scheduling the async copy of source disk $($SourceDisk.DiskName) to $destStorageAccount..."

    # [SS: Check if we are copying from a RA-GRS secondary storage account]
    if ($IsReadOnlySecondary -eq $true)
    {
        # Append "-secondary" to the media location URI to reference the RA-GRS copy        
        $sourceUri = $sourceUri.Replace($srcStorageAccount, "$srcStorageAccount-secondary")
    }

    # [SS: Need to be in the source subscription context for the copy operation to work correctly]
    # Set context to source subscription
    Select-AzureSubscription -SubscriptionName $SourceSubscription -Current  

    # Schedule a blob copy operation of the source disk to the destination storage account
    if ($Overwrite -eq $true)
    {
        # Use the Force flag to overwrite destination blob if it exists
        $copyTask = Start-AzureStorageBlobCopy -Context $srcContext -SrcUri $sourceUri `
                                               -DestContext $destContext -DestContainer $container -DestBlob $blobName `
                                               -Force `
                                               -ErrorAction SilentlyContinue -ErrorVariable LastError
    }
    else
    {
        # Without the force flag
        $copyTask = Start-AzureStorageBlobCopy -Context $srcContext -SrcUri $sourceUri `
                                               -DestContext $destContext -DestContainer $container -DestBlob $blobName `
                                               -ErrorAction SilentlyContinue -ErrorVariable LastError
    }

    # Check if the copy task was created successfully
    if ($copyTask -eq $null)
    {
        throw "Failed to schedule async copy task of blob: $blob to storage account: $destStorageAccount. Details: $LastError" 
    }
    
    Write-Log "Copy of source disk $($SourceDisk.DiskName) to $destStorageAccount has been scheduled successfully"

    (Get-Process -id $pid).PriorityClass = "Normal"

    return $copyTask
}


<#
.SYNOPSIS
   Monitor async copy tasks and wait for all to complete
.EXAMPLE
   WaitAll-AsyncCopyJobs
.OUTPUTS
   None
#>
function WaitAll-AsyncCopyJobs
{
    (Get-Process -id $pid).PriorityClass = "High"

    # Monitor async tasks and wait for all to complete
    $delaySeconds = 5 
    Write-Log "Checking storage copy job status every $delaySeconds seconds."
    do 
    { 
        $continue = $false 
        $progressId = 1
        
        foreach ($copyTask in $copyTasks) 
        { 
            # [SS: For some reason we get some non blob copy tasks in the collection so we need to filter these out]
            # Check the copy state for the blob
            if ($copyTask.ICloudBlob -ne $null)
            {
                $copyState = $copyTask | Get-AzureStorageBlobCopyState 
                $copyStatus = $copyState.Status
                $copyPercent = (($copyState.BytesCopied/$copyState.TotalBytes)*100)
                $copyPercentText = "{0:N2}" -f $copyPercent
                
                # Display progress
                Write-Progress -Id $progressId -Activity "Copying... (% $CopyPercentText Completed)" -PercentComplete $copyPercent -CurrentOperation $copyTask.Name -Status $copyState.Status
            }
            else { $copyStatus = [Microsoft.WindowsAzure.Storage.Blob.CopyStatus]::Invalid }

            # Continue checking status as long as at least one operations is still pending
            if ($copyStatus -eq [Microsoft.WindowsAzure.Storage.Blob.CopyStatus]::Pending ) { $continue = $true }
            
            $progressId += 1
        } 

        # Pause if we are checking again
        if ($continue) { Start-Sleep -Seconds $delaySeconds }

    } while ($continue)

    Write-Log "All async tasks have completed. Check output for failures."

    # Display final state
    $copyTasks | Get-AzureStorageBlobCopyState | Format-Table -AutoSize -Property Status,BytesCopied,TotalBytes,copyId,Source

    (Get-Process -id $pid).PriorityClass = "Normal"
}

#endregion Functions

#region ===  Script Execution ================================================

try
{
    #
    #region - Shutdown and Export VM configuration
    #

    # Set source subscription context
    write-host "`t[EXEC] : Set source subscription context"
    Select-AzureSubscription -SubscriptionName $SourceSubscription -Current

    # Stop VM
    write-host "`t[EXEC] : Stop VM"
    Stop-AzureVMAndWait -ServiceName $SourceServiceName -VMName $VMName

    # Export VM config to temporary file
    write-host "`t[EXEC] : Export VM config to temporary file" 
    $exportPath = "{0}\{1}-{2}-State.xml" -f $ScriptPath, $SourceServiceName, $VMName 
    Export-AzureVM -ServiceName $SourceServiceName -Name $VMName -Path $exportPath
    if (-not(Test-Path $exportPath))
    {
        throw "Failed to export VM state. Aborting..."
    }

    #endregion
    #
    #
    #region - Copy all attached VHDs to destination storage using async copy jobs
    #

    # Get list of azure disks that are currently attached to the VM   
    write-host "`t[EXEC] : Get list of azure disks that are currently attached to the VM "
    $disks = Get-AzureDisk | ? { $_.AttachedTo.RoleName -eq $VMName }
    
    # Loop through each disk
    write-host "`t[EXEC] : Loop through each disk"
    $copyTasks = $null
    foreach($disk in $disks)
    {
        try
        {
            # Start the async copy of the underlying VHD to the corresponding destination storage account
            $copyTasks += Copy-AzureDiskAsync -SourceDisk $disk
        }
        catch {}   # Support for existing VHD in destination storage account
    }
    Start-Sleep -Seconds 15

    # Monitor async copy tasks and wait for all to complete
    write-host "`t[EXEC] : Monitor async copy tasks and wait for all to complete"
    WaitAll-AsyncCopyJobs   

    #endregion
    #
    #
    #region - Re-construct OS and Data disks
    #

    # Set destination subscription context
    write-host "`t[EXEC] : Set destination subscription context"
    Select-AzureSubscription -SubscriptionName $DestSubscription -Current

    # Load VM config
    write-host "`t[EXEC] : Load VM Config"
    $vmConfig = Import-AzureVM -Path $exportPath

    # Loop through each disk again
    write-host "`t[EXEC] : Loop through each disk again"
    $diskNum = 0
    foreach($disk in $disks)
    {
        # Construct new Azure disk name as [DestServiceName]-[VMName]-[Index]
        $destDiskName = "{0}-{1}-{2}" -f $DestServiceName,$VMName,$diskNum   

        Write-Log "Checking if $destDiskName exists..."

        # Check if an Azure Disk already exists in the destination subscription
        $azureDisk = Get-AzureDisk -DiskName $destDiskName -ErrorAction SilentlyContinue -ErrorVariable LastError
        if ($azureDisk -ne $null)
        {
            Write-Log "$destDiskName already exists"

            if ($RemoveDisk -eq $true)
            {
                # Remove the disk from the repository
                Remove-AzureDisk -DiskName $destDiskName

                Write-Log "Removed AzureDisk $destDiskName"
                $azureDisk = $null
            }
            # else keep the disk and continue
        }

        # Determine media location
        $container = ($disk.MediaLink.Segments[1]).Replace("/","")
        $blobName = $disk.MediaLink.Segments | Where-Object { $_ -like "*.vhd" } 
        $destMediaLocation = "http://{0}.blob.core.windows.net/{1}/{2}" -f $DestStorageAccountName,$container,$blobName

        # Attempt to add the azure OS or data disk  
        if ($disk.OS -ne $null -and $disk.OS.Length -ne 0) 
        {
            # OS disk
            if ($azureDisk -eq $null)
            {
                $azureDisk = Add-AzureDisk -DiskName $destDiskName -MediaLocation $destMediaLocation -Label $destDiskName -OS $disk.OS -ErrorAction SilentlyContinue -ErrorVariable LastError
            }

            # Update VM config
            $vmConfig.OSVirtualHardDisk.DiskName = $azureDisk.DiskName     
        }
        else
        {
            # Data disk
            if ($azureDisk -eq $null)
            {
                $azureDisk = Add-AzureDisk -DiskName $destDiskName -MediaLocation $destMediaLocation -Label $destDiskName -ErrorAction SilentlyContinue -ErrorVariable LastError
            }

            # Update VM config
            #   Match on source disk name and update with dest disk name
            $vmConfig.DataVirtualHardDisks.DataVirtualHardDisk | ? { $_.DiskName -eq $disk.DiskName } | ForEach-Object { 
                $_.DiskName = $azureDisk.DiskName 
            }                
        }              

        # Next disk number
        $diskNum = $diskNum + 1
    }
        
    #endregion
    #
    #
    #region - Restore VM in destination cloud service
    #
    Write-Log "Restoring $VMName to $DestServiceName..."

    # Restore VM
    write-host "`t[EXEC] : Checking Existing VMs"
    $existingVMs = Get-AzureService -ServiceName $DestServiceName | Get-AzureVM
    if ($existingVMs -eq $null -and $DestVNETName.Length -gt 0)
    {
        # Kaynak subscription'da olusturmak istedigimiz DNS isminde baska bir cloud service var mi?
        write-host "`t[EXEC] : Selecting Source Subscription $SourceSubscription"
        Select-AzureSubscription -SubscriptionName $SourceSubscription
        
        write-host "`t[EXEC] : Checking Source Cloud Service for DNS Name availability"
        $sourceService = Get-AzureService -ServiceName $SourceServiceName
        if(Get-azureService | where {$_.Label -in $DestServiceName -and $_.Location -eq $SourceServiceLocation})
        {    
            # evet var, silmeliyiz
            write-host "`t[EXEC] : Removing Source Cloud Service"
            $sourceService | Remove-AzureService -Force
        }
        Else
        {
            # yok, bulamadik
            write-host "`t[INFO] : Source Cloud Service DNS name not found and not removed"
        }
        write-host "`t[EXEC] : Selecting Destination Subscription $DestSubscription"
        Select-AzureSubscription -SubscriptionName $DestSubscription

        # Restore first VM to the cloud service specifying VNet
        write-host "`t[EXEC] : Restore VM"
        $vmConfig | Set-AzureSubnet $destVNetSubnetName | New-AzureVM -ServiceName $DestServiceName -VNetName $DestVNETName -Location $DestStorageLocation -WaitForBoot

    }
    else
    {
        # Restore VM to the cloud service
        $vmConfig | New-AzureVM -ServiceName $DestServiceName -WaitForBoot
    }

    # Startup VM
    write-host "`t[EXEC] : Startup VM"
    Start-AzureVMAndWait -ServiceName $DestServiceName -VMName $VMName

    #endregion
    #
}
catch
{
    Write-Log "Exception caught while migrating $VMName. Details: $Error"
}

#endregion Script Execution