break #prevents the entire script from running in case F5 was hit

$wsStaging = "Staging"
$wsName="contoso-web"
$wjPath = "E:\Contoso-WebJob.exe"
$wjName =  "Contoso-WebJob"
New-AzureWebSiteJob -Name $wsName -JobName $wjName -JobType Triggered -Slot $wsStaging -JobFile $wjPath


# To create a Traffic Manager Profile
New-AzureTrafficManagerProfile -Name ContosoTM `
-DomainName contoso-web-tm.trafficmanager.net -LoadBalancingMethod Failover `
-MonitorPort 80 -MonitorProtocol Http -MonitorRelativePath "/" -Ttl 30


# To add an endpoint to the Traffic Manager
$tmProfile = Get-AzureTrafficManagerProfile -Name "ContosoTM"
Add-AzureTrafficManagerEndpoint -TrafficManagerProfile $tmProfile `
    -DomainName "contoso-web-west.azurewebsites.net" -Type AzureWebsite `
    -Status Enabled |
    Set-AzureTrafficManagerEndpoint

#To remove an endpoint from the Traffic Manager profile
$tmProfile = Get-AzureTrafficManagerProfile -Name "ContosoTM"
Remove-AzureTrafficManagerEndpoint -TrafficManagerProfile $tmProfile `
    -DomainName "contoso-web-west.azurewebsites.net" |
    Set-AzureTrafficManagerEndpoint


#To disable an endpoint
$tmProfile = Get-AzureTrafficManagerProfile -Name "ContosoTM"
Set-AzureTrafficManagerEndpoint -TrafficManagerProfile $tmProfile `
    -DomainName "contoso-web-west.azurewebsites.net" -Status Disabled |
    SetAzureTrafficManagerProfile


# Adding Handler mappings. The script below demonsrates adding a handler mapping for *.php files
$wsName = "contoso-web"
$handlerMapping = New-Object Microsoft.WindowsAzure.Commands.Utilities.Websites.Services.WebEntities.HandlerMapping

$handlerMapping.Extension = "*.php"
$handlerMapping.ScriptProcessor = "d:\home\site\wwwroot\bin\php54\php-cgi.exe"

Set-AzureWebsite -Name $wsName -HandlerMappings $handlerMapping


#Objective 1.3: Configure Diagnostics, monitoring, and analytics

# Enable/disable diagnostic logs. The code below enables web server logging and the failed request tracing
$wsName = "contoso-web"
Set-AzureWebsite -Name $wsName -RequestTracingEnabled $true -HttpLoggingEnabled $true

# Download log files. This code will download the log files and store them in E:\Weblogs.zip
# Note: Save-AzureWebsiteLog method does not download the Failed Request logs
$wsName = "contoso-web"
Save-AzureWebsiteLog -Name $wsName -Output e:\Weblogs.zip


# Stream logs directly to the console window. The code below streams web server logs
Get-AzureWebsiteLog -Name "contoso-web-west" -Tail -Path http

# The code below filters the log-streaming output to just application logs that are categorized as errors
Get-AzureWebsitLog -Name "contoso-web-west" -Tail -Message Error

   
# CHAPTER 2 Implement virtual machines
    
#Objective 2.1: Deploy workloads on Azure virtual machines (VMs)

# Using New-AzureQuickVM to create a VM instance
$adminUser = "[admin user name]"
$password = "[admin password]"
$serviceName = "contoso-vms"
$location = "West US"
$size = "Small"
$vmName = "vm1"

$imageFamily = "Windows Server 2012 R2 Datacenter"
$imageName = Get-AzureVMImage | 
                where {$_.ImageFamily -eq $imageFamily } |
                          sort PublishedDate -Descending |
                 select -ExpandProperty ImageName -First 1

New-AzureQuickVM -Windows `
    -ServiceName $serviceName `
    -Name -$vmName `
    -ImageName $imageName `
    -AdminUserName $adminUser `
    -Password $password `
    -Location $location `
    -InstanceSize $size



# Using New-AzureVMConfig and New-AzureVM to create a VM instance
$adminUser = "[admin user name]"
$password = "[admin password]"
$serviceName = "contoso-vms"
$location = "West US"
$size = "Small"
$vmName = "vm2"

$imageFamily = "Windows Server 2012 R2 Datacenter"
$imageName = Get-AzureVMImage | 
                where {$_.ImageFamily -eq $imageFamily } |
                          sort PublishedDate -Descending |
                 select -ExpandProperty ImageName -First 1


NewAzureVMConfig -Name $vmName `
                 -InstanceSize $size
                 -ImageName $imageName |

Add-AzureProvisioningConfig -Windows `
                            -AdminUsername $adminUserName `
                            -Password $password |

Add-AzureDataDisk -CreateNew `
                  -DiskSizeInGB 10 `
                  -LUN 0 `
                  -DiskLabel "data" |
                  
                  
Add-AzureEndpoint -Name "SQL" `
                  -Protocol tcp `
                  -LocalPort 1433 `
                  -PublicPort 1433 |

New-AzureVM -ServiceName $serviceName `
            -Location $location   


# Creating VM using Operating System Disk
$adminUser = "[admin user name]"
$password = "[admin password]"
$serviceName = "contoso-vms"
$location = "West US"
$size = "Small"
$vmName = "vm3"
$diskName = "WinOSDisk" #assumes this OS disk is already created in the subscription

New-AzureVMConfig -Name $vmName `
                  -InstanceSize $size `
                  -DiskName $diskName |

Add-AzureEndpoint -Name "RDP" `
                  -Protocol tcp `
                  -LocalPort 3389 `
                  -PublicPort 3389 |

New-AzureVM -ServiceName $serviceName -Location $location


# To view the available operating system disks
Get-AzureDisk |
    where { $_.OS -eq "Windows" -and $_.AttachedTo -eq $null} |
            select DiskName


# To get available sizes for virtual machines
Get-AzureRoleSize -InstanceSize A5 # this one returns only for A5

# To select the correct subscription use
Select-AzureSubscription 


# To validate the availability domain name (cloud service)
$serviceName = "contoso-vms"
Test-AzureName -Service -Name $serviceName # True means name already exists


# To set a default storage account
Set-AzureSubscription -SubscriptionName $subscriptionName `     # must be specified
                      CurrentStorageAccountName $storageAccount # must be specified
                                                         
                                                         


# Overriding virtual hard disk locations
$adminUser = "[admin user name]"
$password = "[admin password]"
$serviceName = "contoso-vms"
$location = "West US"
$size = "Small"
$vmName = "customdisks"

$imageFamily = "Windows Server 2012 R2 Datacenter"
$imageName = Get-AzureVMImage | 
                where {$_.ImageFamily -eq $imageFamily } |
                          sort PublishedDate -Descending |
                 select -ExpandProperty ImageName -First 1

$storage = "examref1"
$osDisk = "https://$storage.blob.core.windows.net/disks/os.vhd"
$data1 = "https://$storage.blob.core.windows.net/disks/data1.vhd"
$data2 = "https://$storage.blob.core.windows.net/disks/data2.vhd"


NewAzureVMConfig -ImageName $imageName `
                 -MediaLocation $osDisk `
                 -InstanceSize $size `
                 -Name $vmName |

Add-AzureProvisioningConfig -Windows `
                            -AdminUsername $adminUserName `
                            -Password $password |

Add-AzureDataDisk -CreateNew `
                  -MediaLocation $data1 `
                  -LUN 0 `
                  -DiskLabel "data 1" |


Add-AzureDataDisk -CreateNew `
                  -MediaLocation $data2 `
                  -LUN 0 `
                  -DiskLabel "data 2" |
                  
New-AzureVM -ServiceName $serviceName `
            -Location $location                                                            


# To generate a SSH certificate using openssl.exe
openssl.exe req -x509 -nodes -days 365 -newkey rsa:2048 -keyout
myPrivateKey.key -out
myCert.pem

# To create an empty cloud service
New-AzureService -ServiceName $serviceName -Location $location


# To install the certificate created in the previous step
$certPath = "C:\MyCerts\myCert.pem"
$cert = Get-PfxCertificate -FilePath $certPath
Add-AzureCertificate -CertToDeploy $cert `
                     -ServiceName $serviceName

# After the certificate is uploaded, pass the configuration information to Azure
# so that the certificate will be deployed correctly on the Linux virtual machine
$sshKey = New-AzureSSHKey -PublicKey -Fingerprint $cert.Thumbprint `
                          -Path "/home/$linuxUser/.ssh/authorized_keys"


# Pass the $sshKey to the Add-AzureProvisioiningConfig cmdlet
Add-AzureProvisioningConfig -SSHPublicKeys $sshKey # and other params



# Complete example to provision an Linux VM
$location = "West US"
$serviceName = "contosolinux1"
$vmName = "linuxvm1"
$size = "Small"
$adminUser = "[admin user name]"
$password = "[admin password]"

$imageFamily = "Ubuntu Server 14.10 DAILY"
$imageName = Get-AzureVMImage |
                where { $_.ImageFamily -eq $imageFamily } |
                           sort PublishedDate -Descending |
                  select -ExpandProperty ImageName -First 1

$certPath = "$PSScriptRoot\MyCert.pem"

New-AzureService -ServiceName $serviceName `
                 -Location $location


$cert = Get-PfxCertificate -FilePath $certPath

Add-AzureCertficate -CertToDeploy $certPath `
                    -ServiceName $serviceName

$sshKey = New-AzureSSHKey -PublicKey -Fingerprint $cert.Thumbprint
                          -Path "/home/$linuxUser/.ssh/authorized_keys"


New-AzureVMConfig -Name $vmName `
                            -InstanceSize $size `
                            -ImageName $imageName |

Add-AzureProvisioningConfig -Linux `
                            -AdminUserName $adminUser `
                            -Password $password `
                            -SSHPublicKeys $sshKey |

New-AzureVM -ServiceName $serviceName


# To disable automatic updates 
Add-AzureProvisioningConfig -DisableAutomaticUpdates # (oteher parameters)


# To set the time-zone
Add-AzureProvisioningConfig -TimeZone "Tokyo Standard Time" # (other parameters)


# To deploy a certificate to VM
$pfxName = Join-Path $PSScriptRoot "ssl-certificate.pfx"
$cert = New-Object System.Cryptography.X509Certificates.X509Certificate2
$cert.Import($pfxName, $certPassword, 'Explorable')

Add-AzureProvisioningConfig -X509Certificates $cert


# To reset password at first logon on Windows VM
Add-AzureProvisioningConfig -ResetPasswordOnFirstLogon # (other params)

# To stop a VM
Stop-AzureVM -ServicenName $serviceName -Name $vmName # this command will put the VM in StoppedDeallocated state

# To stop a VM (avoding the prompt)
Get-AzureVM -ServiceName $serviceName | Stop-AzureVM -Force

# To start a VM
Start-AzureVM -ServiceName $serviceName -Name $vmName

# To delete a VM (retaining the underlying disks)
Remove-AzureVM -ServiceName $serviceName -Name $vmName # use the DeleteVHD parameter to delete underlying disks)


# To delete a cloud service (removes all of the VMs in the service)
Remove-AzureService -ServiceName $serviceName -Name $vmName -Force -DeleteAll # (DeleteAll deletes all underlying disks for all the VMs)

# To launch Remote Desktop Client
Get-AzureRemoteDesktopFile -ServiceName $serviceName -Name $vmName -Launch

# To save the .rdp file locally
Get-AzureRemoteDesktopFile -SericeName $serviceName -Name $vmName -LocaPath $path


# To generate a connection string to VM 
$uri = Get-AzureWinRMUri -ServiceName -$serviceName -Name -$vmName

# To start a remote Windows PowerShell session use the connection uri from above
$credentials = Get-Credentials
Enter-PSSession -ConnectionUri $uri -Credential $credentials
























