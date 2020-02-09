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
	#$context.Display("WhatIf...")
}
else{
    $actionTypes = $context.GetRootScope().ActionTypes().Items()
    foreach($actionType in $actionTypes){
        if($actionType.ContentType() -eq "ScriptFile"){
            $script = $actionType.Content()
            
            if($actionType.GetProperty("mainScriptPath")){
                $script = $actionType.GetProperty("mainScriptPath")

                $context.Display("{white}[{magenta}$($actionType.Name()){white}]{gray} - $($script)")
                $context.PushIndent()
                $help = Get-Help $([System.IO.Path]::GetFullPath($script))
            
                if($help){
                    foreach($syntax in $help.syntax.syntaxItem){
                        
                        $parameters = $syntax.parameter | Where-Object {-not ($_.Name -in @("context", "action", "lifeCycle", "WhatIf", "Clean","Validate","Execute"))}
                        foreach($parameter in $parameters){
                            $optional = ""
                            if($parameter.Required){
                                $optional = " (Required)"
                            }
                            $context.Display("{white}$($parameter.Name){gray}$($optional)")
    
                            $context.PushIndent()
                            $context.Display("$($parameter.description.Text)`r`n")
                            $context.PopIndent()        
                        }
                    }
                    
                    
                }
                else{
                    $context.Display("No Help was found...")
                }
                $context.PopIndent()
            }
            else{
                $context.Display("{white}$($actionType.Name()){gray} - $($script)")
            }
            
        }
        else{
            $context.Display("{white}$($actionType.Name()){gray} ")
        }
    }

}