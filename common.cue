package core

import (
	"strings"
)

#LabelsAnnotationsType: [string]: string | int | bool | [string | int | bool]
#NameType: string & strings.MinRunes(1) & strings.MaxRunes(254)

#VersionType: string & =~"^\\d+\\.\\d+\\.\\d+(-[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?(\\+[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?$"

/////////////////////////////////////////////////////////////////
//// Output Types
/////////////////////////////////////////////////////////////////

// Output format types
#OutputFormat: "yaml" | "json" | "toml" | "hcl"

#FileOutput: {
	data:   _ // File content
	format: #OutputFormat
}

#ModuleOutput: {
	// Single manifest output
	// Can be a structured object or string
	manifest?: _

	// File-based output - map of files
	// Used for: Kustomize, Helm, multi-file outputs
	files?: [string]: #FileOutput
}
