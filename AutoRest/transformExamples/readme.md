# Transform Files
`ConvertFrom-ARSwagger` has got the parameter `Transformpath`. If used the
command will take any *.psd1 file within the given folder and use the contained
data for transformation of the generated `[Command]` objects. By using this
option it is possible to modify the generated PowerShell functions without
 writing any code.

### Source for examples
The examples provided within this folder and readme.md use the [swagger definition of Gitea](https://try.gitea.io/api/swagger). You can download the json file from their [TryOut Web-Site](https://try.gitea.io/swagger.v1.json)

## Structure of the Transform-Files
Each transformation rule file consists of a PowerShell-Data-File. Those *.psd1 files are handled by [Import-PowerShellDataFile](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/import-powershelldatafile?view=powershell-7.2)
and consist of a simple HashTable definition. Each main entry/key may consist of one of the following:

### List of keys for command selecting
1. `<path>:<method>`  
Used for direct transformation of a specific command
1. `globalParameters`  
Contains a Hashtable of parameters which should be modified for all commands
1. `scopedParameters`  
Contains a Hashtable of endpoint-pathes for whom parameters should be modified for all commands

## Content of the transformation
As the value to the corresponding key you use a HashTable containing the

| Key | Description |
| ----------- | ----------- |
| Name | Name of the command to generate |
| Synopsis | Synopsis part of the command help |
| Description | Description part of the command help |
| DocumentationUrl | Link to the online documentation |
| ServiceName | Specific service override to include. Needs to be implemented in the Rest Command used. |
| Scopes | Scopes required in delegate authentication mode. Will be included in help and passed to rest command. |
| RestCommand | Command to use to execute the rest request and handle authentication |
| ProcessorCommand | An additional command used to process the output. This command must be implemented manually. |
| ParameterSets | Hashtable mapping parameterset name to its description. Used in examples. |
| Parameters | HashTable for each parameter to modify. See "Modification of parameters" |

## Modification of parameters:
To override individual properties on parameters, create a
child-hashtable. Each key is the system name of the parameter, entries
govern the properties to override.
```Powershell
Parameters = @{
    MachineID = @{
        Help = 'ID of the machine to get recommendations for.'
    }
}
```
The following table describes the possible attributes of each parameter:
| Key | Description |
| ----------- | ----------- |
| Help | Text contained within the help of the parameter |
| ParameterType | Type of the parameter variable |
| ParameterSet | {default} |
| Weight | Weight for sorting the parameters, default `1000` |
| Name | Name of the parameter variable |
| SystemName | Name of the parameter as expected by the API service, **should never be modified** |
| Mandatory | `True` or `False` |
| ValueFromPipeline | Should the parameter be accepted from the pipeline, possible Values `True` or `False`, default `False` |
| Type | Type of the parameter; specifies where the parameter should be included in the API call, possible Values `Body`, `Path` and `Query` |

## Examples
### Override a specific command
The following transform-content creates the function `Invoke-GiteaAdminCronTask` instead of `Set-GiteaAdminCron`:
```Powershell
@{
    "admin/cron:Post" = @{
        "Name"             = "Invoke-GiteaAdminCronTask"
        "Synopsis"         = "Executes the named cron task"
        "Description"      = "Description part of the command help"
        "DocumentationUrl" = "https://try.gitea.io/api/swagger"
        "ServiceName"      = "MyGiteaService"
        "Scopes"           = "CurrentUser"
        "RestCommand"      = "Invoke-GiteaRestCall"
        "ProcessorCommand" = "ConvertFrom-GiteaCronJob"
    }
}
```
<details>
  <summary>Content of Invoke-GiteaAdminCronTask</summary>

```Powershell
function Invoke-GiteaAdminCronTask {
<#
.SYNOPSIS
    Executes the named cron task

.DESCRIPTION
    Description part of the command help

    Scopes required (delegate auth): CurrentUser

.PARAMETER Task
    task to run

.EXAMPLE
    PS C:\> Invoke-GiteaAdminCronTask -Task $task

    <insert description here>

.LINK
    https://try.gitea.io/api/swagger
#>
    [CmdletBinding(DefaultParameterSetName = 'default')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'default')]
        [string]
        $Task
    )
    process {
        $__mapping = @{

        }
        $__body = $PSBoundParameters | ConvertTo-HashTable -Include @() -Mapping $__mapping
        $__query = $PSBoundParameters | ConvertTo-HashTable -Include @() -Mapping $__mapping
        $__path = 'admin/cron/{task}' -Replace '{task}',$Task
        Invoke-GiteaRestCall -Path $__path -Method post -Body $__body -Query $__query -RequiredScopes 'CurrentUser' -Service MyGiteaService | ConvertFrom-GiteaCronJob
    }
}
```
</details>

### Renaming an existing parameter
The code above contains the parameter `Task`. If it should be renamed into `CronTask` you have to add the following code to the transformation:

```Powershell
        Parameters         = @{
            Task = @{
                Name = "CronTask"
                Help = 'ID of the cron task to be invoked.'
            }
        }
```
<details>
  <summary>Complete *.psd1 Code</summary>

```Powershell
@{
    "admin/cron:Post" = @{
        "Name"             = "Invoke-GiteaAdminCronTask"
        "Synopsis"         = "Executes the named cron task"
        "Description"      = "Description part of the command help"
        "DocumentationUrl" = "https://try.gitea.io/api/swagger"
        "ServiceName"      = "MyGiteaService"
        "Scopes"           = "CurrentUser"
        "RestCommand"      = "Invoke-GiteaRestCall"
        "ProcessorCommand" = "ConvertFrom-GiteaCronJob"
        Parameters         = @{
            Task = @{
                Name = "CronTask"
                Help = 'ID of the cron task to be invoked.'
            }
        }
    }
}
```

</details>
<details>
  <summary>Content of Invoke-GiteaAdminCronTask, v2</summary>

```Powershell
function Invoke-GiteaAdminCronTask {
<#
.SYNOPSIS
    Executes the named cron task

.DESCRIPTION
    Description part of the command help

    Scopes required (delegate auth): CurrentUser

.PARAMETER CronTask
    ID of the cron task to be invoked.

.EXAMPLE
    PS C:\> Invoke-GiteaAdminCronTask -CronTask $crontask

    <insert description here>

.LINK
    https://try.gitea.io/api/swagger
#>
    [CmdletBinding(DefaultParameterSetName = 'default')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'default')]
        [string]
        $CronTask
    )
    process {
        $__mapping = @{

        }
        $__body = $PSBoundParameters | ConvertTo-HashTable -Include @() -Mapping $__mapping
        $__query = $PSBoundParameters | ConvertTo-HashTable -Include @() -Mapping $__mapping
        $__path = 'admin/cron/{task}' -Replace '{task}',$CronTask
        Invoke-GiteaRestCall -Path $__path -Method post -Body $__body -Query $__query -RequiredScopes 'CurrentUser' -Service MyGiteaService | ConvertFrom-GiteaCronJob
    }
}
```
</details>

## Global parameter modification
If you need to modify a parameter for all generated commands you have to describe the modification under the key `globalParameters`.

E.g. if the following snippet would rename all Parameters `Limit` to `PageSize` and modify additional aatributes:

```Powershell
    "globalParameters" = @{
        Limit = @{
            Name          = "PageSize"
            Help          = 'How many elements should be fetched within one call'
            ParameterType = 'int'
        }
    }
```
<details>
  <summary>Content of Invoke-GiteaAdminCronTask, v3, abbreviated</summary>

```Powershell
function Get-GiteaAdminCron {
<#
....
.PARAMETER PageSize
    How many elements should be fetched within one call
....
#>
    [CmdletBinding(DefaultParameterSetName = 'default')]
    param (
....
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'default')]
        [int]
        $PageSize
    )
    process {
        $__mapping = @{
            'Page' = 'page'
            'Connection' = 'Connection'
            'PageSize' = 'limit'
        }
        $__body = $PSBoundParameters | ConvertTo-HashTable -Include @() -Mapping $__mapping
        $__query = $PSBoundParameters | ConvertTo-HashTable -Include @('Page','PageSize') -Mapping $__mapping
        $__path = 'admin/cron'
        Invoke-ARRestRequest -Path $__path -Method get -Body $__body -Query $__query -Service Dagobert
    }
}
```
</details>

## Global parameter modification with scope
If you need to modify a parameter for all generated commands **within a specific path** you may describe the modification under the key `scopedParameters/[Path-Matching String]`.

E.g. if the following snippet would rename all Parameters `Page` to `PageNumber` only for entrypoints within the path `admin/*`

```Powershell
    "scopedParameters" = @{
        "admin*" = @{
            Page = @{
                Name = "PageNumber"
            }
        }
    }
```
**This option should only be used with caution, as it can lead to inconsistent naming patterns.**



<details>
  <summary>Admin Whitelist</summary>

  Content
```Powershell
```
</details>