// Command refgen generates the definitions reference under
// docs/site/reference/definitions/ from the CUE definitions in src/.
//
// It parses src/*.cue (fixtures excluded) with cue/parser and reads each
// definition's doc comment and shape; it never evaluates the schema. The
// generated part of every page sits between two marker comments; text an
// author writes outside them is kept. With -check it writes nothing and fails
// when a committed page differs from what it would write.
package main

import (
	"bytes"
	"errors"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

func main() {
	src := flag.String("src", "../../src", "the CUE module directory holding the core package")
	out := flag.String("out", "../../docs/site/reference/definitions", "the directory the reference pages are written to")
	check := flag.Bool("check", false, "write nothing; fail when the committed pages are stale")
	flag.Parse()
	if err := run(*src, *out, *check); err != nil {
		fmt.Fprintln(os.Stderr, "refgen:", err)
		os.Exit(1)
	}
}

func run(src, out string, check bool) error {
	defs, err := loadDefs(src)
	if err != nil {
		return err
	}
	c, err := newCatalog(defs)
	if err != nil {
		return err
	}
	want := map[string]string{} // file name -> full content
	add := func(file, fm, block string) error {
		if strings.Contains(block, "{{<") || strings.Contains(block, "{{%") {
			return fmt.Errorf("%s: generated text holds a Hugo shortcode delimiter", file)
		}
		existing, err := os.ReadFile(filepath.Join(out, file))
		if err != nil && !errors.Is(err, os.ErrNotExist) {
			return err
		}
		page, err := splice(file, existing, fm, block)
		if err != nil {
			return err
		}
		want[file] = page
		return nil
	}
	if err := add("_index.md", frontMatter("Definitions", "Every OPM definition type, generated from the CUE schema in core.", "", 1), renderIndex(c)); err != nil {
		return err
	}
	for i := range pages {
		p := &pages[i]
		block, err := renderPage(c, src, p)
		if err != nil {
			return err
		}
		if err := add(p.file+".md", frontMatter(p.title, p.description, "reference", i+1), block); err != nil {
			return err
		}
	}

	// Any other file in the directory is one the generator no longer writes.
	var extra []string
	entries, err := os.ReadDir(out)
	if err != nil && !errors.Is(err, os.ErrNotExist) {
		return err
	}
	for _, e := range entries {
		if _, ok := want[e.Name()]; !ok {
			extra = append(extra, e.Name())
		}
	}
	files := make([]string, 0, len(want))
	for f := range want {
		files = append(files, f)
	}
	sort.Strings(files)

	if check {
		var stale []string
		for _, f := range files {
			have, err := os.ReadFile(filepath.Join(out, f))
			if err != nil || !bytes.Equal(have, []byte(want[f])) {
				stale = append(stale, f)
			}
		}
		for _, f := range extra {
			stale = append(stale, f+" (not generated)")
		}
		if len(stale) > 0 {
			return fmt.Errorf("%s is stale; run task docs:reference and commit the result:\n  %s", out, strings.Join(stale, "\n  "))
		}
		fmt.Printf("refgen: %s is up to date (%d pages)\n", out, len(files))
		return nil
	}

	if err := os.MkdirAll(out, 0o755); err != nil {
		return err
	}
	for _, f := range extra {
		if err := os.RemoveAll(filepath.Join(out, f)); err != nil {
			return err
		}
	}
	for _, f := range files {
		if err := os.WriteFile(filepath.Join(out, f), []byte(want[f]), 0o644); err != nil {
			return err
		}
	}
	fmt.Printf("refgen: wrote %d pages to %s\n", len(files), out)
	return nil
}

// splice builds a page from its front matter and generated block, keeping
// what an author wrote in an existing page outside the markers: between the
// front matter and the opening marker, and after the closing one.
func splice(file string, existing []byte, fm, block string) (string, error) {
	before, after := "", ""
	if len(existing) > 0 {
		s := string(existing)
		body, ok := stripFrontMatter(s)
		if !ok {
			return "", fmt.Errorf("%s: no front matter; the generator owns this directory's pages", file)
		}
		i := strings.Index(body, beginMarker)
		j := strings.Index(body, endMarker)
		if i < 0 || j < i {
			return "", fmt.Errorf("%s: generated markers missing or out of order; restore them or delete the file", file)
		}
		before = strings.TrimSpace(body[:i])
		after = strings.TrimSpace(body[j+len(endMarker):])
	}
	var b strings.Builder
	b.WriteString(fm)
	b.WriteString("\n")
	if before != "" {
		b.WriteString(before + "\n\n")
	}
	b.WriteString(beginMarker + "\n\n")
	b.WriteString(strings.TrimSpace(block) + "\n\n")
	b.WriteString(endMarker + "\n")
	if after != "" {
		b.WriteString("\n" + after + "\n")
	}
	return b.String(), nil
}

func stripFrontMatter(s string) (string, bool) {
	if !strings.HasPrefix(s, "---\n") {
		return "", false
	}
	end := strings.Index(s[4:], "\n---\n")
	if end < 0 {
		return "", false
	}
	return s[4+end+5:], true
}
