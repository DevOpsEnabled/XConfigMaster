#:xheader:
#Type=ExtensionType;
#:xheader:

return @{
    DefineExtension = 
    {
        Param([ConfigAutomationContext] $context, [UIConfigMasterExtension] $resource, [System.Xml.XmlElement] $element)
        $resource | Add-Member -MemberType NoteProperty -Name "WrappingXml" -Value $null -TypeName String -Force
        $resource | Add-Member -MemberType ScriptMethod -Name "ToString"  -Value {
            return "$($this.Name()) - `r`n$($this.WrappingXml)"
        } -Force
        
        if(($element.InnerXml )){
            $resource.WrappingXml = $element.InnerXml
            return
        }
        
        throw "Not all the attributes to build the resource type element were found:`r`n  Name:$($element.GetAttribute("Name"))`r`n  Content:$($element.InnerXml)`r`n)"
        
    };
    
    AppyExtension = 
    {
        Param([ConfigAutomationContext] $context, [UIConfigMasterExtension] $extensionType, [System.Xml.XmlElement] $element)
        if($element.GetAttribute("SkipExtensions") -eq "True"){
            return $element
        }
        $element.SetAttribute("SkipExtensions","True")
        $xmlContent = $element.OuterXml
        $xmlContent = $extensionType.WrappingXml.Replace('|CONTENT|', $xmlContent)
        [XML]$xml = "<Root>$($xmlContent)</Root>"
        return $xml.Root.FirstChild
    };
    
}