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
		
		$extracted = $action.Parameters().Extract(@("ScriptType", "OutputVariables", "ScriptScope", "WorkingDirectory"))
		$WorkingDirectory = $extracted.WorkingDirectory
		if($WorkingDirectory){
			$context.Display("{magenta}Working Directory: {gray}'{white}$($WorkingDirectory){gray}'")
			if(-not (Test-Path $WorkingDirectory)){
				$context.Error("Action {white}$($action.Name()){gray} of type {white}$($action.ActionType().Name()){gray} - WorkingDirectory {white}$($WorkingDirectory){gray} was not found")
				return $false
			}
			$WorkingDirectory = [System.IO.Path]::GetFullPath($WorkingDirectory)
		}
		else{
			$context.Display("{magenta}Working Directory: {gray}'{red}Not Found...{gray}'")
		}
		
		if($extracted.ScriptType -eq "Inline"){
			$extracted = $action.Parameters().Extract(@("ScriptBlock"))
			$tempFile  = New-TemporaryFile
			$tempPs1   = [System.IO.Path]::ChangeExtension($tempFile, "ps1")
			
			ren $tempFile $tempPs1
			
			($extracted.ScriptBlock) | Set-Content $tempPs1
			$extracted | Add-Member -MemberType NoteProperty -Name "ScriptPath" -Value $tempPs1 -Force
			$extracted | Add-Member -MemberType NoteProperty -Name "ScriptArguments" -Value "" -Force
		}
		elseif($extracted.ScriptType -eq "ScriptFile" -or (-not $extracted.ScriptType )){
			$extracted = $action.Parameters().Extract(@("ScriptPath", "ScriptArguments", "ScriptScope"))
		}
		
		# Run Actual Script
		$extracted.ScriptArguments = $extracted.ScriptArguments -replace "`n",''
		$extracted.ScriptArguments = $extracted.ScriptArguments -replace "`r",''
		
		$__vsts_input_failOnStandardError   = $action.TestProperty("failOnStandardError","true")
		$__vsts_input_errorActionPreference = $action.TestProperty("errorActionPreference","true")
		if(-not $__vsts_input_errorActionPreference){
			$__vsts_input_errorActionPreference = "stop"
		}
		
		if($extracted.ScriptScope -eq "NewSession"){
			$scriptCommand = "&`"powershell.exe`" `"&'$($extracted.ScriptPath)' $($extracted.ScriptArguments)`""
			# $scriptCommand = "&powershell.exe "+'"'+"$($extracted.ScriptPath)"+'"'+" $($extracted.ScriptArguments)"
			$temp = New-TemporaryFile
			$scriptCommand += "  | Select-WriteHost | out-file '$temp'"
			if($WorkingDirectory){
				$scriptCommand = "pushd '$($WorkingDirectory)'`r`n " + $scriptCommand + "`r`n popd"
			}
			$context.Display("{white}Command:{gray}`r`n$($scriptCommand)")
			$results = Invoke-Expression $scriptCommand
			$content = Get-Content $temp -Raw
			del $temp
		}
		elseif(-not $extracted.ScriptScope){
			$scriptCommand = "&'$($extracted.ScriptPath)' $($extracted.ScriptArguments)"
			# $scriptCommand = "&powershell.exe "+'"'+"$($extracted.ScriptPath)"+'"'+" $($extracted.ScriptArguments)"
			$temp = New-TemporaryFile
			$scriptCommand += " | out-file '$temp'"
			
			if($WorkingDirectory){
				$scriptCommand = "pushd '$($WorkingDirectory)'`r`n " + $scriptCommand + "`r`n popd"
			}
			$context.Display("{white}Command:{gray}`r`n$($scriptCommand)")
			$results = Invoke-Expression $scriptCommand
			
			$content = Get-Content $temp -Raw
			del $temp
		}
		else{
			$context.Error("Unknown valid of {white}ScriptScope{gray} ({white}$($extracted.ScriptScope){gray}). Allowed values are '{white}NewSession{gray}' and '{white}SameSession{gray}'")
			return $false
		}
		
		$context.Display("{white}Result:{gray}`r`n$($content)")
		$results = $results | ForEach-Object {
				if($_ -is [System.Management.Automation.ErrorRecord]) {
					if($_.FullyQualifiedErrorId -eq "NativeCommandError" -or $_.FullyQualifiedErrorId -eq "NativeCommandErrorMessage") {
						,$_
						if($__vsts_input_failOnStandardError -eq $true) {
							"##vso[task.complete result=Failed]"
						}
					}
					else {
						if($__vsts_input_errorActionPreference -eq "continue") {
							,$_
							if($__vsts_input_failOnStandardError -eq $true) {
								"##vso[task.complete result=Failed]"
							}
						}
						elseif($__vsts_input_errorActionPreference -eq "stop") {
							throw $_
						}
					}
				} else {
					,$_
				}
			}
		$expectedVariables = [hashtable]::new()
		
		$OutputVariables = $action.Parameters().Get("OutputVariables").Value($false)
		if($OutputVariables)
		{
			$matches = ([regex]'([^,]+)').Matches($OutputVariables)
			if($matches.Count -gt 0){
				foreach($match in $matches){
					$varName  = $match.Groups[1].Value
					$expectedVariables.Add($varName, $null)
				}

			}
		}

		$actualVariables = [hashtable]::new()
		if($content){
			$matches = ([regex]"(\#\#vso\[task.setvariable variable\=)([^\;]+?)(;{0,1}\])([^`r`n]*)").Matches($content)

			if($matches.Count -gt 0){
				$context.Display("{gray}{white}Output Variables{gray} - Found [{white}$($matches.Count){gray} variables")
				$context.PushIndent()

				foreach($match in $matches){
					$varName  = $match.Groups[2].Value
					$varValue = $match.Groups[4].Value

					if(-not $expectedVariables.ContainsKey($varName)){
						$context.Error("Action {white}$($action.Name()){gray} of type {white}$($action.ActionType().Name()){gray} - Output Variable {white}$($varName){gray} was not expected")
						continue
					}

					$actualVariables.Add($varName, $varValue)
					$context.InjectOutputVariable($action, $varName, $varValue)
				}

				$context.PopIndent()
			}
			
			$expectedVariables.GetEnumerator() | % {
				if(-not $actualVariables.ContainsKey($varName)){
					$context.Error("Action {white}$($action.Name()){gray} of type {white}$($action.ActionType().Name()){gray} - Output Variable {white}$($varName){gray} was expected but not found in the output")
				}
			}
			
			$context.Display("`r`n{white}Result:{gray}`r`n{gray}" + $content)
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

		# $parameterNames = (($action.Parameters().Items() | Foreach {"$($_.ToString())"})) -join "`r`n            "
		
		$extracted = $action.Parameters().Extract(@("ScriptType", "WorkingDirectory"))
		$context.Display("{cyan}Parameters: {gray}'{white}$($parameterNames){gray}'")
		if($extracted.WorkingDirectory){
			$context.Display("{magenta}Working Directory: {gray}'{white}$($extracted.WorkingDirectory){gray}'")
			if(-not (Test-Path $extracted.WorkingDirectory)){
				$context.Error("Action {white}$($action.Name()){gray} of type {white}$($action.ActionType().Name()){gray} - WorkingDirectory {white}$($extracted.WorkingDirectory){gray} was not found")
				return $false
			}
		}
		else{
			$context.Display("{magenta}Working Directory: {gray}'{red}Not Found...{gray}'")
		}
		
		if($extracted.ScriptType -eq "Inline"){
			if(-not $action.Parameters().Validate(@("ScriptBlock"))){
				return $false
			}
			
			$OutputVariables = $action.Parameters().Get("OutputVariables").Value($false)
			if($OutputVariables)
			{
				$matches = ([regex]'([^,]+)').Matches($OutputVariables)

				if($matches.Count -gt 0){
					$context.Display("{gray}{white}Output Variables{gray} - Found [{white}$($matches.Count){gray} variables")
					$context.PushIndent()

					foreach($match in $matches){
						$varName  = $match.Groups[1].Value
						$varValue = $false

						$context.InjectOutputVariable($action, $varName, $varValue)
					}

					$context.PopIndent()
				}
			}
			
		}
		
		elseif($extracted.ScriptType -eq "ScriptFile" -or (-not $extracted.ScriptType )){
			if(-not $action.Parameters().Validate(@("ScriptPath", "ScriptArguments"))){
				return $false
			}
			
			$OutputVariables = $action.Parameters().Get("OutputVariables").Value($false)
			if($OutputVariables)
			{
				$matches = ([regex]'([^,]+)').Matches($OutputVariables)

				if($matches.Count -gt 0){
					$context.Display("{gray}{white}Output Variables{gray} - Found [{white}$($matches.Count){gray} variables")
					$context.PushIndent()

					foreach($match in $matches){
						$varName  = $match.Groups[1].Value
						$varValue = $false

						$context.InjectOutputVariable($action, $varName, $varValue)
					}

					$context.PopIndent()
				}
			}

			$extracted = $action.Parameters().Extract(@("ScriptPath", "ScriptArguments", "ValidationScriptPath", "ValidationScriptArguments"))
			if(-not (Test-Path $extracted.ScriptPath)){
				$context.Error("Action {white}$($action.Name()){gray} of type {white}$($action.ActionType().Name()){gray} - ScriptPath {white}$($extracted.ScriptPath){gray} was not found")
				return $false
			}
			
			$extracted.ScriptArguments = $extracted.ScriptArguments -replace '`n',''
			if($extracted.ValidationScriptPath){
				$context.Error("{white}ValidationScriptPath{gray} not implmented currently...")
				return $false
			}
			return $true
		}
		else{
			$context.Error("Unknown Script Type '{white}$($extracted.ScriptType){gray}'")
			return $false
		}
		
		$extracted = $action.Parameters().Extract(@("ValidationScriptBlock","ValidationScriptPath", "ValidationScriptArguments"))
		if($extracted.ValidationScriptBlock){
			$tempFile  = New-TemporaryFile
			$tempPs1   = [System.IO.Path]::ChangeExtension($tempFile, "ps1")
			
			ren $tempFile $tempPs1
			
			($extracted.ValidationScriptBlock) | Set-Content $tempPs1
			$extracted | Add-Member -MemberType NoteProperty -Name "ValidationScriptPath" -Value $tempPs1 -Force
			if(-not $extracted.ValidationScriptArguments){
				$extracted | Add-Member -MemberType NoteProperty -Name "ValidationScriptArguments" -Value "" -Force
			}
		}
		
		if($extracted.ValidationScriptPath){
		
			if($extracted.ValidationScriptScope -eq "NewSession"){
				$scriptCommand = "&`"powershell.exe`" `"&'$($extracted.ValidationScriptPath)' $($extracted.ValidationScriptArguments)`""
				# $scriptCommand = "&powershell.exe "+'"'+"$($extracted.ScriptPath)"+'"'+" $($extracted.ValidationScriptArguments)"
				$temp = New-TemporaryFile
				$scriptCommand += "  | Select-WriteHost | out-file '$temp'"
				
				$context.Display("{white}Command:{gray}`r`n$($scriptCommand)")
				$results = Invoke-Expression $scriptCommand
				$content = Get-Content $temp -Raw
				del $temp
			}
			else{
				$scriptCommand = "&'$($extracted.ValidationScriptPath)' $($extracted.ValidationScriptArguments) -Verbose"
				# $scriptCommand = "&powershell.exe "+'"'+"$($extracted.ValidationScriptPath)"+'"'+" $($extracted.ValidationScriptArguments)"
				$temp = New-TemporaryFile
				$scriptCommand += " | out-file '$temp'"
				
				$context.Display("{white}Command:{gray}`r`n$($scriptCommand)")
				$results = Invoke-Expression $scriptCommand
				
				$content = Get-Content $temp -Raw
				del $temp
			}
			
			$context.Display("{white}Result:{gray}`r`n$($content)")
			$results = $results | ForEach-Object {
					if($_ -is [System.Management.Automation.ErrorRecord]) {
						if($_.FullyQualifiedErrorId -eq "NativeCommandError" -or $_.FullyQualifiedErrorId -eq "NativeCommandErrorMessage") {
							,$_
							if($__vsts_input_failOnStandardError -eq $true) {
								"##vso[task.complete result=Failed]"
							}
						}
						else {
							if($__vsts_input_errorActionPreference -eq "continue") {
								,$_
								if($__vsts_input_failOnStandardError -eq $true) {
									"##vso[task.complete result=Failed]"
								}
							}
							elseif($__vsts_input_errorActionPreference -eq "stop") {
								throw $_
							}
						}
					} else {
						,$_
					}
				}
		}
			
		
		return $true
		
	};
	
}