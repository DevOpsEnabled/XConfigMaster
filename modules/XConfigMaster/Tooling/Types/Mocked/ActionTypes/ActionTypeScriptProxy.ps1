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
		$extracted = $action.Parameters().Extract(@("ResourceName", "ResourceGroup", "KeyVaultName", "PermissionsToKey", "AADGroupName", "PermissionsToSecrets", "PermissionsToCertificates", "MSIEnableAADGroupApproach"))
		
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

		if(-not $this.Parameters().ValidateAllParameters()){
			return $false
		}
		
		# Return Bool
		return $true
	};
	
}