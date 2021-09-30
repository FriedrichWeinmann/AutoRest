function New-CommandParameterBlock
{
	[CmdletBinding()]
	param (
		[AllowEmptyCollection()]
		[string[]]
		$Mandatory,
		
		[AllowEmptyCollection()]
		[string[]]
		$Optional
	)
	
	process
	{
		$stringBuilder = [System.Text.StringBuilder]::new()
		$null = $stringBuilder.AppendLine('    [CmdletBinding()]')
		$null = $stringBuilder.AppendLine('    Param (')
		$first = $true
		
		foreach ($parameter in $Mandatory) {
			if (-not $first) {
				$null = $stringBuilder.AppendLine(',')
				$null = $stringBuilder.AppendLine("")
			}
			$null = $stringBuilder.AppendLine('        [Parameter(Mandatory = $true)]')
			$null = $stringBuilder.Append("        `$$parameter")
			$first = $false
		}
		foreach ($parameter in $Optional) {
			if (-not $first) {
				$null = $stringBuilder.AppendLine(',')
				$null = $stringBuilder.AppendLine("")
			}
			$null = $stringBuilder.Append("        `$$parameter")
			$first = $false
		}
		$null = $stringBuilder.AppendLine("")
		$null = $stringBuilder.AppendLine('    )')
		$stringBuilder.ToString()
	}
}