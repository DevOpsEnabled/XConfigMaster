<#
.SYNOPSIS
	A brief description of the function or script.

.DESCRIPTION
	A longer description.

.PARAMETER FirstParameter
	Description of each of the parameters.
	Note:
	To make it easier to keep the comments synchronized with changes to the parameters,
	the preferred location for parameter documentation comments is not here,
	but within the param block, directly above each parameter.

.PARAMETER SecondParameter
	Description of each of the parameters.

.INPUTS
	Description of objects that can be piped to the script.

.OUTPUTS
	Description of objects that are output by the script.

.EXAMPLE
	Example of how to run the script.

.LINK
	Links to further documentation.

.NOTES
	Detail on what the script does, if this is needed.

#>

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