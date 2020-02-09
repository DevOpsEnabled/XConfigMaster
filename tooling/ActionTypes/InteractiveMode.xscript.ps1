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
		
		$context.PopActionLevel()
		do{
			$command = Read-Host "Enter command arguments"
			if($command -eq "q"){
				return $true
			}
			Function ConvertFrom-CommandLine{
				Param([string] $command)
				$arguments = New-Object System.Collections.ArrayList	
				$command = ([regex]"((?:^| )\-+[^ ]+)").Replace($command, {
					Param( [System.Text.RegularExpressions.Match] $match)
					
					$index = $arguments.Add($match.Groups[1].Value)
					return " _$($index)_ "
				})
				
				$command = ([regex]'((?:^| )\"(.*?)\")').Replace($command, {
					Param( [System.Text.RegularExpressions.Match] $match)
					
					$index = $arguments.Add($match.Groups[2].Value)
					return " _$($index)_ "
				})
				
				$command = ([regex]'((?:^| )[^ ]+)').Replace($command, {
					Param( [System.Text.RegularExpressions.Match] $match)
					if($match.Value -match "_\d+_"){
						return $match.Value
					}
					$index = $arguments.Add($match.Groups[1].Value)
					return " _$($index)_ "
				})
				
				$command = $command.Replace(" ","")
				$command = ([regex]'_(\d+)_').Replace($command, {
					Param( [System.Text.RegularExpressions.Match] $match)
					$id = -1
					if(-not [int]::TryParse($match.Groups[1].Value, [ref] $id)){
						throw "Should not be here. ID: 1234"
					}
					return "," + $arguments[$id].Trim()
				})
				$command = $command -replace "^\,(.*)",'$1'
				if(-not $command.Contains(",")){
					return @($command)
				}
				$args = $command -split ","
				return $args
			}
			$args = ConvertFrom-CommandLine $command
			
			$parameters = [hashtable]::new()
			$actions    = @()
			
			for($i=0;$i -lt $args.length;$i+=1){
			
				if(-not ($args[$i].GetType() -eq [string])){
					$context.Error("Arg[$($i)] - Not a string and was expecting it to be was actually $($args[$i].GetType())")
					continue
				}
				
				if($args[$i] -match "^\-+(.*)"){
					$argName = $Matches[1]
					if(($i+1) -ge $args.length){
						$parameters.Add($argName, $true)
						continue
					}
					
					$parameters.Add($argName, $args[$i+1])
					$i+=1
					continue
				}
				
				if($args[$i] -match "^\/(.*)"){
					$actions += $Matches[1]	
					continue
				}
				
				$actions += $args[$i]
				
			}
			
			$context.PopulateFromArguments($parameters)
			$context.ExecuteActionsFromArguments($actions)
		}while($true)
		
		return $false
	};
	CanExecute = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		return $true
	};
	Validate = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		return $true
	};
	
}