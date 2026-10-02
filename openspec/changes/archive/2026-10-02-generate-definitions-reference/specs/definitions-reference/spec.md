## ADDED Requirements

### Requirement: Every public definition has one generated entry

`task docs:reference` SHALL write `docs/site/reference/definitions/` from `src/*.cue`: a section page `_index.md` that lists every page and every included definition, and one `type: reference` page per group in `tools/refgen/groups.go`. Every exported top-level definition in a non-fixture file of `src/` MUST be either on exactly one page or excluded with a reason; the generator SHALL refuse to run, naming the definition, when one is in neither, when a listed name is not defined, or when an included definition has no doc comment.

#### Scenario: A new definition is classified

- **WHEN** a contributor adds `#Foo` to `src/types.cue` and lists it on a page
- **THEN** `task docs:reference` writes an entry for `#Foo` on that page and a row for it in `_index.md`

#### Scenario: A new definition is left out

- **WHEN** a contributor adds `#Foo` to `src/types.cue` and neither lists nor excludes it
- **THEN** `task docs:reference` fails naming `#Foo` and `tools/refgen/groups.go`, and writes nothing

#### Scenario: A fixture definition is never a candidate

- **WHEN** a `*_pins.cue` file declares a definition
- **THEN** the generator neither lists nor requires it

### Requirement: An entry states only what its source proves

Each entry SHALL follow one order, omitting a part with nothing derivable: summary, at a glance, spec, example, notes, enforcement. The summary SHALL be the first sentence of the definition's doc comment; the spec SHALL be the definition as written in a `cue` code fence; every rule under enforcement SHALL be read off a constraint in the source and tagged as enforced by CUE. The generator SHALL NOT evaluate the schema and SHALL NOT write a part, such as "served by", that the source cannot prove.

#### Scenario: A required field is stated

- **WHEN** a definition declares `name!: #NameType`
- **THEN** its enforcement part lists `name` among the required fields

#### Scenario: Nothing derivable is omitted

- **WHEN** a definition's doc comment has no `Example:` or `Usage:` segment
- **THEN** its entry has no example part

### Requirement: Contributor-only text never reaches a page

The generator SHALL drop every comment group that is not a doc comment or a same-line comment, and every group whose first line opens with `WHY`, and SHALL strip enhancement decision citations, `SPEC.md` section pointers and experiment references from the text it keeps. The spec part SHALL leave out hidden (`_`) fields, with their comments, and comprehensions that set only hidden fields; a rule such a field asserts SHALL still appear under enforcement.

#### Scenario: A citation is stripped

- **WHEN** a field's same-line comment reads `(kind prefix + this resource's own apiVersion, 0010:D49)`
- **THEN** the page shows `(kind prefix + this resource's own apiVersion)`

#### Scenario: Hidden machinery stays off the page

- **WHEN** a definition declares `_leaf: strings.HasSuffix(_ref.registryPath, "/"+name)` and `_leaf: true`
- **THEN** its spec part shows no `_leaf` field, and its enforcement part states that the expression must hold

#### Scenario: A rationale block is dropped

- **WHEN** a field carries a `// WHY` block separated from its doc comment by a blank line
- **THEN** no line of that block appears on any page

### Requirement: The committed reference is never stale

`task docs:reference:check` SHALL write nothing and SHALL fail when any committed page differs from what the generator would write, or when the directory holds a file the generator does not write. `task check` and CI SHALL run it. Text an author writes outside the generated markers SHALL survive regeneration.

#### Scenario: A doc comment changes without regeneration

- **WHEN** a contributor edits a doc comment in `src/` and does not run `task docs:reference`
- **THEN** `task docs:reference:check` fails naming the stale page

#### Scenario: Authored text is kept

- **WHEN** a page holds a paragraph after `<!-- end generated -->`
- **THEN** `task docs:reference` keeps that paragraph unchanged

### Requirement: Pages follow the site page dialect

Every generated page SHALL use only the front-matter keys `title`, `description`, `type` (leaf pages only) and `weight`; tag every code fence; link between entries root-absolute with a trailing slash; and hold no raw HTML, image or shortcode delimiter.

#### Scenario: The site lint accepts the pages

- **WHEN** opmodel.dev's `lint-sources.sh` runs over `docs/site`
- **THEN** it reports no violation in `docs/site/reference/definitions/`
