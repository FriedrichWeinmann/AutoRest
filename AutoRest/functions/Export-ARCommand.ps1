function Export-ARCommand
{
<#
	.SYNOPSIS
		Writes AutoRest Command objects to file as a function definition.
	
	.DESCRIPTION
		Writes AutoRest Command objects to file as a function definition.
	
		To generate AutoRest Command objects, use a parsing command such as ConvertFrom-ARSwagger.
	
	.PARAMETER Path
		The Path in which the resulting set of commands should be placed.
	
	.PARAMETER GroupByEndpoint
		By default, each command will be placed in the OutPath folder.
		Setting this parameter will instead create a folder for the first element in each endpoint path and group the output by that.
	
	.PARAMETER Force
		Overwrite existing files.
		By default, this command will skip files of commands that were already created.
		Setting the -Force parameter enforces those being overwritten, updating the command, but discarding any manual edits.
	
	.PARAMETER Command
		The command object(s) to write to file.
		Can be generated using the ConvertFrom-ARSwagger command.
	
	.EXAMPLE
		PS C:\> $commands | Export-ARCommand
	
		Exports all the commands specified to the current folder.
	
	.EXAMPLE
		PS C:\> ConvertFrom-ARSwagger @param | Export-ARCommand -Path C:\Code\modules\MyApi\functions -GroupByEndpoint -Force
	
		Takes the output of ConvertFrom-ARSwagger and writes it to the specified folder, creating a subfolder for each top-level api endpoint node.
		Existing files will be overwritten.
#>
	[CmdletBinding()]
	param (
		[PsfValidateScript('PSFramework.Validate.FSPath.Folder', ErrorString = 'PSFramework.Validate.FSPath.Folder')]
		[string]
		$Path = '.',
		
		[switch]
		$GroupByEndpoint,
		
		[switch]
		$Force,
		
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[PSFramework.Utility.TypeTransformationAttribute([Command])]
		[Command[]]
		$Command
	)
	
	begin
	{
		$encoding = [System.Text.UTF8Encoding]::new($true)
	}
	process
	{
		foreach ($commandObject in $Command) {
			$targetFolder = Resolve-PSFPath $Path
			if ($GroupByEndpoint) {
				$targetFolder = Join-Path -Path (Resolve-PSFPath $Path) -ChildPath ($commandObject.EndpointUrl -split "/" | Select-Object -First 1)
			}
			if (-not (Test-Path -Path $targetFolder)) {
				$null = New-Item -Path $targetFolder -ItemType Directory -Force
			}
			$filePath = Join-Path -Path $targetFolder -ChildPath "$($commandObject.Name).ps1"
			if (-not $Force -and (Test-Path -Path $filePath)) {
				Write-PSFMessage -Message "Skipping $($commandObject.Name), as $filePath already exists." -Target $commandObject
			}
			Write-PSFMessage -Message "Writing $($commandObject.Name) to $filePath" -Target $commandObject
			[System.IO.File]::WriteAllText($filePath, $commandObject.ToCommand(), $encoding)
		}
	}
}