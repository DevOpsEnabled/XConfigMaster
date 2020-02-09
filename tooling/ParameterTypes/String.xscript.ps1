#:xheader:
#Type=ParameterType;
#:xheader:

return @{
    Validate = 
    {
        Param([ConfigAutomationContext] $context, [object]$name)
        return $true
    };
    TransformInput = 
    {
        Param([ConfigAutomationContext] $context, [string]$name)
        return $name
    };
    TransformParameterType = 
    {
        Param([ConfigAutomationContext] $context)
        return [string]
    };
    TransformParameterUse = 
    {
        Param([ConfigAutomationContext] $context, [string]$inputObj)
        if($inputObj -eq $false){
            return "[NOT SET]"
        }
        return $inputObj
    };
    GenerateDynamicParameters = 
    {
        Param([ConfigAutomationContext] $context, [System.Management.Automation.RuntimeDefinedParameterDictionary]$dynamicParameters, [UIParameter] $parameter, [UIInputCollection] $inputs)
        
        
        
        $dynamicParAttrs = New-Object  System.Collections.ObjectModel.Collection[System.Attribute]
        
        
        $parameterName   = $parameter.ParameterName()
        
        $parameterType   = $parameter.ParameterType().Definition().TransformParameterToCodeType($inputs)
        $input           = $context.Inputs().Get($parameter.ParameterName())

        $parentScope  = $parameter.CurrentScope().ParentScope()
        $currentScope = $parameter.CurrentScope()
        if($parentScope){
        
            if($parentScope.Parameters().Get($parameter.ParameterName(), $true)){
                $prefixScopeName = $parameter.GetAllParents() | ForEach {$_.Name()} -join "."
                $parameterName = "$($prefixScopeName):$($parameterName)"
            }
        }
        $GenericAttr  = New-Object System.Management.Automation.ParameterAttribute
        $GenericAttr.ParameterSetName  = "__AllParameterSets"   	 
        $dynamicParAttrs.Add($GenericAttr)

        $RuntimeParam  = New-Object System.Management.Automation.RuntimeDefinedParameter($parameterName,  $parameterType, $dynamicParAttrs)
        if(-not $dynamicParameters.ContainsKey($parameterName)){
            $dynamicParameters.Add($parameterName,  $RuntimeParam)
        }
        
        return $dynamicParameters
    };
}