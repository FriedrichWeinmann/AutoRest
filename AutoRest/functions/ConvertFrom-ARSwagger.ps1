function ConvertFrom-ARSwagger {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [PsfValidateScript('PSFramework.Validate.FSPath.File', ErrorString = 'PSFramework.Validate.FSPath.File')]
        [Alias('FullName')]
        [string]
        $Path,

        [PsfValidateScript('PSFramework.Validate.FSPath.Folder', ErrorString = 'PSFramework.Validate.FSPath.Folder')]
        [string]
        $TransformPath,

        [PsfValidateScript('PSFramework.Validate.FSPath.Folder', ErrorString = 'PSFramework.Validate.FSPath.Folder')]
        [string]
        $OutPath = '.',

        [Parameter(Mandatory = $true)]
        [string]
        $RestCommand,

        [string]
        $ModulePrefix,

        [string]
        $PathPrefix,

        [switch]
        $GroupByEndpoint,

        [switch]
        $Force,

        [switch]
        $EnableException
    )

    begin {
        #region Functions
        function Copy-ParameterConfig {
            [CmdletBinding()]
            param (
                [Hashtable]
                $Config,

                $Parameter
            )

            if ($Config.Help) { $Parameter.Help = $Config.Help }
            if ($Config.Name) { $Parameter.Name = $Config.Name }
            if ($Config.Alias) { $Parameter.Alias = $Config.Alias }
            if ($Config.Weight) { $Parameter.Weight = $Config.Weight }
            if ($Config.ParameterType) { $Parameter.ParameterType = $Config.ParameterType }
            if ($Config.ContainsKey('ValueFromPipeline')) { $Parameter.ValueFromPipeline = $Config.ValueFromPipeline }
            if ($Config.ParameterSet) { $Parameter.ParameterSet = $Config.ParameterSet }
        }
        
        function New-Parameter {
            [CmdletBinding()]
            param (
                [string]
                $Name,

                [string]
                $Help,

                [string]
                $ParameterType,

                [AllowEmptyString()]
                [AllowNull()]
                [string]
                $ParameterFormat,

                [bool]
                $Mandatory,

                [ParameterType]
                $Type
            )

            $parameter = [CommandParameter]::new(
                $Name,
                $Help,
                $ParameterType,
                $Mandatory,
                $Type
            )
            if ($parameter.ParameterType -eq "integer") {
                $parameter.ParameterType = $ParameterFormat
            }
            $parameter
        }
        #endregion Functions

        $commands = @{ }
        $overrides = @{ }
        if ($TransformPath) {
            foreach ($file in Get-ChildItem -Path $TransformPath -Filter *.psd1) {
                $data = Import-PSFPowerShellDataFile -Path $file.FullName
                foreach ($key in $data.Keys) {
                    $overrides[$key] = $data.$key
                }
            }
        }

        $verbs = @{
            get    = "Get"
            post   = "Set"
            patch  = "Set"
            delete = "Remove"
        }
    }
    process {
        #region Process Swagger file
        foreach ($file in Resolve-PSFPath -Path $Path) {
            $data = Get-Content -Path $file | ConvertFrom-Json
            foreach ($endpoint in $data.paths.PSObject.Properties | Sort-Object { $_.Name.Length }, Name) {
                $endpointPath = ($endpoint.Name -replace "^$PathPrefix" -replace '/{[\w\s\d+]+}$').Trim("/")
                $effectiveEndpointPath = ($endpoint.Name -replace "^$PathPrefix" -replace '\s' ).Trim("/")
                foreach ($method in $endpoint.Value.PSObject.Properties) {
                    $commandKey = $effectiveEndpointPath, $method.Name -join ":"
                    Write-PSFMessage "Processing Command: $($commandKey)"
                    #region Case: Existing Command
                    if ($commands[$commandKey]) {
                        $commandObject = $commands[$commandKey]
                        $parameterSetName = $method.Value.operationId
                        $commandObject.ParameterSets[$parameterSetName] = $method.Value.description

                        #region Parameters
                        foreach ($parameter in $method.Value.parameters) {
                            Write-PSFMessage "  Processing Parameter: $($parameter.Name) ($($parameter.in))"
                            switch ($parameter.in) {
                                #region Body
                                body {
                                    foreach ($property in $parameter.schema.properties.PSObject.Properties) {
                                        if ($commandObject.Parameters[$property.Value.title]) {
                                            $commandObject.Parameters[$property.Value.title].ParameterSet += @($parameterSetName)
                                            continue
                                        }

                                        $parameterParam = @{
                                            Name            = $property.Value.title
                                            Help            = $property.Value.description
                                            ParameterType   = $property.Value.type
                                            ParameterFormat = $property.Value.format
                                            Mandatory       = $parameter.schema.required -contains $property.Value.title
                                            Type            = 'Body'
                                        }
                                        $commandObject.Parameters[$property.Value.title] = New-Parameter @parameterParam
                                        $commandObject.Parameters[$property.Value.title].ParameterSet = @($parameterSetName)
                                    }
                                }
                                #endregion Body

                                #region Path
                                path {
                                    if ($commandObject.Parameters[($parameter.name -replace '\s')]) {
                                        $commandObject.Parameters[($parameter.name -replace '\s')].ParameterSet += @($parameterSetName)
                                        continue
                                    }

                                    $parameterParam = @{
                                        Name            = $parameter.Name -replace '\s'
                                        Help            = $parameter.Description
                                        ParameterType   = $parameter.type
                                        ParameterFormat = $parameter.format
                                        Mandatory       = $parameter.required
                                        Type            = 'Path'
                                    }
                                    $commandObject.Parameters[($parameter.name -replace '\s')] = New-Parameter @parameterParam
                                    $commandObject.Parameters[($parameter.name -replace '\s')].ParameterSet = @($parameterSetName)
                                }
                                #endregion Path

                                #region Query
                                query {
                                    if ($commandObject.Parameters[$parameter.name]) {
                                        $commandObject.Parameters[$parameter.name].ParameterSet += @($parameterSetName)
                                        continue
                                    }

                                    $parameterParam = @{
                                        Name            = $parameter.Name
                                        Help            = $parameter.Description
                                        ParameterType   = $parameter.type
                                        ParameterFormat = $parameter.format
                                        Mandatory       = $parameter.required
                                        Type            = 'Query'
                                    }
                                    $commandObject.Parameters[$parameter.name] = New-Parameter @parameterParam
                                    $commandObject.Parameters[$parameter.name].ParameterSet = @($parameterSetName)
                                }
                                #endregion Query
                            }
                        }
                        #endregion Parameters
                    }
                    #endregion Case: Existing Command

                    #region Case: New Command
                    else {
                        $commandNouns = foreach ($element in $endpointPath -split "/") {
                            if ($element -like "{*}") { continue }
                            [cultureinfo]::CurrentUICulture.TextInfo.ToTitleCase($element) -replace 's$'
                        }
                        $commandObject = [Command]@{
                            Name          = "$($verbs[$method.Name])-$($ModulePrefix)$($commandNouns -join '')"
                            Synopsis      = $method.Value.summary
                            Description   = $method.Value.description
                            Method        = $method.Name
                            EndpointUrl   = $effectiveEndpointPath
                            RestCommand   = $RestCommand
                            ParameterSets = @{
                                'default' = $method.Value.description
                            }
                        }
                        $commands[$commandKey] = $commandObject

                        foreach ($property in $commands[$commandKey].PSObject.Properties) {
                            if ($property.Name -eq 'Parameters') { continue }
                            if ($overrides.$commandKey.$($property.Name)) { $commandObject.$($property.Name) = $overrides.$commandKey.$($property.Name) }
                        }

                        #region Parameters
                        foreach ($parameter in $method.Value.parameters) {
                            Write-PSFMessage "  Processing Parameter: $($parameter.Name) ($($parameter.in))"
                            switch ($parameter.in) {
                                #region Body
                                body {
                                    foreach ($property in $parameter.schema.properties.PSObject.Properties) {
                                        $parameterParam = @{
                                            Name            = $property.Value.title
                                            Help            = $property.Value.description
                                            ParameterType   = $property.Value.type
                                            ParameterFormat = $property.Value.format
                                            Mandatory       = $parameter.schema.required -contains $property.Value.title
                                            Type            = 'Body'
                                        }
                                        $commandObject.Parameters[$property.Value.title] = New-Parameter @parameterParam
                                    }
                                }
                                #endregion Body

                                #region Path
                                path {
                                    $parameterParam = @{
                                        Name            = $parameter.Name -replace '\s'
                                        Help            = $parameter.Description
                                        ParameterType   = $parameter.type
                                        ParameterFormat = $parameter.format
                                        Mandatory       = $parameter.required
                                        Type            = 'Path'
                                    }
                                    $commandObject.Parameters[($parameter.name -replace '\s')] = New-Parameter @parameterParam
                                }
                                #endregion Path

                                #region Query
                                query {
                                    $parameterParam = @{
                                        Name            = $parameter.Name
                                        Help            = $parameter.Description
                                        ParameterType   = $parameter.type
                                        ParameterFormat = $parameter.format
                                        Mandatory       = $parameter.required
                                        Type            = 'Query'
                                    }
                                    $commandObject.Parameters[$parameter.name] = New-Parameter @parameterParam
                                }
                                #endregion Query
                            }
                        }
                        #endregion Parameters

                        #region Parameter Overrides
                        foreach ($parameterName in $overrides.globalParameters.Keys) {
                            if (-not $commandObject.Parameters[$parameterName]) { continue }

                            Copy-ParameterConfig -Config $overrides.globalParameters[$parameterName] -Parameter $commandObject.Parameters[$parameterName]
                        }
                        foreach ($partialPath in $overrides.scopedParameters.Keys) {
                            if ($effectiveEndpointPath -notlike $partialPath) { continue }
                            foreach ($parameterPair in $overrides.scopedParameters.$($partialPath).GetEnumerator()) {
                                if (-not $commandObject.Parameters[$parameterPair.Name]) { continue }

                                Copy-ParameterConfig -Parameter $commandObject.Parameters[$parameterPair.Name] -Config $parameterPair.Value
                            }
                        }
                        foreach ($parameterName in $overrides.$commandKey.Parameters.Keys) {
                            if (-not $commandObject.Parameters[$parameterName]) {
                                Write-PSFMessage -Level Warning -Message "Invalid override parameter: $parameterName - unable to find parameter on $($commandObject.Name)" -Target $commandObject
                                continue
                            }
                            
                            Copy-ParameterConfig -Config $overrides.$commandKey.Parameters[$parameterName] -Parameter $commandObject.Parameters[$parameterName]
                        }
                        #endregion Parameter Overrides
                    }
                    #endregion Case: New Command

                    Write-PSFMessage -Message "Finished processing $($endpointPath) : $($method.Name) --> $($commandObject.Name)" -Target $commandObject -Data @{
                        Overrides     = $overrides
                        CommandObject = $commandObject
                    } -Tag done
                }
            }
        }
        #endregion Process Swagger file
    }
    end {
        $encoding = [System.Text.UTF8Encoding]::new($true)
        foreach ($command in $commands.Values) {
            $targetFolder = $OutPath
            if ($GroupByEndpoint) {
                $targetFolder = Join-Path -Path $OutPath -ChildPath ($command.EndpointUrl -split "/" | Select-Object -First 1)
            }
            if (-not (Test-Path -Path $targetFolder)) {
                $null = New-Item -Path $targetFolder -ItemType Directory -Force
            }
            $filePath = Join-Path -Path $targetFolder -ChildPath "$($command.Name).ps1"
            if (-not $Force -and (Test-Path -Path $filePath)) {
                Write-PSFMessage -Message "Skipping $($command.Name), as $filePath already exists." -Target $command
            }
            Write-PSFMessage -Message "Writing $($command.Name) to $filePath" -Target $command
            [System.IO.File]::WriteAllText($filePath, $command.ToCommand(), $encoding)
        }
    }
}