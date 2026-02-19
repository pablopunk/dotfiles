---
name: web-reader
description: Fetches and reads content from URLs. Extracts article content, converts to markdown, and saves with metadata. Use when the user asks to read a website, fetch a web page, or extract content from any HTTP/HTTPS URL.
---

# Web Reader

Fetches web content and extracts article content using Mozilla's Readability algorithm. Converts HTML to clean Markdown for easy reading.

## Setup

Install dependencies before first use:
```bash
cd /Users/pablopunk/.pi/agent/skills/web-reader && bun install
```

## Usage

### Read Article (Recommended)
Extracts article content and converts to Markdown:
```bash
./read.js <url>
./read.js https://example.com/article
```

### Options
```bash
./read.js <url> [options]

Options:
  --raw          Save raw HTML instead of extracted article
  --json         Output as JSON with metadata (title, author, etc.)
  --md           Force markdown output (default for articles)
  -o <file>      Specify output file (default: /tmp)
  --stdout       Print to stdout instead of saving to file
```

### Examples
```bash
# Extract article as markdown (saved to /tmp)
./read.js https://example.com/article

# Save raw HTML
./read.js https://example.com --raw -o page.html

# Get structured JSON data
./read.js https://example.com --json

# Fetch API data
./read.js https://api.github.com/users/octocat

# Print to stdout (no file created)
./read.js https://example.com --stdout
./read.js https://example.com --json --stdout
```

### Legacy: Raw Fetch
For simple fetching without extraction:
```bash
./fetch.js <url> [output-file]
```

## Features

- **Article Extraction** - Uses Mozilla Readability to extract main content
- **Markdown Conversion** - Clean, readable Markdown output
- **Metadata** - Extracts title, author, publish date, site name, excerpt
- **Reading Time** - Estimates reading time (~200 WPM)
- **Smart Output** - Auto-generates filenames from article titles, saved to `/tmp`
- **Follows Redirects** - Handles HTTP redirects automatically
- **JSON Mode** - Structured output for programmatic use
- **Raw Mode** - Save original HTML when needed
- **Stdout Mode** - Print directly to console without creating files