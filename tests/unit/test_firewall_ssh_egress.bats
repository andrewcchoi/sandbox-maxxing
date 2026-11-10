#!/usr/bin/env bats
#
# Firewall SSH egress and paste-out channel (#379)
#
# Runs the real init-firewall.sh template against stub iptables/ipset/dig/curl/ip
# that record every call, then checks the rules the script produced:
#   - port 22 is accepted only to the git-ssh-hosts set, and rejected for every
#     other destination BEFORE the allowed-domains rule (which accepts any port)
#   - git-ssh-hosts holds GitHub's git ranges and the git hosts, nothing else
#   - gist.github.com is not allowlisted by default
#

BATS_TEST_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
PLUGIN_ROOT="$(cd "$BATS_TEST_DIR/../.." && pwd)"

load '../helpers/test_helper'

FIREWALL="${PLUGIN_ROOT}/skills/_shared/templates/init-firewall.sh"
DOMAINS_JSON="${PLUGIN_ROOT}/skills/_shared/templates/data/allowable-domains.json"

# Fake DNS: git hosts and a non-git allowlisted domain get distinct IPs
GITHUB_IP="140.82.112.3"
GITLAB_IP="172.65.251.78"
BITBUCKET_IP="104.192.141.1"
PYPI_IP="151.101.0.223"
OTHER_IP="10.99.99.99"

# Fake https://api.github.com/meta: one range per field so we can tell them apart
GH_WEB_CIDR="192.30.252.0/22"
GH_API_CIDR="185.199.108.0/22"
GH_GIT_CIDR="140.82.112.0/20"

setup_stubs() {
  STUB_DIR="${BATS_TEST_TMPDIR}/bin"
  CALL_LOG="${BATS_TEST_TMPDIR}/calls.log"
  mkdir -p "$STUB_DIR"
  : > "$CALL_LOG"

  local tool
  for tool in iptables ipset; do
    cat > "$STUB_DIR/$tool" <<EOF
#!/usr/bin/env bash
echo "$tool \$*" >> "$CALL_LOG"
EOF
  done

  cat > "$STUB_DIR/iptables-save" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

  cat > "$STUB_DIR/ip" <<'EOF'
#!/usr/bin/env bash
echo "default via 172.17.0.1 dev eth0"
EOF

  cat > "$STUB_DIR/dig" <<EOF
#!/usr/bin/env bash
domain="\${@: -1}"
case "\$domain" in
  github.com)    ip="$GITHUB_IP" ;;
  gitlab.com)    ip="$GITLAB_IP" ;;
  bitbucket.org) ip="$BITBUCKET_IP" ;;
  pypi.org)      ip="$PYPI_IP" ;;
  *)             ip="$OTHER_IP" ;;
esac
echo "\$domain. 60 IN A \$ip"
EOF

  cat > "$STUB_DIR/curl" <<EOF
#!/usr/bin/env bash
case "\$*" in
  *api.github.com/meta*)
    echo '{"web":["$GH_WEB_CIDR"],"api":["$GH_API_CIDR"],"git":["$GH_GIT_CIDR"]}' ;;
  *example.com*) exit 7 ;;
  *) exit 0 ;;
esac
EOF

  chmod +x "$STUB_DIR"/*
}

run_firewall() {
  setup_stubs
  PATH="$STUB_DIR:$PATH" run bash "$FIREWALL"
  assert_success
}

# Line number of the first OUTPUT rule in the call log matching a regex
rule_line() {
  grep -nE "^iptables -A OUTPUT .*$1" "$CALL_LOG" | head -1 | cut -d: -f1
}

@test "init-firewall.sh runs to completion against stubbed tools" {
  require_command jq
  run_firewall
  assert_output_contains "FIREWALL CONFIGURED SUCCESSFULLY"
}

@test "no OUTPUT rule accepts port 22 without a git-ssh-hosts destination match (#379)" {
  require_command jq
  run_firewall

  run grep -E '^iptables -A OUTPUT .*--dport 22 .*-j ACCEPT' "$CALL_LOG"
  assert_success
  # Every port-22 ACCEPT must be scoped to the git-ssh-hosts set
  while IFS= read -r rule; do
    [[ "$rule" == *"--match-set git-ssh-hosts dst"* ]] || {
      echo "unscoped SSH accept: $rule" >&2
      return 1
    }
  done <<< "$output"
}

@test "port 22 to non-git hosts is rejected before the allowed-domains rule (#379)" {
  require_command jq
  run_firewall

  local ssh_accept ssh_reject allowlist
  ssh_accept=$(rule_line '--dport 22 -m set --match-set git-ssh-hosts dst -j ACCEPT')
  ssh_reject=$(rule_line '--dport 22 -j REJECT')
  allowlist=$(rule_line '--match-set allowed-domains dst -j ACCEPT')

  [ -n "$ssh_accept" ] || { echo "no git-ssh-hosts accept rule" >&2; return 1; }
  [ -n "$ssh_reject" ] || { echo "no port-22 reject rule" >&2; return 1; }
  [ -n "$allowlist" ]  || { echo "no allowed-domains rule" >&2; return 1; }

  [ "$ssh_accept" -lt "$ssh_reject" ]
  [ "$ssh_reject" -lt "$allowlist" ]
}

@test "git-ssh-hosts holds GitHub git ranges and git hosts only (#379)" {
  require_command jq
  run_firewall

  local entry
  for entry in "$GH_GIT_CIDR" "$GITHUB_IP" "$GITLAB_IP" "$BITBUCKET_IP"; do
    grep -qxF "ipset add -exist git-ssh-hosts $entry" "$CALL_LOG" || {
      echo "missing from git-ssh-hosts: $entry" >&2
      return 1
    }
  done

  # Not SSH targets: GitHub web/api ranges and non-git allowlisted domains
  for entry in "$GH_WEB_CIDR" "$GH_API_CIDR" "$PYPI_IP" "$OTHER_IP"; do
    if grep -qxF "ipset add -exist git-ssh-hosts $entry" "$CALL_LOG"; then
      echo "should not be in git-ssh-hosts: $entry" >&2
      return 1
    fi
  done

  # ...but they are still allowlisted for other traffic
  grep -qxF "ipset add -exist allowed-domains $PYPI_IP" "$CALL_LOG"
}

@test "gist.github.com is not allowlisted by default (#379)" {
  run grep -E '^[[:space:]]*"gist\.github\.com"' "$FIREWALL"
  assert_failure

  run jq -r '[.. | .domains? | arrays | .[]] | index("gist.github.com")' "$DOMAINS_JSON"
  assert_success
  [ "$output" = "null" ]
}
