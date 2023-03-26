#:xheader:
#Type=ActionType;
#:xheader:

@{
	Clean = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		return $true
	};
	Action = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		
		$webConfig = $action.Parameters().Extract(@("Framework", "ConfigFile"))
		
		$action.LoadChildren()
		$AppSettings = $action.Section("AppSettings")
		$AppSettings.LoadChildren()
		
		if($webConfig.Framework -eq "NetFramework"){
			try{
				$webConfigFile=$webConfig.ConfigFile
				$savedWebConfig="$($webConfigFile).save.config"
				[XML]$loadedWebConfig = Get-Content $webConfigFile
				if(-not $loadedWebConfig){
					Throw "       Cant load config" 
				}
				$loadedWebConfig.Save($savedWebConfig)
				
				if($AppSettings){
					foreach($appSetting in $AppSettings.Parameters()){
						$node = $loadedWebConfig.SelectNodes("/configuration/appSettings/add[@key='$($appSetting.Name())']")
						if(-not $node -or -not $node.key){
							$context.Error("Unknown App Setting with Key '{magenta}$($appSetting.Name()){gray}'")
							continue
						}
						$context.Display("Setting Key '{magenta}$($appSetting.Name()){gray}' to '{magenta}$($appSetting.Value()){gray}'")
						$node.Attributes[1].Value=$appSetting.Value
					}
				}
				$loadedWebConfig.Save($webConfigFile)
			}
			catch{
				Write-Host "       Unkown able to configure config: $_" -ForegroundColor Red
			}
		}
		else{
			Write-Error "Framework '$($webConfig.Framework)' unkown: "
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

		if(-not $action.Parameters().Validate(@("Framework", "ConfigFile"))){
			return $false
		}
		
		$action.LoadChildren()
		$AppSettings = $action.Section("AppSettings")
		$AppSettings.LoadChildren()
		if(-not $AppSettings){
			$context.Error("AppSettings section is not present")
			return $false
		}
		return $true
	};
	
}