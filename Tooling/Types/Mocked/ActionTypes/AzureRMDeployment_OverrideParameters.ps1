

$parameters = [hashtable]::new()
$actions    = @()
for($i=0;$i -lt$args.length;$i+=1){
	
	if(-not ($args[$i].GetType() -eq [string])){
		$automationContext.Error("Arg[$($i)] - Not a string and was expecting it to be")
		continue
	}
	
	if($args[$i] -match "^\-+(.*)"){
		$argName = $Matches[1]
		if(($i+1) -ge $args.length){
			$parameters.Add($argName, $true)
			continue
		}
		
		$parameters.Add($argName.ToLower(), $args[$i+1])
		$i+=1
		continue
	}
	
	if($args[$i] -match "^\/(.*)"){
		$actions += $Matches[1]	
		continue
	}
	
	$actions += $args[$i]
	
}

if(-not $parameters.ContainsKey("TemplateParametersFile")){
	throw "Unable to provide template overrides without template parameters file: 'TemplateParametersFile'"
}
if(-not $parameters.ContainsKey("NewTemplateParametersFile")){
	throw "Unable to provide template overrides without template parameters file: 'NewTemplateParametersFile'"
}
if(-not (Test-Path $($parameters["TemplateParametersFile"]))){
	throw "Unable to provide template overrides without valid existing template parameters file: '$($parameters["TemplateParametersFile"])'"
}

$parametersJsonContent = Get-Content $($parameters["TemplateParametersFile"]) -Raw 
$parametersContent = ConvertFrom-Json $parametersJsonContent
if(-not $parametersContent.parameters){
	throw "Unable to provide template overrides without valid template parameters file, parameters property does not exists: '$($parameters["TemplateParametersFile"])'"
}

$properties = $parametersContent.parameters.psobject.properties
foreach($property in $properties){
	$propertyName = $property.Name.ToLower()
	if($parameters.ContainsKey($propertyName)){
		$oldValue = $parametersContent.parameters.{$property.Name}
		$newVaue  = $parameters[$propertyName]
		Write-Host "Overwriting Parameter '{white}$($property.Name){gray}' from '{white}$($oldValue){gray}' to '{white}$($newVaue){gray}'"
		$parametersContent.parameters.{$property.Name} = $newVaue
	}
}

Write-Host "Setting new json file '{white}$($parameters["NewTemplateParametersFile"]){gray}'"
$newJson = ConvertTo-Json $parametersContent
$newJson | Set-Content $($parameters["NewTemplateParametersFile"])






