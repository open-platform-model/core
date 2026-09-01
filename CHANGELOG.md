# Changelog

## [2.0.0-alpha.7](https://github.com/open-platform-model/core/compare/v2.0.0-alpha.6...v2.0.0-alpha.7) (2026-09-01)


### ⚠ BREAKING CHANGES

* **platform:** #Subscription and #Platform.#matchers are removed, and #Platform.#composedTransformers changes from an optional kernel-filled slot to a required derived fold. Absorbed on the v2 alpha line. The release is unconsumable by the current library kernel; library stays pinned to the prior alpha until its 0019 Phase B wave lands.

### Features

* **platform:** carry the catalog in the registry entry, drop #Subscription and #matchers ([#61](https://github.com/open-platform-model/core/issues/61)) ([0a71fdc](https://github.com/open-platform-model/core/commit/0a71fdc38bdc1c6dfe206e95435a204928a39f14))
* **transformer:** project #context from the other two #transform inputs ([#59](https://github.com/open-platform-model/core/issues/59)) ([e57dc4b](https://github.com/open-platform-model/core/commit/e57dc4b5261210bd687e6c789ac55fba934eae07))

## [2.0.0-alpha.6](https://github.com/open-platform-model/core/compare/v2.0.0-alpha.5...v2.0.0-alpha.6) (2026-08-26)


### ⚠ BREAKING CHANGES

* **component:** metadata.resourceName's override ceiling widens from #NameType to the new #ObjectNameType (DNS subdomain, 253 runes), and the overlong-default guard is retired as unreachable. #Resource, #Trait and #Blueprint gain a hidden #nameConstraint slot (top by default) that #Component collects and asserts against the resolved name on a hidden field, so a name a rendering primitive rejects is refused at vet. Inert until a catalog declares a constraint. #ComponentNames.resourceName follows the field's ceiling. Adds #ServiceNameType (DNS-1035).
* **component:** #Component.metadata.resourceName now defaults to "<instance>-<component>" instead of the bare component name, so #names.resourceName and #names.dns.* change for every component that does not set resourceName explicitly. This is the name every rendered primary object already carries, so rendered output does not move; the computed name now agrees with it. New refusal: an instance name plus component name whose concatenation exceeds 63 runes fails validation, naming the string.

### Features

* **component:** default resourceName to the instance-qualified name ([#51](https://github.com/open-platform-model/core/issues/51)) ([cd4f4be](https://github.com/open-platform-model/core/commit/cd4f4be6590b34c58d7446268c5c511d5a349b80))
* **component:** name types and per-primitive #nameConstraint ([#52](https://github.com/open-platform-model/core/issues/52)) ([164038c](https://github.com/open-platform-model/core/commit/164038cbc70ebe4f350710a4662840e0e0dcabdb))
* **openspec:** wire enhancement delivery-log declarations into the workflow ([a11aefc](https://github.com/open-platform-model/core/commit/a11aefcf1d4a58116a1b2e9f362bfc0bb385a156))

## [2.0.0-alpha.5](https://github.com/open-platform-model/core/compare/v2.0.0-alpha.4...v2.0.0-alpha.5) (2026-08-15)


### ⚠ BREAKING CHANGES

* **identity:** file contract kinds under a derived apiVersion segment ([#46](https://github.com/open-platform-model/core/issues/46))

### Features

* **identity:** file contract kinds under a derived apiVersion segment ([#46](https://github.com/open-platform-model/core/issues/46)) ([786284b](https://github.com/open-platform-model/core/commit/786284b8ecf36ab4428f5b1b97bff1517feda020))

## [2.0.0-alpha.4](https://github.com/open-platform-model/core/compare/v2.0.0-alpha.3...v2.0.0-alpha.4) (2026-08-09)


### Features

* ship the identity-package and catalog-member publish gates ([#38](https://github.com/open-platform-model/core/issues/38)) ([4b96f49](https://github.com/open-platform-model/core/commit/4b96f49e92aa6b5f3b9fa096058b27c6b6adc5aa))

## [2.0.0-alpha.3](https://github.com/open-platform-model/core/compare/v2.0.0-alpha.2...v2.0.0-alpha.3) (2026-08-07)


### ⚠ BREAKING CHANGES

* scalar subscription version, derived matchLabels, contract fulfilment ([#36](https://github.com/open-platform-model/core/issues/36))
* scalar subscription version, derived matchLabels, contract fulfilment ([#33](https://github.com/open-platform-model/core/issues/33))

### Features

* scalar subscription version, derived matchLabels, contract fulfilment ([#33](https://github.com/open-platform-model/core/issues/33)) ([0070d41](https://github.com/open-platform-model/core/commit/0070d411b9230a539a204b67abfa9e353b5c867e))
* scalar subscription version, derived matchLabels, contract fulfilment ([#36](https://github.com/open-platform-model/core/issues/36)) ([c51f833](https://github.com/open-platform-model/core/commit/c51f833f2356faae1122866f6d3ea23afb9ffdff))

## [2.0.0-alpha.2](https://github.com/open-platform-model/core/compare/v2.0.0-alpha.1...v2.0.0-alpha.2) (2026-08-07)


### ⚠ BREAKING CHANGES

* every catalog member renames version to catalogVersion, every primitive adds apiVersion, and every fqn becomes authored. Re-keying the catalogs is catalogs-identity-authoring.

### Features

* split contract keys from implementation keys on catalog members ([#30](https://github.com/open-platform-model/core/issues/30)) ([3ba2fdb](https://github.com/open-platform-model/core/commit/3ba2fdbe5aadc1f41316bcf08ce808dbfeeef80a))

## [2.0.0-alpha.1](https://github.com/open-platform-model/core/compare/v1.1.0-alpha.1...v2.0.0-alpha.1) (2026-08-07)


### ⚠ BREAKING CHANGES

* the module path moves from `opmodel.dev/core@v1` to `opmodel.dev/core@v2`. Every consumer rewrites its `import` statements as well as its `cue.mod` dependency — `library`, `cli`, `opm-operator`, `catalog_opm`, `catalog_kubernetes`, `catalog_opm_experimental`, `modules` and `releases`.
* **schema:** #ModuleRelease->#ModuleInstance, #ModuleReleaseMap-> #ModuleInstanceMap, #ReleaseIdentity->#InstanceIdentity, #ctx.release-> #ctx.instance, #Component.#release->#instance, transformer #moduleRelease*-> #moduleInstance*; wire kind "ModuleRelease"->"ModuleInstance"; label domain module-release.opmodel.dev/*->module-instance.opmodel.dev/*. The CUE module advances opmodel.dev/core@v0->@v1 (every downstream import re-pins to @v1) and ships on the v1.0.0-alpha.N prerelease line.

### Features

* move the CUE module to opmodel.dev/core@v2 ([#27](https://github.com/open-platform-model/core/issues/27)) ([de60225](https://github.com/open-platform-model/core/commit/de6022534beb575f4274a5372a55e20fbca12fc0))
* **schema:** rename #ModuleRelease family to #ModuleInstance ([#17](https://github.com/open-platform-model/core/issues/17)) ([a03a88b](https://github.com/open-platform-model/core/commit/a03a88badfd882dcfb8216f1c4c9f4073aa522bd))


### Bug Fixes

* allow snake_case catalog module paths; stop injecting stale opm-secrets ([#24](https://github.com/open-platform-model/core/issues/24)) ([7500c5d](https://github.com/open-platform-model/core/commit/7500c5d9ce779a57ccd60fd0feedc39fd7319712))
* **cue:** pin language version to v0.17.0-alpha.1 ([#20](https://github.com/open-platform-model/core/issues/20)) ([40daf05](https://github.com/open-platform-model/core/commit/40daf05eb3aee238c4eda7c42caeaca54f52b441))

## [1.0.0-alpha.3](https://github.com/open-platform-model/core/compare/v1.0.0-alpha.2...v1.0.0-alpha.3) (2026-07-27)


### Bug Fixes

* allow snake_case catalog module paths; stop injecting stale opm-secrets ([#24](https://github.com/open-platform-model/core/issues/24)) ([7500c5d](https://github.com/open-platform-model/core/commit/7500c5d9ce779a57ccd60fd0feedc39fd7319712))

## [1.0.0-alpha.2](https://github.com/open-platform-model/core/compare/v1.0.0-alpha.1...v1.0.0-alpha.2) (2026-06-27)


### Bug Fixes

* **cue:** pin language version to v0.17.0-alpha.1 ([#20](https://github.com/open-platform-model/core/issues/20)) ([40daf05](https://github.com/open-platform-model/core/commit/40daf05eb3aee238c4eda7c42caeaca54f52b441))

## [1.0.0-alpha.1](https://github.com/open-platform-model/core/compare/v1.0.0-alpha.0...v1.0.0-alpha.1) (2026-06-26)


### ⚠ BREAKING CHANGES

* **schema:** #ModuleRelease->#ModuleInstance, #ModuleReleaseMap-> #ModuleInstanceMap, #ReleaseIdentity->#InstanceIdentity, #ctx.release-> #ctx.instance, #Component.#release->#instance, transformer #moduleRelease*-> #moduleInstance*; wire kind "ModuleRelease"->"ModuleInstance"; label domain module-release.opmodel.dev/*->module-instance.opmodel.dev/*. The CUE module advances `opmodel.dev/core@v0` -> `@v1` (every downstream import re-pins to the new major) and ships on the `v1.0.0-alpha.N` prerelease line.

### Features

* **schema:** rename #ModuleRelease family to #ModuleInstance ([#17](https://github.com/open-platform-model/core/issues/17)) ([a03a88b](https://github.com/open-platform-model/core/commit/a03a88badfd882dcfb8216f1c4c9f4073aa522bd))

## [0.6.0](https://github.com/open-platform-model/core/compare/v0.5.0...v0.6.0) (2026-06-17)


### Features

* **module:** add derived nameSnakeCase to #Module.metadata ([#15](https://github.com/open-platform-model/core/issues/15)) ([92bdaf0](https://github.com/open-platform-model/core/commit/92bdaf0acbafd57999b02cd274bdd40ed5c96cac))

## [0.5.0](https://github.com/open-platform-model/core/compare/v0.4.0...v0.5.0) (2026-06-16)


### Features

* **module:** make #Module identity author-supplied (fix self-cycle re-admission) ([#13](https://github.com/open-platform-model/core/issues/13)) ([68e4520](https://github.com/open-platform-model/core/commit/68e4520a05f43c28b82f0584dd1a25d75501af81))

## [0.4.0](https://github.com/open-platform-model/core/compare/v0.3.0...v0.4.0) (2026-05-31)


### Features

* **cue:** require CUE language version v0.17 ([#11](https://github.com/open-platform-model/core/issues/11)) ([d8c7411](https://github.com/open-platform-model/core/commit/d8c7411e1dc62e358b7b9b459f29f3d881b9db19))

## [0.3.0](https://github.com/open-platform-model/core/compare/v0.2.1...v0.3.0) (2026-05-25)


### ⚠ BREAKING CHANGES

* every existing #Module that uses #defines MUST be rewritten as a #Catalog. #Component values that set #release directly fail unification.
* every existing #Platform value MUST be rewritten. The #registry key changes from #NameType (author-chosen Id) to #ModulePathType (catalog package path). #ModuleRegistration is removed. Embedded #Module values move out of the platform spec and into the catalog artifact the platform subscribes to.
* every primitive FQN string changes shape from path/name@vN to path/name@N.N.N. Catalogs publishing primitives MUST stamp SemVer onto metadata.version; consumers pinning FQNs MUST update their references.

### Features

* add #Catalog and module-context types (enhancement 0001 D19/D25/D1) ([bf98af3](https://github.com/open-platform-model/core/commit/bf98af3e5c3472f983af606a84f8ecd22ae5977f))
* add inline #ctx and component #names (enhancement 0001 D1/D2/D3) ([15db9a8](https://github.com/open-platform-model/core/commit/15db9a8ff2f3dad5a421b5165172442fc453b171))
* lift primitive FQNs to SemVer (enhancement 0001 D5) ([45db25e](https://github.com/open-platform-model/core/commit/45db25e8bce2c01bb7f33751f40e7b6ab0ae3e5c))
* reshape #Platform to subscription registry (enhancement 0001 D13/D14) ([6e5c2fd](https://github.com/open-platform-model/core/commit/6e5c2fddf085985f2f1516ed72a18fdd5e11c6a4))
* wire release identity into #Module.#ctx (enhancement 0001 D4) ([75a5d43](https://github.com/open-platform-model/core/commit/75a5d43eb70218b1a26b079a798ff590e2abace8))

## [0.2.1](https://github.com/open-platform-model/core/compare/v0.2.0...v0.2.1) (2026-05-23)


### Code Refactoring

* nest CUE module under src/ ([3d000aa](https://github.com/open-platform-model/core/commit/3d000aaf872165cb8febbe48f4031764c378a0d7))

## [0.2.0](https://github.com/open-platform-model/core/compare/v0.1.3...v0.2.0) (2026-05-23)


### Features

* **spec:** introduce SPEC.md and drift-detection gates ([7013e2b](https://github.com/open-platform-model/core/commit/7013e2b0914704eb6270784f27940903682fecc8))

## [0.1.3](https://github.com/open-platform-model/core/compare/v0.1.2...v0.1.3) (2026-05-23)


### Miscellaneous

* release 0.1.3 ([34b51c6](https://github.com/open-platform-model/core/commit/34b51c62a861b69b819d80ac9cf1eb31180089e1))

## [0.1.2](https://github.com/open-platform-model/core/compare/v0.1.1...v0.1.2) (2026-05-23)


### Miscellaneous

* release 0.1.2 ([b4ec0ec](https://github.com/open-platform-model/core/commit/b4ec0ec6b4aa1628b20c2c5dec98729ecd64c35d))

## [0.1.1](https://github.com/open-platform-model/core/compare/v0.1.0...v0.1.1) (2026-05-22)


### Miscellaneous

* release 0.1.1 ([93cf773](https://github.com/open-platform-model/core/commit/93cf773623f5c5c74e859328f2d5f6cfcffb189b))

## 0.1.0 (2026-05-22)


### Features

* restructure core as a flat v0 schema package ([c4c28f9](https://github.com/open-platform-model/core/commit/c4c28f924ff8a0b9769268ff850e4c8c1aa6983f))
* scaffold opmodel.dev/core schema repository ([427ea07](https://github.com/open-platform-model/core/commit/427ea07075c5f5d58df6b72722d22026c7911acb))


### Miscellaneous

* release initial version as 0.1.0 ([2700d16](https://github.com/open-platform-model/core/commit/2700d166c49475740717d39c873e91b5f6654abe))
