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
		
		$extracted = $action.Parameters().Extract(@("FolderPath", "FileFormat"))
		if(-not (Test-Path $extracted.FolderPath)){
			$context.Error("File Path '{white}$($extracted.FolderPath){gray}' did not exists")
			return $false
		}
		
		$files = @()
		$formats = $extracted.FileFormat -split ";"
		foreach($format in $formats){
			$files = @($files) + @(Get-ChildItem -Path $($extracted.FolderPath) -Filter $($format) -Recurse)
		}
		$success = $true
		foreach($file in $files){
			$file = $file.FullName
			if(-not ([System.IO.File]::Exists($file))){
				continue
			}
			if($file -match ".*\.xconfigmaster\.bak$"){
				continue
			}
			$backedFilePath = [System.IO.Path]::ChangeExtension($file,"xconfigmaster.bak")
			copy $($backedFilePath) $($file)
			del $backedFilePath
			if((Test-Path $backedFilePath)){
				$context.Error("Backup File Path '{white}$($backedFilePath){gray}' was expected to be deleted but wasnt")
				$success = $false
			}
		}
		# Return Bool
		return $success
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
			
		if(-not $action.Parameters().Validate(@("FolderPath", "FileFormat"))){
			return $false
		}
		
		$extracted = $action.Parameters().Extract(@("FolderPath", "FileFormat"))
		if(-not (Test-Path $extracted.FolderPath)){
			$context.Error("File Path '{white}$($extracted.FolderPath){gray}' did not exists")
			return $false
		}
		
		$files = @()
		$formats = $extracted.FileFormat -split ";"
		foreach($format in $formats){
			$files = @($files) + @(Get-ChildItem -Path $($extracted.FolderPath) -Filter $($format) -Recurse)
		}
		$success = $true
		foreach($file in $files){
			$file = $file.FullName
			if(-not ([System.IO.File]::Exists($file))){
				continue
			}
			if($file -match ".*\.xconfigmaster\.bak$"){
				continue
			}
			$backedFilePath = [System.IO.Path]::ChangeExtension($file,"xconfigmaster.bak")
			if(-not (Test-Path $backedFilePath)){
				$context.Error("Backup File Path '{white}$($backedFilePath){gray}' was not found and unable to back up file")
				$success = $false
			}
		}
		# Return Bool
		return $success
	};
	
}