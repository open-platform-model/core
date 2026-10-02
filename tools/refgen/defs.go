package main

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"cuelang.org/go/cue/ast"
	"cuelang.org/go/cue/parser"
)

// def is one exported top-level definition of the core package.
type def struct {
	name  string
	file  string     // file name under src/
	field *ast.Field // as parsed; never mutated
	doc   []string   // raw "//" lines of its doc comment
	refs  []string   // top-level definitions its value names, sorted
}

// loadDefs parses every schema file under src (fixture files, *_pins.cue,
// excluded: their fields are hidden test cases) and returns the exported
// top-level definitions by name.
func loadDefs(src string) (map[string]*def, error) {
	files, err := filepath.Glob(filepath.Join(src, "*.cue"))
	if err != nil {
		return nil, err
	}
	sort.Strings(files)
	defs := map[string]*def{}
	for _, path := range files {
		if strings.HasSuffix(path, "_pins.cue") {
			continue
		}
		f, err := parseFile(path)
		if err != nil {
			return nil, err
		}
		for _, d := range f.Decls {
			fld, ok := d.(*ast.Field)
			if !ok {
				continue
			}
			name, _, err := ast.LabelName(fld.Label)
			if err != nil || !strings.HasPrefix(name, "#") {
				continue
			}
			if prev, dup := defs[name]; dup {
				return nil, fmt.Errorf("%s declared in both %s and %s", name, prev.file, filepath.Base(path))
			}
			defs[name] = &def{name: name, file: filepath.Base(path), field: fld, doc: docLines(fld)}
		}
	}
	for _, d := range defs {
		seen := map[string]bool{}
		ast.Walk(d.field.Value, func(n ast.Node) bool {
			if id, ok := n.(*ast.Ident); ok {
				if _, top := defs[id.Name]; top && id.Name != d.name {
					seen[id.Name] = true
				}
			}
			return true
		}, nil)
		d.refs = sortedKeys(seen)
	}
	return defs, nil
}

func parseFile(path string) (*ast.File, error) {
	b, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	return parser.ParseFile(path, b, parser.ParseComments)
}

// docLines returns the raw lines of a node's doc comment: the comment group
// that ends on the line directly above it.
func docLines(n ast.Node) []string {
	var out []string
	for _, cg := range ast.Comments(n) {
		if !cg.Doc {
			continue
		}
		for _, c := range cg.List {
			out = append(out, c.Text)
		}
	}
	return out
}

func sortedKeys(m map[string]bool) []string {
	out := make([]string, 0, len(m))
	for k := range m {
		out = append(out, k)
	}
	sort.Strings(out)
	return out
}

// catalog ties the definitions to the pages that show them.
type catalog struct {
	defs   map[string]*def
	pageOf map[string]*page
	usedBy map[string][]string
}

// newCatalog checks the inclusion list against the source: every exported
// definition is either on a page or excluded, never both, and every listed
// name exists and, when included, carries a doc comment.
func newCatalog(defs map[string]*def) (*catalog, error) {
	c := &catalog{defs: defs, pageOf: map[string]*page{}, usedBy: map[string][]string{}}
	var problems []string
	for i := range pages {
		p := &pages[i]
		for _, n := range p.defs {
			d, ok := defs[n]
			switch {
			case !ok:
				problems = append(problems, fmt.Sprintf("%s is listed on page %q but not defined in src/", n, p.file))
			case c.pageOf[n] != nil:
				problems = append(problems, fmt.Sprintf("%s is listed on two pages", n))
			case excluded[n] != "":
				problems = append(problems, fmt.Sprintf("%s is both listed and excluded", n))
			case len(d.doc) == 0:
				problems = append(problems, fmt.Sprintf("%s (src/%s) has no doc comment; the reference needs one for its summary", n, d.file))
			}
			c.pageOf[n] = p
		}
	}
	for _, n := range sortedKeys(boolSet(excluded)) {
		if _, ok := defs[n]; !ok {
			problems = append(problems, fmt.Sprintf("%s is excluded but not defined in src/", n))
		}
	}
	names := make([]string, 0, len(defs))
	for n := range defs {
		names = append(names, n)
	}
	sort.Strings(names)
	for _, n := range names {
		if c.pageOf[n] == nil && excluded[n] == "" {
			problems = append(problems, fmt.Sprintf("%s (src/%s) is neither on a page nor excluded; add it to tools/refgen/groups.go", n, defs[n].file))
		}
	}
	if len(problems) > 0 {
		return nil, fmt.Errorf("inclusion list out of step with src/:\n  %s", strings.Join(problems, "\n  "))
	}
	for _, n := range names {
		if c.pageOf[n] == nil {
			continue
		}
		for _, u := range c.uses(n) {
			c.usedBy[u] = append(c.usedBy[u], n)
		}
	}
	return c, nil
}

func boolSet(m map[string]string) map[string]bool {
	out := map[string]bool{}
	for k := range m {
		out[k] = true
	}
	return out
}

// uses returns the included definitions a definition names, following a
// reference to an excluded one through to what that one names.
func (c *catalog) uses(name string) []string {
	out := map[string]bool{}
	seen := map[string]bool{name: true}
	var walk func(string)
	walk = func(n string) {
		for _, r := range c.defs[n].refs {
			if seen[r] {
				continue
			}
			seen[r] = true
			if c.pageOf[r] != nil {
				out[r] = true
			} else {
				walk(r)
			}
		}
	}
	walk(name)
	return sortedKeys(out)
}

// link returns the root-absolute URL of an included definition's entry, or
// "" when the reference names none.
func (c *catalog) link(name string) string {
	p := c.pageOf[name]
	if p == nil {
		return ""
	}
	return sitePath + p.file + "/#" + anchor(name)
}

// anchor is the heading ID Hugo gives "## #Name": lower case, "#" dropped.
func anchor(name string) string {
	return strings.ToLower(strings.TrimPrefix(name, "#"))
}
