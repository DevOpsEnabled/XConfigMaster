# ActionType - Script
Script is used to run a powershell script

### Usage - .xconfigmaster
```XML
<Action Name="{Action Name}" Type="ActionGroup">
    <!-- Actions that will be executed before any action inside of '{Some Action}' are executed -->
    <PreAction Name="{Some Pre Action}" Type="..."/>
    
    <!-- Any sub actions -->
    <Action Name="{Some Action}" Type="..."/>
    
    <!-- Actions that will be executed after any action inside of '{Some Action}' are executed -->
    <PostAction Name="{Some Post Action}" Type="..."/>
</Action>
```

### Parameters
|Name|Type|Required|Description|
|----|----|--------|-----------|
|ScriptType|Parameter|Optional|How is the script defined. Possible options are "**Inline**", and "**Script**". Default is "**Script**"|
|ScriptPath|Parameter|Required <div style='white-space:nowrap'>**ScriptType** = Script|File path of the script executing. Valid if **ScriptType** equals "**Script**"</div>|
|ScriptBlock|Parameter|Required <div style='white-space:nowrap'>**ScriptType** = Inline|File path of the script executing. Valid if **ScriptType** equals "**Inline**"</div>|
|WorkingDirectory|Parameter|Optional|Path where to execute the scripts content|
ScriptScope|Parameter| Optional|Defines if the script should be executed in a new session or not. Possible options are "**NewSession**" and "**SameSession**"|
|OutputVariables|Parameter|Optional|<div>The expected output variables from the script separated with ",". </div><div><b>Note: </b></div>This is under the assumption that scripts will export variables in the format used for Azure DevOps. [Learn More](https://docs.microsoft.com/en-us/azure/devops/pipelines/scripts/logging-commands?view=azure-devops&tabs=bash) |

