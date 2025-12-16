# Testing Guide

## Manual Testing

See `tests/` directory for detailed test cases.

### Quick Test

```bash
# 1. Install plugin
claude plugins add .

# 2. Create test project
mkdir test-sandbox && cd test-sandbox
echo "print('test')" > main.py

# 3. Run setup
claude
/sandbox:setup --basic

# 4. Verify
ls .devcontainer/
docker compose up -d
```

## Test Coverage

- ✅ Basic mode setup
- ✅ Advanced mode setup
- ✅ YOLO tier setup
- ✅ Troubleshooting diagnostics
- ✅ Security auditing
- ✅ Template generation
- ✅ Placeholder replacement
- ✅ Docker services
- ✅ Firewall configuration

## Known Issues

None currently.

## Future Testing

- Automated test framework
- CI/CD integration
- Cross-platform testing (Windows, macOS, Linux)
