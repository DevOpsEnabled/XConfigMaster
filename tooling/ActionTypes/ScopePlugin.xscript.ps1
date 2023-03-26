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
        $context.OverrideScope($action)
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