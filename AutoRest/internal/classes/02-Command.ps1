﻿class Command {
    [string]$Name
    [string]$Synopsis
    [string]$Description
    [string]$DocumentationUrl = '<unknown>'

    [string]$Method
    [string]$EndpointUrl
    [string]$ServiceName
    [string[]]$Scopes = @()

    [Hashtable]$Parameters = @{ }
    [Hashtable]$ParameterSets = @{ }

    [string]$RestCommand
    [string]$ProcessorCommand

	[string]$ShouldProcess
	[string]$ShouldProcessTarget
	[string[]]$PssaRulesIgnored
	[bool]$PassThruActions

    [string]$ConvertToHashtableCommand

    [string]ToExample() {
        $format = @'
.EXAMPLE
    PS C:\> {0}

    {1}
'@
		$sets = @{ }
		foreach ($set in $this.ParameterSets.Keys) {
			$sets[$set] = @()
		}
		foreach ($parameter in $this.Parameters.Values) {
            foreach ($set in $parameter.ParameterSet) {
                if ($sets[$set]) { continue }
                $sets[$set] = @()
            }
            if (-not $parameter.Mandatory) { continue }

            foreach ($set in $parameter.ParameterSet) {
                $sets[$set] += $parameter
            }
        }

        $texts = foreach ($set in $sets.Keys) {
            $descriptionText = '<insert description here>'
            if ($this.ParameterSets[$set]) { $descriptionText = $this.ParameterSets[$set] }

            $commandText = (@($this.Name) + @(($sets[$set] | ForEach-Object ToExample))) -join " "

            $format -f $commandText, $descriptionText
        }

        return $texts -join "`n`n"
    }

    [string]ToHelp() {
        $format = @'
<#
.SYNOPSIS
    {0}

.DESCRIPTION
    {1}

{2}

{3}

.LINK
    {4}
#>
'@
        $parameterHelp = $this.Parameters.Values | Sort-Object Weight | ForEach-Object ToHelp | Join-String -Separator "`n`n"
		if ($this.ShouldProcess) {
			$shouldPropcessHelp = @'
.PARAMETER Confirm
	If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

.PARAMETER WhatIf
	If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.
'@
			$parameterHelp = $parameterHelp, $shouldPropcessHelp -join "`n`n"
		}
        $descriptionText = $this.Description
        if ($this.Scopes) { $descriptionText = $descriptionText, ('    Scopes required (delegate auth): {0}' -f ($this.Scopes -join ", ")) -join "`n`n" }
        return $format -f $this.Synopsis, $descriptionText, $parameterHelp, $this.ToExample(), $this.DocumentationUrl
    }

    [string]ToParam() {
		if (-not $this.ShouldProcess -and $this.Name -match '^New-|^Remove-|^Set-|^Start-') {
			$this.PssaRulesIgnored = @($this.PssaRulesIgnored) + @('PSUseShouldProcessForStateChangingFunctions')
		}
		$pssaString = ''
		foreach ($rule in $this.PssaRulesIgnored) {
			if (-not "$rule") { continue }
			$pssaString += @"
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('$rule', '')]

"@
		}
		
		$supportsShouldProcess = ''
		if ($this.ShouldProcess) { $supportsShouldProcess = ', SupportsShouldProcess = $true' }
		return @"
$pssaString    [CmdletBinding(DefaultParameterSetName = 'default'$($supportsShouldProcess))]
    param (
$($this.Parameters.Values | Sort-Object Weight | ForEach-Object ToParam | Join-String ",`n`n")
    )
"@
    }

    [string]ToProcess() {
        $bodyString = '@({0})' -f (($this.Parameters.Values | Where-Object Type -EQ Body).Name | Add-String "'" "'" | Join-String ",")
        $queryString = '@({0})' -f (($this.Parameters.Values | Where-Object Type -EQ Query).Name | Add-String "'" "'" | Join-String ",")
        $headerString = '@({0})' -f (($this.Parameters.Values | Where-Object Type -EQ Header).Name | Add-String "'" "'" | Join-String ",")
        [string]$pathReplacement = $this.Parameters.Values | Where-Object {
			$_.Type -eq 'Path' -and
            $this.EndpointUrl -like "*{$($_.SystemName)}*"
        } | Format-String -Format " -Replace '{{{0}}}',`${1}" -Property SystemName, Name | Join-String ""
		$pathModifier = ''
        if ($optionalParameter = $this.Parameters.Values | Where-Object { $_.Type -eq 'Path' -and $this.EndpointUrl -notlike "*{$($_.SystemName)}*" }) {
            $pathModifier = 'if (${0}) {{ $__param.Path += "/${0}" }}' -f $optionalParameter.Name
        }
		$actionsString = ''
		if ($this.PassThruActions) { $actionsString = "`$__param += `$PSBoundParameters | $($this.ConvertToHashtableCommand) -Include 'ErrorAction', 'WarningAction', 'Verbose'" }
        $scopesString = ''
        if ($this.Scopes) { $scopesString = 'RequiredScopes = {0}' -f ($this.Scopes | Add-String "'" "'" | Join-String ',') }
        $processorString = ''
        if ($this.ProcessorCommand) { $processorString = " | $($this.ProcessorCommand)" }
        $serviceString = ''
        if ($this.ServiceName) { $serviceString = "Service = '$($this.ServiceName)'" }
        $mappingString = $this.Parameters.Values | Where-Object Type -NE Path | Format-String -Format "            '{0}' = '{1}'" -Property Name, SystemName | Join-String "`n"
        $miscParameterString = $this.Parameters.Values | Where-Object Type -eq Misc | Format-String -Format ' -{0} ${1}' -Property SystemName, Name | Join-String " "
		$shouldProcessString = ''
		if ($this.ShouldProcess) {
			$target = $this.ShouldProcessTarget
			if (-not $target) { $target = '${0}' -f @(@($this.Parameters.Keys).Where{ $_ -like "*ID" })[0] }
			if ($target -eq '$') { $target = '<target>' }
			$shouldProcessString = '        if (-not $PSCmdlet.ShouldProcess("{0}","{1}")) {{ return }}' -f $target, $this.ShouldProcess
		}

		return @"
		`$__mapping = @{
$mappingString
		}

		`$__param = @{
			Body = `$PSBoundParameters | $($this.ConvertToHashtableCommand) -Include $bodyString -Mapping `$__mapping
			Query = `$PSBoundParameters | $($this.ConvertToHashtableCommand) -Include $queryString -Mapping `$__mapping
			Header = `$PSBoundParameters | $($this.ConvertToHashtableCommand) -Include $headerString -Mapping `$__mapping
			Path = '$($this.EndpointUrl)'$pathReplacement
			Method = '$($this.Method)'
			$scopesString
			$serviceString
		}
		$pathModifier
		$actionsString
$shouldProcessString
		try { $($this.RestCommand) @__param$($miscParameterString)$($processorString) }
		catch { `$PSCmdlet.ThrowTerminatingError(`$_) }
"@
    }

	[string]ToCommand([bool]$NoHelp = $false) {
		if ($NoHelp) {
			return @"
function $($this.Name) {
$($this.ToParam())
    process {
$($this.ToProcess())
    }
}
"@
		}
        return @"
function $($this.Name) {
$($this.ToHelp())
$($this.ToParam())
    process {
$($this.ToProcess())
    }
}
"@
    }
}