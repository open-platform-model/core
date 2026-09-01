## REMOVED Requirements

The capability is retired. Its subject, what a `#Platform` declares about the catalog builds it admits, survives in full under the new `platform-registry` capability, restated in the vocabulary of the import model (enhancement 0019 D5, D17). The name went with `#Subscription`: every requirement below was phrased against a `version!` scalar that no longer exists, and a capability directory named for a removed construct misdescribes what it holds.

Removing all four requirements leaves no requirement block, so this change's `.openspec.yaml` sets `retire_capabilities: true` and the sync deletes the main spec and its directory.

### Requirement: A subscription names exactly one catalog build

**Reason**: `#Subscription` is removed (enhancement 0019 D5). A version string is inert data nothing in a build resolves; the entry now carries the build itself by import, and one entry still names exactly one build, selected by the platform module's `cue.mod`.

**Migration**: replace each `"<path>": {version: "X.Y.Z"}` subscription with an import of the catalog module at that version and an entry `"<path>": {#catalog: <import>}`; move the version pin into the platform module's `cue.mod`. The successor requirement is `platform-registry` § "A registry entry carries its catalog by import".

### Requirement: A prerelease is selected by being written down

**Reason**: the `version!` field the requirement was phrased against is removed. The behavior survives inside `platform-registry` § "Catalog selection is a pure function of committed source": a prerelease is selected by naming it in the platform module's `cue.mod`.

**Migration**: name the prerelease in the platform module's `cue.mod` dependency on the catalog.

### Requirement: Catalog selection is a pure function of committed source

**Reason**: carried to `platform-registry` under the same title, with its mechanism restated. The property is unchanged and is the one enhancement 0010 D14 established; what changes is where the committed source lives, from the platform file's `version!` to the platform module's `cue.mod`, which is committed source too.

**Migration**: none. The property holds across the reshape; the successor requirement states it against `cue.mod`.

### Requirement: One subscription per catalog path

**Reason**: restated in entry vocabulary as `platform-registry` § "One registry entry per catalog path". The mechanism (CUE map semantics) and the force are unchanged, and the import model adds a second mechanism beneath it: the platform module's `cue.mod` admits one build per catalog major.

**Migration**: none; the constraint is carried forward by the successor requirement.
