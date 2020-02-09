#:xheader:
#Type=ExtensionType;
#:xheader:

return @{
    DefineExtension = 
    {
        Param([ConfigAutomationContext] $context, [UIConfigMasterExtension] $resource, [System.Xml.XmlElement] $element)
        $Search      = $element.GetAttribute("Search")
        $ReplaceWith = $element.GetAttribute("ReplaceWith")
    
        
    };
    
    AppyExtension = 
    {
        Param([ConfigAutomationContext] $context, [UIConfigMasterExtension] $extensionType, [System.Xml.XmlElement] $main)
        
        
        $elements = @($main.SelectNodes($extensionType.XPath()))
        $context.Display("Extension {white}Replace{gray}, Number of elements [$($elements.Count)]")
        foreach($element in $elements){
            
            $xmlContent = $element.Body.InnerXml
            foreach($rule in $element.ReplaceRule){
                $Search      = $rule.GetAttribute("Search")
                $ReplaceWith = $rule.GetAttribute("ReplaceWith")
                $xmlContent = $xmlContent.Replace($Search, $ReplaceWith)
            }
            
            [XML]$xml = "<Root>$($xmlContent)</Root>"
            
            
            foreach($replaceItem in $xml.Root.ChildNodes){
                if($replaceItem.Name -eq "ConfigAutomation"){
                    foreach($replaceItem in $replaceItem.ChildNodes){
                        $imported = $element.OwnerDocument.ImportNode($replaceItem, $true)
                        $item = $element.ParentNode.AppendChild($imported)
                    }
                    continue
                }
                $imported = $element.OwnerDocument.ImportNode($replaceItem, $true)
                $item = $element.ParentNode.AppendChild($imported)
            }
            
            $item = $element.ParentNode.RemoveChild($element)
            
            # $context.Display("Performed Replace:")
            # $context.Display($main.OuterXml)
        }
        
        
        return $main
    };
    
}