@{
	Clean = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		return $true
	};
	Action = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		
		$extracted = $action.Parameters().Extract(@("ResourceName", "ResourceType", "QueryCode", "ExportVariable"))
		
		$resource = Get-AzureRmResource -ODataQuery "`$filter=resourcetype eq '$($extracted.ResourceType)' and name eq '$($extracted.ResourceName)'"
		
		$resourceExpanded = Get-AzureRmResource –ResourceId $resourceId -ExpandProperties
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

		if(-not $action.Parameters().Validate(@("ResourceName", "QueryCode", "ExportVariable"))){
			return $false
		}
		
		return $true
	};
	
}