@{
	# Script module or binary module file associated with this manifest
	RootModule = 'AutoRest.psm1'

	# Version number of this module.
	ModuleVersion = '0.2.0'

	# ID used to uniquely identify this module
	GUID = '18c33632-995c-4b5e-82fb-c52c2f6a176f'

	# Author of this module
	Author = 'Friedrich Weinmann'

	# Company or vendor of this module
	CompanyName = 'Microsoft'

	# Copyright statement for this module
	Copyright = 'Copyright (c) 2021 Friedrich Weinmann'

	# Description of the functionality provided by this module
	Description = 'Automate command creation wrapping a REST api'

	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion = '5.1'

	# Modules that must be imported into the global environment prior to importing
	# this module
	RequiredModules = @(
		@{ ModuleName = 'PSFramework'; ModuleVersion = '1.6.205' }
#		@{ ModuleName = 'ImportExcel'; ModuleVersion = '7.1.0' }
		@{ ModuleName = 'String'; ModuleVersion = '1.0.0' }
	)

	# Assemblies that must be loaded prior to importing this module
	# RequiredAssemblies = @('bin\AutoRest.dll')

	# Type files (.ps1xml) to be loaded when importing this module
	# TypesToProcess = @('xml\AutoRest.Types.ps1xml')

	# Format files (.ps1xml) to be loaded when importing this module
	# FormatsToProcess = @('xml\AutoRest.Format.ps1xml')

	# Functions to export from this module
	FunctionsToExport = @(
		'ConvertFrom-ARSwagger'
		'Export-ARCommand'
	)

	# Private data to pass to the module specified in ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
	PrivateData = @{

		#Support for PowerShellGet galleries.
		PSData = @{

			# Tags applied to this module. These help with module discovery in online galleries.
			Tags = @('rest', 'codegen')

			# A URL to the license for this module.
			LicenseUri = 'https://github.com/FriedrichWeinmann/AutoRest/blob/master/LICENSE'

			# A URL to the main website for this project.
			ProjectUri = 'https://github.com/FriedrichWeinmann/AutoRest'

			# A URL to an icon representing this module.
			# IconUri = ''

			# ReleaseNotes of this module
			# ReleaseNotes = ''

		} # End of PSData hashtable

	} # End of PrivateData hashtable
}