package main

import (
	"fmt"
	"path/filepath"
	"strconv"
	"strings"

	"cuelang.org/go/cue/ast"
	"cuelang.org/go/cue/format"
	"cuelang.org/go/cue/token"
)

// commentWidth is where a doc comment the cleaning rules changed is
// re-wrapped in the spec block.
const commentWidth = 76

// elideLines is the size above which a derived struct value is shown as its
// type alone: a comprehension that long is how the value is computed, not
// what a reader writes against.
const elideLines = 40

// specSource returns the definition as CUE for the Spec part: the source as
// written, formatted, with every comment but doc and same-line comments
// dropped and those cleaned of contributor-only references. The definition's
// own doc comment is the entry's summary and notes, so it is not repeated.
func specSource(src string, d *def) (string, error) {
	f, err := parseFile(filepath.Join(src, d.file))
	if err != nil {
		return "", err
	}
	var fld *ast.Field
	for _, decl := range f.Decls {
		if x, ok := decl.(*ast.Field); ok {
			if n, _, _ := ast.LabelName(x.Label); n == d.name {
				fld = x
			}
		}
	}
	if fld == nil {
		return "", fmt.Errorf("%s vanished from src/%s", d.name, d.file)
	}
	ast.SetComments(fld, nil)
	if err := elide(fld); err != nil {
		return "", err
	}
	dropHidden(fld.Value)
	ast.Walk(fld.Value, func(n ast.Node) bool {
		if _, ok := n.(*ast.CommentGroup); ok {
			return false
		}
		filterComments(n)
		return true
	}, nil)
	sections(fld.Value)
	b, err := format.Node(fld, format.UseSpaces(4), format.TabIndent(false))
	if err != nil {
		return "", err
	}
	return strings.TrimRight(string(b), "\n"), nil
}

// dropHidden removes hidden (`_`) fields, with their comments, and the
// comprehensions that only set them: they are the schema's internal
// machinery, not fields an author writes or reads. The rules they assert
// still reach the Enforcement part, which reads the unmodified source.
func dropHidden(n ast.Node) {
	ast.Walk(n, func(n ast.Node) bool {
		st, ok := n.(*ast.StructLit)
		if !ok {
			return true
		}
		kept := st.Elts[:0]
		for _, e := range st.Elts {
			if !onlyHidden(e) {
				kept = append(kept, e)
			}
		}
		st.Elts = kept
		return true
	}, nil)
}

// onlyHidden reports a hidden field, or a comprehension whose body declares
// nothing but hidden fields.
func onlyHidden(e ast.Decl) bool {
	switch e := e.(type) {
	case *ast.Field:
		name, ok := plainLabel(e.Label)
		return ok && strings.HasPrefix(name, "_")
	case *ast.Comprehension:
		body, ok := e.Value.(*ast.StructLit)
		if !ok || len(body.Elts) == 0 {
			return false
		}
		for _, x := range body.Elts {
			if !onlyHidden(x) {
				return false
			}
		}
		return true
	}
	return false
}

// filterComments keeps a node's doc and same-line comments, cleaned, and
// drops every other group: rationale blocks and notes separated from the
// field by a blank line.
func filterComments(n ast.Node) {
	cgs := ast.Comments(n)
	if len(cgs) == 0 {
		return
	}
	var kept []*ast.CommentGroup
	for _, cg := range cgs {
		if !cg.Doc && !cg.Line {
			continue
		}
		raw := make([]string, 0, len(cg.List))
		for _, c := range cg.List {
			raw = append(raw, c.Text)
		}
		width := commentWidth
		if cg.Line {
			width = 1 << 20
		}
		lines := cleanComment(raw, width)
		if len(lines) == 0 {
			continue
		}
		list := make([]*ast.Comment, len(lines))
		for i, l := range lines {
			if l == "" {
				list[i] = &ast.Comment{Text: "//"}
			} else {
				list[i] = &ast.Comment{Text: "// " + l}
			}
		}
		kept = append(kept, &ast.CommentGroup{Doc: cg.Doc, Line: cg.Line, Position: cg.Position, List: list})
	}
	ast.SetComments(n, kept)
}

// sections restores the layout the dropped comment groups held: a field
// with a doc comment starts a new section (a blank line before it), and the
// first element of a struct follows its brace directly.
func sections(n ast.Node) {
	ast.Walk(n, func(n ast.Node) bool {
		st, ok := n.(*ast.StructLit)
		if !ok {
			return true
		}
		for i, e := range st.Elts {
			rel := token.NewSection
			if i == 0 {
				rel = token.Newline
				if e.Pos().RelPos() == token.NewSection {
					ast.SetRelPos(e, rel)
				}
			}
			for _, cg := range ast.Comments(e) {
				if cg.Doc {
					cg.List[0].Slash = cg.List[0].Slash.WithRel(rel)
				}
			}
		}
		return true
	}, nil)
}

// elide replaces a long derived value "T & {...comprehensions...}" by T and
// says so in the field's doc comment.
func elide(top *ast.Field) error {
	var err error
	ast.Walk(top.Value, func(n ast.Node) bool {
		f, ok := n.(*ast.Field)
		if !ok || err != nil {
			return err == nil
		}
		be, ok := f.Value.(*ast.BinaryExpr)
		if !ok || be.Op != token.AND {
			return true
		}
		st, ok := be.Y.(*ast.StructLit)
		if !ok || !hasComprehension(st) {
			return true
		}
		b, ferr := format.Node(st)
		if ferr != nil {
			err = ferr
			return false
		}
		if strings.Count(string(b), "\n") < elideLines {
			return true
		}
		f.Value = be.X
		note := &ast.Comment{Text: "// Derived in the source; the derivation is not shown here."}
		for _, cg := range ast.Comments(f) {
			if cg.Doc {
				cg.List = append(cg.List, &ast.Comment{Text: "//"}, note)
				return false
			}
		}
		ast.AddComment(f, &ast.CommentGroup{Doc: true, List: []*ast.Comment{note}})
		return false
	}, nil)
	return err
}

// isStructValue reports a struct literal, alone or as one conjunct.
func isStructValue(e ast.Expr) bool {
	for _, c := range conjuncts(e) {
		if _, ok := c.(*ast.StructLit); ok {
			return true
		}
	}
	return false
}

func hasComprehension(n ast.Node) bool {
	found := false
	ast.Walk(n, func(n ast.Node) bool {
		if _, ok := n.(*ast.Comprehension); ok {
			found = true
		}
		return !found
	}, nil)
	return found
}

// glance holds the facts the At a glance part states, all read off the
// definition's shape in source.
type glance struct {
	shape  string   // "struct, closed", "string constraint", ...
	kind   string   // the value of its `kind` field, quoted, or ""
	embeds []string // definitions embedded at the top level
}

func atAGlance(d *def) glance {
	var g glance
	switch v := d.field.Value.(type) {
	case *ast.StructLit:
		g.shape = structShape(v)
		for _, e := range v.Elts {
			switch e := e.(type) {
			case *ast.Field:
				if n, _, _ := ast.LabelName(e.Label); n == "kind" {
					if bl, ok := e.Value.(*ast.BasicLit); ok && bl.Kind == token.STRING {
						g.kind = bl.Value
					}
				}
			case *ast.EmbedDecl:
				if id, ok := e.Expr.(*ast.Ident); ok {
					g.embeds = append(g.embeds, id.Name)
				}
			}
		}
	case *ast.BinaryExpr:
		switch {
		case v.Op == token.OR:
			g.shape = "disjunction"
		case isStringConstraint(v):
			g.shape = "string constraint"
		default:
			g.shape = "unification"
		}
	default:
		g.shape = "value"
	}
	return g
}

func structShape(s *ast.StructLit) string {
	fields, patterns := 0, 0
	for _, e := range s.Elts {
		switch e := e.(type) {
		case *ast.Ellipsis:
			return "struct, open"
		case *ast.Field:
			if _, ok := e.Label.(*ast.ListLit); ok {
				patterns++
			} else {
				fields++
			}
		}
	}
	if fields == 0 && patterns > 0 {
		return "map"
	}
	return "struct, closed"
}

// conjuncts flattens an "a & b & c" chain.
func conjuncts(e ast.Expr) []ast.Expr {
	if be, ok := e.(*ast.BinaryExpr); ok && be.Op == token.AND {
		return append(conjuncts(be.X), conjuncts(be.Y)...)
	}
	if pe, ok := e.(*ast.ParenExpr); ok {
		return conjuncts(pe.X)
	}
	return []ast.Expr{e}
}

func isStringConstraint(e ast.Expr) bool {
	for _, c := range conjuncts(e) {
		if id, ok := c.(*ast.Ident); ok && id.Name == "string" {
			return true
		}
	}
	return false
}

// rule is one constraint the Enforcement part states. CUE enforces every one
// of them: each is read off a constraint written in the schema. code, when
// set, is shown in a text block under the rule (a regular expression would
// read as a Markdown link inside inline code).
type rule struct {
	text string
	code string
}

func enforcement(d *def) []rule {
	var rules []rule
	switch v := d.field.Value.(type) {
	case *ast.StructLit:
		if structShape(v) == "struct, closed" {
			rules = append(rules, rule{text: "A field the definition does not declare is refused: the definition is closed."})
		}
		var req []string
		requiredFields(v, "", "", &req)
		if len(req) > 0 {
			rules = append(rules, rule{text: "A value is incomplete until each required field (`!`) is set, and CUE names the missing one when it needs a complete value: " + strings.Join(req, ", ") + "."})
		}
		rules = append(rules, assertions(v, "")...)
	case *ast.BinaryExpr:
		if isStringConstraint(v) {
			rules = append(rules, stringRules(v)...)
		}
	}
	return rules
}

// requiredFields collects the paths of fields marked `!`, descending into
// plain struct values and into the bodies of `if` clauses.
func requiredFields(s *ast.StructLit, prefix, cond string, out *[]string) {
	for _, e := range s.Elts {
		switch e := e.(type) {
		case *ast.Field:
			name, ok := plainLabel(e.Label)
			if !ok {
				continue
			}
			if e.Constraint == token.NOT {
				entry := "`" + prefix + name + "`"
				if cond != "" {
					entry += " when `" + cond + "`"
				}
				*out = append(*out, entry)
			}
			if inner, ok := e.Value.(*ast.StructLit); ok {
				requiredFields(inner, prefix+name+".", cond, out)
			}
		case *ast.Comprehension:
			if len(e.Clauses) != 1 {
				continue
			}
			ic, ok := e.Clauses[0].(*ast.IfClause)
			if !ok {
				continue
			}
			if body, ok := e.Value.(*ast.StructLit); ok {
				requiredFields(body, prefix, exprString(ic.Condition), out)
			}
		}
	}
}

// plainLabel returns a field's name, unwrapping a label alias (M=metadata),
// and reports false for a pattern constraint.
func plainLabel(l ast.Label) (string, bool) {
	if a, ok := l.(*ast.Alias); ok {
		if lbl, ok := a.Expr.(ast.Label); ok {
			l = lbl
		}
	}
	if _, ok := l.(*ast.ListLit); ok {
		return "", false
	}
	name, _, err := ast.LabelName(l)
	if err != nil {
		return "", false
	}
	return name, true
}

// assertions finds a field declared more than once in one struct: the
// declarations must unify, which is how the schema states a check. The
// common form pins a hidden field to true beside the expression it tests.
func assertions(s *ast.StructLit, prefix string) []rule {
	byName := map[string][]ast.Expr{}
	var order []string
	for _, e := range s.Elts {
		f, ok := e.(*ast.Field)
		if !ok {
			continue
		}
		name, ok := plainLabel(f.Label)
		if !ok {
			continue
		}
		if _, seen := byName[name]; !seen {
			order = append(order, name)
		}
		byName[name] = append(byName[name], f.Value)
	}
	var rules []rule
	for _, name := range order {
		vals := byName[name]
		if len(vals) == 1 {
			if inner, ok := vals[0].(*ast.StructLit); ok {
				rules = append(rules, assertions(inner, prefix+name+".")...)
			}
			continue
		}
		var exprs []string
		pinnedTrue, composed := false, false
		for _, v := range vals {
			switch {
			case exprString(v) == "true":
				pinnedTrue = true
				continue
			case isStructValue(v):
				composed = true
			}
			exprs = append(exprs, "`"+exprString(v)+"`")
		}
		if composed {
			// A struct written beside a type composes the value; it states
			// no check.
			continue
		}
		path := "`" + prefix + name + "`"
		switch {
		case pinnedTrue && len(exprs) > 0:
			rules = append(rules, rule{text: strings.Join(exprs, " and ") + " must hold (" + path + ")."})
		case len(exprs) > 1:
			rules = append(rules, rule{text: path + " must satisfy both " + strings.Join(exprs, " and ") + "."})
		}
	}
	return rules
}

// stringRules states a string constraint's pattern and length bounds.
func stringRules(e ast.Expr) []rule {
	var rules []rule
	minR, maxR := "", ""
	for _, c := range conjuncts(e) {
		switch c := c.(type) {
		case *ast.UnaryExpr:
			if c.Op == token.MAT {
				if bl, ok := c.X.(*ast.BasicLit); ok {
					if p, err := strconv.Unquote(bl.Value); err == nil {
						rules = append(rules, rule{text: "The string must match this regular expression:", code: p})
					}
				}
			}
		case *ast.CallExpr:
			if sel, ok := c.Fun.(*ast.SelectorExpr); ok && len(c.Args) == 1 {
				if bl, ok := c.Args[0].(*ast.BasicLit); ok {
					switch exprString(sel) {
					case "strings.MinRunes":
						minR = bl.Value
					case "strings.MaxRunes":
						maxR = bl.Value
					}
				}
			}
		}
	}
	switch {
	case minR != "" && maxR != "":
		rules = append(rules, rule{text: "The string must be " + minR + " to " + maxR + " runes long."})
	case minR != "":
		rules = append(rules, rule{text: "The string must be at least " + minR + " runes long."})
	case maxR != "":
		rules = append(rules, rule{text: "The string must be at most " + maxR + " runes long."})
	}
	return rules
}

// exprString formats an expression on one line.
func exprString(e ast.Node) string {
	b, err := format.Node(e)
	if err != nil {
		return "?"
	}
	s := strings.Join(strings.Fields(string(b)), " ")
	return strings.NewReplacer("[ ", "[", ", ]", "]").Replace(s)
}
