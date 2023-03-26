<#
.SYNOPSIS
	A brief description of the function or script.

.DESCRIPTION
	A longer description.

.PARAMETER FirstParameter
	Description of each of the parameters.
	Note:
	To make it easier to keep the comments synchronized with changes to the parameters,
	the preferred location for parameter documentation comments is not here,
	but within the param block, directly above each parameter.

.PARAMETER SecondParameter
	Description of each of the parameters.

.INPUTS
	Description of objects that can be piped to the script.

.OUTPUTS
	Description of objects that are output by the script.

.EXAMPLE
	Example of how to run the script.

.LINK
	Links to further documentation.

.NOTES
	Detail on what the script does, if this is needed.

#>

#:xheader:
#Type=ActionType;
#ScriptPath=$(ScriptProxyActionTypeFilePath);
#mainScriptPath=$(ThisFile);
#includeActionTypeParameters=true;
#cleanEnabled=true;
#:xheader:
Param(
	# Action Type Default Parameters
	[object] $context,
	[object] $action,

	[ValidateSet('Validate','Clean','Execute')]
	[string] $lifeCycle,

	# Set to true in the 'Validation' Lifecycle
	[switch] $WhatIf,

	# Set to true in the 'Clean' Lifecycle
	[switch] $Validate,
	
	# Set to true in the 'Clean' Lifecycle
	[switch] $Execute,
	
	# Set to true in the 'Clean' Lifecycle
    [switch] $Clean,
    
	# Personal Access Token. Cannot be given along with Oath Token
	# [ValidateScript(
	# 	{
	# 		if (-not ($PAT -or $Oath)) {
	# 			throw "Either 'PAT' or 'Oath' is required. None is not excepted"
	# 		}
	# 		if ($PAT -and $Oath) {
	# 			throw "Either 'PAT' or 'Oath' is required. Both are not excepted"
	# 		}
	# 	}
	# )]
    [Parameter()]
    [string] $PAT,

	# Oath Token. Cannot be given along with Personal Access Token
	# [ValidateScript(
	# 	{
	# 		if (-not ($PAT -or $Oath)) {
	# 			throw "Either 'PAT' or 'Oath' is required. None is not excepted"
	# 		}
	# 		if ($PAT -and $Oath) {
	# 			throw "Either 'PAT' or 'Oath' is required. Both are not excepted"
	# 		}
	# 	}
	# )]
    [Parameter()]
	[string] $Oath,
	
	# REST Method. Allowed Values are 'Get', 'Post', and 'Put'
	[ValidateSet('Get','Post','Put')]
	[Parameter(Mandatory=$true)]
	[string] $Method,
	
	# Instance. This is the organization url. In the format of https://dev.azure.com/xconfigmaster
	[Parameter(Mandatory=$true)]
	[string] $Instance,

	# Represents the project we are referencing. Currently not supporting Organization level rest api calls.
	[Parameter(Mandatory=$true)]
	[string] $Project,

	# The area of the API. Find more here https://docs.microsoft.com/en-us/rest/api/azure/devops/?view=azure-devops-rest-5.1
	[Parameter(Mandatory=$true)]
	[string] $Area,

	# The resource of the API. Find more here https://docs.microsoft.com/en-us/rest/api/azure/devops/?view=azure-devops-rest-5.1
	[Parameter(Mandatory=$true)]
	[string] $Resource,

	# Represents the RouteParameters portion of the URL
	# Final Url will be in the following format:
	# {Instance}/{Project}/{Area}/{Resource}/{RouteParameters}?{QueryParameters}
	[Parameter(Mandatory=$false)]
	[string] $RouteParameters,

	# Represents the QueryParameters portion of the URL
	# Final Url will be in the following format:
	# {Instance}/{Project}/{Area}/{Resource}/{RouteParameters}?{QueryParameters}
	[Parameter(Mandatory=$false)]
	[string] $QueryParameters,

	# The resource of the API. Find more here https://docs.microsoft.com/en-us/rest/api/azure/devops/?view=azure-devops-rest-5.1
	[Parameter(Mandatory=$false)]
	[string] $Body = $null,

	# The name of the variable that will be used to export the results of the api to. 
	# Note:
	# The type of this parameter should be of type Object.
	[Parameter(Mandatory=$false)]
	[string] $OutputVariable

	
    
)
Process{


	$url = "$($Instance)/$($Project)/_apis/$($Area)/$($Resource)/$($RouteParameters)?$($QueryParameters)"
	if($WhatIf){
		$url = "WhatIf: "+$url
	}

	$context.Display("{white}$($Method){gray} $($url)")
	$headers = [hashtable]::new()
	$headers.Add("Content-Type","application/json; charset=utf-8")
	$headers.Add("Cache-Control","no-cache")

	if($PAT){
		$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f "",$this.PersonalAccessToken)))
		$headers.Add("Authorization",("Basic {0}" -f $base64AuthInfo))
	}
	elseif($Oath){
		$base64AuthInfo = $this.OathToken
		$headers.Add("Authorization",("Bearer {0}" -f $base64AuthInfo))
	}
	else{
		$context.Error("No PAT or Oath was provided... We should have caught this during script parameter validations")
		return $false
	}

	if($WhatIf){
		$obj = @{
			Mocked = "Mocked"
		}
	}
	else{
		if($Method -ieq "Get"){
			$obj = Invoke-RestMethod $url -Method $Method -Headers $headers -ContentType "application/json; charset=utf-8" -ErrorAction SilentlyContinue -ErrorVariable RestCallError -WarningAction SilentlyContinue -WarningVariable RestCallWarning
		}
		else{
			$obj = Invoke-RestMethod $url -Method $Method -Headers $headers -Body $Body -ContentType "application/json; charset=utf-8" -ErrorAction SilentlyContinue -ErrorVariable RestCallError -WarningAction SilentlyContinue -WarningVariable RestCallWarning
		}
	}
	
	

	if($RestCallError){
		$context.Error("Rest Call Failed`r`n$($RestCallError.Message)")
		return $false
	}
	if($RestCallWarning){
		$context.Warning("Rest Call through warnings:`r`n$($RestCallError.Message)")
	}

	if($OutputVariable){
		$context.InjectOutputVariable($action, $OutputVariable, $($obj | ConvertTo-Json))
	}

	return $true

}
