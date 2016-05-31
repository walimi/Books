# Chapter 3: Implement Cloud Services


# Objective 3.1: Configure Cloud Services and Roles

# Configuring role instance count

# To find out how many cores are being used and what the core capacity is for a subscription.
Get-AzureSubscription -Current -ExtendedDetails `
                      | Select CurrentCoreCount, MaxCoreCount `
                      | Format-List
                      
# Configuring role instance count for a cloud service using Azure PowerShell

# To set the instance count for a role in an existing cloud service
$csName = "Contosocloudservice"
$csRole = "Demo.WebRole"
$roleCount = 4
Set-AzureRole -ServiceName $csName -RoleName $csRole -Slot Staging -Count $roleCount                        

# Configuring role operating system settings

# The available options for osVersion can be identified using
Get-AzureOSVersion | Format-Table Family, FamilyLabel, Version



# Configuring a custom domain

# To find the site URL
$csName = "ContosoCloudService"
Get-AzureDeployment -ServiceName $csName -Slot Production | Select Url

# To find the public virtual IP (VIP)
Get-AzureVM -ServiceName $csName | Get-AzureEndpoint | Select Vip


# Configuring SSL

# To add a certificate to a cloud service environment
$cert = Get-Item E:\contoso-cs-ssl.pfx
$certPwd = "[YOUR PASSWORD]"
$csName = "ContosoCloudService"
Add-AzureCertificate -ServiceName $csName -CertToDeploy $cert -Password $certPwd


# Configuring a reserved IP address

# Reserving an IP address

# To reserve an IP address 
New-AzureReservedIP -ReservedIPName "contosocloudserviceip" -Location "East US"

# To retrieve the IP addressess reserved in a subscription
Get-AzureReservedIP | Select ReservedIPName, Address


# To remove a reserved IP address
Remove-AzureReservedIP -ReservedIPName "contosocloudserviceip" -Force


# Configuring role instance size

# To determine role instance sizes that are available
Get-AzureRoleSize `
    | where { $_.SupportedByWebWorkerRoles -eq $true } `
    | Select InstanceSize, Cores, MemoryInMb, WebWorkerResourceDiskSizeInMb    

# To apply the following filters:
#      - At least 3 cores
#      - At least 48GB of memory
#      - At least 500GB for local resource storage
Get-AzureRoleSize `
    | where { $_.SupportedByWebWorkerRoles -eq $true } `
    | where { ($_.Cores -ge 4) -and ($_.MemoryInMb -ge 48000) -and ($_.VirtualMachineResourceDiskSizeInMb -ge 500000) } `
    | Select InstanceSize, Cores, MemoryInMb, WebWorkerResourceDiskSizeInMb


# Configuring remote desktop

# To configure RDP acccess for a cloud service
$creds = Get-Credential
$csName = "ContosoCloudService"
$csRole = "DemoWorkerRole"
$certThumbPrint = "[YOUR MGMT CERTIFICATE THUMBPRINT]"
$cert = Get-Item Cert:\CurrentUser\My\$certThumbprint

Set-AzureServiceRemoteDesktopExtension -ServiceName $csName -Role $csRole `
                                       -Credential $creds `
                                       -X509Certificate $cert 

# To disalbe RDP access
Remove-AzureServiceRemoteDesktopExtension -ServiceName $csName -Role $csRole
