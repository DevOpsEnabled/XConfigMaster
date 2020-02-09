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
		$extracted = $action.Parameters().Extract(@("Project", "MSBuildArguments", "Platform", "Configuration", "MSBuildPath"))
		
		$context.Display("{yellow}:: Skipping actual executing (In Mock Mode){gray}")
		
		$files = Get-ChildItem -Path $($extracted.Project) -Recurse -Depth 10
		foreach($project in $files){
			$command = '&' + "'" + $($extracted.MSBuildPath) + "' " +"'"+$project+"' " + '  /p:Configuration="' + $($extracted.Configuration) + '" /p:Platform="' + $($extracted.Platform) + '" ' + $($extracted.MSBuildArguments) + ""
			
			$context.Display("{white}Executing the following:`r`n{gray}$($command)")
			$result = Invoke-Expression $command
			$context.Display("Executing was successful with output of type '{white}$($result.GetType()){gray}`r`n")
			foreach($item in $result){
				$context.Display($($item.ToString()))
			}
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

		if(-not $action.Parameters().Validate(@("Project", "MSBuildArguments", "Platform", "Configuration", "MSBuildPath"))){
			return $false
		}
		
		$extracted = $action.Parameters().Extract(@("Project", "MSBuildArguments", "Platform", "Configuration", "MSBuildPath"))
		
		$files = Get-ChildItem -Path $($extracted.Project) -Recurse -Depth 10
		if($files.Count -eq 0){
			$context.Error("Action {white}$($action.Name()){gray} of type {white}$($action.ActionType().Name()){gray} - No Projects files found in source path {white}$($extracted.Project){gray}")
			return $false
		}
		
		
		
		return $true
	};
	
}