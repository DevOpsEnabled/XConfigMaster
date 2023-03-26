#:xheader:
#Type=ActionType;
#:xheader:

@{
	Clean = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		
		# Return Bool
		return $true
	};
	Action = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		$extracted = $action.Parameters().Extract(@("Payload", "CurrentPayload"))
		
		
		$array  = ConvertFrom-Json $($extracted.CurrentPayload)
		$newObj = ConvertFrom-Json $($extracted.Payload)
		
		if(-not $array){
			$array = @()
		}
		
		if(-not ($array -is [array])){
			$array = @($array)
		}
		
		# Append New Rule
		$array += $newObj
		
		# New Array
		$newPayload = ConvertTo-Json $($array)
		
		$context.InjectOutputVariable($action, "CurrentPayload", $newPayload)
		
		# Return Bool
		return $true
	};
	CanExecute = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		
		
		
		# Return Bool
		return $true
	};
	Validate = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)

		if(-not $action.Parameters().Validate(@("Payload", "CurrentPayload"))){
			return $false
		}
		
		$extracted = $action.Parameters().Extract(@("Payload", "CurrentPayload"))
		
		Write-Host ("JSON:`r`n$($extracted.Payload)")
		$newObj = ConvertFrom-Json $($extracted.Payload)
		if(-not $newObj){
			$context.Error("Invalid Json Object")
			return $false
		}
		
		# Return Bool
		return $true
	};
	
}