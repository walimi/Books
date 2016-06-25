﻿# Chapter 4: Implement Storage

# Objective 4.1: Implement blobs and Azure files

# To create a storage container
New-AzureStorageContainer -Name "newcontainer" `
                          -Permission Off 
                          
# To set the tier while creating the storage account
$accountName = "[storage account name]"
$location = "West US"
$type = "Standard_LRS"
New-AzureStorageAccount -StorageAccountName $accountName `
                        -Location $location `
                        -Type $type
                        
# To set the tier after storage account has been created
$type = "Standard_RAGRS"
Set-AzureStorageAccount -StorageAccountName $accountName `
                        -Type $type
                        
# Using the async blob copy service

$blobCopyState = Start-AzureStorageBlobCopy -SrcBlob $vhdName `
                                            -SrcContainer $srcContainer `
                                            -Context $srcContext ` # Created by New-AzureStorageContext cmdlet. It has the storage account name and key.
                                            -DestContainer $destContainer `
                                            -DestBlob $vhdName `
                                            -DestContext $destContext

# Here is a complete example of how to use the Start-AzureStorageBlobCopy cmdlet to copy
# a blob between two storage accounts

$vhdName = "[file name]"
$srcContainer = "[source container]"
$destContainer = "[destination container]"
$srcStorageAccount = "[source storage]"
$destStorageAccount = "[destination storage]"

$srcStorageKey = (Get-AzureStorageKey -StorageAccountName $srcStorageAccount).Primary
$destStorageKey = (Get-AzureStorageKey -StorageAccountName $destStorageAccount).Primary

$srcContext = New-AzureStorageContext -StorageAccountName $srcStorageAccount `
                                      -StorageAccountKey $srcStoragekey
                                      
$destContext = New-AzureStorageContext -StorageAccountName $destStorageAccount `
                                       -StorageAccountKey $destStorageKey
                                       
New-AzureStorageContainer -Name $destContainer `
                          -Context $destContext
                          
$copiedBlob = Start-AzureStorageBlobCopy -SrcBlob $vhdName `
                                         -SrcContainer $srcContainer `
                                         -Context $srcContext `
                                         -DestContainer $destContainer `
                                         -DestBlob $vhdName `
                                         -DestContext $destComtext   
                                         
# The following returns the CopyId, Status, Source, BytesCopied, CompletionTime, StatusDescription, and TotalBytes
$copiedBlob | Get-AzureStorageBlobCopyState                                                                                                                                                  
        
        
# Configuring and using Azure files

# To create a share
$storageAccount = "[storage account name]"
$shareName = "contosoweb"
$storageKey = (Get-AzureStorageKey -StorageAccountName $storageAccount).Primary
$ctx = New-AzureStorageContext -StorageAccountName $storageAccount `
                               -StorageAccountKey $storageKey
                               
                                        
New-AzureStorageShare -Name $shareName -Context $ctx


# To access a share created in Azure file, you should store the storage account name and key
# using the cmdkey.exe utility
cmdkey.exe /add:[stroage account name].file.core.windows.net /user:[storage account name] /pass:[storage account key]


# After the credentials are stored, use the net use command to map a drive to the file share
net use z: \\examref1.file.core.windows.net\contosoweb

# Using the Import and Export Service

# To prepare the drive for import use the following MS Azure Import/Export tool (WAImportExport.exe)
WAImportExport PrepImport /sk:<StorageAccountKey> /t:<TargetDriveLetter> [/format] [/silentmode] [/encrypt] [/bk:<BitLockerKey>] [/logdir:<LogDirectory>]
/j:[JournalFile] /id:<SessionId> /srcdir:<source directory> /dstdir:<DestinationBlob Virtual Directory> /Disposition:<Disposition> [/BlobType:<BlockBlob|PageBlob>]
[/PropertyFile:<PropertyFile>] [/MetadataFile:<Metadatafile>]


# Implementing Content Delivery Network

# The example below shows how you can use the Set-AzureStorageBlobContent to upload a set of files (blobs) to a storage account
$storageAccount = "[storage account name]"
$storageKey = (Get-AzureStorageKey -StorageAccountName $storageAccount).Primary
$context = New-AzureStorageContext -StorageAccountName $storageAccount `
                                   -StorageAccountKey $storageKey
                                   
$filesPath = "C:\CDNContent"
$container =  "cdncontent"
New-AzureStorageContainer -Name $container `
                          -Context $context `
                          -Permission Blob
                          
                          
Get-ChildItem $filePath | foreach {
    $contentType = "img/png"
    $cacheControl = "public, max-age=86400"
    $blobProperties = @{ContentType=$contentType; CacheControl=$cacheControl}

    Set-AzureStorageBlobContent -File $_.FullName `
                                -Container $container `
                                -Context $context `
                                -Properties $blobProperties 
}                                                                                                 
                                    

# Object 4.2: Manage access

# Creating and using Shared Access Signatures (SAS)

# The following example shows how to create a SAS URI

Add-AzureAccount
Select-AzureSubscription -SubscriptionName "Pay-As-You-Go" –Default

$account = "wahidstorage1"
$key = (Get-AzureStorageKey -StorageAccountName $account).Primary
$context = New-AzureStorageContext -StorageAccountName $account `
                                   -StorageAccountKey $key `
$startTime = Get-Date 
$endTime = $startTime.AddHours(4)
New-AzureStorageBlobSASToken -Container "media" `
                             -Blob "Ch01.pptx" `
                             -Permission "rwd" `
                             -StartTime $startTime `
                             -ExpiryTime $endTime `
                             -Context $context


# Objective 4.3: Configure Diagnostics, monitoring, and analytics

# Configuring Azure Storage Diagnostics

# In the following example, the Set-AzureStorageMetricsProperty cmdlet enables hourly
# storage metrics on the blob service with a retention period of 30 days and at the
# ServiceAndApi level. The next call is to the Set-AzureStorageServiceLoggingProperty
# cmdlet, which is also configuring the blob service and 30-day retention period but 
# is only logging delete operations.

$account = "[storage account name]"
$key = (Get-AzureStorageKey -StorageAccountName $account).Primary
$context = New-AzureStorageContext -StorageAccountName $account `
                                   -StorageAccountKey $key
                                   
Set-AzureStorageServiceMetricsProperty -ServiceType Blob `
                                       -MetricsType Hour `
                                       -RetentionDays 30 `
                                       -MetricsLevel ServiceAndApi `
                                       -Context $context
                                       
Set-AzureStorageServiceLoggingProperty -ServiceType Blob `
                                       -RetentionDays 30 `
                                       -LoggingOperations Delete `
                                       -Context $context                                                                              

# Objective 4.4: Implement SQL Databases

# Implementing Point-in-time recovery

# The following example enumerates all the recoverable databases from a specified SQL Database server
Get-AzureSqlRecoverableDatabase -ServerName $sqlServer

# The following example shows how you can use the Start-AzureSqlDatabaseRestore cmdlet to recover
# a database to a specified point-in-time. 
$recoveryPoint = "Sunday, November 30, 2014, 4:55 00 pm"
$sqlServer = "examrefdbsrv"
$sourceSqlDB = "ExamRefDB1"
$targetSqlDB = "ExamRefDBRestored"

$op = Start-AzureSqlDatabaseRestore -SourceServerName $sqlServer `
                                    -SourceDatabaseName $sourceSqlDB `  
                                    -PointInTime $recoveryPoint `
                                    -TargetServerName $sqlServer `
                                    -TargetDatabasName $targetSqlDB

# The operation can be monitored by passing the RequestID property of the returned operation
# object to the Get-AzureSqlDatabaseOperation cmdlet
$ctx = New-AzureSqlDatabaseServerContext -ServerName $sqlServer `
                                         -UseSubscription
Get-AzureSqlDatabaseOperation -ConnectionContext $ctx `
                              -OperationGuid $op.RequestID


# Implementing Geo-replication

# Standard geo-replication

# The following example shows how to create a secondary database for geo-replication
$sqlPrimaryServer = "[primary server name]"
$sqlSecondaryServer = "[secondary server name]" # this database server must already exist
$sqlDB = "[database name]"
Start-AzureSqlDatabaseCopy -ServerName $sqlPrimaryServer `
                           -DatabaseName $sqlDB `
                           -PartnerServer $sqlSecondaryServer `
                           -ContinousCopy `
                           -OfflineSecondary

# To break the continous copy relationship use the Stop-AzureSqlDatabaseCopy cmdlet
# Note: With standard geo-replication you must specify the ForcedTermination parameter because
# planned termination is only supported with active geo-replication. 
Stop-AzureSqlDatabaseCopy -ServerName $sqlPrimaryServer `
                          -PartnerServer $sqlSecondaryServer `
                          -DatabaseName $sqlDB `
                          -ForcedTermination

# Active geo-replication

# To add a secondary database replica use the Start-AzureSqlDatabaseCopy cmdlet. To make the
# database online with read-only access, omit the OfflineSecondary parameter. 
$sqlPrimaryServer = "[primary server name]"
$sqlSecondaryServer = "[secondary server name]" # this database server must already exist
$sqlDB = "[database name]"
Start-AzureSqlDatabaseCopy -ServerName $sqlPrimaryServer `
                           -DatabaseName $sqlDB `
                           -PartnerServer $sqlSecondaryServer `
                           -ContinousCopy 

# Just like standard geo-replication, you can use the Stop-AzureSqlDatabaseCopy cmdlet to 
# break the continous copy relationship with the primary database in active geo-replication. 
# However, activea geo-replication does support planned termination so you do not have to 
# specify the ForcedTermination parameter unless needed. 
Stop-AzureSqlDatabaseCopy -ServerName $sqlPrimaryServer `
                          -PartnerServer $sqlSecondaryServer `
                          -DatabaseName $sqlDB



                      





                                            
                                            
                                                                                                                   