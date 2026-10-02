package main

import (
	"regexp"
	"strings"
	"unicode"
	"unicode/utf8"
)

// Doc comments in src/ carry lines for contributors that a reader of the
// site cannot resolve: enhancement decision citations (0010:D37), SPEC.md
// section pointers and experiment paths. Rationale lives in separate "// WHY"
// blocks, which never reach the generator: they are not doc comments. The
// rules below remove what is left, deterministically.

const cite = `\d{4}:(?:D|OQ)\d+(?::R\d+(?:/R\d+)*)?(?:/(?:D|OQ)?\d+(?::R\d+(?:/R\d+)*)?)*`

var (
	citeList = cite + `(?:\s*[,;]\s*(?:` + cite + `|D\d+))*`
	// A parenthetical that holds nothing but a citation, with an optional
	// lead-in word.
	reCiteParen = regexp.MustCompile(`\s*\((?:(?:see|per|enhancement)\s+)?` + citeList + `\)`)
	// A citation inside running text, with the comma or lead-in before it.
	reCiteInline = regexp.MustCompile(`(?:[,;]\s*)?(?:(?:per|enhancement)\s+)?` + citeList)
	// "See SPEC.md § 3.2." as a sentence, and "SPEC.md § 2.2" inside one.
	reSpecSentence = regexp.MustCompile(`\s*See SPEC\.md\s*§\s*\d+(?:\.\d+)*\.?`)
	reSpecInline   = regexp.MustCompile(`\s*(?:and\s+)?SPEC\.md\s*§\s*\d+(?:\.\d+)*`)
	// Experiment references.
	reExperiment = regexp.MustCompile(`\s*\(?(?:enhancement\s+)?\d{4}\s+experiment\s+\d+\)?|\s*enhancements/\d{4}/experiments/\S+`)
	// Clean-up after a removal.
	reEmptyParen  = regexp.MustCompile(`\(\s*[,;]?\s*\)`)
	reSpaceBefore = regexp.MustCompile(`\s+([,.;:)])`)
	reSpaceAfter  = regexp.MustCompile(`\(\s+`)
	reCommaParen  = regexp.MustCompile(`[,;]\s*\)`)
	reParenComma  = regexp.MustCompile(`\(\s*[,;]\s*`)
	reSeeNothing  = regexp.MustCompile(`\bSee\s*\.`)
	reDoubleDot   = regexp.MustCompile(`([^.])\.\s+\.(\s|$)`)
	reSpaces      = regexp.MustCompile(`[ \t]{2,}`)
)

// cleanText removes contributor-only references from one paragraph of
// comment text (lines already joined with single spaces).
func cleanText(s string) string {
	s = reSpecSentence.ReplaceAllString(s, "")
	s = reSpecInline.ReplaceAllString(s, "")
	s = reExperiment.ReplaceAllString(s, "")
	s = reCiteParen.ReplaceAllString(s, "")
	s = reCiteInline.ReplaceAllString(s, "")
	s = reEmptyParen.ReplaceAllString(s, "")
	s = reCommaParen.ReplaceAllString(s, ")")
	s = reParenComma.ReplaceAllString(s, "(")
	s = reSpaceAfter.ReplaceAllString(s, "(")
	s = reSpaceBefore.ReplaceAllString(s, "$1")
	s = reSeeNothing.ReplaceAllString(s, "")
	s = reDoubleDot.ReplaceAllString(s, "$1.$2")
	s = reSpaces.ReplaceAllString(s, " ")
	return strings.TrimSpace(s)
}

// block is one paragraph or one verbatim line of a comment.
type block struct {
	text     string
	verbatim bool // a list item or an indented line: kept on its own line
}

// commentLines strips the comment markers from raw "//" lines.
func commentLines(raw []string) []string {
	out := make([]string, 0, len(raw))
	for _, l := range raw {
		l = strings.TrimPrefix(l, "//")
		l = strings.TrimPrefix(l, " ")
		out = append(out, strings.TrimRight(l, " \t"))
	}
	return out
}

// isWhyLine reports a rationale line, which never reaches a public page.
func isWhyLine(l string) bool {
	return strings.HasPrefix(strings.TrimSpace(l), "WHY")
}

// paragraphs splits comment lines into blocks. A blank line ends a paragraph;
// a list item ("- ") or an indented line stands alone. WHY lines are dropped.
// A nil entry in the result marks a paragraph break.
func paragraphs(lines []string) []*block {
	var out []*block
	var cur []string
	flush := func() {
		if len(cur) > 0 {
			out = append(out, &block{text: strings.Join(cur, " ")})
			cur = nil
		}
	}
	for _, l := range lines {
		switch {
		case isWhyLine(l):
			continue
		case strings.TrimSpace(l) == "":
			flush()
			out = append(out, nil)
		case strings.HasPrefix(l, "- ") || strings.HasPrefix(l, "  "):
			flush()
			out = append(out, &block{text: l, verbatim: true})
		default:
			cur = append(cur, strings.TrimSpace(l))
		}
	}
	flush()
	return out
}

// cleanComment applies cleanText to raw comment lines and returns the
// resulting lines, without markers. Paragraphs whose text the rules leave
// unchanged keep their original line breaks; a changed one is re-wrapped.
//
// A group whose first line opens with "WHY" is a rationale block as a whole,
// even where it sits directly above a field or closing brace, and yields
// nothing.
func cleanComment(raw []string, width int) []string {
	lines := commentLines(raw)
	for _, l := range lines {
		if strings.TrimSpace(l) == "" {
			continue
		}
		if isWhyLine(l) {
			return nil
		}
		break
	}
	var out []string
	var para []string
	emit := func(orig []string) {
		if len(orig) == 0 {
			return
		}
		joined := strings.Join(trimAll(orig), " ")
		c := cleanText(joined)
		switch {
		case c == "":
		case c == joined:
			out = append(out, orig...)
		default:
			out = append(out, wrap(c, width)...)
		}
	}
	for _, l := range lines {
		switch {
		case isWhyLine(l):
		case strings.TrimSpace(l) == "":
			emit(para)
			para = nil
			if len(out) > 0 && out[len(out)-1] != "" {
				out = append(out, "")
			}
		case strings.HasPrefix(l, "- ") || strings.HasPrefix(l, "  "):
			emit(para)
			para = nil
			if c := cleanText(l); c != "" {
				out = append(out, leadingSpace(l)+c)
			}
		default:
			para = append(para, l)
		}
	}
	emit(para)
	for len(out) > 0 && out[len(out)-1] == "" {
		out = out[:len(out)-1]
	}
	return out
}

func trimAll(ls []string) []string {
	out := make([]string, len(ls))
	for i, l := range ls {
		out[i] = strings.TrimSpace(l)
	}
	return out
}

func leadingSpace(s string) string {
	return s[:len(s)-len(strings.TrimLeft(s, " "))]
}

// wrap breaks s into lines of at most width runes, at spaces.
func wrap(s string, width int) []string {
	var out []string
	line := ""
	for _, w := range strings.Fields(s) {
		if line != "" && utf8.RuneCountInString(line)+1+utf8.RuneCountInString(w) > width {
			out = append(out, line)
			line = w
			continue
		}
		if line == "" {
			line = w
		} else {
			line += " " + w
		}
	}
	if line != "" {
		out = append(out, line)
	}
	return out
}

// docProse is a definition's doc comment as public prose: the summary (its
// first sentence), the remaining paragraphs, and any Example or Usage lines.
type docProse struct {
	summary  string
	notes    []*block // nil entries are paragraph breaks
	examples []example
}

type example struct {
	usage bool   // a "Usage:" expression rather than "Example:" values
	text  string // the raw text after the marker
}

var reExampleMarker = regexp.MustCompile(`\b(Example|Usage):\s*`)

// parseDoc turns a definition's raw doc comment into public prose.
func parseDoc(name string, raw []string) docProse {
	var d docProse
	var blocks []*block
	for _, b := range paragraphs(commentLines(raw)) {
		if b == nil {
			blocks = append(blocks, nil)
			continue
		}
		t := cleanText(b.text)
		if t == "" {
			continue
		}
		// Example and Usage run to the end of their paragraph.
		if !b.verbatim {
			if loc := reExampleMarker.FindStringIndex(t); loc != nil {
				rest := t[loc[0]:]
				t = strings.TrimSpace(t[:loc[0]])
				parts := reExampleMarker.FindAllStringSubmatchIndex(rest, -1)
				for i, p := range parts {
					end := len(rest)
					if i+1 < len(parts) {
						end = parts[i+1][0]
					}
					d.examples = append(d.examples, example{
						usage: rest[p[2]:p[3]] == "Usage",
						text:  strings.TrimSpace(rest[p[1]:end]),
					})
				}
				if t == "" {
					continue
				}
			}
		}
		blocks = append(blocks, &block{text: t, verbatim: b.verbatim})
	}
	// Drop leading, trailing and doubled paragraph breaks.
	var tidy []*block
	for _, b := range blocks {
		if b == nil && (len(tidy) == 0 || tidy[len(tidy)-1] == nil) {
			continue
		}
		tidy = append(tidy, b)
	}
	for len(tidy) > 0 && tidy[len(tidy)-1] == nil {
		tidy = tidy[:len(tidy)-1]
	}
	if len(tidy) == 0 {
		return d
	}
	first := stripNameLabel(name, tidy[0].text)
	sum, rest := firstSentence(first)
	d.summary = sum
	if rest != "" {
		tidy[0] = &block{text: rest}
		d.notes = tidy
	} else {
		d.notes = tidy[1:]
		for len(d.notes) > 0 && d.notes[0] == nil {
			d.notes = d.notes[1:]
		}
	}
	return d
}

// stripNameLabel removes a leading "#Name:" or "Name:" label and gives a bare
// leading "Name" its "#", then capitalises the first letter.
func stripNameLabel(name, s string) string {
	bare := strings.TrimPrefix(name, "#")
	for _, p := range []string{name + ":", bare + ":"} {
		if strings.HasPrefix(s, p) {
			return upperFirst(strings.TrimSpace(s[len(p):]))
		}
	}
	if strings.HasPrefix(s, bare+" ") {
		return name + s[len(bare):]
	}
	return upperFirst(s)
}

// upperFirst capitalises a sentence whose first word is a plain word; an
// identifier such as snake_case keeps its spelling.
func upperFirst(s string) string {
	word, _, _ := strings.Cut(s, " ")
	for _, r := range word {
		if !unicode.IsLetter(r) && r != '-' && r != '\'' {
			return s
		}
	}
	r, n := utf8.DecodeRuneInString(s)
	if r == utf8.RuneError || !unicode.IsLower(r) {
		return s
	}
	return string(unicode.ToUpper(r)) + s[n:]
}

// firstSentence splits s after its first sentence. A sentence ends at ".",
// "!" or "?" followed by a space; "e.g.", "i.e.", "etc." and "vs." never end
// one.
func firstSentence(s string) (string, string) {
	for i := 0; i < len(s); i++ {
		c := s[i]
		if c != '.' && c != '!' && c != '?' {
			continue
		}
		if i+1 == len(s) {
			return s, ""
		}
		if s[i+1] != ' ' || i+2 >= len(s) {
			continue
		}
		if c == '.' && abbreviation(s[:i+1]) {
			continue
		}
		return s[:i+1], strings.TrimSpace(s[i+2:])
	}
	if !strings.HasSuffix(s, ".") {
		s += "."
	}
	return s, ""
}

func abbreviation(s string) bool {
	for _, a := range []string{"e.g.", "i.e.", "etc.", "vs."} {
		if strings.HasSuffix(s, " "+a) || s == a || strings.HasSuffix(s, "("+a) {
			return true
		}
	}
	return false
}

// reDollarRef matches a "$"-prefixed field name in prose: "$secretName".
var reDollarRef = regexp.MustCompile(`\$[A-Za-z_][A-Za-z0-9_]*`)

// reDefRef matches a definition reference in prose: "#Trait",
// "#Trait.optional", "#ctx.components".
var reDefRef = regexp.MustCompile(`#[A-Za-z_][A-Za-z0-9_]*(?:\.[#$A-Za-z_][A-Za-z0-9_]*)*`)

// markdown renders one line of prose as Markdown: outside code spans it links
// a reference to an included definition, puts any other "#name" in a code
// span, and escapes "<" so no text can read as raw HTML.
func markdown(s string, self string, link func(def string) string) string {
	var b strings.Builder
	parts := strings.Split(s, "`")
	for i, p := range parts {
		if i > 0 {
			b.WriteString("`")
		}
		if i%2 == 1 && i < len(parts)-1 {
			b.WriteString(p) // inside a code span
			continue
		}
		p = strings.ReplaceAll(p, "<", `\<`)
		p = strings.ReplaceAll(p, "{{", `{\{`)
		p = reDefRef.ReplaceAllStringFunc(p, func(m string) string {
			base := m
			if j := strings.Index(m, "."); j > 0 {
				base = m[:j]
			}
			if base != self {
				if u := link(base); u != "" {
					return "[`" + m + "`](" + u + ")"
				}
			}
			return "`" + m + "`"
		})
		p = reDollarRef.ReplaceAllString(p, "`$0`")
		b.WriteString(p)
	}
	return b.String()
}
