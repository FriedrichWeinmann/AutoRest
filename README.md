# AutoRest (PowerShell)

Welcome to the home of the AutoRest for PowerShell project.
This toolkit is designed to help with generating client code for Rest APIs.

## Installation

To install this PowerShell module - and you need it only on the machine _generating_ the code, the output itself has no dependencies in this module - run the following line in your PowerShell console of choice:

```powershell
Install-Module AutoRest -Scope CurrentUser
```

## Requirements

+ PowerShell 5.1+ ([PowerShell 7+ recommended](https://aka.ms/pwsh))
+ Module: [PSFramework](https://psframework.org)
+ Module: strings

> All module dependencies are installed automatically with the above install command

## Getting started

For details on how to use each command, see their help, but fundamentally, the system has two steps:

+ Convert source to Command data
+ Export Command data to file as command

Example:

```powershell
$paramConvertFromARSwagger = @{
    Transformpath   = '.\transform'
    RestCommand     = 'Invoke-ARRestRequest'
    ModulePrefix    = 'Mg'
    PathPrefix      = '/api/'
}

Get-ChildItem .\swaggerfiles | ConvertFrom-ARSwagger @paramConvertFromARSwagger | Export-ARCommand -Path .
```

> [More Information on Customizing the result using Transforms](https://github.com/FriedrichWeinmann/AutoRest/tree/master/AutoRest/transformExamples)

## Authentication & Invocation

The commands generated from this module assume the actual authentication and request execution is provided externally.
An example authentication component has been provided through the sister project "RestConnect"
