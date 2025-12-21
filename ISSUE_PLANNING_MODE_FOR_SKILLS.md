# Implement Automatic Planning Mode Initiation for Devcontainer Skills

## Problem

The devcontainer skills (`devcontainer-setup-basic`, `devcontainer-setup-intermediate`, `devcontainer-setup-advanced`, `devcontainer-setup-yolo`) perform significantly better when they initiate planning mode first. Planning mode allows the skills to:

1. Scan the project directory structure
2. Analyze existing files and configurations
3. Create comprehensive task/todo lists
4. Provide more consistent and complete implementations

Currently, skills jump directly into execution without this discovery phase, leading to:
- Missed edge cases
- Incomplete implementations
- Less context-aware decisions

## Proposed Solution

Modify devcontainer skills to automatically enter planning mode before execution. This would:

1. Enable directory and file scanning
2. Analyze project requirements
3. Generate detailed task lists
4. Present plan to user for approval
5. Execute with full context

## Implementation Plan

### Phase 1: Research & Design
- [ ] Audit all devcontainer skills to identify planning mode integration points
- [ ] Review existing EnterPlanMode and ExitPlanMode tool usage patterns
- [ ] Design skill structure that triggers planning mode automatically
- [ ] Document the planning mode pattern for use in skill instructions
- [ ] Determine which other skills would benefit from this pattern

### Phase 2: Update Skill Structure
- [ ] Create a planning mode initialization pattern/template for skills
- [ ] Define clear entry criteria for when skills should use planning mode
- [ ] Update skill instructions to trigger EnterPlanMode at the start
- [ ] Ensure skills properly exit planning mode after user approval

### Phase 3: Update Individual Skills
- [ ] Update `devcontainer-setup-basic` skill with planning mode initiation
- [ ] Update `devcontainer-setup-intermediate` skill with planning mode initiation
- [ ] Update `devcontainer-setup-advanced` skill with planning mode initiation
- [ ] Update `devcontainer-setup-yolo` skill with planning mode initiation
- [ ] Ensure consistent behavior across all devcontainer skill modes

### Phase 4: Task List Standardization
Based on observed successful task lists, ensure all skills generate complete task lists including:

**Discovery Phase:**
- [ ] Scan project directory structure
- [ ] Identify project type (Python, Node.js, etc.)
- [ ] Check for existing .devcontainer configuration
- [ ] Analyze project dependencies and requirements
- [ ] Determine required services (databases, caches, etc.)

**Planning Phase:**
- [ ] Select appropriate Dockerfile template based on project type
- [ ] Determine security mode (basic/intermediate/advanced/yolo)
- [ ] Plan firewall rules and network configuration
- [ ] Identify required environment variables and secrets
- [ ] Plan VS Code extensions and settings

**Implementation Phase:**
- [ ] Create .devcontainer directory (if not exists)
- [ ] Copy and customize appropriate Dockerfile template
- [ ] Create docker-compose.yml (if services needed)
- [ ] Create .devcontainer/devcontainer.json with VS Code config
- [ ] Copy/create required scripts:
  - [ ] init-firewall.sh (if intermediate/advanced mode)
  - [ ] setup-claude-credentials.sh
  - [ ] Any project-specific initialization scripts
- [ ] Configure environment variables (.env setup)
- [ ] Set up secrets management (data/secrets.json)
- [ ] Make all scripts executable (chmod +x)
- [ ] Add .env and secrets files to .gitignore

**Verification Phase:**
- [ ] Verify all required files exist
- [ ] Check file permissions are correct
- [ ] Validate Dockerfile syntax
- [ ] Validate docker-compose.yml syntax
- [ ] Validate devcontainer.json syntax
- [ ] Run configuration validation checks

**Optional Post-Setup:**
- [ ] Offer to pull Docker images
- [ ] Offer to build devcontainer
- [ ] Offer to start services
- [ ] Provide troubleshooting guidance if issues detected

### Phase 5: Testing & Validation
- [ ] Test each updated skill with planning mode on fresh projects
- [ ] Test with existing projects that already have devcontainer configs
- [ ] Verify task list completeness across different project types:
  - [ ] Python projects
  - [ ] Node.js projects
  - [ ] Full-stack projects
  - [ ] Projects with databases
  - [ ] Projects without databases
- [ ] Ensure consistent behavior across all modes (basic, intermediate, advanced, yolo)
- [ ] Validate that planning mode provides clear user visibility
- [ ] Test user approval/rejection workflows
- [ ] Verify graceful handling of edge cases

### Phase 6: Documentation
- [ ] Update individual skill documentation (SKILL.md files)
- [ ] Document the planning mode pattern in skill development guidelines
- [ ] Add examples of generated task lists to documentation
- [ ] Update CONTRIBUTING.md with planning mode best practices
- [ ] Create troubleshooting guide for planning mode issues
- [ ] Document how to test skills with planning mode

### Phase 7: Rollout & Monitoring
- [ ] Deploy updated skills
- [ ] Monitor skill performance metrics
- [ ] Collect user feedback on planning mode experience
- [ ] Identify and fix any issues discovered in production
- [ ] Document lessons learned
- [ ] Identify other skills that could benefit from this pattern
- [ ] Create follow-up issues for other skill improvements

## Example Task Lists (from successful runs)

### Example 1 - Basic Mode:
```
☒ Create .devcontainer directory
☒ Write .devcontainer/Dockerfile
☒ Write docker-compose.yml
☒ Write .devcontainer/devcontainer.json
☒ Write .devcontainer/setup-claude-credentials.sh
☒ Make scripts executable
☒ Verify all files exist
☐ Offer to pull Docker images
```

### Example 2 - Intermediate Mode with Services:
```
☐ Create .devcontainer directory
☐ Copy and customize Dockerfile.python to .devcontainer/Dockerfile
☐ Create docker-compose.yml with postgres + redis
☐ Create .devcontainer/devcontainer.json
☐ Copy init-firewall.sh to .devcontainer/
☐ Copy setup-claude-credentials.sh to .devcontainer/
☐ Make scripts executable
☐ Verify all files exist
```

### Example 3 - Advanced Mode:
```
☐ Create .devcontainer directory
☐ Copy and customize Dockerfile
☐ Create docker-compose.yml with PostgreSQL and Redis
☐ Create devcontainer.json with VS Code config
☐ Copy init-firewall.sh script
☐ Copy setup-claude-credentials.sh script
☐ Verify all files and make scripts executable
```

### Recommended Enhanced Task List:
```
Discovery:
☐ Scan project directory
☐ Identify project type
☐ Check existing configuration
☐ Analyze requirements

Planning:
☐ Select Dockerfile template
☐ Determine security mode
☐ Plan required services
☐ Plan environment configuration

Implementation:
☐ Create .devcontainer directory
☐ Copy and customize Dockerfile
☐ Create docker-compose.yml (if needed)
☐ Create devcontainer.json
☐ Copy init-firewall.sh (if intermediate+)
☐ Copy setup-claude-credentials.sh
☐ Configure .env and secrets
☐ Make scripts executable

Verification:
☐ Verify all files exist
☐ Validate syntax
☐ Check permissions
☐ Run configuration checks

Post-Setup:
☐ Offer to pull images
☐ Provide next steps
```

## Benefits

- **Consistency**: All devcontainer setups follow the same thorough process
- **Completeness**: No missed steps or files
- **Context-awareness**: Skills understand project structure before making decisions
- **User visibility**: Clear task lists show what will be done before execution
- **Better error handling**: Can identify issues during planning phase instead of mid-execution
- **User approval**: Users can review and approve the plan before changes are made
- **Flexibility**: Users can request modifications to the plan before execution

## Technical Considerations

1. **EnterPlanMode Integration**: Skills should call EnterPlanMode at the beginning of their execution
2. **ExitPlanMode Handling**: Skills should properly exit planning mode and begin implementation after user approval
3. **Tool Access**: Ensure skills have access to Glob, Grep, and Read tools during planning phase
4. **Error Handling**: Handle cases where planning mode is declined or cancelled
5. **Performance**: Planning mode adds discovery time but significantly improves outcome quality

## Success Metrics

- Reduction in incomplete devcontainer setups
- Fewer user-reported issues with devcontainer skills
- Increased user satisfaction scores
- Reduction in follow-up fixes needed
- More consistent file structure across setups

## Priority

**HIGH** - This should be the next priority item as it directly improves the reliability and user experience of frequently-used skills.

## Labels

- `enhancement`
- `skills`
- `devcontainer`
- `planning-mode`
- `priority: high`
- `user-experience`

## Assignee

@me (current user)

## Related Issues

- None yet (this is the foundational issue)

## Future Considerations

After implementing planning mode for devcontainer skills, consider:
- Applying pattern to other complex skills
- Creating a skill development framework that makes planning mode easier to integrate
- Building automated testing for skills that use planning mode
- Creating metrics dashboard for skill performance
