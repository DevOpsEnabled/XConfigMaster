@{
	Clean = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		return $true
	};
	Action = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		
		$extracted = $action.Parameters().Extract(@("Command", "PathToSolution", "NugetExePath"))
		
		$context.Display("Clearing current sources")
		$results = .([ScriptBlock]::Create("& '$($extracted.NugetExePath)' sources list"))
		$results | Where {$_ -match " +\d\. +(.*) \["} | Foreach {$_ -replace " +\d\. +(.*) \[.*",'$1'} |Foreach {
			$results = .([ScriptBlock]::Create("& '$($extracted.NugetExePath)' sources remove -Name '$($_)'"))
			foreach($item in $result){
				$context.Display($($item.ToString()))
			}
		}
			
			
		$context.Display("Adding new sources")
		
		$results = .([ScriptBlock]::Create("& '$($extracted.NugetExePath)' sources Add -NonInteractive -Name NuGetOrg -Source https://api.nuget.org/v3/index.json"))
		foreach($item in $result){
			$context.Display($($item.ToString()))
		}
		
			
		$files = Get-ChildItem -Path $($extracted.PathToSolution) -Recurse
		foreach($project in $files){
			$command = [ScriptBlock]::Create("& '$($extracted.NugetExePath)' $($extracted.Command) '$($project.FullName)'")
			$context.Display("{white}Command:{gray}`r`n$($command)")
			$result = .$command
			$context.Display("Executing was successful with output of type `r`n")
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

		if(-not $action.Parameters().Validate(@("Command", "PathToSolution", "NugetExePath"))){
			return $false
		}
		
		return $true
	};
	
}