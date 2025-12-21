#!/usr/bin/env python3
"""
Script to update astral/uv Docker image tags from Docker Hub API
Generates data/uv-images.json with filtered, deduplicated tags
"""

import json
import re
import sys
from datetime import date
from pathlib import Path
from urllib.request import urlopen
from urllib.error import URLError
from collections import defaultdict

# Configuration
API_URL = "https://hub.docker.com/v2/repositories/astral/uv/tags/"
SCRIPT_DIR = Path(__file__).parent
OUTPUT_FILE = SCRIPT_DIR / ".." / "data" / "uv-images.json"


def fetch_all_tags():
    """Fetch all tags from Docker Hub API with pagination"""
    all_tags = []
    next_url = f"{API_URL}?page_size=100"

    print("Fetching Docker Hub tags for astral/uv...")

    while next_url:
        print(f"Fetching: {next_url}")
        try:
            with urlopen(next_url) as response:
                data = json.loads(response.read().decode())
                all_tags.extend(data.get('results', []))
                next_url = data.get('next')
        except URLError as e:
            print(f"ERROR: Failed to fetch tags: {e}")
            sys.exit(1)

    return all_tags


def filter_floating_tags(tags):
    """Filter to floating tags only (exclude version-pinned like 0.9.18-*)"""
    filtered = []

    for tag in tags:
        name = tag['name']
        # Exclude version-pinned tags (starting with digits like 0.9.18-)
        if not re.match(r'^[0-9]+\.[0-9]', name):
            filtered.append(tag)

    return filtered


def deduplicate_tags(tags):
    """Keep one tag per Python version + base image combination"""
    # Group by normalized key
    groups = defaultdict(list)

    for tag in tags:
        name = tag['name']

        # Extract Python version
        py_match = re.search(r'python([0-9.]+)', name)
        py_ver = py_match.group(1) if py_match else 'none'

        # Extract base image
        if re.search(r'alpine[0-9.]*', name):
            base = re.search(r'(alpine[0-9.]+)', name)
            base = base.group(1) if base else 'alpine'
        elif 'bookworm' in name:
            base = 'bookworm'
        elif 'trixie' in name:
            base = 'trixie'
        elif 'slim' in name:
            base = 'slim'
        elif 'debian' in name:
            base = 'debian'
        else:
            base = 'other'

        key = f"{py_ver}-{base}"
        groups[key].append(tag)

    # Keep first (most recent) tag from each group
    deduplicated = [group[0] for group in groups.values()]

    # Sort by name
    deduplicated.sort(key=lambda t: t['name'])

    return deduplicated


def categorize_tag(name):
    """Determine category for a tag"""
    if 'alpine' in name:
        return 'alpine'
    elif 'slim' in name:
        return 'debian-slim'
    elif 'bookworm' in name:
        return 'bookworm'
    elif 'trixie' in name:
        return 'trixie'
    else:
        return 'other'


def extract_python_version(name):
    """Extract Python version from tag name"""
    match = re.search(r'python([0-9.]+)', name)
    return match.group(1) if match else 'unknown'


def extract_base_image(name):
    """Extract base image from tag name"""
    if re.search(r'alpine[0-9.]+', name):
        match = re.search(r'(alpine[0-9.]+)', name)
        return match.group(1) if match else 'alpine'
    elif 'alpine' in name:
        return 'alpine'
    elif 'bookworm' in name:
        return 'bookworm'
    elif 'trixie' in name:
        return 'trixie'
    elif 'slim' in name:
        return 'debian-slim'
    else:
        return 'debian'


def calculate_size_mb(images):
    """Calculate size in MB for each architecture"""
    sizes = {}
    if images:
        for img in images:
            if img.get('os') == 'linux':
                arch = img.get('architecture')
                size_bytes = img.get('size', 0)
                sizes[arch] = round(size_bytes / 1048576, 2)
    return sizes


def get_architectures(images):
    """Get list of architectures"""
    archs = []
    if images:
        for img in images:
            if img.get('os') == 'linux':
                archs.append(f"{img['os']}/{img['architecture']}")
    return sorted(set(archs))


def determine_recommended_tier(name):
    """Determine recommended tier based on tag name"""
    if re.search(r'alpine', name) and re.search(r'python3\.(12|13)', name):
        return ["basic", "intermediate", "advanced"]
    elif 'alpine' in name:
        return ["intermediate", "advanced"]
    elif 'slim' in name and re.search(r'python3\.(12|13)', name):
        return ["intermediate", "advanced"]
    elif 'bookworm' in name and re.search(r'python3\.(11|12)', name):
        return ["advanced"]
    elif re.search(r'trixie|python3\.(8|14)', name):
        return ["yolo"]
    else:
        return ["advanced", "yolo"]


def transform_tag(tag):
    """Transform tag to final JSON format"""
    name = tag['name']
    return {
        'name': name,
        'category': categorize_tag(name),
        'python_version': extract_python_version(name),
        'base_image': extract_base_image(name),
        'size_mb': calculate_size_mb(tag.get('images')),
        'last_updated': tag.get('last_updated'),
        'digest': tag.get('digest', 'unknown'),
        'architectures': get_architectures(tag.get('images')),
        'recommended_tier': determine_recommended_tier(name),
        'pull_command': f"docker pull astral/uv:{name}"
    }


def generate_mode_defaults(tags):
    """Generate mode defaults"""
    tag_names = [t['name'] for t in tags]

    basic = sorted([
        name for name in tag_names
        if re.search(r'python3\.(12|13)-alpine$', name)
    ])

    intermediate = sorted([
        name for name in tag_names
        if re.search(r'python3\.(11|12|13)-alpine', name) or
           re.search(r'python3\.(12|13).*slim', name)
    ])

    advanced = sorted([
        name for name in tag_names
        if re.search(r'python3\.(10|11|12|13)', name) and
           not re.search(r'trixie|python3\.(8|14)', name)
    ])

    return {
        'basic': basic,
        'intermediate': intermediate,
        'advanced': advanced,
        'yolo': 'all'
    }


def main():
    """Main execution"""
    # Fetch all tags
    all_tags = fetch_all_tags()
    print(f"Fetched {len(all_tags)} tags")

    # Filter and deduplicate
    print("Processing tags...")
    filtered = filter_floating_tags(all_tags)
    print(f"After filtering: {len(filtered)} tags")

    deduplicated = deduplicate_tags(filtered)
    print(f"After deduplication: {len(deduplicated)} tags")

    # Transform tags
    transformed = [transform_tag(tag) for tag in deduplicated]

    # Build final JSON
    print("Building JSON structure...")
    current_date = date.today().isoformat()

    output = {
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "description": "Astral UV Docker images registry - Python package manager with fast dependency resolution",
        "metadata": {
            "registry": "docker.io",
            "repository": "astral/uv",
            "hub_url": "https://hub.docker.com/r/astral/uv/tags",
            "api_url": "https://hub.docker.com/v2/repositories/astral/uv/tags/",
            "last_updated": current_date,
            "about": "uv is an extremely fast Python package manager written in Rust. These images provide uv pre-installed with various Python versions and base distributions."
        },
        "categories": {
            "alpine": {
                "description": "Alpine Linux base - smallest image size (~40MB)",
                "recommended_for": ["basic", "intermediate", "advanced"]
            },
            "debian-slim": {
                "description": "Debian slim base - balance of size and compatibility",
                "recommended_for": ["intermediate", "advanced"]
            },
            "bookworm": {
                "description": "Debian Bookworm (12) - stable release",
                "recommended_for": ["intermediate", "advanced"]
            },
            "trixie": {
                "description": "Debian Trixie (13) - testing release",
                "recommended_for": ["yolo"]
            }
        },
        "tags": transformed,
        "mode_defaults": generate_mode_defaults(transformed)
    }

    # Write to file
    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_FILE, 'w') as f:
        json.dump(output, f, indent=2)

    print(f"Successfully created {OUTPUT_FILE}")

    # Print summary
    print("\nSummary:")
    print(f"  Total tags: {len(transformed)}")
    print("  Categories:")
    for cat in output['categories'].keys():
        count = sum(1 for t in transformed if t['category'] == cat)
        print(f"    - {cat}: {count} tags")
    print("  Python versions:")
    py_versions = sorted(set(t['python_version'] for t in transformed if t['python_version'] != 'unknown'))
    for ver in py_versions:
        print(f"    - python{ver}")

    print("\nDone!")


if __name__ == '__main__':
    main()
