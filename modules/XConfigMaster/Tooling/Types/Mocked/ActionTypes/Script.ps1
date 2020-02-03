@{
	Clean = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		return $true
	};
	Action = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		
		$extracted = $action.Parameters().Extract(@("ScriptPath", "ScriptArguments"))
		
		$scriptBlockContent = ".'$($extracted.ScriptPath)' $($extracted.ScriptArguments)"
		$extracted.ScriptArguments = $extracted.ScriptArguments -replace "`n",''
		$extracted.ScriptArguments = $extracted.ScriptArguments -replace "`r",''

		$context.Display("{white}Executing:{gray}`r`n" + $scriptBlockContent)

		$tempFile = New-TemporaryFile
		$context.Display("{yellow}:: Skipping actual executing (In Mock Mode){gray}")
		$expectedVariables = [hashtable]::new()
		
		$content = ""
		
		$OutputVariables = $action.Parameters().Get("OutputVariables").Value($false)
		if($OutputVariables)
		{
			$matches = ([regex]'([^,]+)').Matches($OutputVariables)
			if($matches.Count -gt 0){
				foreach($match in $matches){
					$varName  = $match.Groups[1].Value
					$expectedVariables.Add($varName, $null)
					$content +=  'Write-Host "##vso[task.setvariable variable='+$varName+']Mocked '+$varName+'"'+"`r`n"
				}

			}
		}

		$actualVariables = [hashtable]::new()
		if($content){
			$matches = ([regex]'(\#\#vso\[task.setvariable variable\=)(.*?)(\])(.*)').Matches($content)

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

		$extracted = $action.Parameters().Extract(@("ScriptPath", "ScriptArguments"))
		if(-not (Test-Path $extracted.ScriptPath)){
			$context.Error("Action {white}$($action.Name()){gray} of type {white}$($action.ActionType().Name()){gray} - ScriptPath {white}$($extracted.ScriptPath){gray} was not found")
			return $false
		}
		
		$extracted.ScriptArguments = $extracted.ScriptArguments -replace '`n',''
		
		
		return $true
	};
	
}