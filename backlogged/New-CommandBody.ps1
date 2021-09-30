function New-CommandBody {
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$RestCommand,
		
		[Parameter(Mandatory = $true)]
		[string]
		$Endpoint,
		
		[Parameter(Mandatory = $true)]
		[string]
		$Method,
		
		[AllowEmptyCollection()]
		[string[]]
		$ParametersMandatory,
		
		[AllowEmptyCollection()]
		[string[]]
		$ParametersOptional,
		
		[AllowEmptyCollection()]
		[string[]]
		$Scopes,
		
		[AllowEmptyString()]
		[string]
		$ProcessorCommand
	)
	
	process {
		$stringBuilder = [System.Text.StringBuilder]::new()
		$parametersString = ''
		if ($ParametersMandatory -or $ParametersOptional) {
			$null = $stringBuilder.AppendLine('        $parameters = @{ }')
			foreach ($parameter in $ParametersMandatory) {
				$null = $stringBuilder.AppendLine(('        $parameters.{0} = ${0}') -f $parameter)
			}
			foreach ($parameter in $ParametersOptional) {
				$null = $stringBuilder.AppendLine(('        if ($PSBoundParameters.ContainsKey("{0}")) {{ $parameters.{0} = ${0} }}') -f $parameter)
			}
			$parametersString = ' -Body $parameters'
		}
		$processorString = ''
		if ($ProcessorCommand) { $processorString = " | $ProcessorCommand" }
		$scopesString = ''
		if ($Scopes) { $scopesString = ' -RequiredScopes ''{0}''' -f ($Scopes -join "','") }
		
		$null = $stringBuilder.AppendLine("        $RestCommand -Path '$Endpoint' -Method $($Method)$($scopesString)$($parametersString)$($processorString)")
		$stringBuilder.ToString()
	}
}