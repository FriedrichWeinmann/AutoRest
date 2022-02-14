
@{
    "admin/cron:Post"  = @{
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
    "globalParameters" = @{
        Limit = @{
            Name          = "PageSize"
            Help          = 'How many elements should be fetched within one call'
            ParameterType = 'int'
        }
    }
    "scopedParameters" = @{
        "admin*" = @{
            Page = @{
                Name = "PageNumber"
            }
        }
    }
}