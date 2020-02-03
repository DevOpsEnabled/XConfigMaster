
@{
	Clean = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		return $true
	};
	Action = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		
		$extracted = $action.Parameters().Extract(@("ResourceName", "ResourceType", "ResultType"))
		
		$result = $null
		if($($extracted.CheckType) -ieq "export"){
			$expression = $action.Parameters().Get("Expression").Value()
			
			$resource = Get-AzureRmResource -ODataQuery "`$filter=resourcetype eq '$($extracted.ResourceType)' and name eq '$($extracted.ResourceName)'" -ExpandProperties
			if(-not $resource){
				$context.Error("Resource '{white}$($extracted.ResourceName){gray}' of type '{white}$($extracted.ResourceType){gray}' was found, try using the check for exists aswell...")
				return $false
			}
			
			$command =  $expression
			$result = .$command
		}
		elseif($($extracted.CheckType)  -ieq "exists"){
			$resource = Get-AzureRmResource -ODataQuery "`$filter=resourcetype eq '$($extracted.ResourceType)' and name eq '$($extracted.ResourceName)'" -ExpandProperties
			if(-not $resource){
				$result = $false
			}
			else{
				$result = $true
			}
		}
		else{
			$context.Error("CheckType can only be one of the following values: ('{white}export{gray}', '{white}exists{gray}') but found {white}$($extracted.CheckType){gray}")
			return $false
		}
		
		
		if($extracted.ResultType -ieq "output"){
			$outputVariableName = $action.Parameters().Get("OutputVariableName").Value()
			$context.InjectOutputVariable($action, $outputVariableName, $result)
		}
		elseif($extracted.ResultType -ieq "validate"){
			$expression = $action.Parameters().Get("ValidateExpression").Value()
			$command =  $expression
			$finalResult = .$command
			
			if(-not ($finalResult -is [bool])){
				$context.Error("Expression resulted in a type that was not a [bool]. Something is wrong with your '{white}ValidateExpression{gray}'")
				return $false
			}
			
			if($finalResult -eq $false){
				$context.Error("Validation Expression resulted in False")
				return $false
			}
			
			return $true
		}
		else{
			$context.Error("ResultType can only be one of the following values: ('{white}Output{gray}', '{white}Validate{gray}') but found {white}$($extracted.ResultType){gray}")
			return $false
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

		if(-not $action.Parameters().Validate(@("ResourceName", "ResourceType", "CheckType", "ResultType"))){
			return $false
		}
		
		$extracted = $action.Parameters().Extract(@("ResourceName", "ResourceType", "CheckType", "ResultType"))
		
		$isValid = $true
		if($extracted.CheckType -ieq "export"){
			if(-not $action.Parameters().Validate(@("Expression"))){
				$isValid = $false
			}
		}
		elseif($extracted.CheckType -ieq "exists"){
		}
		else{
			$context.Error("CheckType can only be one of the following values: ('{white}export{gray}', '{white}exists{gray}') but found {white}$($extracted.CheckType){gray}")
			$isValid = $false
		}
		
		
		if($extracted.ResultType -ieq "output"){
			if(-not $action.Parameters().Validate(@("OutputVariableName"))){
				$isValid = $false
			}
			$outputVariableName = $action.Parameters().Get("OutputVariableName").Value()
			$context.InjectOutputVariable($action, $outputVariableName, $false)
		}
		elseif($extracted.ResultType -ieq "validate"){
			if(-not $action.Parameters().Validate(@("ValidateExpression"))){
				$isValid = $false
			}
		}
		else{
			$context.Error("ResultType can only be one of the following values: ('{white}Output{gray}', '{white}Validate{gray}') but found {white}$($extracted.ResultType){gray}")
			$isValid = $false
		}
		
		
		return $isValid
	};
	
}