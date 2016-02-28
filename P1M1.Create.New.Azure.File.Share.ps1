# https://azure.microsoft.com/en-us/documentation/articles/storage-dotnet-how-to-use-files/

Add-AzureAccount

$azureSubscription = Get-AzureSubscription `
    | select subscriptionName, IsDefault, IsCurrent, SubscriptionId, DefaultAccount `
    | Out-GridView -PassThru 
Select-AzureSubscription -SubscriptionId $azureSubscription.subscriptionId
Write-Output "Selected Subscription Name:`t`t" $azureSubscription.SubscriptionName

$storageAccount = Get-AzureStorageAccount `
    | select name,label, location, statusofprimary, statusofsecondary, geosecondarylocation, endpoints `
    | Out-GridView  -PassThru 


$storageAccountName = $storageAccount.label
Write-Output "Storage Account Name:`t`t" $storageAccountName

$storageAccountKey  = $(Get-AzureStorageKey -StorageAccountName $StorageAccountName).Primary

$newShareName = Read-Host -Prompt "Please enter new FILE SHARE name"
$newDirName = Read-Host -Prompt "Please enter new Directory name"



# create a context for account and key
$ctx=New-AzureStorageContext -storageAccountName $storageAccountName -StorageAccountKey $storageAccountKey 

# create a new share
$s = New-AzureStorageShare $newShareName -Context $ctx


if($newDirName -ne "")
{
    # create a directory in the share
    New-AzureStorageDirectory -Share $s -Path $newDirName
}

Write-Host ""
Write-Host "Persist your storage account credentials for the virtual machine (run on target computer)" -ForegroundColor Green
write-output  "cmdkey /add:$storageAccountname.file.core.windows.net /user:$storageAccountName /pass:$storageAccountKey"
Write-Host ""


#>
<#

# Persist your storage account credentials for the virtual machine
cmdkey /add:<storage-account-name>.file.core.windows.net /user:<storage-account-name> /pass:<storage-account-key>

#>

Write-Host ""
Write-Host "Mount the file share using the persisted credentials (run on target computer)" -ForegroundColor Green
write-output  "net use z: \\$storageAccountname.file.core.windows.net\$newShareName"
Write-Host ""


<#

# Mount the file share using the persisted credentials
net use <drive-letter>: \\<storage-account-name>.file.core.windows.net\<share-name>

example :
net use z: \\samples.file.core.windows.net\logs
#>

