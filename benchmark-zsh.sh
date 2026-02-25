#!/bin/bash
# Benchmark zsh startup time

echo "=== ZSH Startup Benchmark ==="
echo ""

if command -v hyperfine &>/dev/null; then
  echo "Using hyperfine for accurate benchmarking..."
  hyperfine --warmup 3 --runs 10 'zsh -i -c exit'
else
  echo "hyperfine not found, install it"
fi
