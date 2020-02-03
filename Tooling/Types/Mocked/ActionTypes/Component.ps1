@{
	Clean = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		return $true
	};
	Action = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		$context.IsLoggingEnabled($true)
		Function Show-ArgumentBreakdown{
			Param([ConfigAutomationContext] $context,[UIAction] $action, [hashtable] $breakdown)
			
			$maxLength = 30
			$breakdown.GetEnumerator() | % { 
				if(-not ($_.Value | Where {$_.Parameter.IsRequired()})){
					return
				}
				$max = (($_.Name -split "`n") | Foreach {$_ -replace "[`r`n]",""} | Foreach {$_.length} | Measure -Max).Maximum
				if($maxLength -lt $max){
					$maxLength = $max
				}
			}
			$breakdown.GetEnumerator() | % { 
				if(-not ($_.Value | Where {$_.Parameter.IsRequired()})){
					return
				}
				$required = new-object system.Collections.ArrayList
				$indexes = $_.Value | Where {$_.Parameter.IsRequired()} | Foreach {$required.Add($_)}
				$values = ($required | Foreach {$_.Strategy.ExecuteStrategy()} )
				
				$stateTxt = "Unknown"
				$stateCol = "{gray}"
				if((($required | Foreach {$_.Parameter.Name()} | Unique).Count -gt 1)){
					$stateTxt = "Ambiguous"
					$stateCol = "{yellow}"
				}
				elseif(-not ($values | Where {$_})){
					$stateTxt = "Not Found"
					$stateCol = "{red}"
				}
				elseif(-not ($values | Where {-not $_})){
					$stateTxt = "Found"
					$stateCol = "{green}"
				}
				else{
					$stateTxt = "Partial"
					$stateCol = "{yellow}"
				}
				
				$content = ""
				if(-not $required){
					$content = $null
				}
				elseif($required.Count -eq 1){
					$lines = new-object system.collections.ArrayList
					$index = @($_.Name -split "`n") | Foreach {$lines.Add($_)}
					$name = $lines[0] + "{gray}"+ ($lines[0].PadRight($maxLength,".").Replace($lines[0],""))
					
					$foundIn = $required[0]
					
					$content = ("{0}{1,-10}{2}{3}{4}" -f ($stateCol, $stateTxt, "{white}", $name, ("{gray}: {white}$($foundIn.Parameter.Name().PadRight(50,' ')){gray} | {white}"+$foundIn.Parameter.CurrentScope().FullName()+"{gray}")))
					for($i=1;$i -lt $lines.Count; $i +=1){
						$name =$lines[$i] + "{gray}"+ ($lines[$i].PadRight($maxLength,".").Replace($lines[$i],""))
						$content += ("`r`n{0}{1,-10}{2}{3}{4}" -f ($stateCol, "", "{white}", $name, ("{gray}")))
					}
					
					
					
					
				}
				else{
					$lines = new-object system.collections.ArrayList
					$index = @($_.Name -split "`n") | Foreach {$lines.Add($_)}
					$name = $lines[0] + "{gray}"+ ($lines[0].PadRight($maxLength,".").Replace($lines[0],""))
					$i=1
					$tmpContent = $name
					foreach($foundIn in $required){
						$value = $foundIn.Strategy.ExecuteStrategy()
						$stateTxt = "Unknown"
						$stateCol = "{gray}"
						if($value){
							$stateTxt = "Found"
							$stateCol = "{green}"
						}
						else{
							$stateTxt = "Not Found"
							$stateCol = "{red}"
						}
						
						$content += "{0}{1,-10}{2}{3}{4}`r`n" -f ($stateCol, $stateTxt, "{white}",$tmpContent,("{gray}> {white}$($foundIn.Parameter.Name().PadRight(50,' ')){gray} | {white}"+$foundIn.Parameter.CurrentScope().FullName()+"{gray}"))
						
						if($lines.Count -gt $i){
							$tmpContent = $lines[$i] + "{gray}"+ ($lines[$i].PadRight($maxLength,".").Replace($lines[$i],""))
							$i += 1
						}
						else{
							$tmpContent = "".PadRight($maxLength," ")
						}
					}
					for(;$i -lt $lines.Count; $i +=1){
						$name =$lines[$i] + "{gray}"+ ($lines[$i].PadRight($maxLength,".").Replace($lines[$i],""))
						$content += ("`r`n{0}{1,-10}{2}{3}{4}" -f ($stateCol, "", "{white}", $name, ("{gray}")))
					}
				}
				if($content){
					$context.Display($content)
				}
			}
		}
		
		$currentScope = $context.rootScopes.ToArray()[1]
		$fullName     = $currentScope.FullName(">")
		$headerTitle  = "{0,-63}" -f $fullName
		$displayText  = @"
		
{magenta}::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::{gray}
{magenta}:: {white}Action: {gray}$($headerTitle){gray}{magenta}::{gray}
{magenta}::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::{gray}

"@
		$context.Display($displayText)
		$context.Display("")
		$context.Title("Breadcrumbs:")
		
		$array = $context.rootScopes.ToArray()
		foreach($item in $array){
			$context.Display("{white}$($item.GetType()) {magenta}$($item.Name()){gray")
			$context.PushIndent()
		}
		foreach($item in $array){
			$context.PopIndent()
		}
		
		
		$parents = $currentScope.GetAllParents($true)
		foreach($parent in $parents){
			$parent | Add-Member -MemberType NoteProperty -Name "Visited" -Value $true -TypeName bool -Force
		}
		
		
		$context.Title("`r`n`r`nValidate:")
		
		$finalResults    = new-object System.Collections.ArrayList
		$parameters      = new-object System.Collections.ArrayList
		$scriptArguments = new-object hashtable
		$envVariables    = new-object hashtable
		$outputVariables = new-object hashtable
		$defaultValues   = new-object hashtable
		
		
		$context.IsLoggingEnabled($true)
		$stack = new-object System.Collections.Stack
		$stack.Push(@{Level = 0; Scope = $currentScope; Type="Action"})
		while($stack.Count -gt 0){
			$curr = $stack.Pop()
			
			$curr.Scope | Add-Member -MemberType NoteProperty -Name "Visited" -Value $true -TypeName bool -Force
			# $context.PushLocation($curr.Scope._generatedFromFile)
			# $context.PushScope($curr.Scope)
			if($curr.Scope -is [UIAction]){
				$result = $curr.Scope.Validate()
				$finalResults.Add(@{Success = $result; Item = $curr})
			}
				
			foreach($action in $curr.Scope.PostActions().Items()){
				$stack.Push(@{Level = ($curr.Level + 1); Scope = $action; Type = "PreAction" })
			}
			foreach($action in $curr.Scope.Actions().Items()){
				$stack.Push(@{Level = ($curr.Level + 1); Scope = $action; Type = "Action" })
			}
			foreach($action in $curr.Scope.PreActions().Items()){
				$stack.Push(@{Level = ($curr.Level + 1); Scope = $action; Type = "PostAction" })
			}
			foreach($action in $curr.Scope.Get("ActionOverrides").Items()){
				$stack.Push(@{Level = ($curr.Level + 1); Scope = $action; Type = "Overrides" })
			}
			foreach($section in $curr.Scope.Get("Sections").Items()){
				$section.LoadChildren()
				$stack.Push(@{Level = ($curr.Level + 1); Scope = $section; Type = "Section" })
			}
			
			# $context.PopScope()
			# $context.PopLocation()
		}
		$context.IsLoggingEnabled($true)
		
		
		foreach($currItem in $finalResults){
			$curr = $currItem.Item
			$color = "{green}"
			if(-not ($currItem.Success)){
				$color = "{red}"
			}
			if($curr.Type -eq "Overrides"){
				for($i =0;$i -lt $curr.Level;$i += 1){ $context.PushIndent() }
				$context.Display("Over $($color)$($curr.Scope.Name()){gray}")
				for($i =0;$i -lt $curr.Level;$i += 1){ $context.PopIndent() }
			}
			if($curr.Type -eq "PreAction"){
				for($i =0;$i -lt $curr.Level;$i += 1){ $context.PushIndent() }
				$context.Display("Pre $($color)$($curr.Scope.Name()){gray}")
				for($i =0;$i -lt $curr.Level;$i += 1){ $context.PopIndent() }
			}
			if($curr.Type -eq "Action"){
				for($i =0;$i -lt $curr.Level;$i += 1){ $context.PushIndent() }
				$context.Display("Action $($color)$($curr.Scope.Name()){gray}")
				for($i =0;$i -lt $curr.Level;$i += 1){ $context.PopIndent() }
			}
			if($curr.Type -eq "PostAction"){
				for($i =0;$i -lt $curr.Level;$i += 1){ $context.PushIndent() }
				$context.Display("Post $($color)$($curr.Scope.Name()){gray}")
				for($i =0;$i -lt $curr.Level;$i += 1){ $context.PopIndent() }
			}
			if($curr.Type -eq "Section"){
				for($i =0;$i -lt $curr.Level;$i += 1){ $context.PushIndent() }
				$context.Display("Section $($color)$($curr.Scope.Name()){gray}")
				for($i =0;$i -lt $curr.Level;$i += 1){ $context.PopIndent() }
			}
		}
		
		$context.Title("`r`nActions (Tree / Inputs)")
		$stack = new-object System.Collections.Stack
		$stack.Push(@{Level = 0; Scope = $context.GetRootScope(); Type="Action"; AlreadyVisisted = $false})
		while($stack.Count -gt 0){
			$curr = $stack.Pop()
			$context.PushScope($curr.Scope)
			
			if($curr.Type -eq "Overrides"){
				for($i =0;$i -lt $curr.Level;$i += 1){ $context.PushIndent() }
				$context.Display("Over {magenta}$($curr.Scope.Name()){gray}")
				for($i =0;$i -lt $curr.Level;$i += 1){ $context.PopIndent() }
			}
			if($curr.Type -eq "PreAction"){
				for($i =0;$i -lt $curr.Level;$i += 1){ $context.PushIndent() }
				$context.Display("Pre {white}$($curr.Scope.Name()){gray}")
				for($i =0;$i -lt $curr.Level;$i += 1){ $context.PopIndent() }
			}
			if($curr.Type -eq "Action"){
				for($i =0;$i -lt $curr.Level;$i += 1){ $context.PushIndent() }
				$context.Display("Action {magenta}$($curr.Scope.Name()){gray}")
				for($i =0;$i -lt $curr.Level;$i += 1){ $context.PopIndent() }
			}
			if($curr.Type -eq "Parameters"){
				for($i =0;$i -lt $curr.Level;$i += 1){ $context.PushIndent() }
				$context.Display("Parameter {magenta}$($curr.Scope.Name()){gray}")
				for($i =0;$i -lt $curr.Level;$i += 1){ $context.PopIndent() }
			}
			if($curr.Type -eq "PostAction"){
				for($i =0;$i -lt $curr.Level;$i += 1){ $context.PushIndent() }
				$context.Display("Post {white}$($curr.Scope.Name()){gray}")
				for($i =0;$i -lt $curr.Level;$i += 1){ $context.PopIndent() }
			}
			if($curr.Type -eq "Section"){
				for($i =0;$i -lt $curr.Level;$i += 1){ $context.PushIndent() }
				$context.Display("Section {white}$($curr.Scope.Name()){gray}")
				for($i =0;$i -lt $curr.Level;$i += 1){ $context.PopIndent() }
			}
			
			if($curr.Scope.Visited){
				$curr.AlreadyVisisted = $true
			}
			foreach($action in $curr.Scope.PostActions().Items()){
				$stack.Push(@{Level = ($curr.Level + 1); Scope = $action; Type = "PostAction"; AlreadyVisisted = $curr.AlreadyVisisted })
			}
			
			foreach($action in $curr.Scope.Actions().Items()){
				if(-not $action.Visited -and $curr.AlreadyVisisted){
					continue
				}
				$visitedProperty = $action | Add-Member -MemberType NoteProperty -Name "Visited" -Value $false -TypeName bool -Force
				$stack.Push(@{Level = ($curr.Level + 1); Scope = $action; Type = "Action"; AlreadyVisisted = $curr.AlreadyVisisted })
			}
			
			foreach($action in $curr.Scope.PreActions().Items()){
				$stack.Push(@{Level = ($curr.Level + 1); Scope = $action; Type = "PreAction"; AlreadyVisisted = $curr.AlreadyVisisted })
			}
			foreach($action in $curr.Scope.Get("ActionOverrides").Items()){
				$stack.Push(@{Level = ($curr.Level + 1); Scope = $action; Type = "Overrides"; AlreadyVisisted = $curr.AlreadyVisisted })
			}
			foreach($section in $curr.Scope.Get("Sections").Items()){
				$stack.Push(@{Level = ($curr.Level + 1); Scope = $section; Type = "Section"; AlreadyVisisted = $curr.AlreadyVisisted })
			}
			foreach($parameter in $curr.Scope.Get("Parameters").Items()){
				if(-not $parameter.IsRequired()){
					continue
				}
				
				for($i =0;$i -lt ($curr.Level+1);$i += 1){ $context.PushIndent() }
				$content = "   {0}Input {1}{2,-50} {3}" -f ("{gray}","{white}",$parameter.Name(), "{gray}`r`n")
				if($parameter.InputStrategies().Items().Count -eq 0){
					$content += "{white}[{red}Not Defined{white}]"
				}
				else{
					$contentText = ""
					foreach($inputStrategy in $parameter.InputStrategies().Items()){
						$rawValue = $inputStrategy.ExecuteStrategy()
						$contentText += "      {0}{1,-25}" -f ("{gray}",$inputStrategy.Name())
						
						if($rawValue){
							$contentText += "{0}[{1}]`r`n" -f ("{white}","{green}Found{white}")
						}
						else{
							$contentText += "{white}[{red}Not Found{white}] `r`n" 
						}
						
					} 
					$content += $contentText
				}
				$context.Display($content)
				for($i =0;$i -lt ($curr.Level+1);$i += 1){ $context.PopIndent() }
			}
			foreach($parameter in $curr.Scope.Get("Parameters").Items()){
				$parameters.Add($parameter)
				foreach($inputStrategy in $parameter.InputStrategies().Items()){
				
					if($inputStrategy.InputType().Name() -eq "ScriptParameter"){
						if(-not $scriptArguments.ContainsKey($inputStrategy.Shorthand())){
							$scriptArguments[$inputStrategy.Shorthand()] = new-object system.collections.arraylist
						}
						$index = $scriptArguments[$inputStrategy.Shorthand()].Add(@{Parameter = $parameter; Strategy = $inputStrategy})
						continue
					}
					
					if($inputStrategy.InputType().Name() -eq "EnvironmentVariable"){
						if(-not $envVariables.ContainsKey($inputStrategy.Shorthand())){
							$envVariables[$inputStrategy.Shorthand()] = new-object system.collections.arraylist
						}
						$index = $envVariables[$inputStrategy.Shorthand()].Add(@{Parameter = $parameter; Strategy = $inputStrategy})
						continue
					}
					
					if($inputStrategy.InputType().Name() -eq "DefaultValue"){
						if(-not $defaultValues.ContainsKey($parameter.Name())){
							$defaultValues[$parameter.Name()] = new-object system.collections.arraylist
						}
						$index = $defaultValues[$parameter.Name()].Add(@{Parameter = $parameter; Strategy = $inputStrategy})
						continue
					}
					
					if($inputStrategy.InputType().Name() -eq "OutputVariable"){
						if(-not $outputVariables.ContainsKey($inputStrategy.Shorthand())){
							$outputVariables[$inputStrategy.Shorthand()] = new-object system.collections.arraylist
						}
						$index = $outputVariables[$inputStrategy.Shorthand()].Add(@{Parameter = $parameter; Strategy = $inputStrategy})
						continue
					}
				}
			}
			$context.PopScope()
		}
		
		$context.Title("`r`nScript Arguments")
		Show-ArgumentBreakdown $context $action $scriptArguments
		$context.Title("`r`nEnvironment Variables")
		Show-ArgumentBreakdown $context $action $envVariables
		$context.Title("`r`nOutput Variables")
		Show-ArgumentBreakdown $context $action $outputVariables
		$context.Title("`r`nDefault Values")
		Show-ArgumentBreakdown $context $action $defaultValues
		$context.Title("`r`nParameters")
		$notFoundTxt = @()
		$dependenciesMissingTxt = @()
		$foundTxt = @()
		foreach($parameter in $parameters){
			if(-not $parameter.IsRequired()){
				continue
			}
			$context.PushScope($parameter.CurrentScope())
			$value = $parameter.Value()
			$regexStr = '(['+"$"+'][(][^)\'+"$"+']*?[)])'
			$valueWithRed = $value -replace $regexStr, '{yellow}$1{white}'
			if(-not $value){
				$notFoundTxt += "`r`n{white}[{red}$($parameter.Name()){white}]{gray}"
			}
			else{
				if($value -is [string]){
					$matches = ([regex]$regexStr).Matches($value)
					if($matches.Count -gt 0){
						$dependenciesMissingTxt += "`r`n{white}[{yellow}$($parameter.Name()){white}]{gray}"
						$dependenciesMissingTxt += $valueWithRed
					}
					else{
						$foundTxt += "`r`n{white}[{green}$($parameter.Name()){white}]{gray}"
						$foundTxt += $valueWithRed
					}
				}
				else{
					$foundTxt += "`r`n{white}[{green}$($parameter.Name()){white}]{gray}"
					$foundTxt += $valueWithRed
				}
				
			}
			
			$context.PopScope()
		}
		$foundTxt | Foreach {$context.Display($_)}
		$dependenciesMissingTxt | Foreach {$context.Display($_)}
		$notFoundTxt | Foreach {$context.Display($_)}
		
		$context.Title("`r`nActions Types:")
		$types = @()
		$stack = new-object System.Collections.Stack
		$stack.Push(@{Level = 0; Scope = $context.CurrentScope() })
		while($stack.Count -gt 0){
			$curr = $stack.Pop()
			for($i =0;$i -lt $curr.Level;$i += 1){ $context.PushIndent() }
			foreach($actionType in $curr.Scope.ActionTypes().Items()){
				$context.Display($($actionType.Name()))
			}
			
			for($i =0;$i -lt $curr.Level;$i += 1){ $context.PopIndent() }
			
			foreach($action in $curr.Scope.Actions().Items()){
				$stack.Push(@{Level = ($curr.Level + 1); Scope = $action })
			}
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
		return $true
	};
	
}