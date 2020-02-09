#:xheader:
#Type=ParameterType;
#:xheader:

return @{
    Validate = 
    {
        Param([ConfigAutomationContext] $context, [object]$name, [UIParameter] $parameter)
        
        if($parameter._properties.ContainsKey("LoadedAppRegistration")){
            if($parameter._properties["LoadedAppRegistration"] -and $parameter._properties["LoadedAppRegistration"].Name -ieq $name){
                return $true
            }
        }
        try{
            $appRegistration = Get-AzureADApplication -Filter "DisplayName eq '$($name)'"
            if(-not $resource){
                $context.Error("App Registration $($name) was not found")
                return $false
            }
        }
        catch{
            $context.Error("App Registration $($name) was unable to be fetched: {red}$($_.Exception.Message)")
            return $false
        }
        return $true
    };
    TransformInput = 
    {
        Param([ConfigAutomationContext] $context, [string]$name, [UIParameter] $parameter)
        
        if($parameter._properties.ContainsKey("LoadedAppRegistration")){
            if($parameter._properties["LoadedAppRegistration"] -and $parameter._properties["LoadedAppRegistration"].Name -ieq $name){
                return $true
            }
            
        }
        
        $appRegistration = Get-AzureADApplication -Filter "DisplayName eq '$($name)'"
        $parameter._properties["LoadedAppRegistration"] = $appRegistration
        return $appRegistration
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