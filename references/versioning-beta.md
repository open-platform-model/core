# Versioning: the beta line

Covers the prerelease policy of the `@v2` line: what a break costs, how release-please is configured,
how GA and a major change are forced, and what never to edit by hand.

## The line

The CUE module is on major `@v2` and ships `v2.0.0-beta.N` prereleases (enhancement 0010). The
identity reshape moved the schema off the `@v1` line, which lives on as the protected `v1` maintenance
branch, stable at `v1.1.0`. From its first beta the line is on the path to GA.

## Breaking changes

A breaking change is allowed during beta, but only as a `feat!` commit whose `BREAKING CHANGE:` footer
is the migration note the CHANGELOG shows. It advances the `-beta.N` counter and never moves the
module path to a new major. Stable lines (`opmodel.dev/catalogs/opm@v4` and the module fleets) keep
the normal SemVer rule: a break is a new major. A core beta break that would force a `catalogs/opm`
major needs owner sign-off.

## release-please

release-please runs in prerelease mode in `release-please-config.json`: `prerelease: true`,
`prerelease-type: "beta"`, `bump-minor-pre-major: false`. While the line is a prerelease, `feat:` and
`fix:` also advance `-beta.N`; the minor and patch bumps in the commit-types table apply from GA.

Never add a `release-as` key to `release-please-config.json`, and never hand-edit
`.release-please-manifest.json`. Both would bypass the release PR that carries the changelog.

## Forcing a version

- Changing the prerelease type: put `Release-As: X.0.0-<type>.1` in the final commit message on `main`.
  Flipping `prerelease-type` alone cuts nothing.
- GA drops the suffix: set `prerelease: false` and add a visible carrier commit (a releasable type, or
  a `Release-As: X.0.0` footer). Core's GA carrier comes first in the cross-repo dependency order,
  because every other prerelease line builds on it.
- A major change is possible only after GA. During beta the line never crosses a major. After GA,
  crossing a major edits the `module:` line in `src/cue.mod/module.cue` and forces the version with a
  `Release-As:` footer in the same commit. The two must land together, or `cue mod publish` rejects
  the tag as not matching the declared major.

## Pitfalls

- Typing a break as `feat:` or `fix:`: it is refused. Use `feat!:` with the footer.
- Flipping `prerelease-type` alone: nothing is released. Add the `Release-As:` footer.

## Check before you finish

- [ ] The break carries a `BREAKING CHANGE:` footer that reads as a migration note.
- [ ] `release-please-config.json` has no `release-as` key and the manifest is untouched.
