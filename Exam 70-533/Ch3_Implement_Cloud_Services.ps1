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

