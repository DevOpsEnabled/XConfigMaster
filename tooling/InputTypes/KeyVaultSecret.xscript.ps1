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
        
        $keyVaultName = $inputStrategy.KeyVaultName()
        $secretName   = $inputStrategy.SecretName()
        
        
        # $context.Display("Fetching Secret {magenta}$($inputStrategy.Shorthand()){gray}")
        $secretvalueFromKeyVault = $null
        try{
            $secretvalueFromKeyVault = Get-AzureKeyVaultSecret -VaultName $keyVaultName -Name $secretName
        }
        catch{
            $context.Error("Fetching from Secret {magenta}$($inputStrategy.Shorthand()){gray} {red}failed{gray}`r`n{white}Message:{gray}`r`n$($_.Exception.Message)`r`n{white}Stack Trace:{gray}`r`n$($_.ScriptStackTrace)")
            $secretvalueFromKeyVault = $null
        }
        if($secretvalueFromKeyVault){
            
            $context.Display("{magenta}$($inputStrategy.Shorthand()){gray} - {green}Found{gray}")
            if($secretvalueFromKeyVault -and -not $inputStrategy._skipCachingValue){
                $inputStrategy.SetCacheValue($secretvalueFromKeyVault.SecretValueText)
            }
            return $secretvalueFromKeyVault.SecretValueText
        }
        else{
            $context.Display("{magenta}$($inputStrategy.Shorthand()){gray} - {red}Not Found{gray}")
            return $null
        }
        
    };
    InputMetadata = 
    {
        Param([ConfigAutomationContext] $context, [UIInputStrategy] $inputStrategy, [System.Xml.XmlElement] $element)
        
        if(-not ($element.GetAttribute("KeyVaultName") -or -not ($element.GetAttribute("SecretName")))){
            throw "Not all the attributes to build the input strategy '$($inputStrategy.Name())' of type 'ParamName', element were found:`r`n  KeyVault:$($element.GetAttribute("KeyVault"))`r`n  SecretName:$($element.GetAttribute("SecretName")) )"
        }
        
        $keyVaultName 			 = $($element.GetAttribute("KeyVaultName").ToString())
        $secretName			     = $($element.GetAttribute("SecretName").ToString())
        $skipCachingValue    = $($element.GetAttribute("SkipCachingValue"))
        $validationValue     = $($element.GetAttribute("ValidationValue"))
        
        $inputStrategy | Add-Member -MemberType NoteProperty -Name "_keyVaultName" -Value $keyVaultName -TypeName String -Force
        $inputStrategy | Add-Member -MemberType NoteProperty -Name "_secretName" -Value $secretName -TypeName String -Force
        $inputStrategy | Add-Member -MemberType NoteProperty -Name "_skipCachingValue" -Value $false -TypeName bool -Force
        $inputStrategy | Add-Member -MemberType NoteProperty -Name "_validationValue" -Value $false -TypeName Object -Force
        
        if($skipCachingValue -and $skipCachingValue.ToString() -ieq "true"){
            $inputStrategy._skipCachingValue = $true
        }
        
        $inputStrategy | Add-Member -MemberType ScriptMethod -Name "KeyVaultName" -Value {
            # $original = $this.Context()._parameterizing
            # $this.Context()._parameterizing = $false
            $value = $this.ParameterizeString($this._keyVaultName)
            # $this.Context()._parameterizing = $original
            return $value
        } -Force
        $inputStrategy | Add-Member -MemberType ScriptMethod -Name "SecretName" -Value {
            # $original = $this.Context()._parameterizing
            # $this.Context()._parameterizing = $false
            $value = $this.ParameterizeString($this._secretName)
            # $this.Context()._parameterizing = $original
            return $value
        } -Force
        
        $inputStrategy | Add-Member -MemberType ScriptMethod -Name "ToString" -Value {
            return "Key Vault Secret {white}$($this.KeyVaultName()){gray}/{white}$this.SecretName()){gray}"
        } -Force
        $inputStrategy | Add-Member -MemberType ScriptMethod -Name "Shorthand" -Value {
            return "Key Vault($($this.KeyVaultName())) Secret($($this.SecretName()))"
        } -Force
        return $name
    };
}