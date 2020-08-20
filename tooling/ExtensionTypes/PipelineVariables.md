# PipelineVariable - Pipeline Variable Extension
PipelineVariable is one of the base **ExtensionTypes** in XConfigMaster. It is used to define parameters and all of the cool different **InputTypes** that are available easier. 


### Properties 
- **Name** (Required) - Linkes to Parameter name
- **Type** (Optional) - The type of the parameter which is the name of a **ParameterType**
- **DefaultValue** (Optional) - Links to the value that will be used in the **DefaultValue** InputType
- **KeyValueSecret** (Optional) - Links to the value(s) that will be used in the **KeyVaultSecret** InputType
- **SkipCachingValue** (Optional) - Used with property **KeyVaultSecret**. If set to **true** will attempt to fetch the key vault secret (If conditions are met to do so) even if it already successfully performed the fetch before. Good to ensure your values are true at resolving time

### Parameters 
- No Parameter required
- Any Parameter allowed

### Sections 
- No Parameter required
- No Sections allowed

### Actions 
- 0 Actions expected of any type
- 0 Preactions expected of any type
- 0 Postactions expected of any type

### Usage - .xconfigmaster
#### Required either Environment Variable or Cmd Line Argument

```XML
<PipelineVariable Name="Variable.Name"/>
```
> **Converted To:**
> ```XML
> <Parameter Name="Variable.Name" Type="String">
>   <InputStrategy Priority="0" Type="ScriptParameter" ParamName="variable-name">
>   <InputStrategy Priority="1" Type="EnvironmentVariable" EnvName="VARIABLE_NAME"/>
> </Parameter>
> ```

#### Default Value, can be overwritten using Cmd Line Argument > Environment Variable

```XML
<PipelineVariable Name="Variable.Name" DefaultValue="Default Value"/>
```
> **Converted To:**
> ```XML
> <Parameter Name="Variable.Name" Type="String">
>   <InputStrategy Priority="0" Type="ScriptParameter" ParamName="variable-name">
>   <InputStrategy Priority="1" Type="EnvironmentVariable" EnvName="VARIABLE_NAME"/>
>   <InputStrategy Priority="2" Type="DefaultValue" DefaultValue="Default Value"/>
> </Parameter>
> ```

#### Required as either Key Vault Secret, Environment Variable, or Cmd Line Argument can overwrite

```XML
<PipelineVariable Name="Variable.Name" KeyVaultSecret="KeyVaultName/SecretName"/>
```
> **Converted To:**
> ```XML
> <Parameter Name="Variable.Name" Type="String">
>   <InputStrategy Priority="0" Type="ScriptParameter" ParamName="variable-name">
>   <InputStrategy Priority="1" Type="EnvironmentVariable" EnvName="VARIABLE_NAME"/>
>   <InputStrategy Priority="2" Type="KeyVaultSecret" KeyVaultSecret="KeyVaultName/SecretName"/>
> </Parameter>
> ```

#### Default value, can be overwritten using Cmd Line Argument > Environment Variable > Key Vault Secret

```XML
<PipelineVariable Name="Variable.Name" DefaultValue="Default Value" KeyVaultSecret="KeyVaultName/SecretName"/>
```
> **Converted To:**
> ```XML
> <Parameter Name="Variable.Name" Type="String">
>   <InputStrategy Priority="0" Type="ScriptParameter" ParamName="variable-name">
>   <InputStrategy Priority="1" Type="EnvironmentVariable" EnvName="VARIABLE_NAME"/>
>   <InputStrategy Priority="2" Type="KeyVaultSecret" KeyVaultSecret="KeyVaultName/SecretName"/>
>   <InputStrategy Priority="3" Type="DefaultValue" DefaultValue="Default Value"/>
> </Parameter>
> ```