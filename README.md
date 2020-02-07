# XConfigMaster

[![Build Status](https://dev.azure.com/xconfigmaster/XConfigMaster/_apis/build/status/hecflores.XConfigMaster?branchName=master)](https://dev.azure.com/xconfigmaster/XConfigMaster/_build/latest?definitionId=1&branchName=master)

## Usage
1. Install-Module XConfigMaster
2. xcm

## Goals
**XConfigMaster is a DevOps Pipeline Language.**

There are many DevOps Pipeline Languages in existence. 
1. [Azure DevOps Yaml Pipeline](https://docs.microsoft.com/en-us/azure/devops/pipelines/yaml-schema?view=azure-devops&tabs=schema) - Used in combination with [AzureDevOps](https://azure.microsoft.com/en-us/services/devops/)


The problem XConfigMaster is trying to solve is the ability to define pipelines in more of a flexible fasion. Also, in addition to flexible it still needs the ability to keep the rigidness of other language. What this means is, we want to define pipelines easier but still have pipelines break when they should break.


## Description
XConfigMaster was created due to the need to have a tool that can be dynamic enough to align to any DevOps process but structured enough to be testable/parameter managment/reusable components.

## Design


### Important Concepts
1. XConfigMaster drives on the notion of **Scopes**
2. **Scopes** can have child **Scopes**
3. Information fetched from a scope will fallback to its parent **Scope** - Some situations this does not apply, in the case of validating the definitions defined in a specific **scope**

### Parameters

#### ParameterType

#### Parameter

### Inputs
#### InputType

#### InputStrategy

### Actions
#### ActionType

#### Action

### Templates