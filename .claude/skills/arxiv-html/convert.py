#!/usr/bin/env python3
"""Convert arxiv URL to HTML format."""

import re
import sys

ARXIV_PATTERN = r"arxiv\.org/(?:abs|pdf|html)/(\d{4}\.\d{4,5})(v\d+)?(?:\.pdf)?"


def to_html(url):
    match = re.search(ARXIV_PATTERN, url)
    if match:
        arxiv_id = match.group(1)
        version = match.group(2) or ""
        return f"https://arxiv.org/html/{arxiv_id}{version}"
    return url


def to_abs(url):
    match = re.search(ARXIV_PATTERN, url)
    if match:
        arxiv_id = match.group(1)
        version = match.group(2) or ""
        return f"https://arxiv.org/abs/{arxiv_id}{version}"
    return url


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 convert.py <arxiv_url> [--fallback]")
        sys.exit(1)

    if "--fallback" in sys.argv:
        print(to_abs(sys.argv[1]))
    else:
        print(to_html(sys.argv[1]))
