#:xheader:
#Type=ExtensionType;
#:xheader:

return @{
    DefineExtension = 
    {
        Param([ConfigAutomationContext] $context, [UIConfigMasterExtension] $resource, [System.Xml.XmlElement] $element)
    };
    
    AppyExtension = 
    {
        Param([ConfigAutomationContext] $context, [UIConfigMasterExtension] $extensionType, [System.Xml.XmlElement] $mainElement)
        
        # $context.Display("{magenta}Pipeline Enter:{gray}`r`n$($mainElement.Outerxml | Format-Xml)`r`n`r`n")
        $elements = $mainElement.SelectNodes("PipelineVariable[@Name]")
        foreach($element in $elements){
            $name = $element.GetAttribute("Name")
            
            $paramName = $name -replace "\.","-"
            $envName   = $name -replace "\.","_"
            
            $paramName      = $paramName.ToLower()
            $envName        = $envName.ToUpper()
            $defaultValue   = $element.GetAttribute("DefaultValue") | ??: ($element.InnerText)
            $keyVaultSecret = $element.GetAttribute("KeyVaultSecret")
            
            $newElementXmlText = "<Parameter Name=`"$($name)`">"
            
            $priority = 1
            
            $newElementXmlText += "`r`n   <InputStrategy Priority=`"$($priority)`" Type=`"ScriptParameter`" ParamName=`"$($paramName)`"/>"
            $priority += 1
            
            $newElementXmlText += "`r`n   <InputStrategy Priority=`"$($priority)`" Type=`"EnvironmentVariable`" EnvName=`"$($envName)`"/>"
            $priority += 1
            
            
            if($keyVaultSecret){
                if(-not ($keyVaultSecret -match "^([^\\\/]+)[\/\\]([^\\\/]+)$")){
                    throw "Unable to apply config extension on PipelineVariable. KeyVaultSecret must follow the following format 'KeyVault\SecretName' or 'KeyVault/SecretName'"
                    return $null
                }
                $keyVaultName       = $Matches[1]
                $keyVaultSecretName = $Matches[2]
                $skipCachingValue = $element.GetAttribute("SkipCachingValue")
                if($skipCachingValue){
                    $newElementXmlText += "`r`n   <InputStrategy Priority=`"$($priority)`" Type=`"KeyVaultSecret`" KeyVaultName=`"$($keyVaultName)`" SecretName=`"$($keyVaultSecretName)`" SkipCachingValue=`"$($skipCachingValue)`"/>"
                }
                else{
                    $newElementXmlText += "`r`n   <InputStrategy Priority=`"$($priority)`" Type=`"KeyVaultSecret`" KeyVaultName=`"$($keyVaultName)`" SecretName=`"$($keyVaultSecretName)`"/>"
                }
                $priority += 1
            }
            if($defaultValue){
                $newElementXmlText += "`r`n   <InputStrategy Priority=`"$($priority)`" Type=`"DefaultValue`">$($defaultValue)</InputStrategy>"
                $priority += 1
            }
            $newElementXmlText += "`r`n</Parameter>"
            
            [XML] $newElementDoc = "<Root>$($newElementXmlText)</Root>"
            $newElement = $mainElement.OwnerDocument.ImportNode($newElementDoc.FirstChild.Parameter, $true)
            $newElement = $element.ParentNode.ReplaceChild($newElement, $element)
            # $context.Display("Replacing PipelineVariable $($newElement.Name)")
        }
        # $context.Display("{magenta}Pipeline Exit:{gray}`r`n$($mainElement.Outerxml | Format-Xml)`r`n`r`n")
        return $mainElement
    };
    
}