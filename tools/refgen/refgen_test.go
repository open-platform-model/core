package main

import (
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"
)

func TestCleanText(t *testing.T) {
	cases := map[string]string{
		"Moved when the shape breaks. See SPEC.md § 2.1.":                     "Moved when the shape breaks.",
		"See #Resource.fulfilment and SPEC.md § 2.2.":                         "See #Resource.fulfilment.",
		"kind prefix + own apiVersion, 0010:D49)":                             "kind prefix + own apiVersion)",
		"(kind prefix + this resource's own apiVersion, 0010:D49)":            "(kind prefix + this resource's own apiVersion)",
		"The omission is a decision (0010:D36), not an oversight.":            "The omission is a decision, not an oversight.",
		"Bounded by 0011:D8/D12/D21 at publish.":                              "Bounded by at publish.",
		"the catalog stamp (0019:D5, D9) holds":                               "the catalog stamp holds",
		"measured (0019 experiment 12) twice":                                 "measured twice",
		"open at the top level (`...`).":                                      "open at the top level (`...`).",
		"organisation (github.com/open-platform-model/...).":                  "organisation (github.com/open-platform-model/...).",
		"under the module's own requirement 0011:D9:R1/R2, and nothing else.": "under the module's own requirement, and nothing else.",
		"enhancement 0015:D1 lists what the catalog DEFINES":                  "lists what the catalog DEFINES",
		"Nothing to clean here.":                                              "Nothing to clean here.",
	}
	for in, want := range cases {
		if got := cleanText(in); got != want {
			t.Errorf("cleanText(%q)\n got %q\nwant %q", in, got, want)
		}
	}
}

func TestFirstSentence(t *testing.T) {
	cases := []struct{ in, sum, rest string }{
		{"Semver 2.0", "Semver 2.0.", ""},
		{"A thing. data holds more.", "A thing.", "data holds more."},
		{"Uses e.g. a value. Then more.", "Uses e.g. a value.", "Then more."},
		{"Reads #Trait.optional and SPEC.md first. Next.", "Reads #Trait.optional and SPEC.md first.", "Next."},
	}
	for _, c := range cases {
		sum, rest := firstSentence(c.in)
		if sum != c.sum || rest != c.rest {
			t.Errorf("firstSentence(%q) = %q, %q; want %q, %q", c.in, sum, rest, c.sum, c.rest)
		}
	}
}

func TestStripNameLabel(t *testing.T) {
	cases := map[[2]string]string{
		{"#Module", "#Module: The portable thing"}:           "The portable thing",
		{"#NameType", "NameType: RFC 1123 DNS label"}:        "RFC 1123 DNS label",
		{"#SnakeNameType", "SnakeNameType: snake_case name"}: "snake_case name",
		{"#IdentityPackage", "IdentityPackage is the shape"}: "#IdentityPackage is the shape",
		{"#Catalog", "#Catalog: top-level catalog"}:          "Top-level catalog",
	}
	for in, want := range cases {
		if got := stripNameLabel(in[0], in[1]); got != want {
			t.Errorf("stripNameLabel(%q, %q) = %q; want %q", in[0], in[1], got, want)
		}
	}
}

func TestMarkdown(t *testing.T) {
	link := func(n string) string {
		if n == "#Trait" {
			return "/docs/reference/definitions/x/#trait"
		}
		return ""
	}
	got := markdown("See #Trait.optional, #ctx and `#Trait` for <name> and $dataKey.", "#Module", link)
	want := "See [`#Trait.optional`](/docs/reference/definitions/x/#trait), `#ctx` and `#Trait` for \\<name> and `$dataKey`."
	if got != want {
		t.Errorf("markdown:\n got %q\nwant %q", got, want)
	}
	if got := markdown("#Module is itself", "#Module", link); got != "`#Module` is itself" {
		t.Errorf("self reference: got %q", got)
	}
}

// TestPagesFollowTheDialect renders every page into a scratch directory and
// checks the page-dialect rules a generated page can break.
func TestPagesFollowTheDialect(t *testing.T) {
	out := t.TempDir()
	if err := run("../../src", out, false); err != nil {
		t.Fatal(err)
	}
	reLink := regexp.MustCompile(`\]\(([^)]*)\)`)
	files, _ := filepath.Glob(filepath.Join(out, "*.md"))
	if len(files) != len(pages)+1 {
		t.Fatalf("got %d pages, want %d", len(files), len(pages)+1)
	}
	for _, f := range files {
		b, err := os.ReadFile(f)
		if err != nil {
			t.Fatal(err)
		}
		s := string(b)
		name := filepath.Base(f)
		fm, ok := strings.CutPrefix(s, "---\n")
		if !ok {
			t.Fatalf("%s: no front matter", name)
		}
		fm, _, _ = strings.Cut(fm, "\n---\n")
		for _, l := range strings.Split(fm, "\n") {
			k, _, _ := strings.Cut(l, ":")
			switch k {
			case "title", "description", "weight":
			case "type":
				if name == "_index.md" {
					t.Errorf("%s: a section page declares no type", name)
				}
			default:
				t.Errorf("%s: front-matter key %q is not allowed", name, k)
			}
		}
		inFence := false
		for i, l := range strings.Split(s, "\n") {
			// Up to three spaces may indent a fence, as in the site's lint.
			if f := strings.TrimPrefix(strings.TrimPrefix(strings.TrimPrefix(l, " "), " "), " "); strings.HasPrefix(f, "```") {
				if !inFence && f == "```" {
					t.Errorf("%s:%d: code fence without a language tag", name, i+1)
				}
				inFence = !inFence
				continue
			}
			if inFence {
				continue
			}
			for _, m := range reLink.FindAllStringSubmatch(l, -1) {
				u := m[1]
				if !strings.HasPrefix(u, "/docs/") || !regexp.MustCompile(`/(#[a-z0-9-]+)?$`).MatchString(u) {
					t.Errorf("%s:%d: link %q is not root-absolute with a trailing slash", name, i+1, u)
				}
			}
		}
		if inFence {
			t.Errorf("%s: unclosed code fence", name)
		}
		if strings.Contains(s, "{{<") || strings.Contains(s, "{{%") {
			t.Errorf("%s: holds a shortcode delimiter", name)
		}
	}
	// A second run over the written pages changes nothing.
	if err := run("../../src", out, true); err != nil {
		t.Errorf("output is not stable: %v", err)
	}
}

func TestWhyGroupIsDropped(t *testing.T) {
	got := cleanComment([]string{"// WHY x: nothing implies it.", "// A second line of the same block."}, 76)
	if len(got) != 0 {
		t.Errorf("a WHY group must yield nothing, got %q", got)
	}
	got = cleanComment([]string{"// Contract text.", "// WHY: a stray rationale line."}, 76)
	if len(got) != 1 || got[0] != "Contract text." {
		t.Errorf("a WHY line inside a doc comment is dropped alone, got %q", got)
	}
}
