﻿function ConvertFrom-ARSwagger {
	<#
	.SYNOPSIS
		Parse a swagger file and generate commands from it.

	.DESCRIPTION
		Parse a swagger file and generate commands from it.
		Only supports the JSON format of swagger file.

	.PARAMETER Path
		Path to the swagger file(s) to process.

	.PARAMETER TransformPath
		Path to a folder containing psd1 transform files.
		These can be used to override or add to individual entries from the swagger file.
		For example, you can add help URI, fix missing descriptions, add parameter help or attributes...

	.PARAMETER RestCommand
		Name of the command executing the respective REST queries.
		All autogenerated commands will call this command to execute.

	.PARAMETER ConvertToHashtableCommand
		In order to make it easier to include a version of `ConvertTo-Hashtable` you can rename the used
		function name by using this parameter. Defaults to `ConvertTo-Hashtable`.

	.PARAMETER ModulePrefix
		A prefix to add to all commands generated from this command.

	.PARAMETER PathPrefix
		Swagger files may include the same first uri segments in all endpoints.
		While this could be just passed through, you can also remove them using this parameter.
		It is then assumed, that the command used in the RestCommand is aware of this and adds it again to the request.
		Example:
		All endpoints in the swagger-file start with "/api/"
		"/api/users", "/api/machines", "/api/software", ...
		In that case, it could make sense to remove the "/api/" part from all commands and just include it in the invokation command.

	.PARAMETER ServiceName
		Adds the servicename to the commands generated.
		When exported, they will be hardcoded to execute as that service.
		This simplifies the configuration of the output, but prevents using multiple connections to different instances or under different privileges at the same time.

	.EXAMPLE
		PS C:\> Get-ChildItem .\swaggerfiles | ConvertFrom-ARSwagger -Transformpath .\transform -RestCommand Invoke-ARRestRequest -ModulePrefix Mg -PathPrefix '/api/'

		Picks up all items in the subfolder "swaggerfiles" and converts it to PowerShell command objects.
		Applies all transforms in the subfolder transform.
		Uses the "Invoke-ARRestRequest" command for all rest requests.
#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[PsfValidateScript('PSFramework.Validate.FSPath.File', ErrorString = 'PSFramework.Validate.FSPath.File')]
		[Alias('FullName')]
		[string]
		$Path,

		[PsfValidateScript('PSFramework.Validate.FSPath.Folder', ErrorString = 'PSFramework.Validate.FSPath.Folder')]
		[string]
		$TransformPath,

		[Parameter(Mandatory = $true)]
		[string]
		$RestCommand,

		[string]
		$ConvertToHashtableCommand = 'ConvertTo-Hashtable',

		[string]
		$ModulePrefix,

		[string]
		$PathPrefix,

		[string]
		$ServiceName
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
		function Add-ParameterConfig {
			[CmdletBinding()]
			param (
				[Hashtable]
				$ParameterConfig,
				[string]$ParameterName,
				$Command
			)
			Write-PSFMessage -Level Verbose -Tag "AddParameter" -Message "Adding Parameter $ParameterName mit $($ParameterConfig|ConvertTo-json -Compress) to Command $($Command.Name)"
			$additionalParameter = [CommandParameter]::new(
				$ParameterName,
				$ParameterConfig.Help,
				$ParameterConfig.ParameterType,
				$ParameterConfig.Mandatory,
				[ParameterType]$ParameterConfig.Type
			)
			if ($ParameterConfig.ParameterSet) { $additionalParameter.ParameterSet = $ParameterConfig.ParameterSet }
			if ($ParameterConfig.Weight) { $additionalParameter.Weight = $ParameterConfig.Weight }
			if ($ParameterConfig.SystemName) { $additionalParameter.SystemName = $ParameterConfig.SystemName }
			if ($ParameterConfig.ValueFromPipeline) { $additionalParameter.ValueFromPipeline = $ParameterConfig.ValueFromPipeline }

			$Command.Parameters.add($ParameterName, $additionalParameter)
		}

		function New-Parameter {
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
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

		function Resolve-ParameterReference {
			[CmdletBinding()]
			param (
				[string]
				$Ref,

				$SwaggerObject
			)

			# "#/components/parameters/top"
			$segments = $Ref | Set-String -OldValue '^#/' | Split-String -Separator '/'
			$paramValue = $SwaggerObject
			foreach ($segment in $segments) {
				$paramValue = $paramValue.$segment
			}
			$paramValue
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
			put    = "New"
			post   = "Set"
			patch  = "Set"
			delete = "Remove"
			head   = "Invoke"
		}
	}
	process {
		#region Process Swagger file
		foreach ($file in Resolve-PSFPath -Path $Path) {
			$data = Get-Content -Path $file | ConvertFrom-Json
			foreach ($endpoint in $data.paths.PSObject.Properties | Sort-Object { $_.Name.Length }, Name) {
				$endpointPath = ($endpoint.Name -replace "^$PathPrefix" -replace '/{[\w\s\d+-]+}$').Trim("/")
				$effectiveEndpointPath = ($endpoint.Name -replace "^$PathPrefix" -replace '\s' ).Trim("/")
				foreach ($method in $endpoint.Value.PSObject.Properties) {
					$commandKey = $endpointPath, $method.Name -join ":"
					Write-PSFMessage "Processing Command: $($commandKey)"
					#region Case: Existing Command
					if ($commands[$commandKey]) {
						$commandObject = $commands[$commandKey]
						$parameterSetName = $method.Value.operationId
						$commandObject.ParameterSets[$parameterSetName] = $method.Value.description

						#region Parameters
						foreach ($parameter in $method.Value.parameters) {
							if ($parameter.'$ref') {
								$parameter = Resolve-ParameterReference -Ref $parameter.'$ref' -SwaggerObject $data
								if (-not $parameter) {
									Write-PSFMessage -Level Warning -Message "  Unable to resolve referenced parameter $($parameter.'$ref')"
									continue
								}
							}

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
										ParameterType   = 'string'
										ParameterFormat = $parameter.format
										Mandatory       = $parameter.required -as [bool]
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

									$parameterType = $parameter.type
									if (-not $parameterType -and $parameter.schema.type) {
										$parameterType = $parameter.schema.type
										if ($parameter.schema.type -eq "array" -and $parameter.schema.items.type) {
											$parameterType = '{0}[]' -f $parameter.schema.items.type
										}
									}
									$parameterParam = @{
										Name            = $parameter.Name
										Help            = $parameter.Description
										ParameterType   = $parameterType
										ParameterFormat = $parameter.format
										Mandatory       = $parameter.required -as [bool]
										Type            = 'Query'
									}
									$commandObject.Parameters[$parameter.name] = New-Parameter @parameterParam
									$commandObject.Parameters[$parameter.name].ParameterSet = @($parameterSetName)
								}
								#endregion Query

								#region Header
								header {
									if ($commandObject.Parameters[$parameter.name]) {
										$commandObject.Parameters[$parameter.name].ParameterSet += @($parameterSetName)
										continue
									}
									$parameterType = $parameter.type
									if (-not $parameterType -and $parameter.schema.type) {
										$parameterType = $parameter.schema.type
										if ($parameter.schema.type -eq "array" -and $parameter.schema.items.type) {
											$parameterType = '{0}[]' -f $parameter.schema.items.type
										}
									}
									$parameterParam = @{
										Name            = $parameter.Name
										Help            = $parameter.Description
										ParameterType   = $parameterType
										ParameterFormat = $parameter.format
										Mandatory       = $parameter.required -as [bool]
										Type            = 'header'
									}
									$commandObject.Parameters[$parameter.name] = New-Parameter @parameterParam
									$commandObject.Parameters[$parameter.name].ParameterSet = @($parameterSetName)
								}
								#endregion Header
								Default {
									Write-PSFMessage -Level Warning -Message "Unknown Parameter Type $($parameter.in)"
								}
							}
						}
						#endregion Parameters
					}
					#endregion Case: Existing Command

					#region Case: New Command
					else {
						$commandNouns = foreach ($element in $endpointPath -split "/") {
							if ($element -like "{*}") { continue }
							[cultureinfo]::CurrentUICulture.TextInfo.ToTitleCase($element) -replace 's$' -replace '\$'
						}
						$commandObject = [Command]@{
							Name                      = "$($verbs[$method.Name])-$($ModulePrefix)$($commandNouns -join '')"
							Synopsis                  = $method.Value.summary
							Description               = $method.Value.description
							Method                    = $method.Name
							EndpointUrl               = $effectiveEndpointPath
							RestCommand               = $RestCommand
							ParameterSets             = @{
								'default' = $method.Value.description
							}
							ConvertToHashtableCommand = $ConvertToHashtableCommand
						}
						if ($ServiceName) { $commandObject.ServiceName = $ServiceName }
						$commands[$commandKey] = $commandObject

						foreach ($property in $commands[$commandKey].PSObject.Properties) {
							if ($property.Name -eq 'Parameters') { continue }
							if ($overrides.$commandKey.$($property.Name)) { $commandObject.$($property.Name) = $overrides.$commandKey.$($property.Name) }
						}

						#region Parameters
						foreach ($parameter in $method.Value.parameters) {
							if ($parameter.'$ref') {
								$parameter = Resolve-ParameterReference -Ref $parameter.'$ref' -SwaggerObject $data
								if (-not $parameter) {
									Write-PSFMessage -Level Warning -Message "  Unable to resolve referenced parameter $($parameter.'$ref')"
									continue
								}
							}

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
										ParameterType   = 'string'
										ParameterFormat = $parameter.format
										Mandatory       = $parameter.required -as [bool]
										Type            = 'Path'
									}
									$commandObject.Parameters[($parameter.name -replace '\s')] = New-Parameter @parameterParam
								}
								#endregion Path

								#region Query
								query {
									$parameterType = $parameter.type
									if (-not $parameterType -and $parameter.schema.type) {
										$parameterType = $parameter.schema.type
										if ($parameter.schema.type -eq "array" -and $parameter.schema.items.type) {
											$parameterType = '{0}[]' -f $parameter.schema.items.type
										}
									}

									$parameterParam = @{
										Name            = $parameter.Name
										Help            = $parameter.Description
										ParameterType   = $parameterType
										ParameterFormat = $parameter.format
										Mandatory       = $parameter.required -as [bool]
										Type            = 'Query'
									}
									$commandObject.Parameters[$parameter.name] = New-Parameter @parameterParam
								}
								#endregion Query

								#region Header
								header {
									$parameterType = $parameter.type
									if (-not $parameterType -and $parameter.schema.type) {
										$parameterType = $parameter.schema.type
										if ($parameter.schema.type -eq "array" -and $parameter.schema.items.type) {
											$parameterType = '{0}[]' -f $parameter.schema.items.type
										}
									}

									$parameterParam = @{
										Name            = $parameter.Name
										Help            = $parameter.Description
										ParameterType   = $parameterType
										ParameterFormat = $parameter.format
										Mandatory       = $parameter.required -as [bool]
										Type            = 'Header'
									}
									$commandObject.Parameters[$parameter.name] = New-Parameter @parameterParam
								}
								#endregion Header
								Default {
									Write-PSFMessage -Level Warning -Message "Unknown Parameter Type $($parameter.in)"
								}

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

						#region Parameter Additions
						foreach ($parameterName in $overrides.additionalGlobalParameters.Keys) {
							if ($commandObject.Parameters[$parameterName]) {
								Write-PSFMessage -Level Warning -Message "Invalid additional parameter: $parameterName - already exists on $($commandObject.Name)" -Target $commandObject
								continue
							}
							Add-ParameterConfig -ParameterName $parameterName -ParameterConfig $overrides.additionalGlobalParameters[$parameterName] -Command $commandObject
						}
						foreach ($partialPath in $overrides.additionalScopedParameters.Keys) {
							if ($effectiveEndpointPath -notlike $partialPath) { continue }
							# write-host "Checking $effectiveEndpointPath against ScopedPath `$partialPath=$partialPath"
							foreach ($parameterPair in $overrides.additionalScopedParameters.$($partialPath).GetEnumerator()) {
								$parameterName = $parameterPair.Name
								if ($commandObject.Parameters[$parameterName]) {
									Write-PSFMessage -Level Warning -Message "Invalid additional parameter: $parameterName - already exists on $($commandObject.Name)" -Target $commandObject
									continue
								}

								Add-ParameterConfig -ParameterName $parameterName -ParameterConfig $parameterPair.value -Command $commandObject

								# Copy-ParameterConfig -Parameter $commandObject.Parameters[$parameterPair.Name] -Config $parameterPair.Value
							}
						}
						foreach ($parameterName in $overrides.additionalParameters.$commandKey.Keys) {
							if ($commandObject.Parameters[$parameterName]) {
								Write-PSFMessage -Level Warning -Message "Invalid additional parameter: $parameterName - already exists on $($commandObject.Name)" -Target $commandObject
								continue
							}
							Add-ParameterConfig -ParameterName $parameterName -ParameterConfig $overrides.additionalParameters.$commandKey[$parameterName] -Command $commandObject
						}
						#endregion Parameter Additions
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
		$commands.Values
	}
}