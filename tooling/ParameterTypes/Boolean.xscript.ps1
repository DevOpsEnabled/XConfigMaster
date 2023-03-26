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
        if($name -ieq "True" -or $name -ieq "`$true"){
            return $true
        }
        return $false
    };
    TransformParameterType = 
    {
        Param([ConfigAutomationContext] $context)
        return [bool]
    };
    TransformParameterUse = 
    {
        Param([ConfigAutomationContext] $context, [string]$inputObj)
        if($inputObj -ieq "True" -or $inputObj -ieq "`$true"){
            return $true
        }
        return $false
    };
    GenerateDynamicParameters = 
    {
        Param([ConfigAutomationContext] $context, [System.Management.Automation.RuntimeDefinedParameterDictionary]$dynamicParameters, [UIParameter] $parameter, [UIInputCollection] $inputs)
        return $dynamicParameters
    };
}