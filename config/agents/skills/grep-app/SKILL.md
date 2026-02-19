---
name: grep-app
description: Search code across GitHub repositories using grep.app. Use when you need to find code examples, search for patterns across many repos, or explore how other projects implement specific functions.
---

# grep.app Search

Search code across a million GitHub repositories using grep.app.

## Setup

Install dependencies:
```bash
cd /Users/pablopunk/.pi/agent/skills/grep-app && bun install
```

## Usage

### Basic Search
```bash
./search.sh "query" [language]
```

### Examples
```bash
# Search for console.log in JavaScript
./search.sh "console.log" javascript

# Search for function patterns in TypeScript
./search.sh "function handle" typescript

# Search in Go
./search.sh "func main" go

# Search in Rust
./search.sh "impl Drop" rust
```

## Supported Languages

javascript, typescript, go, rust, python, java, c, cpp, ruby, php, swift, kotlin, scala, dart, elixir, erlang, haskell, lua, perl, r, shell, sql, vim, yaml, json, markdown, dockerfile, makefile, terraform, protobuf, graphql

## Output

Returns top 10 results with:
- Repository name
- File path
- Code snippet with context
- Link to full file on GitHub