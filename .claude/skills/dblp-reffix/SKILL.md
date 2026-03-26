---
name: dblp-reffix
description: >-
  Look up papers on DBLP to get authoritative BibTeX references. Use when the
  user wants to find or fix a citation, resolve an arXiv preprint to its
  published venue, or get canonical publication metadata for a paper given its
  title or authors.
allowed-tools: Bash(python3:*), Read, Edit, WebFetch(https://dblp.org:*)
---

# DBLP Reference Lookup & Fixing

## When to Use

- User asks to find a BibTeX entry for a paper (by title, authors, or both)
- User wants to upgrade an arXiv citation to its published conference/journal form
- User asks to fix or clean up references in a `.bib` file
- User wants canonical publication metadata (venue, year, DOI, pages) from DBLP

## Lookup Script

The helper script uses only Python stdlib (no dependencies). Run it with:

```bash
python3 ~/.claude/skills/dblp-reffix/dblp_lookup.py [OPTIONS] [QUERY...]
```

### Options

| Flag | Description |
|------|-------------|
| `QUERY...` | Free-form search (title words, author names, etc.) |
| `-t TITLE` | Search by title (can combine with `-a`) |
| `-a AUTHOR` | Search by author (can combine with `-t`) |
| `-n NUM` | Max results to return (default: 10) |
| `-b` / `--bibtex` | Output BibTeX for the top match |
| `--all-bibtex` | Output BibTeX for every match |
| `--prefer-published` | Sort published (non-arXiv) results first |
| `--json` | Output raw JSON from the DBLP API |

### Examples

```bash
# Search by title
python3 ~/.claude/skills/dblp-reffix/dblp_lookup.py -t "Attention is All You Need"

# Search by title + author, get BibTeX
python3 ~/.claude/skills/dblp-reffix/dblp_lookup.py -t "Attention is All You Need" -a "Vaswani" -b

# Prefer published over arXiv, get BibTeX
python3 ~/.claude/skills/dblp-reffix/dblp_lookup.py -t "Attention is All You Need" --prefer-published -b

# Free-form search
python3 ~/.claude/skills/dblp-reffix/dblp_lookup.py "GPT-4 Technical Report"
```

## Workflow for Fixing References

When asked to fix references in a `.bib` file:

1. **Read the `.bib` file** to get existing entries.
2. For each entry that needs fixing, extract the title and first author.
3. **Run the lookup script** with `--prefer-published -b` to get the DBLP BibTeX.
4. **Compare** the DBLP result with the original entry:
   - Keep the original BibTeX key (the `@type{key,` identifier).
   - Prefer the DBLP metadata (authors, venue, year, pages, DOI).
   - If the original was an arXiv entry and DBLP has a published version, use that.
5. **Edit the `.bib` file** to replace the entry, preserving the original key.

## Workflow for Single Paper Lookup

When asked to find a reference for a specific paper:

1. **Search DBLP** using the title (and optionally an author name for disambiguation).
2. **Review results** — if multiple matches, pick the one matching the user's intent.
   Use `--prefer-published` if the user wants the archival/published version.
3. **Fetch BibTeX** with `-b` and present it to the user.

## Matching Tips

- DBLP search works best with **full or near-full titles**.
- Adding the **first author's last name** helps disambiguate common titles.
- For papers with special characters in titles, the search is fairly tolerant.
- Results marked `[arXiv]` in the output are preprint-only entries. Use
  `--prefer-published` to prioritize conference/journal versions.
- If no results are found, try simplifying the query (drop subtitle, use key
  phrases).

## Title Case Protection

When inserting DBLP BibTeX into LaTeX projects, wrap words with internal
capitals in braces to prevent BibTeX style files from lowercasing them:
- `PartNet` → `{PartNet}`
- `GPT-4` → `{GPT-4}`
- `Mip-NeRF` → `{Mip-NeRF}`

Apply this to the `title` field if the user's BibTeX style lowercases titles.
