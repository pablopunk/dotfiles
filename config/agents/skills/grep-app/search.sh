#!/bin/bash
#
# grep.app search wrapper
# Usage: ./search.sh "query" [language]

QUERY="$1"
LANG="${2:-}"

if [ -z "$QUERY" ]; then
    echo "Usage: ./search.sh \"query\" [language]"
    echo ""
    echo "Examples:"
    echo "  ./search.sh \"console.log\" javascript"
    echo "  ./search.sh \"func main\" go"
    echo "  ./search.sh \"impl Drop\" rust"
    exit 1
fi

# URL encode query
ENCODED_QUERY=$(printf '%s' "$QUERY" | sed 's/ /%20/g; s/+/%2B/g; s/"/%22/g; s/#/%23/g; s/&/%26/g')

# Build URL
if [ -n "$LANG" ]; then
    URL="https://grep.app/search?q=${ENCODED_QUERY}&filter=lang%3A${LANG}"
else
    URL="https://grep.app/search?q=${ENCODED_QUERY}"
fi

echo "🔍 Searching grep.app..."
echo "   Query: $QUERY"
[ -n "$LANG" ] && echo "   Language: $LANG"
echo ""

# Fetch results
curl -s "$URL" \
    -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
    -H "Accept: text/html" | \
    grep -oP '(?<=href=")https://github.com/[^"]+' | \
    sort -u | \
    head -20 | \
    while read -r line; do
        # Convert grep.app URL to GitHub URL
        if [[ "$line" == *"/blob/"* ]]; then
            echo "📄 $line"
        fi
    done

echo ""
echo "🔗 Full results: $URL"