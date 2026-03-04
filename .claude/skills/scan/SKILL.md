---
name: scan
description: >-
  Scan documents using the Epson ES-C320W network scanner, and retrieve
  previously scanned documents from Google Drive. Use when the user wants to:
  (1) scan/digitize physical pages, (2) find or retrieve previously scanned
  documents from Drive by searching name/description, or (3) archive scans
  to Drive. Supports single/multi-page, simplex/duplex, produces PDF output
  ready for OCR or analysis.
allowed-tools: Bash(scanimage:*, img2pdf:*, magick:*, mkdir:*, ls:*, mv:*, rm:*), Bash(uv run:*)
---

# Document Scanner (Epson ES-C320W via SANE)

## Setup (One-Time per Machine)

### 1. Install dependencies

```bash
brew install sane-backends img2pdf
```

### 2. Configure SANE backend

The scanner uses the `epsonds` backend (not `epson2`). Add the scanner's IP to
the config:

```bash
echo "net <SCANNER_IP>" >> /opt/homebrew/etc/sane.d/epsonds.conf
```

To find the scanner's IP: check your router's connected clients list, or ping
sweep the subnet looking for the Epson device. The scanner exposes port 1865
(epsonds protocol). SNMP query (`snmpget -v 1 -c public <IP> 1.3.6.1.2.1.1.1.0`)
returns "EPSON Built-in 11b/g/n Print Server" for positive identification.

### 3. Verify

```bash
scanimage -L
# Should show: device `epsonds:net:<IP>' is a Epson ...
```

If `scanimage -L` returns nothing, confirm:
- Scanner Wi-Fi light is solid white (connected to network)
- Scanner IP is reachable: `ping <SCANNER_IP>`
- Port 1865 is open: `nc -z -w 2 <SCANNER_IP> 1865`

### 4. Archive mode setup (optional)

For uploading scans to Google Drive, the Drive scripts support `--profile`
for OAuth (shared with the gmail skill) or ADC as a fallback.

**OAuth (preferred):** Credentials and tokens are stored in
`~/.config/google-oauth/`, shared with the gmail and calendar skills.
One-time setup:

1. Create a GCP project and enable the Google Drive API
2. Create an OAuth client ID (Desktop app)
3. Download the client JSON to `~/.config/google-oauth/credentials.json`
4. On the OAuth consent screen, add the `drive`, `gmail.readonly`,
   `calendar.events`, and `calendar.readonly` scopes, and add your
   Google account(s) as test users

First run with `--profile` opens a browser to authorize. Pass
`--profile personal` (or any profile name) to the Drive scripts.

**ADC (fallback):** If no `--profile` is given, falls back to Application
Default Credentials:

```bash
gcloud auth application-default login \
  --scopes="https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/drive"
```

Create a shared "Scans" folder in Google Drive and note its folder ID (the
last segment of the folder's URL).

## Scanner Discovery

Always use the `epsonds` backend. To get the device string:

```bash
scanimage -L 2>&1 | grep epsonds
```

The device string looks like `epsonds:net:<SCANNER_IP>`. If the scanner has
moved IPs (e.g., after router restart), re-discover with the above command and
update `/opt/homebrew/etc/sane.d/epsonds.conf` if needed.

## Scanning

### Basic command structure

```bash
scanimage -d 'epsonds:net:<IP>' \
  --source "<SOURCE>" \
  --resolution <DPI> \
  --mode <MODE> \
  -x <WIDTH_MM> -y <HEIGHT_MM> \
  --format=png \
  --batch=<OUTPUT_PATTERN>
```

### Source options

| Source | Description |
|--------|-------------|
| `ADF Front` | Single-sided (simplex) |
| `ADF Duplex` | Both sides (duplex) — pages output in reading order |

### Standard scan settings

Use these unless the user requests otherwise:

- **Resolution**: `300` (good balance of quality and file size)
- **Mode**: `Color`
- **Paper size**: US Letter (`-x 215.9 -y 279.4`)

### Paper sizes

| Paper | `-x` (mm) | `-y` (mm) |
|-------|-----------|-----------|
| US Letter | 215.9 | 279.4 |
| US Legal | 215.9 | 355.6 |
| A4 | 210 | 297 |
| A5 | 148 | 210 |

### Additional options

| Option | Effect |
|--------|--------|
| `--adf-skew=yes` | Auto skew correction |
| `--batch-count=N` | Scan exactly N pages then stop |

**Note**: `--adf-crp=yes` (auto-crop) is advertised but does not work on this
model. Use explicit paper dimensions instead.

### Multi-page scanning

`scanimage --batch` scans all pages in the feeder until empty. For duplex, each
sheet produces two pages (front then back), so N sheets = 2N output files.

## Post-Processing Pipeline

### 1. Compress PNGs to JPEG

Always compress scanned PNGs to JPEG before creating PDFs, unless the user
explicitly requests lossless output:

```bash
for f in "$SCAN_DIR"/page_*.png; do
  magick "$f" -quality 85 "${f%.png}.jpg"
done
```

Default quality is 85 (good for handwriting, printed text, and colored
elements like Post-its). At q85, each 300dpi letter page is ~1.5MB vs ~11MB
for the raw PNG.

### 2. Create PDF

```bash
img2pdf "$SCAN_DIR"/page_*.jpg -o "$SCAN_DIR/scan.pdf"
```

`img2pdf` wraps images into PDF without re-encoding — compression is controlled
entirely by the JPEG quality step above.

### Size budget for Claude's Read tool

The `Read` tool has a 20MB PDF limit. At q85, roughly **12 pages** fit within
this limit. For larger scans, split into multiple PDFs and read them
sequentially.

### Splitting scans into separate documents

When a single scan batch contains logically distinct documents (e.g., notes
from different meetings, separate forms), split them into separate PDFs before
uploading. To decide where to split:

1. After compression, read the individual JPEG pages to identify document
   boundaries (look for title pages, topic changes, date headers, etc.)
2. Group the pages by document
3. Generate a separate PDF for each group

```bash
# Example: pages 1-2 are one document, pages 3-4 are another
img2pdf "$SCAN_DIR"/page_001.jpg "$SCAN_DIR"/page_002.jpg -o "$SCAN_DIR/doc_a.pdf"
img2pdf "$SCAN_DIR"/page_003.jpg "$SCAN_DIR"/page_004.jpg -o "$SCAN_DIR/doc_b.pdf"
```

If the scan is a single cohesive document but exceeds the 20MB read limit,
chunk into PDFs of ~12 pages each, numbered sequentially (e.g.,
`scan_part1.pdf`, `scan_part2.pdf`).

## Workflow

### Ephemeral mode (default)

Use when the user wants to scan something for immediate use (e.g., OCR a
document, analyze a form). Infer this mode unless the user explicitly asks to
save/archive.

```bash
SCAN_DIR=$(mktemp -d /tmp/scan_XXXXXX)
scanimage -d 'epsonds:net:<IP>' \
  --source "ADF Duplex" --resolution 300 --mode Color \
  -x 215.9 -y 279.4 \
  --format=png --batch="$SCAN_DIR/page_%03d.png"
for f in "$SCAN_DIR"/page_*.png; do magick "$f" -quality 85 "${f%.png}.jpg"; done
img2pdf "$SCAN_DIR"/page_*.jpg -o "$SCAN_DIR/scan.pdf"
```

Then read the PDF (or individual JPEGs for large scans) and use directly.
Files in `/tmp` are cleaned up on reboot.

### Archive mode

Use when the user wants to keep the scan long-term.

```bash
SCAN_DIR=~/Scans/$(date +%Y-%m-%d_%H%M%S)
mkdir -p "$SCAN_DIR"
scanimage -d 'epsonds:net:<IP>' \
  --source "ADF Duplex" --resolution 300 --mode Color \
  -x 215.9 -y 279.4 \
  --format=png --batch="$SCAN_DIR/page_%03d.png"
for f in "$SCAN_DIR"/page_*.png; do magick "$f" -quality 85 "${f%.png}.jpg"; done
```

After compression, read the JPEGs to identify document boundaries. If the
batch contains distinct documents, split into separate PDFs (see "Splitting
scans" above). Otherwise, create a single PDF:

```bash
img2pdf "$SCAN_DIR"/page_*.jpg -o "$SCAN_DIR/scan.pdf"
```

Before uploading, read the PDF to generate a brief description (1-2 sentences
summarizing the document contents). Ask the user for a descriptive filename
(e.g., `2026-03-03_meeting_notes.pdf`), then upload:

```bash
cd ~/.claude/skills/scan && uv run python drive_upload.py "$SCAN_DIR/scan.pdf" \
  --profile personal \
  --name "2026-03-03_meeting_notes.pdf" \
  --description "Notes from project planning session" \
  --folder-id <DRIVE_FOLDER_ID>
```

The `--folder-id` flag is optional; without it, files upload to Drive root.
Multiple files can be passed in a single invocation.

### Retrieving archived scans

Search for previously archived scans by name or description:

```bash
cd ~/.claude/skills/scan && uv run python drive_search.py --profile personal search "tax return"
cd ~/.claude/skills/scan && uv run python drive_search.py --profile personal search --folder-id <DRIVE_FOLDER_ID>
```

Download a file by its Drive ID:

```bash
cd ~/.claude/skills/scan && uv run python drive_search.py download <FILE_ID> -o /tmp/document.pdf
```

## Troubleshooting

- **"No scanners were identified"**: Scanner may be asleep or IP changed.
  Check Wi-Fi light on scanner, try `ping`, re-run `scanimage -L`.
- **"Document feeder out of documents"**: Normal — this is how the scanner
  signals the feeder is empty. Not an error.
- **Scanner status = 5**: Normal operational status during batch scanning.
- **Scans have white padding**: The `-y` value is too large for the paper.
  Use the paper size table above.
- **`epson2` backend detected instead of `epsonds`**: Both may detect the
  scanner, but `epsonds` has proper ADF/duplex support. Always use the
  `epsonds:net:...` device string.
