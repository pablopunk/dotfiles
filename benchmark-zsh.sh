#!/bin/bash
# Benchmark zsh startup time

echo "=== ZSH Startup Benchmark ==="
echo ""

if command -v hyperfine &>/dev/null; then
  echo "Using hyperfine for accurate benchmarking..."
  hyperfine --warmup 3 --runs 10 'zsh -i -c exit'
else
  echo "Running 10 iterations (install hyperfine for better benchmarking)..."
  echo ""
  
  # Warm-up run
  zsh -i -c exit 2>/dev/null
  
  times=()
  for i in {1..10}; do
    # Capture time output
    result=$( { /usr/bin/time -p zsh -i -c exit; } 2>&1 )
    real_time=$(echo "$result" | grep real | awk '{print $2}')
    ms=$(echo "$real_time * 1000" | bc)
    printf "  Run %2d: %.2f ms\n" "$i" "$ms"
    times+=("$ms")
  done
  
  # Calculate average
  total=0
  for t in "${times[@]}"; do
    total=$(echo "$total + $t" | bc)
  done
  avg=$(echo "scale=2; $total / ${#times[@]}" | bc)
  
  echo ""
  echo "Average: ${avg} ms"
fi
