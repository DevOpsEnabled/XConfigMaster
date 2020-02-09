# ActionType - Script
Script is used to run a powershell script


### Parameters
|Name|Type|Required|Description|
|----|----|--------|-----------|
|ScriptType|Parameter|Optional|How is the script defined. Possible options are "**Inline**", and "**Script**". Default is "**Script**"|
|ScriptArguments|Parameter|Optional|Arguments to use for the script in the format of "-name {value}"|
|ScriptPath|Parameter|Required <div style='white-space:nowrap'>**ScriptType** = Script|File path of the script executing. Valid if **ScriptType** equals "**Script**"</div>|
|ScriptBlock|Parameter|Required <div style='white-space:nowrap'>**ScriptType** = Inline|File path of the script executing. Valid if **ScriptType** equals "**Inline**"</div>|
|WorkingDirectory|Parameter|Optional|Path where to execute the scripts content|
ScriptScope|Parameter| Optional|Defines if the script should be executed in a new session or not. Possible options are "**NewSession**" and "**SameSession**"|
|OutputVariables|Parameter|Optional|<div>The expected output variables from the script separated with ",". </div><div><b>Note: </b></div>This is under the assumption that scripts will export variables in the format used for Azure DevOps. [Learn More](https://docs.microsoft.com/en-us/azure/devops/pipelines/scripts/logging-commands?view=azure-devops&tabs=bash) |


### Usage 

#### Execute a Powershell Script file in folder
```XML
<Action Name="MyAction" Type="Script">
    <Parameter Name="ScriptType" Value="Script"/>
    <Parameter Name="ScriptPath" Value="$(ThisFolder)/my-script.ps1"/>
    <Parameter Name="ScriptArguments" Value="-someArgument 'SomeArgument'"/>
</Action>
```

#### Execute a Powershell Script inline
```XML
<Action Name="MyAction" Type="Script">
    <Parameter Name="ScriptType" Value="Inline"/>
    <Parameter Name="ScriptBlock">
        Write-Host "This is a test of my script. And $(MyVariable) is the value of MyVariable"
    </Parameter>
</Action>
```

#### Execute a Powershell Script inline + Output Variables
```XML
<Action Name="MyAction" Type="Script">
    <Parameter Name="ScriptType" Value="Inline"/>
    <Parameter Name="ScriptBlock">
        Write-Host "This is a test of my script. And $(MyVariable) is the value of MyVariable"

        $someVariableINeed1="Some Content 2"
        $someVariableINeed2="Some Content 2"

        Write-Host "##vso[task.setvariable variable=MyOutput1;]$someVariableINeed1"
        Write-Host "##vso[task.setvariable variable=MyOutput2;]$someVariableINeed2"
    </Parameter>
    <Parameter Name="OutputVariables" Value="MyOutput1,MyOutput2">
</Action>
```
Without the "**OutputVariables**" parameter, it will be hard for **actions that depend on these variables** to proper validate themselves during the **Validation life cycle**. Meaning, this information is **critical for providing proper testing of a pipeline**