#!/usr/bin/env python3
"""Query DBLP for publication metadata and BibTeX entries.

Uses only stdlib — no external dependencies required.
"""

import argparse
import json
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

DBLP_SEARCH_API = "https://dblp.org/search/publ/api"
USER_AGENT = "dblp-reffix-skill/1.0"


def search_dblp(query, num_results=10):
    """Search DBLP publications API and return parsed JSON results."""
    params = urllib.parse.urlencode({"q": query, "format": "json", "h": num_results})
    url = f"{DBLP_SEARCH_API}?{params}"
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})

    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                data = json.loads(resp.read().decode())
            return data.get("result", {}).get("hits", {}).get("hit", [])
        except urllib.error.HTTPError as e:
            if e.code == 429:
                wait = 30 * (2**attempt)
                print(f"Rate limited, waiting {wait}s...", file=sys.stderr)
                time.sleep(wait)
            else:
                raise
    return []


def fetch_bibtex(dblp_url):
    """Fetch BibTeX entry from a DBLP record URL."""
    bib_url = dblp_url.rstrip("/") + ".bib"
    req = urllib.request.Request(bib_url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=30) as resp:
        return resp.read().decode()


def get_authors(hit):
    """Extract author list from a hit."""
    authors_data = hit.get("info", {}).get("authors", {}).get("author", [])
    if isinstance(authors_data, dict):
        authors_data = [authors_data]
    return [a.get("text", a) if isinstance(a, dict) else a for a in authors_data]


def is_arxiv(hit):
    """Check if a DBLP result is an arXiv entry."""
    info = hit.get("info", {})
    venue = info.get("venue", "")
    url = info.get("url", "")
    ee = info.get("ee", "")
    if isinstance(ee, list):
        ee = " ".join(ee)
    combined = f"{venue} {url} {ee}".lower()
    return "arxiv" in combined


def normalize_title(title):
    """Strip non-alphanumeric characters and lowercase for comparison."""
    return re.sub(r"[^0-9a-zA-Z]", "", title).lower()


def format_result(hit, index):
    """Format a single DBLP search result for display."""
    info = hit.get("info", {})
    authors = get_authors(hit)
    arxiv_tag = " [arXiv]" if is_arxiv(hit) else ""

    lines = []
    lines.append(f"--- Result {index}{arxiv_tag} ---")
    lines.append(f"  Title:   {info.get('title', 'N/A')}")
    lines.append(f"  Authors: {', '.join(authors)}")
    lines.append(f"  Venue:   {info.get('venue', 'N/A')}")
    lines.append(f"  Year:    {info.get('year', 'N/A')}")
    lines.append(f"  Type:    {info.get('type', 'N/A')}")
    if info.get("doi"):
        lines.append(f"  DOI:     {info['doi']}")
    ee = info.get("ee", "")
    if ee:
        if isinstance(ee, list):
            for u in ee:
                lines.append(f"  URL:     {u}")
        else:
            lines.append(f"  URL:     {ee}")
    lines.append(f"  DBLP:    {info.get('url', 'N/A')}")
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(
        description="Query DBLP for publication references"
    )
    parser.add_argument("query", nargs="*", help="Free-form search query")
    parser.add_argument("-t", "--title", help="Search by title")
    parser.add_argument("-a", "--author", help="Search by author")
    parser.add_argument(
        "-n", "--num-results", type=int, default=10, help="Max results (default: 10)"
    )
    parser.add_argument(
        "-b", "--bibtex", action="store_true", help="Output BibTeX for the best match"
    )
    parser.add_argument(
        "--all-bibtex", action="store_true", help="Output BibTeX for all matches"
    )
    parser.add_argument(
        "--prefer-published",
        action="store_true",
        help="Sort published (non-arXiv) versions first",
    )
    parser.add_argument("--json", action="store_true", help="Output raw JSON results")
    args = parser.parse_args()

    parts = []
    if args.query:
        parts.append(" ".join(args.query))
    if args.title:
        parts.append(args.title)
    if args.author:
        parts.append(args.author)

    if not parts:
        parser.error("Provide a search query, --title, --author, or combination")

    query = " ".join(parts)
    hits = search_dblp(query, args.num_results)

    if not hits:
        print("No results found.", file=sys.stderr)
        sys.exit(1)

    if args.json:
        print(json.dumps(hits, indent=2))
        return

    if args.prefer_published:
        published = [h for h in hits if not is_arxiv(h)]
        arxiv = [h for h in hits if is_arxiv(h)]
        if published:
            hits = published + arxiv

    if args.bibtex:
        best = hits[0]
        dblp_url = best.get("info", {}).get("url", "")
        if dblp_url:
            print(fetch_bibtex(dblp_url))
        else:
            print("No DBLP URL for best match", file=sys.stderr)
            sys.exit(1)
    elif args.all_bibtex:
        for hit in hits:
            dblp_url = hit.get("info", {}).get("url", "")
            if dblp_url:
                print(fetch_bibtex(dblp_url))
    else:
        print(f"Found {len(hits)} result(s):\n")
        for i, hit in enumerate(hits, 1):
            print(format_result(hit, i))
            print()


if __name__ == "__main__":
    main()
