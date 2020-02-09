#:xheader:
#Type=ActionType;
#:xheader:

return @{
    Clean = 
    {
        Param([ConfigAutomationContext] $context,[UIAction] $action)
        return $true
    };
    Action = 
    {
        Param([ConfigAutomationContext] $context,[UIAction] $action)
        
        $extract = $action.Parameters().Extract(@("Folder"))
        if(Test-Path $($extract.Folder)){
            Remove-Item -Path $($extract.Folder) -Force -Recurse
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

        if(-not $action.Parameters().Validate(@("Folder"))){
            return $false
        }
       $extract = $action.Parameters().Extract(@("Folder"))
        if($action.TestProperty("DontSkipInValidation","true",$true)){
            Remove-Item -Path $($extract.Folder) -Force -Recurse
        }
        return $true
    };
    
}