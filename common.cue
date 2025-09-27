package core

import (
	"strings"
)

#LabelsAnnotationsType: [string]: string | int | bool
#NameType:    string & strings.MinRunes(1) & strings.MaxRunes(254)
#VersionType: string & =~"^\\d+\\.\\d+\\.\\d+(-[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?(\\+[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?$"
