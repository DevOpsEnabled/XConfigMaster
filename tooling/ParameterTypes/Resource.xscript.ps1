#:xheader:
#Type=ParameterType;
#:xheader:

return @{
    Validate = 
    {
        Param([ConfigAutomationContext] $context, [object]$name, [UIParameter] $parameter)
        
        try{
            $resource = $context.AzureRmResources($name, $null, $null)
            if(-not $resource){
                $context.Error("Resource $($name) was not found")
                return $false
            }
        }
        catch{
            $context.Error("Resource $($name) was unable to be fetched: {red}$($_.Exception.Message)")
            return $false
        }
        return $true
    };
    TransformInput = 
    {
        Param([ConfigAutomationContext] $context, [string]$name, [UIParameter] $parameter)
        
        
        $resource = $context.AzureRmResources($name, $null, $null)
        return $resource
    };
    TransformParameterType = 
    {
        Param([ConfigAutomationContext] $context)
        return [object]
    };
    TransformParameterUse = 
    {
        Param([ConfigAutomationContext] $context, [string]$inputObj)
        
        return $inputObj
    };
    GenerateDynamicParameters = 
    {
        Param([ConfigAutomationContext] $context, [System.Management.Automation.RuntimeDefinedParameterDictionary]$dynamicParameters, [UIParameter] $parameter, [UIInputCollection] $inputs)
        
        
        return $dynamicParameters
    };
}