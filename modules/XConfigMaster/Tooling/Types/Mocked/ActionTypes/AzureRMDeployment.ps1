@{
	Clean = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		return $true
	};
	Action = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		
		$overrideParametersScript = $this.Parameters().Get("OverrideParametersScript").Value()
		if(-not (Test-Path $($overrideParametersScript))){
			$context.Error("Override Parameters file does not exists: {white}$($overrideParametersScript){gray}")
			return $false
		}
		
		$extracted = $action.Parameters().Extract(@("DeploymentName", "ResourceGroup", "Location", "Template", "TemplateParameters", "OutputVariables"))
		
		$extracted.TemplateParameters = $extracted.TemplateParameters -replace "`n",''
		$extracted.TemplateParameters = $extracted.TemplateParameters -replace "`r",''
		if(-not $extracted.DeploymentName){
			$extracted.DeploymentName = ((Get-ChildItem($extracted.Template)).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm'))
		}
		
		$context.Display("{yellow}:: Skipping actual executing (In Mock Mode){gray}")
		
		$expectedVariables = [hashtable]::new()
		$content = ""
		
		$DeploymentName             = $extracted.DeploymentName
		$ResourceGroupName          = $extracted.ResourceGroup
		$ResourceGroupLocation      = $extracted.Location
		$TemplateFile               = $extracted.Template
		$TemplateParametersFile     = $extracted.TemplateParameters
		$OverrideTemplateParameters = new-object hashtable
		
		$overrideParameterSection = $action.Get("Sections").Get("OverrideTemplateParameters")
		
		foreach($parameter in $overrideParameterSection.Parameters().Items()){
			if($parameter.TestProperty("IsSecret", "true", $true)){
				$OverrideTemplateParameters.Add($parameter.Name(), (ConvertTo-SecureString -String $parameter.Value() -Force -AsPlainText))
			}
			else{
				$OverrideTemplateParameters.Add($parameter.Name(), $parameter.Value())
			}
		}
		
		New-AzureRmResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation -Verbose -Force
		$content = New-AzureRmResourceGroupDeployment -Name $DeploymentName `
                                       -ResourceGroupName $ResourceGroupName `
                                       -TemplateFile $TemplateFile `
                                       -TemplateParameterFile $TemplateParametersFile `
									   									@OverrideTemplateParameters `
                                       -Force -Verbose -ErrorVariable ErrorVar
									  
		if ($ErrorVar) {
			$context.Error( @('', 'Template deployment returned the following errors:', (ConvertTo-Json $ErrorVar)) -join "`r`n");
			$context.Display("`r`n{white}Result:{gray}`r`n{gray}" + $content)
			return $false
		}
		
		if($content){
			$context.Display("Content Type: " + $content.GetType())
			if($extracted.OutputVariables)
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
		else{
			$context.Display("Content Type: {red}Null{gray}")
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
		
		$overrideParametersScript = $this.Parameters().Get("OverrideParametersScript").Value()
		if(-not (Test-Path $($overrideParametersScript))){
			$context.Error("Override Parameters file does not exists: {white}$($overrideParametersScript){gray}")
			return $false
		}
		
		if(-not $action.Parameters().Validate(@("ResourceGroup", "Location", "Template", "TemplateParameters"))){
			return $false
		}
		
		$action.LoadChildren()
		$action.Get("Sections").LoadChildren()
		if(-not $action.Get("Sections").Get("OverrideTemplateParameters")){
			$context.Error("Expected Section 'OverrideTemplateParameters' for override parameters")
			return $false
		}
		$action.Get("Sections").Get("OverrideTemplateParameters").LoadChildren()
		$overrideParameterSection = $action.Get("Sections").Get("OverrideTemplateParameters")
		if(-not $overrideParameterSection.Parameters().ValidateAllParameters()){
			$context.Error("Section 'OverrideTemplateParameters' has some parameters that are invalid")
			return $false
		}
		

		$OutputVariables = $action.Parameters().Get("OutputVariables", $false).Value($false)
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

		$extracted = $action.Parameters().Extract(@("ResourceGroup", "Location", "Template", "TemplateParameters", "OverrideTemplateParameters", "OutputVariables"))
		if(-not (Test-Path $extracted.Template) -and (-not $action.TestProperty("Validate", "AtRunTime", $true))){
			$context.Error("Action {white}$($action.Name()){gray} of type {white}$($action.ActionType().Name()){gray} - Template {white}$($extracted.ScriptPath){gray} was not found`r`n{white}$($extracted.Template){gray}")
			return $false
		}
		if(-not (Test-Path $extracted.TemplateParameters) -and (-not $action.TestProperty("Validate", "AtRunTime", $true))){
			$context.Error("Action {white}$($action.Name()){gray} of type {white}$($action.ActionType().Name()){gray} - Template {white}$($extracted.ScriptPath){gray} was not found{white}$($extracted.TemplateParameters){gray}")
			return $false
		}
		
		
		
		return $true
	};
	
}