#!/bin/bash
# Diff-based comparison analyzer

# Calculate structural similarity (JSON/YAML)
calculate_structure_similarity() {
    local template="$1"
    local generated="$2"

    # Extract keys only (ignoring values)
    local template_keys generated_keys

    if [[ "$template" == *.json ]]; then
        template_keys=$(jq -r 'paths | join(".")' "$template" 2>/dev/null | sort)
        generated_keys=$(jq -r 'paths | join(".")' "$generated" 2>/dev/null | sort)
    elif [[ "$template" == *.yml ]] || [[ "$template" == *.yaml ]]; then
        # Use python for YAML key extraction
        template_keys=$(python3 -c "
import yaml, sys
def get_paths(d, prefix=''):
    if not isinstance(d, dict):
        return
    for k, v in d.items():
        path = f'{prefix}.{k}' if prefix else k
        print(path)
        if isinstance(v, dict):
            get_paths(v, path)
try:
    with open('$template') as f:
        get_paths(yaml.safe_load(f))
except:
    pass
" 2>/dev/null | sort)
        generated_keys=$(python3 -c "
import yaml, sys
def get_paths(d, prefix=''):
    if not isinstance(d, dict):
        return
    for k, v in d.items():
        path = f'{prefix}.{k}' if prefix else k
        print(path)
        if isinstance(v, dict):
            get_paths(v, path)
try:
    with open('$generated') as f:
        get_paths(yaml.safe_load(f))
except:
    pass
" 2>/dev/null | sort)
    fi

    # Compare key sets
    local common_keys total_keys
    common_keys=$(comm -12 <(echo "$template_keys") <(echo "$generated_keys") | wc -l)
    total_keys=$(echo "$template_keys" | grep -c . || echo "1")

    # Avoid division by zero
    if [ "$total_keys" -eq 0 ]; then
        echo "0"
        return
    fi

    # Calculate percentage
    echo "scale=2; ($common_keys / $total_keys) * 100" | bc
}

# Validate file syntax
validate_syntax() {
    local file="$1"

    if [[ "$file" == *.json ]]; then
        jq empty "$file" 2>/dev/null
        return $?
    elif [[ "$file" == *.yml ]] || [[ "$file" == *.yaml ]]; then
        python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null
        return $?
    elif [[ "$file" == Dockerfile* ]]; then
        # Basic Dockerfile validation
        grep -q "^FROM" "$file"
        return $?
    fi

    return 0
}
