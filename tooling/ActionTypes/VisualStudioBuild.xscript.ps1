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
		$extracted = $action.Parameters().Extract(@("Solution", "MSBuildArguments", "Platform", "Configuration", "MSBuildPath"))
		
		$context.Display("{yellow}:: Skipping actual executing (In Mock Mode){gray}")
		
		$files = Get-ChildItem -Path $($extracted.Solution) -Recurse
		foreach($project in $files){
			
			$command =[ScriptBlock]::Create('& ' + "'" + $($extracted.MSBuildPath) + "' " +"'"+($project.FullName)+"' " + '  /p:Configuration="' + $($extracted.Configuration) + '" /p:Platform="' + $($extracted.Platform) + '" ' + $($extracted.MSBuildArguments) + "")
			
			
			$context.Display("{white}Executing the following:`r`n{gray}$($command)")
			$result = .$command
			$context.Display("Executing was successful with output of type '{white}$($result.GetType()){gray}`r`n...")
			
			for($i=$result.Count - 5; $i -lt $result.Count; $i += 1){
				$context.Display($($result[$i].ToString()))
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

		if(-not $action.Parameters().Validate(@("Solution", "MSBuildArguments", "Platform", "Configuration", "MSBuildPath"))){
			return $false
		}
		$extracted = $action.Parameters().Extract(@("Solution", "MSBuildArguments", "Platform", "Configuration"))
		
		$files = Get-ChildItem -Path $($extracted.Solution) -Recurse
		if($files.Count -eq 0){
			$context.Error("Action {white}$($action.Name()){gray} of type {white}$($action.ActionType().Name()){gray} - No Solutions files found in source path {white}$($extracted.Solution){gray}")
			return $false
		}
		return $true
	};
	
}