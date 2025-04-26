#!/bin/bash

# Check if directory is passed
if [ -z "$1" ]; then
  echo "Usage: $0 <directory>"
  exit 1
fi

BASE_DIR="$1"

# Check if the directory exists
if [ ! -d "$BASE_DIR" ]; then
  echo "Error: Directory '$BASE_DIR' does not exist."
  exit 1
fi

# Find all directories recursively
find "$BASE_DIR" -type d | while IFS= read -r dir; do
  # Find YAML files in this directory (null-separated for safe spaces)
  yaml_files=$(find "$dir" -maxdepth 1 -type f \( -iname "*.yml" -o -iname "*.yaml" \) -print0)

  if [ -n "$yaml_files" ]; then
    # Prepare output filename
    relative_dir="${dir#$BASE_DIR/}" # remove BASE_DIR/ prefix if it exists
    mkdir -p "output/$relative_dir"

    output_file="output/$relative_dir/merged.txt"

    echo "Merging YAMLs in $dir → $output_file"

    # Merge all YAML files into the output file safely
    find "$dir" -maxdepth 1 -type f \( -iname "*.yml" -o -iname "*.yaml" \) -print0 | xargs -0 cat >"$output_file"
  fi
done
