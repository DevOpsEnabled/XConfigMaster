#:xheader:
#Type=ActionType;
#ScriptPath=$(ScriptProxyActionTypeFilePath);
#mainScriptPath=$(ThisFile);
#includeActionTypeParameters=true;
#hideVerbose=true;
#:xheader:

Param(
	# Action Type Default Parameters
	[ConfigAutomationContext] $context,
	[UIAction] $action,

	# Set to true in the 'Validation' Lifecycle
	[switch] $WhatIf
)

if($WhatIf){
	$context.Display("WhatIf...")
    return $true
}
else{
    $action.CurrentScope().ParentScope().LoadChildren()
    $actions = $action.CurrentScope().ParentScope().Actions().Items()
    foreach($action in $actions){
        $context.Display("{white}$($action.Name()){gray}")
    }

}