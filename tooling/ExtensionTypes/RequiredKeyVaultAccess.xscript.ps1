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
        
        $elements = $mainElement.SelectNodes($extensionType.XPath())
        foreach($element in $elements){

            $resourceName = $element.ResourceName | ?expected -ErrorMessage "{white}ResourceName{gray} was not found in the required access definition, review XML:`r`n$($element.Outerxml)" -ErrorCallback {
                continue
            }
            $keyVaultName = $element.KeyVaultName | ?expected -ErrorMessage "{white}KeyVaultName{gray} was not found in the required access definition, review XML:`r`n$($element.Outerxml)" -ErrorCallback {
                continue
            }
            
            
            [XML]$xmlToImport = ('
            <Template Ref="access-definitions">
                <Action Name="Allow ''' + $resourceName + ''' to access key vault ''' + $keyVaultName + '''" Type="GiveKeyVaultAccess">
                    <Parameter Name="KeyVaultName" Value="' + $keyVaultName + '"/>
                    <Parameter Name="ResourceName">' + $resourceName +'</Parameter>
                    ' + ($($element.ResourceGroup) | ?: { '<Parameter Name="ResourceGroup">' + $_ + '</Parameter>' } : "") + '
                    ' + ($($element.ResourceType)  | ?: { '<Parameter Name="ResourceType">' + $_ + '</Parameter>' } : "") + '
                    ' + ($($element.PermissionsToKey) | ?: { '<Parameter Name="PermissionsToKey">' + $_ + '</Parameter>' } : "") + '
                    ' + ($($element.PermissionsToSecrets) | ?: { '<Parameter Name="PermissionsToSecrets">' + $_ + '</Parameter>' } : "") + '
                    ' + ($($element.PermissionsToCertificates) | ?: { '<Parameter Name="PermissionsToCertificates">' + $_ + '</Parameter>' } : "") + '
                </Action>
            </Template>')
            
            $newElement = $mainElement.OwnerDocument.ImportNode($xmlToImport.FirstChild, $true)
            $newElement = $element.ParentNode.ReplaceChild($newElement, $element)
        }
        
        return $mainElement
    };
}