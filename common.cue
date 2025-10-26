package core

import (
	"strings"
)

#LabelsAnnotationsType: [string]: string | int | bool | [string | int | bool]
#NameType: string & strings.MinRunes(1) & strings.MaxRunes(254)

#VersionType: string & =~"^\\d+\\.\\d+\\.\\d+(-[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?(\\+[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?$"

// OpenAPIv3-compatible schema validator
#OpenAPIv3Primitive: null | bool | string | bytes | number | float | int
#OpenAPIv3Array: [...#OpenAPIv3Schema]
#OpenAPIv3Object: {
	[string]: #OpenAPIv3Schema
	...
}

#OpenAPIv3Schema: #OpenAPIv3Primitive | #OpenAPIv3Array | #OpenAPIv3Object

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
