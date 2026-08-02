#!/bin/sh
# POSIX shell fixture for shell_strategy.md and README.md
#
# Scans fenced sh/bash/zsh blocks for prohibited unsafe patterns and checks the
# README installation section. No dependencies beyond POSIX shell, awk, and grep.
#
# Usage: ./test.sh [red|green|verify]
#   red    - expect failures (non-zero failures means exit 0, zero failures exit 1)
#   green  - expect zero failures
#   verify - same as green

set -u

DOCS_DIR="${DOCS_DIR:-.}"
README="$DOCS_DIR/README.md"
STRATEGY="$DOCS_DIR/shell_strategy.md"
PROG=$(basename "$0")

PHASE="${1:-green}"

case "$PHASE" in
  red|green|verify) ;;
  *) echo "Usage: $PROG [red|green|verify]" >&2; exit 2 ;;
esac

if [ ! -f "$README" ]; then
  echo "FAIL: README.md not found: $README" >&2
  exit 1
fi
if [ ! -f "$STRATEGY" ]; then
  echo "FAIL: shell_strategy.md not found: $STRATEGY" >&2
  exit 1
fi

tmp="${TMPDIR:-/tmp}/shell-strategy-fixture-$$"
if ! mkdir "$tmp"; then
  echo "FAIL: cannot create temporary directory: $tmp" >&2
  exit 1
fi
trap 'rm -rf "$tmp"' 0

# Prohibited patterns inside fenced shell blocks.
# Per-command environment prefixes (e.g. FOO=bar cmd) are NOT listed here and
# are therefore allowed. Global export/profile mutation forms are rejected.
cat > "$tmp/prohibited.txt" <<'EOF'
yes |
StrictHostKeyChecking=no
sudo -S
echo "password" | sudo
export
>> ~/.bashrc
>> ~/.profile
>> ~/.zshrc
EOF

cat > "$tmp/required_forms.txt" <<'EOF'
BatchMode=yes
StrictHostKeyChecking=accept-new
sudo -n
npm init -y
EOF

touch "$tmp/extracted_blocks.txt"

cat > "$tmp/check.awk" <<'EOF'
BEGIN {
  while ((getline line < prohibited_file) > 0) {
    if (line != "") pat[++n] = line
  }
  close(prohibited_file)
}

/^```(sh|bash|zsh)$/ { in_block=1; block_line=NR; content=""; next }
/^```$/ && in_block {
  in_block=0
  print content >> extracted_file
  close(extracted_file)
  # The pragma must be the first non-empty line of the block.
  sub(/^[ \t\n]+/, "", content)
  sub(/\n.*$/, "", content)
  if (content ~ /^# fixture-exempt: negative-example/) { content=""; next }
  for (i=1; i<=n; i++) {
    if (index(content, pat[i]) > 0) {
      printf "FAIL: %s:%d contains prohibited pattern: %s\n", FILENAME, block_line, pat[i]
    }
  }
  content=""
  next
}
in_block { content = content $0 "\n" }
EOF

failures=0

awk_output=$(awk -v prohibited_file="$tmp/prohibited.txt" -v extracted_file="$tmp/extracted_blocks.txt" -f "$tmp/check.awk" "$README" "$STRATEGY")
if [ -n "$awk_output" ]; then
  printf '%s\n' "$awk_output"
  count=$(printf '%s\n' "$awk_output" | grep -c '^FAIL:')
  failures=$((failures + count))
fi

# Positive assertions: required safe forms must appear in fenced shell blocks.
while IFS= read -r form; do
  [ -n "$form" ] || continue
  if grep -F -q "$form" "$tmp/extracted_blocks.txt"; then
    echo "OK: required safe form '$form' found"
  else
    echo "FAIL: required safe form '$form' not found in any fenced shell block"
    failures=$((failures + 1))
  fi
done < "$tmp/required_forms.txt"

# README installation section: must use the instructions[] mechanism with a
# remote raw.githubusercontent.com URL pointing to shell_strategy.md.
install_section=$(awk '/^## Installation$/{p=1;next} /^## /{p=0} p' "$README")

if printf '%s\n' "$install_section" | grep -qF '"instructions"'; then
  echo "OK: README installation section references instructions[]"
else
  echo "FAIL: README installation section does not reference instructions[]"
  failures=$((failures + 1))
fi

if printf '%s\n' "$install_section" | grep -qE 'https://raw\.githubusercontent\.com/[^/]+/[^/]+/trunk/shell_strategy\.md'; then
  echo "OK: README installation section uses remote trunk instruction URL"
else
  echo "FAIL: README installation section does not use remote trunk instruction URL"
  failures=$((failures + 1))
fi

if grep -F -q '~/.config/opencode/plugin/shell-strategy' "$README"; then
  echo "FAIL: README still references local plugin path"
  failures=$((failures + 1))
else
  echo "OK: README does not reference local plugin path"
fi

if grep -qE 'git clone.*shell-strategy' "$README"; then
  echo "FAIL: README still uses clone-based installation as primary route"
  failures=$((failures + 1))
else
  echo "OK: README does not use clone-based installation as primary route"
fi

echo "---"
if [ "$failures" -eq 0 ]; then
  echo "PASS: 0 failures"
  if [ "$PHASE" = "red" ]; then
    echo "RED phase: expected failures but none found"
    exit 1
  fi
  exit 0
fi

echo "FAIL: $failures failures"
if [ "$PHASE" = "red" ]; then
  echo "RED phase: expected failures found"
  exit 0
fi
exit 1
