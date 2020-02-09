#:xheader:
#Type=InputType;
#:xheader:

return @{
    Clean = 
    {
        Param([ConfigAutomationContext] $context,[UIInputStrategy] $inputStrategy)
        $context.Action("Parameters", "Clearing Output Variable '{white}$($inputStrategy.OutputVariableName){gray}'")
        $currentScope = $inputStrategy.CurrentScope()
        if($currentScope.OutputVariables.ContainsKey($inputStrategy.OutputVariableName)){
            $currentScope.OutputVariables.Remove($inputStrategy.OutputVariableName)
        }
        return $true
    };
    InputValue = 
    {
        Param([ConfigAutomationContext] $context,[UIInputStrategy] $inputStrategy)
        if(-not $inputStrategy.CurrentScope().ExpectedOutputVariables.ContainsKey($inputStrategy.OutputVariableName)){
            return $null
        }
        return $inputStrategy.CurrentScope().OutputVariables[$inputStrategy.OutputVariableName]
    };
    InputMetadata = 
    {
        Param([ConfigAutomationContext] $context,[UIInputStrategy] $inputStrategy, [System.Xml.XmlElement] $element)
        $variableName = $element.GetAttribute("VariableName")
            
        if(-not ($variableName) ){
            throw "Not all the attributes to build the input strategy '$($inputStrategy.Name())' of type 'VariableName', element were found:`r`n  VariableName:$($element.GetAttribute("VariableName"))`r`n )"
        }
        
        $currentScope = $inputStrategy.CurrentScope()
        [Helper]::SetPropertyIfNotExists($currentScope, "hashtable", "OutputVariables", [hashtable]::new())
        [Helper]::SetPropertyIfNotExists($currentScope, "hashtable", "ExpectedOutputVariables", [hashtable]::new())
        [Helper]::SetProperty($inputStrategy, "String", "OutputVariableName", $variableName)


        $currentScope.ExpectedOutputVariables[$variableName] = $true

        $inputStrategy | Add-Member -MemberType ScriptMethod -Name "ToString" -Value {
            return "Out {white}$($this.OutputVariableName){gray}`r`n"
        } -Force
        $inputStrategy | Add-Member -MemberType ScriptMethod -Name "Shorthand" -Value {
            return "$($this.OutputVariableName)"
        } -Force

        if(-not ($context.psobject.methods | Foreach {$_.Name} | Where {$_ -eq "InjectOutputVariable"})){
            $context | Add-Member -MemberType ScriptMethod -Name "InjectOutputVariable" -Value {
                Param([UIAction] $action, [string] $varName, [string] $varValue)

                $parents = $action.GetAllParents($true)
                $context = $action.Context()

                $context.Display("{white}[{magneta}$($varName){white}]{gray} - $($varValue)")

                # $foundScope = $null
                $scopeResults = @()
                foreach($parent in $parents){

                    if(-not [Helper]::HasProperty($parent, "OutputVariables")){
                        # $context.Display("{red}No Output Variables{white} are xpected")
                        # $scopeResults += (new-object psobject -Property @{Status = "{red}No Output Variables{white} are xpected"; Scope = $parent})
                        continue
                    }

                    if(-not $parent.ExpectedOutputVariables.ContainsKey($varName)){	
                        # $context.Display("{red}No Output Variable $($varName){gray} were expected")
                        # $scopeResults += (new-object psobject -Property @{Status = "{red}No Output Variable $($varName){gray} were expected"; Scope = $parent})
                        continue
                    }
                                
                    if($parent.OutputVariables[$varName]){
                        $oldValue = $parent.OutputVariables[$varName]
                        $newValue = $varValue
                        # $context.Display("{yellow}Overwriting{white} Output Variable $($varName){gray} old {white}$($oldValue){gray}, new {white}$($newValue){gray}")
                        $scopeResults += (new-object psobject -Property @{Status = "{yellow}Overwriting{white}Output Variable $($varName){gray} old {white}$($oldValue){gray}, new {white}$($newValue){gray}"; Scope = $parent})
                        $parent.OutputVariables[$varName] = $varValue
                        continue
                    }

                    if($parent.OutputVariables[$varName] -eq $false){
                        $oldValue = $parent.OutputVariables[$varName]
                        $newValue = $varValue
                        # $context.Display("{green}Overwriting Valid{white} Output Variable $($varName){gray} old {white}$($oldValue){gray}, new {white}$($newValue){gray}")
                        $scopeResults += (new-object psobject -Property @{Status = "{green}Overwriting Valid{white}Output Variable $($varName){gray} old {white}$($oldValue){gray}, new {white}$($newValue){gray}"; Scope = $parent})
                        $parent.OutputVariables[$varName] = $varValue
                        continue
                    }

                    $scopeResults += (new-object psobject -Property @{Status = "{green}New Output Variable{white} $($varName){gray} added as {white}$($varValue){gray}"; Scope = $parent})
                    # $context.Display("{green}New Output Variable{white} $($varName){gray} added as {white}$($varValue){gray}")
                    $parent.OutputVariables[$varName] = $varValue
                }
                foreach($result in $scopeResults){
                    $context.PushIndent()
                    $context.Display("{white}[{magenta}$($result.Scope.Name()){white}]{gray} - $($result.Status)")
                }

                foreach($result in $scopeResults){
                    $context.PopIndent()
                }
            }
        }
                        
        return $name
    };
}