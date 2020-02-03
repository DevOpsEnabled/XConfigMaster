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
		$extracted = $action.Parameters().Extract(@("ResourceName", "ResourceGroup", "KeyVaultName", "PermissionsToKey", "ServicePrincipleId", "AADGroupName", "PermissionsToSecrets", "PermissionsToCertificates", "MSIEnableAADGroupApproach"))
		
		$ResourceName               = $extracted.ResourceName
		$ResourceGroup              = $extracted.ResourceGroup
		$KeyVaultName               = $extracted.KeyVaultName
		$AADGroupName               = $extracted.AADGroupName
		$MSIEnableAADGroupApproach  = $extracted.MSIEnableAADGroupApproach
		$PermissionsToKey           = $extracted.PermissionsToKey -split ","
		$PermissionsToSecrets       = $extracted.PermissionsToSecrets -split ","
		$PermissionsToCertificates  = $extracted.PermissionsToCertificates -split ","
		$ServicePrincipleId         = $extracted.ServicePrincipleId

		
		$keyVault = $context.AzureRmResources($KeyVaultName, $null, $null)
		if(-not $($keyVault)){
			$context.Error("Key Vault {white}$($KeyVaultName){gray} was not found")
			return $false
		}
		
		if($ResourceName){
		
			$odataQuery  = "`$filter=name eq '$($ResourceName)'"
			$odataQuery += $extracted.ResourceGroup | ?: {" and resourcegroup eq '$_'"} : ""
			$odataQuery += $extracted.ResourceType  | ?: {" and resourcetype eq '$_'"} : ""
			
			$resourceFullName  = ("/" + $ResourceName)
			$resourceFullName  = $extracted.ResourceType  | ?: {"$_/$($resourceFullName)"} : $resourceFullName
			$resourceFullName  = $extracted.ResourceGroup | ?: {"$_/$($resourceFullName)"} : $resourceFullName
			
			$resource = $context.AzureRmResources($ResourceName, $ResourceGroup, $null)
			if(-not $resource){
				$context.Error("Resource {white}$($resourceFullName){gray} was not found")
				return $false
			}
			
			if(-not $ServicePrincipleId)
			{
				$ServicePrincipleId = $resource.Identity.PrincipalId
				if(-not $($ServicePrincipleId)){
					$context.Error("Resource {white}$($resourceFullName){gray} has no Principal id which is required to give the resource access to key vault {white}$($KeyVaultName){gray}`r`n$(ConvertTo-Json $($resource.Identity))")
					return $false
				}
			}
		}
		
		if($AADGroupName -and ($MSIEnableAADGroupApproach -ieq "true") ){
			
			
			# Handle Group
			$context.Display("0. Handling Group")
			$aadGroup = Get-AzureADGroup | Where {$_.DisplayName -ieq $($AADGroupName)}
			if(-not $aadGroup){
				$context.Display("AAD Group '$($AADGroupName)' was not found, moving to create it")
				$aadGroup = (New-AzureADGroup -DisplayName $($AADGroupName) -MailEnabled $false -SecurityEnabled $true -MailNickName "NotSet" )
				
				# If failed to create
				if(-not $aadGroup){
					$context.Error("AAD Group '$($AADGroupName)' failed to be created")
					return $false
				}
			}
			$context.Display("   GroupId: " + ($aadGroup.ObjectId))

			$context.Display("1. Handling Service Principal")
			$servicePrincipal = Get-AzureADServicePrincipal -ObjectId $ServicePrincipleId
			if(-not $servicePrincipal){
				$context.Error("Service Principal '$($PrincipalId)' failed to be fetched with command 'Get-AzureRmADServicePrincipal'")
				return $false
			}
			$context.Display("   PrincipleId: " + ($servicePrincipal.ObjectId))
			$context.Display("2. Handle Group Membership")
			$memberInGroup = Get-AzureADGroupMember -ObjectId  $($aadGroup.ObjectId) | Where { $_.ObjectId -eq $($servicePrincipal.ObjectId)}
			if(-not $memberInGroup){
				$context.Display("Group Membership was not already established, so adding service Principal '$($servicePrincipal.ObjectId)' to group '$($aadGroup.DisplayName)' ($($aadGroup.ObjectId))")
				
				$memberInGroup = Add-AzureADGroupMember -ObjectId  $($aadGroup.ObjectId) -RefObjectId $($servicePrincipal.ObjectId)
				$memberInGroup = Get-AzureADGroupMember -ObjectId $($aadGroup.ObjectId) | Where { $_.ObjectId -eq $($servicePrincipal.ObjectId) }
				
				if(-not $memberInGroup){
					$context.Error("Group Membership was not successful when adding Service Principal '$($ServicePrincipleId)' to group '$($aadGroup.DisplayName)' ($($aadGroup.ObjectId)) using module 'Add-AzureRmADGroupMember'")
					return $false
				}
			}
			$context.Display("   MemberShipID: "+ ($memberInGroup.ObjectId))


			$context.Display("5. Adding ServicePrincipleId {magenta}$($aadGroup.ObjectId){gray} Access to key vault {magenta}$($KeyVaultName){gray}")
			
			# Add Access Policies
			Set-AzureRmKeyVaultAccessPolicy -VaultName $KeyVaultName -ObjectId $($aadGroup.ObjectId)  -PermissionsToKeys $PermissionsToKey -PermissionsToSecrets $PermissionsToSecrets -PermissionsToCertificates $PermissionsToCertificates
		}
		else{
			$context.Display("Adding ServicePrincipleId {magenta}$($ServicePrincipleId){gray} Access to key vault {magenta}$($KeyVaultName){gray}")

			Set-AzureRmKeyVaultAccessPolicy -VaultName $KeyVaultName -ObjectId $($ServicePrincipleId) -PermissionsToKeys $PermissionsToKey -PermissionsToSecrets $PermissionsToSecrets -PermissionsToCertificates $PermissionsToCertificates
		}
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

		if(-not $action.Parameters().Validate(@("KeyVaultName", "PermissionsToKey", "PermissionsToSecrets", "PermissionsToCertificates"))){
			return $false
		}
		
		# Return Bool
		return $true
	};
	
}