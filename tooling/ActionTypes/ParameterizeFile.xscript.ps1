#:xheader:
#Type=ActionType;
#:xheader:

@{
	Clean = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		
		$extracted = $action.Parameters().Extract(@("FilePath"))
		$backedFilePath = [System.IO.Path]::ChangeExtension($extracted.FilePath,"xconfigmaster.bak")
		if(-not (Test-Path $backedFilePath)){
			$context.Error("File Path '{white}$($backedFilePath){gray}' failed to be deleted")
			return $false
		}
		del $backedFilePath
		
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
		
		$fileContent = [System.IO.File]::ReadAllText($extracted.FilePath)
		if(-not ($action.ValidateValue("File '$($extracted.FilePath)'", $fileContent))){
			$context.Error("Some Referenced Parameters in File Path '{white}$($extracted.FilePath){gray}' failed validation")
			return $false
		}
		
		$fileContent = $action.ParameterizeString($fileContent)
		$backedFilePath = [System.IO.Path]::ChangeExtension($extracted.FilePath,"xconfigmaster.bak")
		copy $($extracted.FilePath) $($backedFilePath)
		if(-not (Test-Path $backedFilePath)){
			$context.Error("File Path '{white}$($extracted.FilePath){gray}' failed to be backed up")
			return $false
		}
		
		[System.IO.File]::WriteAllText($extracted.FilePath, $fileContent)
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
		
		$fileContent = [System.IO.File]::ReadAllText($extracted.FilePath)
		$fileContent = $action.ParameterizeString($fileContent)
		if(-not ($action.ValidateValue("File '$($extracted.FilePath)'", $fileContent))){
			$context.Error("Some Referenced Parameters in File Path '{white}$($extracted.FilePath){gray}' failed validation")
			return $false
		}
		
		$backedFilePath = [System.IO.Path]::ChangeExtension($extracted.FilePath,"xconfigmaster.bak")
		copy $($extracted.FilePath) $($backedFilePath)
		if(-not (Test-Path $backedFilePath)){
			$context.Error("File Path '{white}$($extracted.FilePath){gray}' failed to be backed up")
			return $false
		}
		# Return Bool
		return $true
	};
	
}