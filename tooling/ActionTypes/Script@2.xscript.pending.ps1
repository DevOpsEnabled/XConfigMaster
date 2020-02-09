<#
.SYNOPSIS
	A brief description of the function or script.

.DESCRIPTION
	A longer description.

.PARAMETER FirstParameter
	Description of each of the parameters.
	Note:
	To make it easier to keep the comments synchronized with changes to the parameters,
	the preferred location for parameter documentation comments is not here,
	but within the param block, directly above each parameter.

.PARAMETER SecondParameter
	Description of each of the parameters.

.INPUTS
	Description of objects that can be piped to the script.

.OUTPUTS
	Description of objects that are output by the script.

.EXAMPLE
	Example of how to run the script.

.LINK
	Links to further documentation.

.NOTES
	Detail on what the script does, if this is needed.

#>

#:xheader:
#Type=ActionType;
#ScriptPath=$(ScriptProxyActionTypeFilePath);
#mainScriptPath=$(ThisFile);
#includeActionTypeParameters=true;
#cleanEnabled=true;
#hideVerbose=true;
#:xheader:
Param(
	# XConfigMaster Context
	[object] $context,

	# XConfigMaster Current action
	[object] $action,

	# Set to true in the 'Validation' Lifecycle
	[Parameter(Mandatory=$true, ParameterSetName="ValidateLifecycle_ScriptFileMode")]
	[Parameter(Mandatory=$true, ParameterSetName="ValidateLifecycle_ScriptBlockMode")]
	[switch] $Validate,

	# Set to true in the 'Clean' Lifecycle
	[Parameter(Mandatory=$true, ParameterSetName="CleanLifecycle")]
	[switch] $Clean,

	# Set to true in the 'Execute' Lifecycle
	[Parameter(Mandatory=$true, ParameterSetName="ExecuteLifecycle_ScriptFileMode")]
	[Parameter(Mandatory=$true, ParameterSetName="ExecuteLifecycle_ScriptBlockMode")]
	[switch] $Execute,

	# What type of execution
	[Parameter(Mandatory=$true, ParameterSetName="ExecuteLifecycle_ScriptFileMode")]
	[string] $ScriptPath,

	# Arguments sent to the script
	[Parameter(Mandatory=$true, ParameterSetName="ExecuteLifecycle_ScriptFileMode")]
	[string] $ScriptArguments,

	# Script block that will be executed in string form
	[Parameter(Mandatory=$true, ParameterSetName="ExecuteLifecycle_ScriptBlockMode")]
	[string] $ScriptBlock,

	# What type of execution
	[Parameter(Mandatory=$false, ParameterSetName="ValidateLifecycle_ScriptFileMode")]
	[string] $ValidationScriptPath,

	# Arguments sent to the script
	[Parameter(Mandatory=$false, ParameterSetName="ValidateLifecycle_ScriptFileMode")]
	[string] $ValidationScriptArguments,

	# Script block that will be executed in string form
	[Parameter(Mandatory=$false, ParameterSetName="ValidateLifecycle_ScriptBlockMode")]
	[string] $ValidationScriptBlock,

	# Script block that will be executed in string form
	[Parameter(Mandatory=$false)]
	[string] $WorkingDirectory,

	# Expected output variables
	[ValidatePattern('([^,]+)')]
	[Parameter(Mandatory=$false)]
	[string] $OutputVariables,

	# What type of session
	[ValidateSet("NewSession")]
	[Parameter(Mandatory=$false)]
	[string] $ScriptScope


)
Process
{
	if($PSCmdlet.ParameterSetName -eq "CleanLifecycle")
	{
		return $true
	}

	if($PSCmdlet.ParameterSetName -eq "ExecuteLifecycle_ScriptBlockMode")
	{
		$extracted = $ScriptBlock
		$tempFile  = New-TemporaryFile
		$tempPs1   = [System.IO.Path]::ChangeExtension($tempFile, "ps1")
		
		Rename-Item $tempFile $tempPs1
		
		($extracted.ScriptBlock) | Set-Content $tempPs1
		$ScriptPath = $tempPs1
		$ScriptArguments = ""
	}

	if($PSCmdlet.ParameterSetName -eq "ValidateLifecycle_ScriptBlockMode")
	{
		if(-not $ValidationScriptBlock -and -not $OutputVariables){
			$context.Display("No Validation Script Block was available alone with no needed outputs")
			return $true;
		}
		if(-not $ValidationScriptBlock -and $OutputVariables){
			$matches = ([regex]'([^,]+)').Matches($OutputVariables)
			$ValidationScriptBlock = @($matches | ForEach-Object {$_.Groups[1].Value} | ForEach-Object {
				return ('Write-Host "##vso[task.setvariable variable='+$_+';]False')
			}) -join "`r`n"
		}
		$extracted = $ValidationScriptBlock
		$tempFile  = New-TemporaryFile
		$tempPs1   = [System.IO.Path]::ChangeExtension($tempFile, "ps1")
		
		Rename-Item $tempFile $tempPs1
		
		($extracted.ScriptBlock) | Set-Content $tempPs1
		$ScriptPath = $tempPs1
		$ScriptArguments = ""
	}
	if($PSCmdlet.ParameterSetName -eq "ValidateLifecycle_ScriptFileMode")
	{
		if(-not $ValidationScriptPath -and -not $OutputVariables){
			$context.Display("No Validation Script File was available alone with no needed outputs")
			return $true;
		}
		if(-not $ValidationScriptPath -and $OutputVariables){
			$matches = ([regex]'([^,]+)').Matches($OutputVariables)
			$ValidationScriptBlock = @($matches | ForEach-Object {$_.Groups[1].Value} | ForEach-Object {
				return ('Write-Host "##vso[task.setvariable variable='+$_+';]False')
			}) -join "`r`n"
		}
		$ScriptPath = $ValidationScriptPath
		$ScriptArguments = $ValidationScriptArguments
	}
	
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

	# Run Actual Script
	$ScriptArguments = $ScriptArguments -replace "`n",''
	$ScriptArguments = $ScriptArguments -replace "`r",''
	
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
		Remove-Item $temp
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
		Remove-Item $temp
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
}

	