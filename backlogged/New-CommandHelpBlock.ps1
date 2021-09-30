function New-CommandHelpBlock
{
	[CmdletBinding()]
	Param (
		[String[]]
		$Parameters,
		
		[string[]]
		$Scopes
	)
	
	begin
	{
		
	}
	process
	{
		$stringBuilder = [System.Text.StringBuilder]::new()
		$helpString = @'
<#
.SYNOPSIS
    <Add Synopsis here>

.DESCRIPTION
    <Add Description here>

{0}

.EXAMPLE
    PS C:\> {1}

    <Add Example Description here>

.NOTES
    Scopes needed: {2}
    Author: {3}
    Company: {4}
#>
'@
	}
	end
	{
		
	}
}