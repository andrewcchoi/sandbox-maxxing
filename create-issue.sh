#!/bin/bash

# Script to open GitHub issue creation page
# Since gh CLI is not available, this will provide the issue URL

REPO="andrewcchoi/sandbox-maxxing"
ISSUE_TITLE="Implement automatic planning mode initiation for devcontainer skills"
LABELS="enhancement,skills,devcontainer,planning-mode,priority: high,user-experience"

echo "=============================================="
echo "GitHub Issue Creation"
echo "=============================================="
echo ""
echo "Repository: ${REPO}"
echo "Title: ${ISSUE_TITLE}"
echo "Labels: ${LABELS}"
echo ""
echo "To create this issue:"
echo ""
echo "1. Open this URL in your browser:"
echo "   https://github.com/${REPO}/issues/new"
echo ""
echo "2. Copy the content from: ISSUE_PLANNING_MODE_FOR_SKILLS.md"
echo ""
echo "3. Paste it as the issue body"
echo ""
echo "4. Assign to yourself"
echo ""
echo "5. Add these labels: ${LABELS}"
echo ""
echo "Or, if you have gh CLI configured with authentication:"
echo "   gh issue create --title \"${ISSUE_TITLE}\" --body-file ISSUE_PLANNING_MODE_FOR_SKILLS.md --assignee @me --label \"${LABELS}\""
echo ""
echo "=============================================="
