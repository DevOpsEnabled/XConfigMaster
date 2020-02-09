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
        
        $variableGroupsScript = $extensionType.ParameterizeString("`$(ThisFolder)./../azuredevops/VSTSDump-VariableGroups.ps1")
        
        $elements = $mainElement.SelectNodes("ImportVariableGroup[@VariableGroupId]")
        foreach($element in $elements){
            $variableGroupId = $element.GetAttribute("VariableGroupId")
            $context.Display("{magenta}Loading Variable Groups: {gray}$($variableGroupId)")
            
            $tempXml = New-TemporaryFile 
            $command = "&`"powershell.exe`" `"&'$($variableGroupsScript)' -VariableGroupId $($variableGroupId)`" -ExportToFile `"$($tempXml)`""
            # $context.Display("{gray}[command] $($command)")
            $output = Invoke-Expression $command
            [XML] $newElementDoc = Get-Content $tempXml -Raw
            if($newElementDoc.FirstChild.Error){
                throw "Loading Error: {white}$($xml.FirstChild.Error){gray}"
            }
            
            $newElement = $mainElement.OwnerDocument.ImportNode($newElementDoc.FirstChild, $true)
            $newElement = $element.ParentNode.ReplaceChild($newElement, $element)
            # $context.Display("Replacing Load VariableGroup $($newElement.Name)")
            $deleted = del $tempXml
        }
        
        return $mainElement
    };
}