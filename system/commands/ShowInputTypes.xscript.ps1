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
    $types = $context.GetRootScope().InputTypes().Items()
    foreach($type in $types){
        if($type.ContentType() -eq "ScriptFile"){
            $context.Display("{white}$($type.Name()){gray} - $($type.Content())")
        }
        else{
            $context.Display("{white}$($type.Name()){gray} ")
        }
    }

}