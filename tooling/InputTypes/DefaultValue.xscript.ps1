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
        Param([ConfigAutomationContext] $context,[UIInputStrategy] $inputStrategy)
        return $inputStrategy.DefaultValue
    };
    InputMetadata = 
    {
        Param([ConfigAutomationContext] $context,[UIInputStrategy] $inputStrategy, [System.Xml.XmlElement] $element)
        $defaultValue = $element.InnerText
        
        if(-not $defaultValue){
            $defaultValue = $element.GetAttribute("DefaultValue")
        }
        if(-not ($defaultValue) ){
            throw "Not all the attributes to build the input strategy '$($inputStrategy.Name())' of type 'DefaultValue', element were found:`r`n  DefaultValue:$($element.GetAttribute("DefaultValue"))`r`n )"
        }

        $defaultValue = $defaultValue.Trim()
        $inputStrategy | Add-Member -MemberType NoteProperty -Name "DefaultValue" -Value $($defaultValue) -TypeName String -Force

        $inputStrategy | Add-Member -MemberType ScriptMethod -Name "ToString" -Value {
            return "Default {white}$($this.DefaultValue){gray}`r`n"
        } -Force
        $inputStrategy | Add-Member -MemberType ScriptMethod -Name "Shorthand" -Value {
            return "$($this.DefaultValue)"
        } -Force
        return $name
    };
}