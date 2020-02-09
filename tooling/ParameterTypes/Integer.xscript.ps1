#:xheader:
#Type=ParameterType;
#:xheader:

return @{
    Validate = 
    {
        Param([ConfigAutomationContext] $context, [object]$content)
        if(-not ($content -is [String])){
                $context.Error("'{white}$content{gray}' is of type {white}$($content.GetType().Name){gray}, expected {white}string{gray}")
                return $false
        }
        if(-not ($content -match '^\d+$')){
                $context.Error("'{white}$content{gray}' has non-digit characters which fails to parse as an {white}integer{gray}")
                return $false
        }
        
        return $true
    };
    TransformInput = 
    {
        Param([ConfigAutomationContext] $context, [string]$content)
        return [Int32]::Parse($content)
    };
    TransformParameterType = 
    {
        Param([ConfigAutomationContext] $context)
        return [int]
    };
    TransformParameterUse = 
    {
        Param([ConfigAutomationContext] $context, [string]$inputObj)
        if($inputObj -eq $false){
            return "[NOT SET]"
        }
        return ConvertTo-SecureString $inputObj -AsPlainText -Force
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