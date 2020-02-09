#:xheader:
#Type=ParameterType;
#:xheader:

return @{
    Validate = 
    {
        Param([ConfigAutomationContext] $context, [object]$name, [UIParameter] $parameter)
        
        if($parameter._properties.ContainsKey("LoadedResource")){
            if($parameter._properties["LoadedResource"] -and $parameter._properties["LoadedResource"].Name -ieq $name){
                return $true
            }
            
        }
        try{
            $resource = $context.AzureRmResources($name, $null, $null) | Where {$_.ResourceType -eq 'Microsoft.web/sites'}
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
        
        if($parameter._properties.ContainsKey("LoadedResource")){
            if($parameter._properties["LoadedResource"].Name -ieq $name){
                return $parameter._properties["LoadedResource"]
            }
            
        }
        
        $resource = $context.AzureRmResources($name, $null, $null) | Where {$_.ResourceType -eq 'Microsoft.web/sites'}
        $parameter._properties["LoadedResource"] = $resource
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