# exclusions.ps1
# Library for handling .repokeeper-ignore file patterns

# Auto-detect repo root
$script:RepoRoot = if ($env:REPO_ROOT) {
    $env:REPO_ROOT
} elseif ($env:REPO_ROOT_OVERRIDE) {
    $env:REPO_ROOT_OVERRIDE
} else {
    $scriptDir = Split-Path -Parent $PSCommandPath
    (Resolve-Path (Join-Path $scriptDir "..\..\..\.." )).Path
}

# Path to ignore file (can be overridden via env var)
$script:IgnoreFile = if ($env:REPOKEEPER_IGNORE_FILE) {
    $env:REPOKEEPER_IGNORE_FILE
} else {
    Join-Path $script:RepoRoot ".repokeeper-ignore"
}

# Flag to disable exclusions
$script:NoIgnore = if ($env:REPOKEEPER_NO_IGNORE -eq "true") { $true } else { $false }

# Cache for exclusion patterns
$script:ExclusionPatterns = @()
$script:NegationPatterns = @()
$script:PatternsLoaded = $false

<#
.SYNOPSIS
Load exclusion patterns from .repokeeper-ignore

.DESCRIPTION
Populates the script-level ExclusionPatterns and NegationPatterns arrays
#>
function Get-ExclusionPatterns {
    if ($script:PatternsLoaded) {
        return
    }

    # If --no-ignore flag is set, don't load any patterns
    if ($script:NoIgnore) {
        $script:PatternsLoaded = $true
        return
    }

    # Check if ignore file exists
    if (-not (Test-Path $script:IgnoreFile)) {
        # No ignore file, just use built-in exclusions
        $script:ExclusionPatterns = @("node_modules/", ".git/")
        $script:PatternsLoaded = $true
        return
    }

    # Read patterns from file
    $lines = Get-Content $script:IgnoreFile
    foreach ($line in $lines) {
        # Skip empty lines
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        # Skip comments
        if ($line.TrimStart().StartsWith("#")) {
            continue
        }

        # Trim whitespace
        $line = $line.Trim()
        if ([string]::IsNullOrEmpty($line)) {
            continue
        }

        # Check for negation pattern (starts with !)
        if ($line.StartsWith("!")) {
            # Remove ! prefix and add to negation patterns
            $pattern = $line.Substring(1).Trim()
            $script:NegationPatterns += $pattern
        } else {
            # Regular exclusion pattern
            $script:ExclusionPatterns += $line
        }
    }

    # Always exclude node_modules and .git (built-in)
    $script:ExclusionPatterns += "node_modules/"
    $script:ExclusionPatterns += ".git/"

    $script:PatternsLoaded = $true
}

<#
.SYNOPSIS
Check if a path should be excluded

.PARAMETER Path
The file path to check (can be absolute or relative)

.RETURNS
$true if should exclude, $false if should not exclude
#>
function Test-PathExcluded {
    param([string]$Path)

    Get-ExclusionPatterns

    # If --no-ignore, never exclude
    if ($script:NoIgnore) {
        return $false
    }

    # Make path relative to repo root
    $relativePath = if ($Path.StartsWith($script:RepoRoot)) {
        $Path.Substring($script:RepoRoot.Length).TrimStart('/', '\')
    } else {
        $Path
    }

    # Normalize path separators to forward slashes
    $relativePath = $relativePath.Replace('\', '/')

    # Check negation patterns first (if pattern matches negation, don't exclude)
    foreach ($pattern in $script:NegationPatterns) {
        $pattern = $pattern.Replace('\', '/')

        # Convert glob pattern to regex
        $regexPattern = "^" + [regex]::Escape($pattern).Replace("\*", ".*") + "$"

        if ($relativePath -match $regexPattern) {
            return $false  # Don't exclude (negation matched)
        }

        # Check if path contains the pattern
        if ($relativePath -like "*/$pattern" -or $relativePath -like "*/$pattern/*") {
            return $false  # Don't exclude
        }
    }

    # Check exclusion patterns
    foreach ($pattern in $script:ExclusionPatterns) {
        $pattern = $pattern.Replace('\', '/')

        # Directory pattern (ends with /)
        if ($pattern.EndsWith("/")) {
            # Check if path contains this directory
            if ($relativePath.StartsWith($pattern) -or $relativePath -like "*/$pattern*") {
                return $true  # Should exclude
            }
        }
        # Wildcard pattern
        elseif ($pattern.Contains("*")) {
            # Convert glob pattern to regex
            $regexPattern = "^" + [regex]::Escape($pattern).Replace("\*", ".*") + "$"

            if ($relativePath -match $regexPattern) {
                return $true  # Should exclude
            }
        }
        # Exact filename match
        else {
            $filename = Split-Path -Leaf $Path
            if ($filename -eq $pattern) {
                return $true  # Should exclude
            }
        }
    }

    return $false  # Don't exclude
}

<#
.SYNOPSIS
Get glob exclusion patterns for Get-ChildItem -Exclude

.RETURNS
Array of patterns suitable for -Exclude parameter
#>
function Get-GlobExclusions {
    Get-ExclusionPatterns

    $exclusions = @()
    foreach ($pattern in $script:ExclusionPatterns) {
        # Convert directory patterns to wildcard patterns
        if ($pattern.EndsWith("/")) {
            $exclusions += $pattern.TrimEnd("/")
        } else {
            $exclusions += $pattern
        }
    }

    return $exclusions
}

<#
.SYNOPSIS
Get count of loaded exclusion patterns

.RETURNS
Number of exclusion patterns loaded
#>
function Get-ExclusionCount {
    Get-ExclusionPatterns
    return $script:ExclusionPatterns.Count
}

# Set NoIgnore flag (used by scripts with --no-ignore parameter)
function Set-NoIgnore {
    param([bool]$Value)
    $script:NoIgnore = $Value
    $env:REPOKEEPER_NO_IGNORE = if ($Value) { "true" } else { "false" }
}

# Export functions
Export-ModuleMember -Function Get-ExclusionPatterns, Test-PathExcluded, Get-GlobExclusions, Get-ExclusionCount, Set-NoIgnore
