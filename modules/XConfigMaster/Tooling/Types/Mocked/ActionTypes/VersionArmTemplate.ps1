@{
	Clean = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		return $true
	};
	Action = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		$extracted = $action.Parameters().Extract(@("BuildNumber", "SourcePath", "FilePattern", "VersionSource", "VersionExtractPattern"))
		
		$context.Display("{yellow}:: Skipping actual executing (In Mock Mode){gray}")
		
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

		if(-not $action.Parameters().Validate(@("BuildNumber", "SourcePath", "FilePattern", "VersionSource", "VersionExtractPattern"))){
			return $false
		}
		
		$extracted = $action.Parameters().Extract(@("BuildNumber", "SourcePath", "FilePattern", "VersionSource", "VersionExtractPattern"))
		
		$files = Get-ChildItem -Path $($extracted.SourcePath) -Filter $($extracted.FilePattern) -Recurse
		if($files.Count -eq 0){
			$context.Error("Action {white}$($action.Name()){gray} of type {white}$($action.ActionType().Name()){gray} - No Template files found in source path {white}$($extracted.SourcePath){gray} with filter {white}$($extracted.FilePattern){gray}")
			return $false
		}
		
		return $true
	};
	
}