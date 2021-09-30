function New-Command {
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	param (
		[string]
		$Name,
		
		[string[]]
		$ParametersMandatory,
		
		[string[]]
		$ParametersOptional,
		
		[string[]]
		$Scopes,
		
		[string]
		$Begin,
		
		[string]
		$Process,
		
		[string]
		$End
	)
	
	process {
		$stringBuilder = [System.Text.StringBuilder]::new()
		$null = $stringBuilder.AppendLine("function $Name {")
		$null = $stringBuilder.AppendLine((New-CommandHelpBlock -Parameters (@($ParametersMandatory) + @($ParametersOptional)) -Scopes $Scopes))
		$null = $stringBuilder.AppendLine((New-CommandParameterBlock -Mandatory $ParametersMandatory -Optional $ParametersOptional))
		if ($Begin) {
			$null = $stringBuilder.AppendLine('    begin {')
			$null = $stringBuilder.AppendLine($Begin)
			$null = $stringBuilder.AppendLine('    }')
		}
		if ($Process) {
			$null = $stringBuilder.AppendLine('    process {')
			$null = $stringBuilder.AppendLine($Process)
			$null = $stringBuilder.AppendLine('    }')
		}
		if ($End) {
			$null = $stringBuilder.AppendLine('    end {')
			$null = $stringBuilder.AppendLine($End)
			$null = $stringBuilder.AppendLine('    }')
		}
		$null = $stringBuilder.AppendLine('}')
		$stringBuilder.ToString()
	}
}