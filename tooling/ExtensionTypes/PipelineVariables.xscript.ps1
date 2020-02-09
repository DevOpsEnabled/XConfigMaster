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
        
        # $context.Display("{magenta}Pipelines Enter:{gray}`r`n$($mainElement.Outerxml | Format-Xml)`r`n`r`n")
        $elements = $mainElement.SelectNodes("./PipelineVariables")
        foreach($element in $elements){
        
            if($element.VariableGroupName){
                $pipelineVariables = $element.SelectNodes("PipelineVariable[@Name]")
                foreach($pipelineVariable in $pipelineVariables){
                    $pipelineVariable.SetAttribute("VariableGroupName", $element.VariableGroupName)
                }
            }
            
            
            $pipelineVariables = $element.SelectNodes("./PipelineVariable[@Name]")
            foreach($pipelineVariable in $pipelineVariables){
                $context.Display("Moving {magenta}$($pipelineVariable.Name){gray}")
                $moved = $element.ParentNode.InsertBefore($pipelineVariable, $element)
            }
            
            $removed = $element.ParentNode.RemoveChild($element)
        }
        
        # $context.Display("{magenta}Pipelines Exits:{gray}`r`n$($mainElement.Outerxml | Format-Xml)`r`n`r`n")
        return $mainElement
    };
    
}