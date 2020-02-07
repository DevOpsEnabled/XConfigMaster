@{
	Clean = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		return $true
	};
	Action = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		$extracted = $action.Parameters().Extract(@("SourceFolder", "Contents", "TargetFolder", "FlattenFolders"))
		
		$SourceFolder   = $extracted.SourceFolder
		$TargetFolder   = $extracted.TargetFolder
		$Contents       = $extracted.Contents
		$FlattenFolders = $extracted.FlattenFolders
		$Contents = $Contents -split "`n" | Foreach {$_.Trim()}
		$include      = @($Contents | Where {$_[0] -ne "!"}                                          | Foreach {"'$_'"}) -join " "
		$excludeDir   = @($Contents | Where {$_ -match "^\!(.*[\/\\])\*$"}                             | Foreach {$_ -replace "^\!(.*[\/\\])\*$",'''$1'''}) -join " "
		$excludeFiles = @($Contents | Where {$_[0] -eq "!" -and (-not ($_ -match "^\!.*[\/\\]\*$"))} | Foreach {$_ -replace "^\!(.*)$)",'''$1'''}) -join " "
		$robocopy = "robocopy '$($SourceFolder)' '$($TargetFolder)' $include /xf $excludeFiles /xd $excludeDir /s"

		
		$context.Display($robocopy)
		Invoke-Expression $robocopy
		
		if($FlattenFolders -ieq "true" -or $FlattenFolders -eq $true){
			$context.Display("Flattening Folders")
			Get-ChildItem -Path $TargetFolder -Recurse -Filter "*.*" | Where-Object {[System.IO.File]::Exists($_.FullName)} | Move-Item -Destination "$($TargetFolder)/$($_.Name)"
			$directories = [System.IO.Directory]::GetDirectories($TargetFolder)
			foreach($directory in $directories){
				$context.Display("Removing Directory $($directory)")
				[System.IO.Directory]::Delete($directory, $true)
			}
		}
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

		if(-not $action.Parameters().Validate(@("SourceFolder", "Contents", "TargetFolder"))){
			return $false
		}

		if($action.TestProperty("DontSkipInValidation", "true", $true)){
			$extracted = $action.Parameters().Extract(@("SourceFolder", "Contents", "TargetFolder", "FlattenFolders"))
		
			$SourceFolder   = $extracted.SourceFolder
			$TargetFolder   = $extracted.TargetFolder
			$Contents       = $extracted.Contents
			$FlattenFolders = $extracted.FlattenFolders
			$Contents = $Contents -split "`n" | Foreach {$_.Trim()}
			$include      = @($Contents | Where {$_[0] -ne "!"}                                          | Foreach {"'$_'"}) -join " "
			$excludeDir   = @($Contents | Where {$_ -match "^\!(.*[\/\\])\*$"}                             | Foreach {$_ -replace "^\!(.*[\/\\])\*$",'''$1'''}) -join " "
			$excludeFiles = @($Contents | Where {$_[0] -eq "!" -and (-not ($_ -match "^\!.*[\/\\]\*$"))} | Foreach {$_ -replace "^\!(.*)$)",'''$1'''}) -join " "
			$robocopy = "robocopy '$($SourceFolder)' '$($TargetFolder)' $include /xf $excludeFiles /xd $excludeDir /s"

			
			$context.Display($robocopy)
			Invoke-Expression $robocopy
			
			if($FlattenFolders -ieq "true" -or $FlattenFolders -eq $true){
				$context.Display("Flattening Folders")
				Get-ChildItem -Path $TargetFolder -Recurse -Filter "*.*" | Where-Object {[System.IO.File]::Exists($_.FullName)} | Move-Item -Destination "$($TargetFolder)/$($_.Name)"
				$directories = [System.IO.Directory]::GetDirectories($TargetFolder)
				foreach($directory in $directories){
					$context.Display("Removing Directory $($directory)")
					[System.IO.Directory]::Delete($directory, $true)
				}
			}
			return $true
		}
		else{
			$extracted = $action.Parameters().Extract(@("SourceFolder", "Contents", "TargetFolder"))
		
			if(-not (Test-Path $($extracted.SourceFolder))){
				$context.Error("SourceFolder '{white}$($extracted.SourceFolder){gray}' does not exists")
				return $false
			}
			
			return $true
		}
		
	};
	
}