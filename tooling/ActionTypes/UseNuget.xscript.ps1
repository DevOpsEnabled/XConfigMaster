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
		
		$extracted = $action.Parameters().Extract(@("NugetVersion"))
		
		$temp = New-TemporaryFile
		$exe = [System.IO.Path]::ChangeExtension($temp, "exe")
		ren $temp $exe
		$nugetFile = $exe
		
		$context.Display("Downloading NuGet {white}v$($nugetFile){gray}")
		Invoke-WebRequest -Uri https://dist.nuget.org/win-x86-commandline/v$($extracted.NugetVersion)/nuget.exe -OutFile $nugetFile
		$context.InjectOutputVariable($action, "NugetExePath", $nugetFile)
		
		$context.PushScope($context.GetRootScope())
		$xml = [XML]@"
<ConfigAutomation>
	<PostAction Name="Cleaning Nuget Exe - Deleting $($nugetFile)" Type="CleanFolder">
		<Parameter Name="Folder" Value="$($nugetFile)"/>
	</PostAction>
</ConfigAutomation>		
"@
		$context.PopulateFromXml($xml.ConfigAutomation, $context.CurrentScope())
		$context.PopScope()
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

		if(-not $action.Parameters().Validate(@("NugetVersion"))){
			return $false
		}
		$context.InjectOutputVariable($action, "NugetExePath","Test Version")
		return $true
	};
	
}