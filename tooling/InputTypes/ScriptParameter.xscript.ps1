#:xheader:
#Type=InputType;
#:xheader:

return @{
    Clean = 
    {
        Param([ConfigAutomationContext] $context,[UIInputStrategy] $inputStrategy)
        
        return $true
    };
    InputValue = 
    {
        Param([ConfigAutomationContext] $context,[UIInputStrategy] $inputStrategy, [object] $arguments)
        
        if(-not $context.ParameterArguments()){
            return $null
        }
        
        $args =  $context.ParameterArguments()
        $value = $args[$inputStrategy.ParamName]
        # Write-Host "Getting Script Parameter '$($inputStrategy.ParamName)' which is found to be '$($value)'"
        
        return $value
    };
    InputMetadata = 
    {
        Param([ConfigAutomationContext] $context, [UIInputStrategy] $inputStrategy, [System.Xml.XmlElement] $element)
        
        if(-not ($element.GetAttribute("ParamName") )){
            throw "Not all the attributes to build the input strategy '$($inputStrategy.Name())' of type 'ParamName', element were found:`r`n  ParamName:$($element.GetAttribute("ParamName"))`r`n )"
        }
        
        $value = $($element.GetAttribute("ParamName").ToString())
        
        $parameterName   = $value
        $parameterType   = "String"
        
        # $context.GetExpectedParameters().Add($parameterName, $parameterType)
        # Write-Host "Updating Update to add 'ParamName' as '$($value)'"
        $inputStrategy | Add-Member -MemberType NoteProperty -Name "ParamName" -Value $value -TypeName String -Force

        $inputStrategy | Add-Member -MemberType ScriptMethod -Name "ToString" -Value {
            return "Parameter {white}$($this.ParamName){gray} | {magenta}Example {gray}-$($this.ParamName) '$($this.ParamName)'"
        } -Force
        $inputStrategy | Add-Member -MemberType ScriptMethod -Name "Shorthand" -Value {
            return "-$($this.ParamName)"
        } -Force
        return $name
    };
}