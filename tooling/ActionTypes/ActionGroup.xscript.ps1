
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
	# Action Type Default Parameters
	[object] $context,
	[object] $action,

	[ValidateSet('Validate','Clean','Execute')]
	[string] $lifeCycle,

	# Set to true in the 'Validation' Lifecycle
	[switch] $WhatIf,

	# Set to true in the 'Clean' Lifecycle
	[switch] $Clean
)

$allWorked = $true
foreach($subAction in $action.Actions().Items()){
	if($lifeCycle -eq "Clean"){
		$allWorked = $subAction.Clean() -and $allWorked
	}
	elseif($lifeCycle -eq "Validate"){
		$allWorked = $subAction.Validate() -and $allWorked
	}
	elseif($lifeCycle -eq "Execute"){
		$allWorked = $subAction.ExecuteAction() -and $allWorked
	}
	else{
		$context.Error("Unknown Lifecycle '{white}$($lifeCycle){gray}'... Script validation should have caught this")
		$allWorked = $false
	}
}
return $allWorked