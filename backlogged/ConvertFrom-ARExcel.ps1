function ConvertFrom-ARExcel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [PsfValidateScript('PSFramework.Validate.FSPath.File', ErrorString = 'PSFramework.Validate.FSPath.File')]
        [Alias('FullName')]
        [string]
        $Path,
		
        [PsfValidateScript('PSFramework.Validate.FSPath.Folder', ErrorString = 'PSFramework.Validate.FSPath.Folder')]
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
        foreach ($entry in Import-Excel -Path $Path) {
            if (-not ($entry.Command -and $entry.Endpoint -and $entry.Method)) {
                Stop-PSFFunction -String 'ConvertFrom-ARExcel.BadInput' -StringValues $entry -Target $entry -Continue -EnableException $EnableException
            }
			
            $param = @{
                CommandName         = $entry.Command
                Endpoint            = $entry.Endpoint
                Method              = $entry.Method
                ParametersMandatory = $entry.ParametersMandatory | Remove-PSFNull | Split-String -Separator ',|;' | Get-SubString -Trim " "
                ParametersOptional  = $entry.ParametersOptional | Remove-PSFNull | Split-String -Separator ',|;' | Get-SubString -Trim " "
                Filters             = $entry.Filters | Remove-PSFNull | Split-String -Separator ',|;' | Get-SubString -Trim " "
                Scopes              = $entry.Scopes | Remove-PSFNull | Split-String -Separator ',|;' | Get-SubString -Trim " "
                ProcessorCommand    = $entry.Processor
                OutPath             = $OutPath
                RestCommand         = $RestCommand
                GroupByEndpoint     = $GroupByEndpoint
                Force               = $Force
            }
            ConvertTo-ARCommand @param
        }
    }
}