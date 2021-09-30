function ConvertTo-ARCommand {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]
        $CommandName,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]
        $Endpoint,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]
        $Method,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [AllowEmptyCollection()]
        [string[]]
        $ParametersMandatory,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [AllowEmptyCollection()]
        [string[]]
        $ParametersOptional,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [AllowEmptyCollection()]
        [string[]]
        $Filters,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string[]]
        $Scopes,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]
        $ProcessorCommand,

        [string]
        $OutPath = '.',

        [Parameter(Mandatory = $true)]
        [string]
        $RestCommand,
		
		[switch]
		$GroupByEndpoint,
		
		[switch]
		$Force,
		
		[switch]
		$EnableException
    )

    process {
        $paramNewCommandBody = $PSBoundParameters | ConvertTo-PSFHashtable -Include RestCommand, Endpoint, Method, ParametersMandatory, ParametersOptional, Scopes, ProcessorCommand
        $bodyCode = New-CommandBody @paramNewCommandBody
        
        $paramNewCommand = @{
            Name = $CommandName
            ParametersMandatory = $ParametersMandatory
            ParametersOptional = $ParametersOptional
            Process = $bodyCode
        }
        if ($Scopes) { $paramNewCommand.Scopes = $Scopes }
        $commandCode = New-Command @paramNewCommand
        
        $outFolder = Resolve-PSFPath -Path $OutPath
        if ($GroupByEndpoint) {
            $endpointElement = @($Endpoint -split "/")[0]
            $outFolder = Join-Path -Path $outFolder -ChildPath ([System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase($endpointElement))
        }
        if (-not (Test-Path -Path $outFolder)) { $null = New-Item -Path $outFolder -ItemType Directory -Force }
        $commandPath = Join-Path -Path $outFolder -ChildPath "$($CommandName).ps1"
        if (-not $Force -and (Test-Path -Path $commandPath)) { continue }
        $encoding = [System.Text.UTF8Encoding]::new($true)
        [System.IO.File]::WriteAllText($commandPath, $commandCode, $encoding)
    }
}