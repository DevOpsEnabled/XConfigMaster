@{
	Clean = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		return $true
	};
	Action = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		
		# Extract Required Fields
		$extracted = $this.Parameters().Extract(@("AppServiceName", "AppendAppSettings"))
		
		# Variables
		$AppServiceName    = $extracted.AppServiceName
		$AppendAppSettings = $extracted.AppendAppSettings
		
		$action.Get("Sections").LoadChildren()
		$action.Get("Sections").Get("AppSettings").LoadChildren()
		
		$action.Get("Sections").LoadChildren()
		$action.Get("Sections").Get("ConnectionStrings").LoadChildren()
		
		if(-not $action.Get("Sections").Get("AppSettings").Get("Parameters").ValidateAllParameters()){
			$context.Error("Some App Settings are invalid")
			return $false
		}
		if(-not $action.Get("Sections").Get("ConnectionStrings").Get("Parameters").ValidateAllParameters()){
			$context.Error("Some Connection Strings are invalid")
			return $false
		}
		
		# Gather Resource Info
		$resource = $context.AzureRmResources($AppServiceName, $null, $null) | Where {$_.ResourceType -eq 'Microsoft.web/sites'}
		if(-not $resource){
			$context.Error("Resource {white}$($AppServiceName){gray} was not found, unable to configure this service")
			return $false
		}
		
		# Variables
		$AppServiceName    = $extracted.AppServiceName
		$AppendAppSettings = $extracted.AppendAppSettings
		
		# Load any Children 
		$action.Get("Sections").LoadChildren()
		$action.Get("Sections").Get("AppSettings").LoadChildren()
		$action.Get("Sections").Get("AppSettings").Get("Parameters").LoadChildren()
		$action.Get("Sections").Get("ConnectionStrings").LoadChildren()
		$action.Get("Sections").Get("ConnectionStrings").Get("Parameters").LoadChildren()
		
		# Get Deploying Content
		$deployAppsettings       = $action.Get("Sections").Get("AppSettings").Get("Parameters").Items()
		$deployConnectionStrings = $action.Get("Sections").Get("ConnectionStrings").Get("Parameters").Items()
		
		# Gather Resource Current Settings
		$appSettingList        = (Invoke-AzureRMResourceAction -ResourceGroupName $resource.ResourceGroupName -ResourceType 'Microsoft.Web/sites/Config' -Name "$($AppServiceName)/appsettings" -Action list -ApiVersion 2015-08-01 -Force).Properties
		$connectionStringsList = (Invoke-AzureRMResourceAction -ResourceGroupName $resource.ResourceGroupName -ResourceType 'Microsoft.Web/sites/Config' -Name "$($AppServiceName)/connectionstrings" -Action list -ApiVersion 2015-08-01 -Force).Properties
		
		# Build App Settings
        $appSettings = @{}
		if($AppendAppSettings -ieq "true"){
			$appSettingList.psobject.properties | Foreach { $appSettings[$_.Name] = $_.Value}
		}
		$appSettings["WEBSITE_NODE_DEFAULT_VERSION"] = "6.9.1"
		
		# Showing Changes Found
		$context.Display("      Changes Found ({white}$(@($deployAppsettings).Count){gray})")
		$deployAppsettings | Foreach {
			[string] $appKey   = $_.Name()
			[string] $oldValue = $appSettings[$appKey]
			[string] $newValue = $_.Value()
			
			if($appSettings.ContainsKey($appKey)){
				if(-not ($oldValue -eq $newValue)){
					$context.Display( "      '$($appKey)' *Changed* ")
					$context.Display( "         [OLD] '$($oldValue)' ")
					$context.Display( "         [NEW] '$($newValue)' ")
				}
				else{
					$context.Display( "      '$($appKey)' up-to-date ")
				}
				
			}
			else{
				$context.Display( "      '$($appKey)' *New* ")
				$context.Display( "         [NEW] '$($newValue)' ")
				
				
			}
			$appSettings[$appKey] =  $newValue
		}
		
		# Showing All App Settings
		$_ = "    Full List"; $context.Display($_)
		$appSettings.GetEnumerator() | % {
		   $key = $_.key
		   $value=$_.value
           $context.Display("        '$($key)' => '$($value)'")
        }
		
		
		# Build Connection Strings
        $connectionStrings = @{}
		if($AppendAppSettings -ieq "true"){
			 $connectionStringsList.psobject.properties | Foreach { @{Type = 'SQLAzure'; Value = $_.Value}}
		}
		
		
		# Showing Changes Found
		$context.Display("      Changes Found ({white}$(@($deployConnectionStrings).Count){gray})")
		foreach($deployConnectionString in $deployConnectionStrings){
			$appKey   = $deployConnectionString.Name()
			$oldValue = $connectionStrings[$appKey]
			$newValue = $deployConnectionString.Value()
			
			if($connectionStrings.ContainsKey($appKey)){
				if(-not ($oldValue -eq $newValue)){
					$_ = "      '$($appKey)' *Changed* "; $context.Display($_)
					$_ = "         [OLD] '$($oldValue.Value)'"; $context.Display($_)
					$_ = "         [NEW] '$($newValue.Value)'"; $context.Display($_) 
				}
				else{
					$_ = "      '$($appKey)' up-to-date "; $context.Display($_)
				}
			}
			else{
				$context.Display( "      '$($appKey)' *New* ")
				$context.Display( "         [NEW] '$($newValue.Value)' ")
			}
			
			$connectionStrings[$appKey] =  $newValue
		}
		
		# If no connection strings, Add a empty one to not cause any errors
		if($connectionStrings.Count -eq 0){
			$connectionStrings["NONE"] = @{ Type = 'SQLAzure'; Value = "NONE" }
		}
		
		# Showing All App Settings
		$_ = "    Full List"; $context.Display($_)
		$connectionStrings.GetEnumerator() | % {
		   $key = $_.key
		   $value=$_.value
           $_ = "        '$($key)' => '$($value)'"; $context.Display($_)
        }
		
		# Update App Settings on actual resource
		try{
			Set-AzureRMWebAppSlot -ResourceGroupName ($resource.ResourceGroupName) -Name $AppServiceName -AppSettings $appSettings -ConnectionStrings $connectionStrings -Slot Production
			
			$_ = "`r`n  Successfully Updated Azure App Settings for App Service($($AppServiceName))"; $context.Display($_)
		}
		catch  [Exception] {
			$_msg  = "Error(Setting Configuration to App Services)";
			$_msg += "  Message: $($_.Exception.Message)";
			$_msg += "  Item...: $($_.Exception.FailedItem)";
			
            echo $_.Exception|format-list -force
			
			$context.Error($_msg)
		}
		
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

		if(-not $this.Parameters().Validate(@("AppServiceName", "AppendAppSettings"))){
			return $false
		}
		
		# Extract Required Fields
		$extracted = $this.Parameters().Extract(@("AppServiceName", "AppendAppSettings"))
		
		# Variables
		$AppServiceName    = $extracted.AppServiceName
		$AppendAppSettings = $extracted.AppendAppSettings
		
		$action.Get("Sections").LoadChildren()
		$action.Get("Sections").Get("AppSettings").LoadChildren()
		
		$action.Get("Sections").LoadChildren()
		$action.Get("Sections").Get("ConnectionStrings").LoadChildren()
		
		if(-not $action.Get("Sections").Get("AppSettings").Get("Parameters").ValidateAllParameters()){
			$context.Error("Some App Settings are invalid")
			return $false
		}
		if(-not $action.Get("Sections").Get("ConnectionStrings").Get("Parameters").ValidateAllParameters()){
			$context.Error("Some Connection Strings are invalid")
			return $false
		}
		
		
		return $true
	};
	
}