# XConfigMaster

[![Build Status](https://dev.azure.com/xconfigmaster/XConfigMaster/_apis/build/status/xconfigmaster-release?branchName=master)](https://dev.azure.com/xconfigmaster/XConfigMaster/_build/latest?definitionId=2&branchName=master)
![Downloads](https://img.shields.io/powershellgallery/dt/XConfigMaster?label=Downloads)
![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/XConfigMaster?label=XConfigMaster)
## Usage
1. `Install-Module XConfigMaster`
2. `xcm :x create`


## Description
**XConfigMaster** is a **Extensible**, **Highly Configurable**, **DevOps Pipeline Language.**

XConfigMaster was created due to the need to have a tool that can be dynamic enough to align to any DevOps process but structured enough have good testability , parameter management, reusable components.


## Goals


There are many DevOps Pipeline Languages in existence. 
1. [Azure DevOps Yaml Pipeline](https://docs.microsoft.com/en-us/azure/devops/pipelines/yaml-schema?view=azure-devops&tabs=schema) - Used in combination with [AzureDevOps](https://azure.microsoft.com/en-us/services/devops/)
2. Much more, just dont know the names


The problem XConfigMaster is trying to solve is the ability to define pipelines in more of a flexible fasion. Also, in addition to flexible it still needs the ability to keep the rigidness of other language. What this means is, we want to define pipelines easier but still have pipelines break when they should break.


## Design


### Important Concepts
1. XConfigMaster drives on the notion of **Scopes**
2. **Scopes** can have child **Scopes**
3. Information fetched from a scope will fallback to its parent **Scope** - Some situations this does not apply, in the case of validating the definitions defined in a specific **scope**

### Parameters
Defines what named parameters can be referenced. They can be referenced by **Actions** , **Templates**, and other **Parameters** for basic information that is populated using **InputStrategies**
#### `<ParameterType/>`
Defines how a parameter is validated, transformed, and what Powershell Type is will return.

Example:
- **String** - Can contain anything that is a string. The default for parameters with no type
- **Integer** - Can contain only numbers in its value. Will error otherwise. Will convert the string into a integer when resolved
- **Boolean** - Can only be 'true', or 'false'. Will error otherwise. Will convert the string into a boolean depending on its value
- **Secure String** - Can be a string. Will error otherwise. Will convert the string into a secure string with `ConvertTo-SecureString` which will be the value type of the parameter
- **Azure Resource**, Can be a string. Will error otherwise. Will fetch azure using `Get-AzureRMResource` and error if no resource was found returning the value otherwise.
#### `<Parameter/>`
Defines the actual parameter with a given `Name` and `Type` (Optional, Default is `String`)

Can contain `<InputStrategies/>` as children which will define how the input is resolved for this parameter.

Where it is defined will be its scope. What this means is, if you define a parameter in the following format:
```XML
<Action Name="action1" Type="ActionGroup">
  <Action Name="action2" Type="ActionGroup">

    <Parameter Name="MyParameter" Type="String">
      <InputStrategy Type="DefaultValue" DefaultValue="Some Default Value"/>
    </Parameter>
    
    <Parameter Name="Reference1" Type="String">
      <InputStrategy Type="DefaultValue" DefaultValue="$(MyParameter)"/>
    </Parameter>

    <Action Name="print-reference1" Type="Print">
      <Parameter Name="Content">
        Reference1 = $(Reference1)
      </Parameter>
    </Action>
  </Action>

  <Parameter Name="Reference2" Type="String">
    <InputStrategy Type="DefaultValue" DefaultValue="$(MyParameter)"/>
  </Parameter>

  <Action Name="print-reference2" Type="Print">
    <Parameter Name="Content">
      Reference2 = $(Reference2)
    </Parameter>
  </Action>
</Action>

```

The following will have the following results:
- `xcm action1 action2` 
  - <font color="green">**No Validation errors**</font>
- `xcm actuion1` - 
  - **<font color='red'>MyParameter missing** Scope (action1)</font>
  - **<font color='orange'>Reference2 partially missing** - scope(action1)</font>

### Inputs
Defines how parameters or content is consumed by XConfigMaster. This means either **Default Inputs/Value**, **Script Argument**, **Environment Variable**, and can even be extend to **Cloud based configuration stores**

#### `<InputType/>`
Represents the manner at which an input is defined. This is where the extensibility of XConfigMaster really takes shape. You can create your own InputType by following the documentation but the default InputTypes are **Default Value**, **Script Argument**, and **Environment Variable** which is the basis for any pipeline process.

#### `<InputStrategy/>`
Represents one of the `<InputType>`s a particular `<Parameter>` will use as its `<InputStrategy>` for resolving its value 

### Actions
Defines a named activity that represent the `Work` of the pipeline. There are three type of Actions depending on how you want the action to execute. There are `PreActions`, `PostActions`, `Actions`. 

Actions execute under the following life cycle
1. **Validation** - Is used to determin if the action/parameters/inputs configured are valid to execute. The manner at which an action validates itself is up to the `<ActionType>` it refers to
2. **Clean** - Is used to clean up any "mocked" content that may have been needed during the **Validation** life cycle. Usually, Actions that depend on the Output of other actions usually are the main reason for this life cycle. Where those depending actions can set a dummy value as its output to properly validate a pipeline. Which then need to be cleaned before execution
3. **Execution** - Is where the meat of the actions are performed. 
    
  > The goal of **XConfigMaster** is to bring a **sense of confidence that a pipeline will run successfully** if it can reach this the **Execution** life cycle. Having proper validation in the action types will allow the pipeline to achieve this

#### `<ActionType/>`
Defines what an `<Action>` will do when **Validating**, **Cleaning**, and **Executing**. These are completly extensable and created either by XConfigMaster developers or by the XConfigMaster module users. 

> **Still pending** is how to enable a better control of new types when it comes to proper documentation, typing, version, and usage rules for the consumers of these extensions


#### `<Action>`
Defines the actual `<Action>` which will have a `Name`, `Type` and `Ref` (Which is used to directly reference this action from the command line and other places in definition files

### Templates
Defines a named definition of a pipeline that can be imported any where using `<ImportTemplate>`. Templates trully is one of the most important parts of XConfigMasters infrastructure. 

With Templates,

You can define reusable stubs for common tasks and they can be imported in different ways by different teirs of your application. 

You can define a overall goal in your pipeline, lets say `build-apis`, and where there is an api a simple addition to the template be added using `<Template Ref='build-apis-template'>`. So once you are ready to build all apis, you as the DevOps engineer dont need to worry if the apis change folder, are deleted, or new apis are added. 
> Still pending... Providing documentation on this scenario since its more complex. We will create documentation showing a real world example for use.

### Extensions
Lastly extensions. Extensions are not a usual component that would be added to your everday pipeline but if you needed the ability to define how your pipeline is constructed in a way that you can manage, extensions allows for that. 

A good example is the Extension added to the Module `<PipelineVariable>`. Instead of defining a `<Parameter>` with 3 different `<InputStrategy>` for **Script Argument**, **Environment Variable**, and/or **Key Vault Secret** you can simply do `<PipelineVariable Name='SomeName'>`
> Still pending... Providing documentation on this scenario since its more complex. We will create documentation showing a real world example for use.