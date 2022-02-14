
@{
    "additionalParameters"       = @{
        "admin/cron:Post"            = @{
            "MyAdditionalBodyParam"  = @{
                "Help"          = "Text contained within the help of the parameter"
                "ParameterType" = "String"
                "SystemName"    = "myadditionalbodyparam"
                "Mandatory"     = $true
                "Type"          = "Body"
            }
            "MyAdditionalQueryParam" = @{
                "Help"          = "Text contained within the help of the parameter"
                "ParameterType" = "String"
                "SystemName"    = "addQueryParam"
                "Mandatory"     = $true
                "Type"          = "Query"
            }
        }
    }
    "additionalScopedParameters" = @{
        "admin*" = @{
            "MyAdditionalScopedParam" = @{
                "Help"          = "Text contained within the help of the parameter"
                "ParameterType" = "String"
                "SystemName"    = "addScopedParam"
                "Mandatory"     = $true
                "Type"          = "Query"
            }
        }
    }
    "additionalGlobalParameters" = @{
        "Connection" = @{
            "Help"          = "Connection object for authentication"
            "ParameterType" = "object"
            "Mandatory"     = $true
            "Type"          = "Misc"
        }
    }
}