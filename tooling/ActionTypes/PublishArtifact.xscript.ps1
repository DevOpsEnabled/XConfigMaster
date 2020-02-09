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
		$extracted = $action.Parameters().Extract(@("ArtifactSubName", "PathToPublish", "PathToPublishTo"))
		
		$context.Display("{yellow}:: Skipping actual executing (In Mock Mode){gray}")
		$extracted.PathToPublishTo = [System.IO.Path]::Combine($extracted.PathToPublishTo, $extracted.ArtifactSubName)
		$extracted.PathToPublish = [System.IO.Path]::Combine($extracted.PathToPublish, "./*")
		if(-not (Test-Path $($extracted.PathToPublishTo))){
			$result = New-Item $($extracted.PathToPublishTo) -ItemType Directory
			foreach($item in $result){
				$context.Display($($item.ToString()))
			}
		}
		$result = Copy-Item -Path $($extracted.PathToPublish) -Destination $($extracted.PathToPublishTo) -Recurse
		foreach($item in $result){
			$context.Display($($item.ToString()))
		}
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

		if(-not $action.Parameters().Validate(@("ArtifactSubName", "PathToPublish", "PathToPublishTo"))){
			return $false
		}
		$extracted = $action.Parameters().Extract(@("ArtifactSubName", "PathToPublish", "PathToPublishTo"))
		
		return $true
	};
	
}