# Ch 6: Implement Virtual Networks

# Objective 6.1: Configure a virtual network

# Deploying a virtual machine into a virtual network

# The following example shows creating a virtual machine in the ContosoVNET virtual network and Management subnet using the New-AzureQuickVM cmdlet. 
# This cmdlet does not support specifying a static IP address.

$vnetName = "ContosoVNET"
$subnet = "Management"
New-AzureQuickVM -Windows `
                 -ServiceName $serviceName `
                 -Name $vmName `
                 -ImageName $imageName `
                 -AdminUserName $adminUser `
                 -Password $password `
                 -Location $location `
                 -InstanceSize $size `
                 -SubnetNames $subnet `
                 -VNetName $vnetName

# The following example shows how to configure the network configuration using the New-AzureVM
# cmdlet. 
$vnetName = "ContosoVNET"
$subnet = "Management"
$staticIP = "10.0.1.68"
New-AzureVMConfig -Name $vmName `
                  -InstanceSize $size `
                  -ImageName $imageName |

Add-AzureProvisioningConfig -Windows `
                            -AdminUsername $adminUser `
                            -Password $password |

Set-AzureStaticVNetIP -IPAddress $staticIP |
Set-AzureSubnet -SubnetNames $subnet |
New-AzureVM -ServiceName $serviceName `
            -Location $location `
            -VNetName $vnetName

# Active Directory Domain Join

# The following is a complete example of using Windows PowerShell to domain join a virtual machine. 
$adminUser = "[admin user name]"
$adminPassword = "[admin password]"
$domainUser = "[domain admin user name]"
$domainPassword = "[domain admin passowrd]"
$ou = 'OU=AzureVMs,DC=fabrikam,DC=com' # Organizational Unit
$domain = "contoso"
$fqdnDomain = "contoso.com"
$imageFamily = "Windows Server 2012 R2 Datacenter"

$imageName = Get-AzureVMImage |
                where { $_.ImageFamily -eq $imageFamily } | 
                sort PublishedDate -Descending |
                select -ExpandProperty ImageName -First 1

New-AzureVMConfig -Name $vmName `
                  -InstanceSize $size `
                  -ImageName $imageName |

Add-AzureProvisioningConfig -WindowsDomain `
                            -AdminUsername $adminUser `
                            -Password $adminPassword `
                            -Domain $domain `
                            -JoinDomain $fqdnDomain `
                            -DomainUserName $domainUser `
                            -DomainPassword $domainPassword `
                            -MachineObjectOU $ou |

Set-AzureSubnet -SubnetNames $subnet |
New-AzureVM -ServiceName $serviceName `
            -Location $location `
            -VNETName $vnetName


# Configuring internal load balancing

# The internal load balancer can only be specified when the virtual machine is created by using
# Windows PowerShell. 

# To configure the internal load balancer, do the following:

# 1. Identify an IP address from a subnet on a virtual network using your subscription. The following
# example creates several variables that define the configuration from the previously created
# network. 

$vip = "10.0.1.30"
$lbName = "web"
$subnet = "Intranet"
$vnetName = "ContosoVNET"


# 2. Create a load balancer configuration object using the New-AzureInternalLoadBalancerConfig cmdlet
# and specify the configuration.
$ilb = New-AzureInternalLoadBalancerConfig -InternalLoadBalancerName $lbName `
                                           -StaticVNetIPAddress $vip `
                                           -SubnetName $subnet

# 3. Specify the name of the load balancer to each load-balanced endpoint in the set. The following
# example creates two virtual machine configuration objects. Each configuration has a load-balanced
# endpoint added using the Add-AzureEndpoint cmdlet. The internal load balancer name is specified with
# InternalLoadBalancer name parameter. 

$vm1 = New-AzureVMConfig -ImagaeName -$ImageName `
                         -Name "lb1" `
                         -InstanceSize Small |
       Add-AzureProvisioningConfig -Windows `
                                   -AdminUserName $adminUser `
                                   -Password $password |
        Set-AzureSubnet -SubnetNames $subnet |
        Add-AzureEndpoint -Name "web" `
                          -Protocol tcp `
                          -LocalPort 80 `
                          -PublicPort 80 `
                          -LBSetName "weblbset" `
                          -InternalLoadBalancerName $lbName `
                          -DefaultProbe
                          
$vm2 = New-AzureVMConfig -ImagaeName -$ImageName `
                         -Name "lb2" `
                         -InstanceSize Small |
       Add-AzureProvisioningConfig -Windows `
                                   -AdminUserName $adminUser `
                                   -Password $password |
        Set-AzureSubnet -SubnetNames $subnet |
        Add-AzureEndpoint -Name "web" `
                          -Protocol tcp `
                          -LocalPort 80 `
                          -PublicPort 80 `
                          -LBSetName "weblbset" `
                          -InternalLoadBalancerName $lbName `
                          -DefaultProbe
                          
# 4. Create the virtual machines using the New-AzureVM cmdlet. The internal load balancer
# configuration created earlier must be passed to the InternalLoadBalancerConfig cmdlet as 
# shown in the following example. 

New-AzureVM -ServiceName $serviceName `
            -Location $location `
            -VNetName $vnetName `
            -VMs $vm1, $vm2 `
            -InternalLoadBalancerConfig $ilb

# Objective 6.2 Modify a network configuration

# Changing an existing network configuration

# To change a virtual machine's subnet, first retrieve the current virtual machine configuration
# with a call to the Get-AzureVM cmdlet. Next, pass the returned configuration to Set-AzureSubnet
# cmdlet. The modified configuration is then passed to the Update-AzureVM. 

Get-AzureVM -ServiceName $serviceName `
            -Name $vmName |
Set-AzureSubnet -SubnetNames $newSubnet |
Update-AzureVM