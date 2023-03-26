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
	[switch] $Clean,

	# Content that will be printed on the screen
	[ValidatePattern(".+")]
	[string] $Content
)

if($lifeCycle -eq 'Validate'){
	$context.Display("WhatIf: $($content)")
	return $true
}
if($lifeCycle -eq 'Clean'){
	return $true
}
if($lifeCycle -eq 'Execute'){
	$context.Display("WhatIf: $($content)")
	return $true
}