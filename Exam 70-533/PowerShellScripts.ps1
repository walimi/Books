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

    






















