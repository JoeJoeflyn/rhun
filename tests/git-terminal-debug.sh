#!/bin/sh
# Diagnoses the terminal commit step of tests/scripts/git.rsc: prints the terminal and git state
# after the commit typed into the embedded terminal. Temporary, for CI investigation.
cd "$(dirname "$0")/.."
tmp=$(mktemp -d)
home=$tmp/home
mkdir -p "$home"
sh tests/data/git.setup "$home" "$tmp/state" > /dev/null
shell=/bin/sh
[ "$(uname -s)" = Darwin ] && shell=/bin/dash
cat > "$tmp/d.rsc" <<'EOF'
wait-git
print-git
cmd toggle_terminal
wait 300
print-term
type git commit -qam 'Commit all'
key Return
wait 1500
print-term
wait-git
print-git
wait 4000
print-term
wait-git
print-git
type echo SHELL=$0 PATH=$PATH; command -v git; git --version; git status --short
key Return
wait 3000
print-term
quit
EOF
echo "shell=$shell $(ls -l $shell)"
XDG_CONFIG_HOME=$tmp/config XDG_STATE_HOME=$tmp/state HOME=$home SHELL=$shell PS1='$ ' \
    build/rhun "$home/repo" --headless 1400x860 --script "$tmp/d.rsc" 2>&1
echo "exit=$?"
rm -rf "$tmp"
