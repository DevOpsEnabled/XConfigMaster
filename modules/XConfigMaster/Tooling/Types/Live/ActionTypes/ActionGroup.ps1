@{
	Clean = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		$allWorked = $true
		foreach($subAction in $action.Actions().Items()){
			$seperatedName = $subAction.Name()
			# Write-Color "`r`n{magenta}:: {white}Executing [{magenta}$($seperatedName){white}] - {yellow} Mocking Mode Enabled{gray}"
			$allWorked = $subAction.Clean() -and $allWorked
		}
		return $allWorked
	};
	Action = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		$allWorked = $true
		foreach($subAction in $action.Actions().Items()){
			$seperatedName = $subAction.Name()
			# Write-Color "`r`n{magenta}:: {white}Executing [{magenta}$($seperatedName){white}] - {yellow} Mocking Mode Enabled{gray}"
			$allWorked =$subAction.ExecuteAction() -and $allWorked
		}
		return $allWorked
	};
	CanExecute = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		return $true
	};
	Validate = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		$valid = $true
		
		foreach($subAction in $action.Actions().Items()){
			# Write-Color "{white}Validating {magenta}$($subAction.FullName()){white} ...                                             `r" -NoNewLine
			$valid = $($subAction.Validate()) -and $valid
		}

		return $valid
	};
	
}