#:xheader:
#Type=ActionType;
#:xheader:

@{
	Clean = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		return $true
	};
	Action = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		
		# $extracted = $action.Parameters().Extract(@("RefLoading"))
		# $obj = $context.Ref($extracted.RefLoading)
		# if(-not $obj){
		# 	$context.Error("Ref '{white}$($extracted.RefLoading){gray}' was not found")
		# 	return $false
		# }
		
		# $xmlDefinition = $obj.XmlDefinition()
		# $xmlTxt = $xmlDefinition.OuterXml
		# $xmlTxt = $action.ParameterizeString($xmlTxt,$false, "@")
		# [XML]$xmlDefinition = $xmlTxt
		
		# $context.PopulateFromXml($xmlDefinition, $action.ParentScope())
		
		return $true
	};
	CanExecute = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		return $true
	};
	Validate = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)

		if(-not $action.Parameters().Validate(@("RefLoading"))){
			return $false
		}
		$obj = $context.Ref($extracted.RefLoading)
		if(-not $obj){
			$context.Error("Ref '{white}$($extracted.RefLoading){gray}' was not found")
			return $false
		}
		
		$xmlDefinition = $obj.XmlDefinition()
		$xmlTxt = $xmlDefinition.OuterXml
		$xmlTxt = $action.ParameterizeString($xmlTxt, $false, "@")
		if(-not $action.ValidateValue($xmlTxt, "XML Content for $($action.FullName())", "@", $true)){
			$context.Error("Validation of the XML Content failed")
			return $false
		}
		
		[XML]$xmlDefinition = $xmlTxt
		$context.PopulateFromXml($xmlDefinition.FirstChild, $action.ParentScope())
		
		return $true
	};
	
}