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
                      -CurrentStorageAccountName $storageAccount # must be specified
                                                         
                                                         


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


# Objective 2.2: Implement images and disks

# How to upload a virtual hard disk file to an Azure Storage account

$storage = "[storage account name]"
$storagePath = "https://$storage.blob.core.windows.net/uploads/myosdisk.vhd"
$sourcePath = "C:\mydisks\myosdisk.vhd"

Add-AzureVhd -Destination $storagePath `
             -LocalFilePath $sourcePath

# Downloading VM using Save-AzureVHD
Save-AzureVHD -Source $storagePath
              -LocalFilePath $localPath

# To create a generic image
Save-AzureVMImage -ServiceName $serviceName `
                  -Name $vmName `
                  -ImageName  $imageName `
                  -ImageLabel $imageLabel `
                  -OSState Generalized

# To create a specialized image
Save-AzureVMImage -ServiceName $serviceName `
                  -Name $vmName `
                  -ImageName  $imageName `
                  -ImageLabel $imageLabel `
                  -OSState Specialized

# To create a legacy operating system image (simply omit the OSState param)
Save-AzureVMImage -ServiceName $serviceName `
                  -Name $vmName `
                  -ImageName  $imageName `
                  -ImageLabel $imageLabel `

# To change the configuration of a captured image.
#      The following code changes the HostCache setting and the label
#      of an existing data disk
$diskName = "[data disk name]"
$imageName = "[image name]"
$imageLabel = "[new image label]"

$imgCtx = Get-AzureVMImage $imageName
$config = Get-AzureVMImageDiskConfigSet -ImageContext $imgCtx

Set-AzureVMImageDataDiskConfig -DataDiskName $diskName `
                               -HostCaching ReadWrite `
                               -DiskConfig $config
                 
Update-AzureVMImage -ImageName $diskName `
                    -Label $imageLabel `
                    -DiskConfig $config


# To associate a virtual hard disk (.vhd) file as a disk (not an image)
#       The following code registers the disk named MyOSDisk with the VHD file  
$storage = "[storage account name]"
$storagePath = "https://$storage.blob.core.windows.net/uploads/myosdisk.vhd"
$diskName = "MyOSDisk"
$label = "MyOSDisk"
Add-AzureDisk -DiskName $diskName -Label $label -MediaLocation $storagePath -OS Windows

# To create a data disk you would just omit the OS parameter
$storage = "[storage account name]"
$storagePath = "https://$storage.blob.core.windows.net/uploads/mydatadisk.vhd"
$diskName = "MyDataDisk"
$label = "MyDataDisk"
Add-AzureDisk -DiskName $diskName -Label $label -MediaLocation $storagePath



# To associate a Linux-based image
$storage = "[storage account name]"
$storagePath = "https://$storagePath.blob.core.windows.net/uploads/myosimage.vhd"
$imageName = "MyGeneralizedImage"
$label = "MyGeneralizedImage"
Add-AzureVMImage -ImageName $imageName `
                 -MediaLocation $storagePath `
                 -OS Linux


# To create a VM with 10GB data disk already attached when VM is provisioned
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
                  
                  
New-AzureVM -ServiceName $serviceName `
            -Location $location  

# To attach a second data disk on the virtual machine
$serviceName = "contoso-vms"
$vmName = "vm1"
Get-AzureVM -ServiceName $serviceName -Name $vmName |
Add-AzureDataDisk -CreateNew `
                  -DiskSizeInGB 500 `
                  -LUN 1 `
                  -DiskLabel "data 2" |
Update-AzureVM

# To view the data disk configureation of your VM
Get-AzureVM -ServiceName $serviceName -Name $vmName | Get-AzureDataDisk  


# To reference an existing data disk use the Import parameter
#      This code assumes the disk is already assocaited with the VM
Add-AzureDataDisk -Import -DiskName "mydatadisk" -LUN 1

# If the VHD file was not associated 
$storagePath = "https://$storage.blob.core.windows.net/uploads/mydatadisk.vhd"
Add-AzureDataDisk -ImportFrom `
                  -DiskLabel "Data 2" `
                  -MediaLocation $storagePath
                  -LUN 1  
# To delete a VM image and the associated .vhd file
Remove-AzureVMImage -ImageName "MyGeneralizedImage" -DeleteVHD

# To delete a disk and the associated .vhd file
Remove-AzureDisk -DiskName "mydatadisk" -DeleteVHD

#--------------------------------------------------------------------------------------------
# Objective 2.3: Perform Configuration Management

# Using the Custom Script Extension

# The following script deploys the Active Directory Domain Services role. It accepts two parameters:
# one is for the domain name and the other is for the administrator password
param (
    $domain, 
    $password
)

$smPassword = (ConvertTo-SecureString $password -AsPlainText -Force)

Install-WindowsFeature -Name "AD-Domain-Services" `
                       -IncludeManagementTools `
                       -IncludeAllSubFeature
                       
                       
Install-ADDSForest -DomainName $domain `
                   -DomainMode Win2012 `
                   -ForestMode Win2012 `
                   -Force `
                   -SafeModeAdministratorPassword $smPassword

# The followig code executes the Set-AzureVMCustomScriptExtension during provisioning time
$scriptName = "install-active-directory.ps1"
$scriptUri = http://$storageAccount.blob.core.windows.net/scripts/$scriptName
$scriptArgument = "fabrikam.com $password"
$imageFamily = "Windows Server 2012 R2 Datacenter"
$imageName = Get-AzureVMImage |
                where { $_.ImageFamily -eq $imageFamily } |
                           sort PublishedDate -Descending |
                  select -ExpandProperty ImageName -First 1

New-AzureVMConfig -Name $vmName `
                  -InstanceSize $size `
                  -ImageName $imageName |
                  
                  
Add-AzureProvisioningConfig -Windnows `
                            -AdminUsername $adminUser `
                            -Password -$password |

Set-AzureSubnet -SubnetNames $subnet |
Set-AzureStaticVNetIP -IPAddress $ipAddress |
Set-AzureVMCustomScriptExtension -FileUri $scriptUri `
                                 -Run $scriptName `
                                 -Argument "$domain $password" |

New-AzureVM -ServiceName $serviceName `
            -Location $location
            -VNetName $vnetName                                     


# To run a custom extension script after the VM is configured
Get-AzureVM -ServiceName $serviceName -Name $vmName |
Set-AzureVMCustomScriptExtension -FileUri $scriptUri `
                                 -Run $scriptName `
                                 -Argument "$domain $password" |
Update-AzureVM                                                                                                                      


# Implementing Windows PowerShell Desired State Configuration


# The following DSC script declares that the Web-Server role should be intsalled
# along with the Web-Asp-Net45 feature. The Windows Feature code represents a 
# DSC resource.
Configuration ContosoSimple
{
    Node "localhost"
    {
        #Install the IIS role
        WindowsFeature IIS
        {
            Ensure = "Present"
            Name = "Web-Server"
        }
        
        #Install ASP.NET 4.5
        WindowsFeature AspNet45
        {
            Ensure = "Present"
            Name = "Web-Asp-Net45"
        }
    }
}

# The following example uses a downloadable resource xWebAdministration to create a new IIS
# website, stop the default website, and deploy an application from a file share to the 
# destination website folder.

Configuration ContosoAdvanced
{
    # Import the module that defines custom resources
    # Import-DscResource -Module xWebAdministration 
    # (uncomment the above line after downloading the
    # xWebAdministration module from https://gallery.technet.microsoft.com/scriptcenter
    # and storing it into the C:\Program Files\WindowsPowerShell\Modules folder)                                                                        
    
    Node "localhost"
    {
        # Install the IIS role
        WindowsFeature IIS 
        {
            Ensure = "Present"
            Name = "Web-Server"
        }

        # Install the ASP.NET 4.5 role
        WindowsFeature AspNet45
        {
            Ensure = "Present"
            Name = " Web-Asp-Net45"
        }

        # Stop existing website
        xWebsite DefaultSite
        {
            Ensure = "Present"
            Name = "Default Web Site"
            State = "Stopped"
            PhysicalPath = "C:\inetpub\wwwroot"
            DependsOn = "[WindowsFeature]IIS"
        }

        # Copy the website content
        File WebContent
        {
            Ensure = "Present"
            SourcePath = "\\vmconfig\share\app"
            DestinationPath = "C:\inetpub\contoso"
            Recurse = $true
            Type = "Directory"
            DependsOn = "[WindowsFeature]AspNet45"
        }

        # Create a new website
        xWebsite Fabrikam
        {
            Ensure = "Present"
            Name = "Contoso Advanced"
            State = "Started"
            PhysicalPath = "C:\inetpub\contoso"
            DependsOn="[File]WebContent"
        }
    }
}

# To publish the DSC configuration (including the resources)
Publish-AzureVMDscConfiguration .\ContosoAdvanced.ps1 # (i.e., the above script)

# To see the .zip file created by the above cmdlet
$dscFileName = "ContosoAdvanced.ps1.zip" # refer to the book for filename
Publish-AzureVMDscConfiguration .\ContosoAdvancedps1 `
                               -ConfigurationArchivePath $dscFileName

# To upload the generaeted .zip file directly. If the .zip file already exists in the
# storage account, use the Force parameter to overwrite
Publish-AzureVMDscConfiguraiton $dscFileName -Force


# To specify an alternative storage account
$storageAccount = "[storage account name]"
$storageKey = (Get-AzureStorageKey -StorageAccountName $storageAccount).Primary
$ctx = New-AzureStorageContext -StorageAccountName $storageAccount `
                               -StorageAccountKey $storageKey

Publish-AzureVMDscConfiguration -ConfigurationPath ".\ContosoAdvanced.ps1" `
                                -StorageContext $ctx 
                                
                                
# After the configuraiton is published it be can applied to any virtual machine at 
# provisioning time or afte the fact using the Set-AzureVMDscExtension cmdlet.
$configArchive = "ContosoAdvanced.ps1.zip"
$configName = "ContosoAdvanced"

$imageFamily = "Windows Server 2012 R2 Datacenter"
$imageName = Get-AzureVMImage |
                where { $_.ImageFamily -eq $imageFamily } |
                           sort PublishedDate -Descending |
                  select -ExpandProperty ImageName -First 1                                                               


New-AzureVMConfig -Name $vmName `
                  -InstanceSize $size `
                  -ImageName $imageName |


Add-AzureProvisioningConfig -Windnows `
                            -AdminUsername $adminUser `
                            -Password -$password |

Set-AzureSubnet -SubnetNames $subnet |
Set-AzureVMDscExtension -ConfigurationArchive $configArchive `
                        -ConfigurationName $configName |
New-AzureVM -ServiceName $serviceName `
            -Location $location
            -VNetName $vnetName                                     


# To apply the DSC configuration to an existing VM
$configArchive = "Contoso.ps1.zip"
$configName = "ContosoAdvanced"
Get-AzureVM -ServiceName $serviceName -Name $vmName |
Set-AzureVMDscExtension -ConfigurationArchive $configArchive `
                        -ConfigurationName $configName |
Update-AzureVM

# To make the previous example flexible enough to deploy any web application with the same
# dependencies, you could move some of the parameters to a Windows PowerShell data file 
# (file with a .psd1 extension) and create a hashtable

# ContosoConfig.psd1
@{
    AllNodes = @(
        @{
            NodeName = "localhost"
            WebsiteName = "ContosoWebApp"
            SourcePath = "\\vmconfig\share\app"
            DestinationPath = "C:\inetpub\contoso"
        }
    );
}


# The following code references the variable names inline using the $Node.[Variable] name syntax.
Configuration WebSiteConfig
{
    # Import the module that defines custom resources
    # Import-DscResource -Module xWebAdministration 
    # (uncomment the above line after downloading the
    # xWebAdministration module from https://gallery.technet.microsoft.com/scriptcenter
    # and storing it into the C:\Program Files\WindowsPowerShell\Modules folder)                                                                        
    
    Node $Node.NodeName
    {
        # Install the IIS role
        WindowsFeature IIS 
        {
            Ensure = "Present"
            Name = "Web-Server"
        }

        # Install the ASP.NET 4.5 role
        WindowsFeature AspNet45
        {
            Ensure = "Present"
            Name = " Web-Asp-Net45"
        }

        # Stop existing website
        xWebsite DefaultSite
        {
            Ensure = "Present"
            Name = "Default Web Site"
            State = "Stopped"
            PhysicalPath = "C:\inetpub\wwwroot"
            DependsOn = "[WindowsFeature]IIS"
        }

        # Copy the website content
        File WebContent
        {
            Ensure = "Present"
            SourcePath = $Node.SourcePath
            DestinationPath = $Node.DestinationPath
            Recurse = $true
            Type = "Directory"
            DependsOn = "[WindowsFeature]AspNet45"
        }

        # Create a new website
        xWebsite Fabrikam
        {
            Ensure = "Present"
            Name = $Node.WebsiteName
            State = "Started"
            PhysicalPath = "C:\inetpub\contoso"
            DependsOn="[File]WebContent"
        }
    }
}


# Because the script configuraiton has changed, the Publish-VMDscConfiguration cmdlet
# is used to publish the configuration.
Publish-AzureVMDscConfiguration .\DeployWebApp.ps1


# The followign example uses the ConfigurationDataPath parameter to specify the ContosoConfig.psd1 file
# which contains application-specific deployment information.
$configArchive = "DeployWebApp.ps1.zip"
$configName = "WebsiteConfig"

Get-AzureVM -ServiceName $serviceName -Name $vmName |
SetAzureVMDscExtension -ConfigurationArchive $configArchive `
                       -ConfigurationName $configName `
                       -ConfigurationDataPath .\ContosoConfig.psd1 |
Update-AzureVM  


# To view the current DSC extension configuration
Get-AzureVM -ServiceName $serviceName -Name $vmName | Get-AzureVMDscExtension


# To remove the DSC extension from the VM
Get-AzureVM -ServiceName $serviceName -Name $vmName |
Remove-AzueVMDscExtension |
Update-AzureVM

$config = Get-AzureVM -ServiceName $serviceName -Name $vmName
$config | Remove-AzureVMDscExtension
$config | Update-AzureVM


# The configuration could be passed on using the VM parameter like this:
Remove-AzureVMDscExtension -VM $config

# Using the Virtual Machine Acccess Extension
# This cmdlet can be used to reset the local administrator name, password and also 
# enable Remote Desktop access if it is accidentaly disabled.
Get-AzureVM -ServiceName $serviceName -Name $vmName |
Set-AzureVMAccessExtension -UserName $userName -Password $password |
Update-AzureVM


# Enabling the Puppet virtual machine extension
$puppetServer = "puppetmaster.cloudapp.net"
$imageFamily = "Windows Server 2012 R2 Datacenter"
$imageName = Get-AzureVMImage |
                where { $_.ImageFamily -eq $imageFamily  } |
                            sort PublishedDate -Descending |
                   select -ExpandProperty ImageName -First 1

New-AzureVMConfig -Name $vmName `
                  -InstanceSize $size `
                  -ImageName $imageName |

Add-ProvisioningConfig -Windows `
                       -AdminUserName $adminUser `
                       -Password $password |

Set-AzureVMPuppetExtension -PuppetMasterServer $puppetServer |

New-AzureVM -ServiceName $serviceName `
            -Location $location
                               
# To enable Puppet extension on a provisioned machine
$puppetServer = "puppetmaster.cloudapp.net"
Get-AzureVM -ServiceName $serviceName -Name $vmName |
Set-AzureVMPuppetExtension -PuppetMasterServer $puppetServer |
Update-AzureVM


# Enabling Chef Virtual machine extension
# The Chef does not currently have a specific Azure PowerShell extension cmdlet. 

# Extensions without cmdlets
# To get list of extensions 
Get-AzureVMAvailableExtension | Out-GridView


#--------------------------------------------------------------------------------
# Objective 2.4: Configure VM Networking

# Configuring Endpoints

# To create a port forwarded endpoint
Get-AzureVM -ServiceName $serviceName -Name $vmName |
Add-AzureEndpoint -Name "SQL" `
                  -Protocol tcp `
                  -LocalPort 1433 `
                  -PublicPort 1433 |
Update-AzureVM


# To modify a port forwarded endpoint after it's been created
Get-AzureVM -ServiceName $serviceName -Name $vmName |
Set-AzureEndpoint -Name "SQL" `
                  -Protocol tcp `
                  -LocalPort 1433 `
                  -PublicPort 2000 |
Update-AzureVM


# To remove an endpoint
Get-AzureVM -ServiceName $serviceName -Name $vmName |
Remove-AzureEndpoint -Name "SQL" |
Update-AzureVM

# This example shows adding a load-balanced endpoint with a TCP probe
$config | Add-AzureEndpoint -Name "WEB" `
                            -Protocol tcp `
                            -LocalPort 80 `
                            -PublicPort 80 `
                            -LBSetName "LBWEB" `
                            -ProbeProtocol tcp `
                            -ProbePort 80
  
# To set the probe on an existing load balanced endpoint
Set-AzureLoadBalancedEndpoint -ServiceName $serviceName `
                              -LBSetName "LBWEB" `
                              -ProbeProtocolHTTP `
                              -ProbePort 80 `
                              -ProbePath "/healthcheck.aspx"


# To specify an access control list
$permitSubnet1 = "[remote admin IP 1]/32"
$permitSubnet2 = "[remote admin IP 1]/32"
$acl = New-AzureAclConfig
Set-AzureAclConfig -ACL $acl `
                   -AddRule Permit `
                   -RemoteSubnet $permitSubnet1 `
                   -Order 1 `
                   -Description "remote admin 1"
                                                          
Set-AzureAclConfig -ACL $acl `
                   -AddRule Permit `
                   -RemoteSubnet $permitSubnet2 `
                   -Order 2 `
                   -Description "remote admin 2"

Get-AzureVM -ServiceName $serviceName -Name $vmName |
Set-AzureEndpoint -Name "PowerShell" -ACL $acl |
UpdateAzureVM
                                                 
                                
# Configuring reserved IP addresses
# To create a new reserved IP 
$reservedIPName = "WebFarm"
$label = "IP for Webfarm"
$location = "West US"
New-AzureReservedIP -ReservedIPName $reservedIPName `
                    -Label $label `
                    -Location $location

# After the reserved IP has been created, you can associate it with the cloud service
# hosting your VM at creation time. You can use either command
New-AzureQuickVM -ReservedIPName $reservedIPName # (other params)
New-AzureVM -ReservedIPName $reservedIPName # (other params)


# You can use the Get-AzureReservedIP to enumarate list of available reserved IP addresses
# This command also accepts the

# To delete a reserved ip address use the Remove-AzureReservedIP. 


# Configuring public IP addresses

# This example shows how to add a new public IP address named PassiveFTP to an existing VM
Get-AzureVM -ServiceName $serviceName -Name $vmName |
Set-AzurePublicIP -PublicIPName "PassiveFTP" |
Update-AzureVM

# To extract the new public IP address
Get-AzureVM -ServiceName $serviceName -Name $vmName | Get-AzurePublicIP

# To remove public IP
Get-AzureVM -ServiceName $serviceName -Name $vmName |
Remove-AzurePublicIP -PublicName "PassiveFTP" |
Update-AzureVM


#-------------------------------------------------------------------------------------------
# Objective 2.5: Configure VM for Resiliency

# Configuring avaialability sets

# To add an existing VM to an availability set
Get-AzureVM -ServiceName $serviceName -Name $vmName |
Set-AzureAvailabilitySet WebACVSet |
Update-AzureVM

# Scaling a machine up or down

# To change the size of a virtual machine
$newSize = "A9"
Get-AzureVm -ServiceName $serviceName -Name $vmName |
Set-AzureVMSize -InstanceSize $newSize |
Update-AzureVM










