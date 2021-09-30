class CommandParameter {
    [string]$Name
    [string]$SystemName
    [string]$Help = '<insert description here>'
    [string]$ParameterType = 'string'
    [string[]]$ParameterSet = @('default')
    [string[]]$Alias
    [bool]$Mandatory
    [bool]$ValueFromPipeline
    [int]$Weight = 1000
    [ParameterType]$Type

    [string]ToExample() {
        return '-{0} ${1}' -f $this.Name, $this.Name.ToLower()
    }

    [string]ToHelp() {
        return @'
.PARAMETER {0}
    {1}
'@ -f $this.Name, $this.Help
    }

    [string]ToParam() {
        $sb = [System.Text.StringBuilder]::new()
        $mandatoryString = ''
        if ($this.Mandatory) { $mandatoryString = 'Mandatory = $true, ' }
        $pipelineString = ''
        if ($this.ValueFromPipeline) { $pipelineString = 'ValueFromPipeline = $true, ' }
        foreach ($set in $this.ParameterSet) {
            $null = $sb.AppendLine(("        [Parameter({0}{1}ValueFromPipelineByPropertyName = `$true, ParameterSetName = '{2}')]" -f $mandatoryString, $pipelineString, $set))
        }
        if ($this.Alias) { $null = $sb.AppendLine("        [Alias($($this.Alias | Add-String "'" "'" | Join-String ','))]") }
        $null = $sb.AppendLine("        [$($this.ParameterType)]")
        $null = $sb.Append("        `$$($this.Name)")
        return $sb.ToString()
    }

    CommandParameter() { }

    CommandParameter(
        [string]$Name
    ) {
        $this.SystemName = $Name
        $this.Name = $Name.Trim('$') | Split-String -Separator "\s" | ForEach-Object {
            $_.SubString(0, 1).ToUpper() + $_.Substring(1)
        } | Join-String -Separator ""
    }
    CommandParameter(
        [string]$Name,
        [string]$Help,
        [string]$ParameterType,
        [bool]$Mandatory,
        [ParameterType]$Type
    ) {
        $this.SystemName = $Name
        $this.Name = $Name.Trim('$') | Split-String -Separator "\s" | ForEach-Object {
            $_.SubString(0, 1).ToUpper() + $_.Substring(1)
        } | Join-String -Separator ""
        $this.Help = $Help
        $this.ParameterType = $ParameterType
        if ($Name -eq '$select' -and $ParameterType -eq 'string') {
            $this.ParameterType = 'string[]'
        }
        $this.Mandatory = $Mandatory
        $this.Type = $Type
    }
}