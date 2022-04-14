<#
This is an example configuration file

By default, it is enough to have a single one of them,
however if you have enough configuration settings to justify having multiple copies of it,
feel totally free to split them into multiple files.
#>

<#
# Example Configuration
Set-PSFConfig -Module 'AutoRest' -Name 'Example.Setting' -Value 10 -Initialize -Validation 'integer' -Handler { } -Description "Example configuration setting. Your module can then use the setting using 'Get-PSFConfigValue'"
#>

Set-PSFConfig -Module 'AutoRest' -Name 'Import.DoDotSource' -Value $false -Initialize -Validation 'bool' -Description "Whether the module files should be dotsourced on import. By default, the files of this module are read as string value and invoked, which is faster but worse on debugging."
Set-PSFConfig -Module 'AutoRest' -Name 'Import.IndividualFiles' -Value $false -Initialize -Validation 'bool' -Description "Whether the module files should be imported individually. During the module build, all module code is compiled into few files, which are imported instead by default. Loading the compiled versions is faster, using the individual files is easier for debugging and testing out adjustments."

Set-PSFConfig -Module 'AutoRest' -Name 'Author' -Value $env:USERNAME -Initialize -Validation string -Description 'The user running this module. Will be added to output metadata.'
Set-PSFConfig -Module 'AutoRest' -Name 'Company' -Value 'Contoso ltd.' -Initialize -Validation string -Description 'The company owning the output. Will be added to output metadata.'
Set-PSFConfig -Module 'AutoRest' -Name 'Logging.Level' -Value 'Warning' -Initialize -Validation string -Description 'The maximum level of logging when generating commands from swagger file. Corresponds to PSFramework message levels. Set this to "Critical" to have all actions logged. Enabling this logging costs performance when parsing swagger files, but helps with debugging.'