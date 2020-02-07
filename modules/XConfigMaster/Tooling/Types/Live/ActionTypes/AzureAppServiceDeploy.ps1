@{
	Clean = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		return $true
	};
	Action = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		
		$extracted = $action.Parameters().Extract(@("AppType", "AppServiceName", "PackageOrFolder", "MSBuildPath"))
		
		
		$resourceName = $extracted.AppServiceName
		$PackagePath =[System.IO.Path]::GetFullPath($extracted.PackageOrFolder)
		$resource = Get-AzureRmResource -ODataQuery "`$filter=resourcetype eq 'Microsoft.Web/sites' and name eq '$($resourceName)'"
		$resource=$resource[0]
		
		$tmp = (New-TemporaryFile).FullName
		$xmlcontent = (Get-AzureRmWebAppPublishingProfile -Name $resourceName -ResourceGroupName $resource.ResourceGroupName -OutputFile $tmp )	
		$xml = New-Object -TypeName System.Xml.XmlDocument
		$xml.LoadXml($xmlcontent)
		
		$username = ([xml]$xml).SelectNodes("//publishProfile[@publishMethod=`"MSDeploy`"]/@userName").value
		$password = ([xml]$xml).SelectNodes("//publishProfile[@publishMethod=`"MSDeploy`"]/@userPWD").value
		$url = ([xml]$xml).SelectNodes("//publishProfile[@publishMethod=`"MSDeploy`"]/@publishUrl").value
		$siteName = ([xml]$xml).SelectNodes("//publishProfile[@publishMethod=`"MSDeploy`"]/@msdeploySite").value
		del $tmp
		

		$msdeployArguments = 
			'-verb:sync ' +
			"-source:package='$PackagePath' " + 
			"-dest:auto,ComputerName=https://$url/msdeploy.axd?site=$siteName,UserName=$username,Password=$password,AuthType='Basic',includeAcls='False' " +
			"-setParam:name='IIS Web Application Name',value=$siteName"
		$commandLine = '&"C:\Program Files\IIS\Microsoft Web Deploy V3\msdeploy.exe" --% ' + $msdeployArguments
		
		$temp = New-TemporaryFile
		$commandLine += "  | Select-WriteHost | out-file '$temp'"
		$context.Display("{white}Command:{gray}`r`n$($commandLine)")
		$result = Invoke-Expression $commandLine
		$content = Get-Content $temp -Raw
		del $temp
		$context.Display("{white}Results:{gray}`r`n$($content)")
		
		return $true
	};
	CanExecute = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		return $true
	};
	Validate = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)

		if(-not $action.Parameters().Validate(@("AppType", "AppServiceName", "PackageOrFolder", "MSBuildPath"))){
			return $false
		}
		
		
		return $true
	};
	
}