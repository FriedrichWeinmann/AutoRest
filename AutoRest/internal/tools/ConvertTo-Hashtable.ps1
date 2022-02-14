function ConvertTo-Hashtable {
	<#
	.SYNOPSIS
		Converts an inputobject into a hashtable.

	.DESCRIPTION
		Converts an inputobject into a hashtable.
		Allows remapping keys as needed.

	.PARAMETER Include
		Which properties / keys to include.
		Only properties that exist on the input will be included, no matter what.

	.PARAMETER Mapping
		A hashtable mapping keys to another name.
		This is used to change the keys on hashtables.
		Specifically, this allows providing PowerShell-compliant parameter names, while passing them to the REST api how the API wants them.

	.PARAMETER InputObject
		The object to convert into a hashtable.

	.EXAMPLE
		PS C:\> $PSBoundParameters | ConvertTo-Hashtable -Include Name, Description, ID -Mapping @{ ID = 'objectId; Name = 'name' }

		Converts the $PSBoundParameters system-variable into a regular hashtable, discarding all entries but Name, Description and ID.
		"Name" will be renamed to be lowercase if specified, "ID" will be renamed to "objectId" if specified.
#>
	[CmdletBinding()]
	param (
		[AllowEmptyCollection()]
		[string[]]
		$Include,

		[Hashtable]
		$Mapping = @{ },

		[Parameter(ValueFromPipeline = $true)]
		$InputObject
	)

	process {
		$result = @{ }
		# Empty includes lead to empty hashtable; Otherwhise it would be the same as $Include='*'
		if ($Include) {
			if ($InputObject -is [System.Collections.IDictionary]) {
				foreach ($pair in $InputObject.GetEnumerator()) {
					if ($Include -and $pair.Key -notin $Include) { continue }
					if ($Mapping[$pair.Key]) { $result[$Mapping[$pair.Key]] = $pair.Value }
					else { $result[$pair.Key] = $pair.Value }
				}
			}
			else {
				foreach ($property in $InputObject.PSObject.Properties) {
					if ($Include -and $property.Name -notin $Include) { continue }
					if ($Mapping[$property.Name]) { $result[$Mapping[$property.Name]] = $property.Value }
					else { $result[$property.Name] = $property.Value }
				}
			}
  		}
		$result
	}
}