# Changelog

## 1.0.4 (2024-03-18)

+ Upd: Export-ARCommand - Added `Start-` to the list of verbs that defaults to skip ShouldProcess requirements.
+ Fix: Export-ARCommand - ConvertToHashtableCommand is not respected for translating common parameters

## 1.0.2

+ Upd: Added support to pass through some common parameters via `PassThruActions` command setting
+ Fix: ConvertFrom-ARSwagger errors when parameterset keys are empty

## 1.0.0 (2022-04-14)

+ Upd: Added Support to disable any PSSA rule per command config 'PssaRulesIgnored' (string[])
+ Upd: Added Support for ShouldProcess
+ Upd: Automatically include a PSScriptAnalyzer exemption for ShouldProcess in commands that have state-changing verbs, unless ShouldProcess is provided for
+ Upd: Disabled message integration when parsing swagger files. Added configuration setting to enable it again. Performance optimization. (Thank you @nohwnd; #8)
+ Fix: Error when overriding parameters on a secondary parameterset
+ Fix: Fails to apply override example help for secondary parametersets

## 0.2.0 (2022-02-14)

+ New: Support header parameters (#13 | @Callidus2000)
+ New: Support adding parameters to pass through (#13 | @Callidus2000)
+ Upd: ConvertFrom-ARSwagger - Added ability to select hashtable processing command (#13 | @Callidus2000)
+ Other: Added docs and examples (#13 | @Callidus2000)

## 0.1.4 (2021-10-01)

+ Upd: Added option to export commands without help
+ Fix: Example not included in help when command has no parameters
+ Fix: Parameter-Type defaults to object if not specified
+ Fix: Fails to resolve referenced parameter

## 0.1.0 (2021-09-30)

+ Initial Release
