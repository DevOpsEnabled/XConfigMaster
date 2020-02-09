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
        $value = [Environment]::GetEnvironmentVariable($inputStrategy.EnvName)
        # Write-Host "Getting Script Parameter '$($inputStrategy.EnvName)' which is found to be '$($value)'"
        return $value
    };
    InputMetadata = 
    {
        Param([ConfigAutomationContext] $context,[UIInputStrategy] $inputStrategy, [System.Xml.XmlElement] $element)
        if(-not ($element.GetAttribute("EnvName") )){
            throw "Not all the attributes to build the input strategy '$($inputStrategy.Name())' of type 'EnvName', element were found:`r`n  EnvName:$($element.GetAttribute("EnvName"))`r`n )"
        }
        $inputStrategy | Add-Member -MemberType NoteProperty -Name "EnvName" -Value $($element.GetAttribute("EnvName").ToString()) -TypeName String -Force
        
        $inputStrategy | Add-Member -MemberType ScriptMethod -Name "ToString" -Value {
            return "Env {white}$($this.EnvName){gray}`r`n"
        } -Force
        $inputStrategy | Add-Member -MemberType ScriptMethod -Name "Shorthand" -Value {
            return "`$env:$($this.EnvName)"
        } -Force
        return $name
    };
}