@{
	Clean = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		return $true
	};
	Action = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		
		
		Function Find-MsBuild([int] $MaxVersion = 2017)
		{
			$agentPath = "$Env:programfiles (x86)\Microsoft Visual Studio\2017\BuildTools\MSBuild\15.0\Bin\msbuild.exe"
			$devPath = "$Env:programfiles (x86)\Microsoft Visual Studio\2017\Enterprise\MSBuild\15.0\Bin\msbuild.exe"
			$proPath = "$Env:programfiles (x86)\Microsoft Visual Studio\2017\Professional\MSBuild\15.0\Bin\msbuild.exe"
			$communityPath = "$Env:programfiles (x86)\Microsoft Visual Studio\2017\Community\MSBuild\15.0\Bin\msbuild.exe"
			$fallback2015Path = "${Env:ProgramFiles(x86)}\MSBuild\14.0\Bin\MSBuild.exe"
			$fallback2013Path = "${Env:ProgramFiles(x86)}\MSBuild\12.0\Bin\MSBuild.exe"
			$fallbackPath = "C:\Windows\Microsoft.NET\Framework\v4.0.30319"
				
			If ((2017 -le $MaxVersion) -And (Test-Path $agentPath)) { return $agentPath } 
			If ((2017 -le $MaxVersion) -And (Test-Path $devPath)) { return $devPath } 
			If ((2017 -le $MaxVersion) -And (Test-Path $proPath)) { return $proPath } 
			If ((2017 -le $MaxVersion) -And (Test-Path $communityPath)) { return $communityPath } 
			If ((2015 -le $MaxVersion) -And (Test-Path $fallback2015Path)) { return $fallback2015Path } 
			If ((2013 -le $MaxVersion) -And (Test-Path $fallback2013Path)) { return $fallback2013Path } 
			If (Test-Path $fallbackPath) { return $fallbackPath } 
				
			throw "Yikes - Unable to find msbuild"
		}
		
		$msbuildPath = Find-MsBuild
		$context.InjectOutputVariable($action, "MSBuildPath", $msbuildPath)
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
		
		Function Find-MsBuild([int] $MaxVersion = 2017)
		{
			$agentPath = "$Env:programfiles (x86)\Microsoft Visual Studio\2017\BuildTools\MSBuild\15.0\Bin\msbuild.exe"
			$devPath = "$Env:programfiles (x86)\Microsoft Visual Studio\2017\Enterprise\MSBuild\15.0\Bin\msbuild.exe"
			$proPath = "$Env:programfiles (x86)\Microsoft Visual Studio\2017\Professional\MSBuild\15.0\Bin\msbuild.exe"
			$communityPath = "$Env:programfiles (x86)\Microsoft Visual Studio\2017\Community\MSBuild\15.0\Bin\msbuild.exe"
			$fallback2015Path = "${Env:ProgramFiles(x86)}\MSBuild\14.0\Bin\MSBuild.exe"
			$fallback2013Path = "${Env:ProgramFiles(x86)}\MSBuild\12.0\Bin\MSBuild.exe"
			$fallbackPath = "C:\Windows\Microsoft.NET\Framework\v4.0.30319"
				
			If ((2017 -le $MaxVersion) -And (Test-Path $agentPath)) { return $agentPath } 
			If ((2017 -le $MaxVersion) -And (Test-Path $devPath)) { return $devPath } 
			If ((2017 -le $MaxVersion) -And (Test-Path $proPath)) { return $proPath } 
			If ((2017 -le $MaxVersion) -And (Test-Path $communityPath)) { return $communityPath } 
			If ((2015 -le $MaxVersion) -And (Test-Path $fallback2015Path)) { return $fallback2015Path } 
			If ((2013 -le $MaxVersion) -And (Test-Path $fallback2013Path)) { return $fallback2013Path } 
			If (Test-Path $fallbackPath) { return $fallbackPath } 
				
			throw "Yikes - Unable to find msbuild"
		}
		$msbuildPath = Find-MsBuild
		if(-not (Test-Path $msbuildPath)){
			$context.Error("Action {white}$($action.Name()){gray} of type {white}$($action.ActionType().Name()){gray} - Msbuild path does not exist `r`n{white}$($msbuildPath)")
			return $false
		}
		
		$context.InjectOutputVariable($action, "MSBuildPath", $msbuildPath)
		return $true
	};
	
}