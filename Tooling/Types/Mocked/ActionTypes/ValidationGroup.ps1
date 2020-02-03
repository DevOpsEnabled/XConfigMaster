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
		# if(-not $arguments.ParentAction){
		# 	Write-Color "`r`n{white}:: E x e c u t i n g ::{gray}"
		# }

		$valid = $true
		# foreach($subAction in $action.Actions().Items()){
		# 	$seperatedName = $subAction.Name()
		# 	$valid = $($subAction.Validate()) -and $valid
		# }
		$allWorked = $true
		# foreach($subAction in $action.Actions().Items()){
		# 	$seperatedName = $subAction.Name()
		# 	# Write-Color "`r`n{magenta}:: {white}Executing [{magenta}$($seperatedName){white}] - {yellow} Mocking Mode Enabled{gray}"
		# 	$allWorked = $subAction.Clean() -and $allWorked
		# }
		
		return $allWorked -and $valid
	};
	CanExecute = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		
		return $true
	};
	Validate = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action, [hashtable] $arguments)

		# if(-not $arguments.ParentAction){
		# 	Write-Color "`r`n{white}:: V a l i d a t i n g ::{gray}"
		# }

		$valid = $true
		foreach($subAction in $action.Actions().Items()){
			$seperatedName = $subAction.Name()
			$valid = $($subAction.Validate()) -and $valid
		}
		return $valid
	};
	
}