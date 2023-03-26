#:xheader:
#Type=ActionType;
#:xheader:

@{
	Clean = 
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
			if(-not (Test-Path $backedFilePath)){
				$context.Error("File Path '{white}$($backedFilePath){gray}' failed to be deleted")
				$success = $false
			}
			del $backedFilePath
		}
		return $success
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
			$fileContent = [System.IO.File]::ReadAllText($file)
			if(-not ($action.ValidateValue("File '$($file)'", $fileContent))){
				$context.Error("Some Referenced Parameters in File Path '{white}$($file){gray}' failed validation")
				return $false
			}
			
			$fileContent = $action.ParameterizeString($fileContent)
			$backedFilePath = [System.IO.Path]::ChangeExtension($file,"xconfigmaster.bak")
			copy $($file) $($backedFilePath)
			if(-not (Test-Path $backedFilePath)){
				$context.Error("File Path '{white}$($file){gray}' failed to be backed up")
				return $false
			}
			
			[System.IO.File]::WriteAllText($file, $fileContent)
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
			$fileContent = [System.IO.File]::ReadAllText($file)
			$fileContent = $action.ParameterizeString($fileContent)
			if(-not ($action.ValidateValue($fileContent, "File '$($file)'", $true))){
				$context.Error("Some Referenced Parameters in File Path '{white}$($file){gray}' failed validation")
				$success = $false
			}
			
			$backedFilePath = [System.IO.Path]::ChangeExtension($file,"xconfigmaster.bak")
			copy $($file) $($backedFilePath)
			if(-not (Test-Path $backedFilePath)){
				$context.Error("File Path '{white}$($file){gray}' failed to be backed up")
				$success = $false
			}
		}
		
		# Return Bool
		return $success
	};
	
}