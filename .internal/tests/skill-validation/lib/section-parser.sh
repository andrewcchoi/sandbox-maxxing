#!/bin/bash
# Section-based template parser

# Extract sections from master template
extract_sections() {
    local template_file="$1"
    local sections=()

    while IFS= read -r line; do
        if [[ "$line" =~ ===SECTION_START:([^=]+)=== ]]; then
            sections+=("${BASH_REMATCH[1]}")
        fi
    done < "$template_file"

    printf '%s\n' "${sections[@]}"
}

# Check if section exists in generated file
section_exists() {
    local generated_file="$1"
    local section_name="$2"

    grep -q "===SECTION_START:$section_name===" "$generated_file" 2>/dev/null
}

# Get section content
get_section_content() {
    local file="$1"
    local section_name="$2"

    awk "/===SECTION_START:$section_name===/,/===SECTION_END:$section_name===/" "$file"
}
