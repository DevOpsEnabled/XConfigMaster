@{
	Clean = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		return $true
	};
	Action = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		
		
		$scope = $action.CurrentScope()
		Write-Host "`r`nValidations:"
		$scope.Validate()

		Write-Host "`r`nParameters:"
		$parents = $scope.GetAllParents($true)
		
		
		foreach($scope in $parents){
			foreach($parameter in $scope.Parameters().Items()){
				if($parameter.IsRequired()){
					$content = "   $($parameter.ToString()) {gray} "
					if($parameter.InputStrategies().Items().Count -eq 0){
						$content += "{white}[{red}Not Defined{white}]"
					}
					else{
						$contentText = ($parameter.InputStrategies().Items() | Foreach {return "{gray}{white}$($input.Shorthand()){gray}"} )
						$contentText = $contentText -join " {magenta}OR{gray} "
						$content += $contentText
					}
					Write-Color $content
					
				}
			}	
		}
		Write-Color "`r`n{white}Actions:{gray}`r`n   $(($scope.Actions().Items() | Where {$_} | Foreach {"$($_.Name())"}) -join "`r`n   ")"
		Write-Color "`r`n{white}Common Actions:{gray}`r`n   $(($scope.Actions().Templates() | Where {$_} | Foreach {"$($_.Name())"}) -join "`r`n   ")"

		
		
	};
	CanExecute = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		return $true
	};
	Validate = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		return $true
	};
	
}