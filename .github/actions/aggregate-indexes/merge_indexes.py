#!/usr/bin/env python3

# This script merges a local Helm index.yaml file with a set of remote indexes
# in temp-indexes/*-index.yaml, then stores the result in index.yaml.

from ruamel.yaml import YAML
from pathlib import Path
import sys

# Initialize YAML processor with better formatting
yaml = YAML()
yaml.preserve_quotes = True  # Match double quotes used by cr/helm
yaml.default_flow_style = False

# Start with current index or empty structure
try:
    with open('index.yaml', 'r') as f:
        merged = yaml.load(f) or {}
    print("Found existing index.yaml")
except FileNotFoundError:
    print("Error: No existing index.yaml", file=sys.stderr)
    sys.exit(1)

# Ensure entries dict exists
if 'entries' not in merged:
    merged['entries'] = {}

# Merge each remote index
for index_file in Path('temp-indexes').glob('*-index.yaml'):
    print(f"Merging {index_file}")
    try:
        with open(index_file, 'r') as f:
            remote_index = yaml.load(f)

        if remote_index and 'entries' in remote_index:
            for chart_name, versions in remote_index['entries'].items():
                if chart_name not in merged['entries']:
                    print(f"Adding chart {chart_name} to index")
                    merged['entries'][chart_name] = []

                # Add versions, avoiding duplicates
                existing_versions = {v.get('version'): v for v in merged['entries'][chart_name]}

                for version in versions:
                    version_num = version.get('version')
                    if version_num not in existing_versions:
                        if 'cofide' in str(version_num):
                            print(f"Adding chart {chart_name} version {version_num} to index")
                            merged['entries'][chart_name].append(version)
                        else:
                            print(f"Skipping non-Cofide version {version_num} for chart {chart_name}")
    except Exception as e:
        print(f"Error processing {index_file}: {e}", file=sys.stderr)
        sys.exit(1)

# Sort versions for each chart (newest first)
for chart_name in merged['entries']:
    merged['entries'][chart_name].sort(
        key=lambda x: x.get('created', ''),
        reverse=True
    )

# Write merged index preserving original formatting
with open('index.yaml', 'w') as f:
    yaml.dump(merged, f)

print("Index merged successfully")
