@{
	Clean = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		return $true
	};
	Action = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		
		$content = $this.Parameters().Get("Content", $false)
		$context.Display($($content.Value()))
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
		
		$content = $this.Parameters().Get("Content", $false)
		
		if(-not $content){
			return $false
		}

		$content.IsRequired($true)

		if(-not $content.Value()){
			return $false
		}
		return $true
	};
	
}