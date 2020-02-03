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
		
		$extracted = $action.Parameters().Extract(@("FilePath"))
		if(-not (Test-Path $extracted.FilePath)){
			$context.Error("File Path '{white}$($extracted.FilePath){gray}' did not exists")
			return $false
		}
		
		$backedFilePath = [System.IO.Path]::ChangeExtension($extracted.FilePath,"xconfigmaster.bak")
		copy $($backedFilePath) $($extracted.FilePath)
		del $backedFilePath
		if((Test-Path $backedFilePath)){
			$context.Error("Backup File Path '{white}$($backedFilePath){gray}' was expected to be deleted but wasnt")
			return $false
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
			
		if(-not $action.Parameters().Validate(@("FilePath"))){
			return $false
		}
		
		$extracted = $action.Parameters().Extract(@("FilePath"))
		if(-not (Test-Path $extracted.FilePath)){
			$context.Error("File Path '{white}$($extracted.FilePath){gray}' did not exists")
			return $false
		}
		$backedFilePath = [System.IO.Path]::ChangeExtension($extracted.FilePath,"xconfigmaster.bak")
		if(-not (Test-Path $backedFilePath)){
			$context.Error("Backup File Path '{white}$($backedFilePath){gray}' was not found and unable to back up file")
			return $false
		}
		# Return Bool
		return $true
	};
	
}