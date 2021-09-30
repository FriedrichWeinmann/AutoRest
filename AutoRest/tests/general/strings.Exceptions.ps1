$exceptions = @{ }

<#
A list of entries that MAY be in the language files, without causing the tests to fail.
This is commonly used in modules that generate localized messages straight from C#.
Specify the full key as it is written in the language files, do not prepend the modulename,
as you would have to in C# code.

Example:
$exceptions['LegalSurplus'] = @(
    'Exception.Streams.FailedCreate'
    'Exception.Streams.FailedDispose'
)
#>
$exceptions['LegalSurplus'] = @(
	
)

<#
A list of entries that MAY be used without being contained in the language file.
It is assumed the strings are provided externally, such as another module this module depends on.
#>
$exceptions['ForeignSourced'] = @(
	'Validate.FSPath.File'
	'Validate.FSPath.Folder'
)

$exceptions