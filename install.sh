#!/bin/bash

# solana-incident-response-skill installer
# Installs into .claude/ directory of your current project

set -e

SKILL_DIR=".claude/solana-incident-response-skill"
REPO_URL="https://github.com/Stan-lee13/solana-incident-response-skill"

echo ""
echo "Installing solana-incident-response-skill..."
echo ""

# Create target directories
mkdir -p "$SKILL_DIR/skill"
mkdir -p "$SKILL_DIR/agents"
mkdir -p "$SKILL_DIR/commands"
mkdir -p "$SKILL_DIR/rules"

# Copy skill files
cp -r skill/. "$SKILL_DIR/skill/"
cp -r agents/. "$SKILL_DIR/agents/"
cp -r commands/. "$SKILL_DIR/commands/"
cp -r rules/. "$SKILL_DIR/rules/"
cp SKILL.md "$SKILL_DIR/SKILL.md"

# Append reference to CLAUDE.md if it exists
if [ -f ".claude/CLAUDE.md" ]; then
  echo "" >> .claude/CLAUDE.md
  echo "## Incident Response Skill" >> .claude/CLAUDE.md
  echo "Security incident playbook loaded at: solana-incident-response-skill/SKILL.md" >> .claude/CLAUDE.md
  echo "Load this skill immediately if you suspect or confirm a security exploit." >> .claude/CLAUDE.md
  echo "" >> .claude/CLAUDE.md
  echo "Added reference to existing CLAUDE.md"
else
  cat > .claude/CLAUDE.md << 'EOF'
# Solana Project

## Incident Response Skill
Security incident playbook loaded at: solana-incident-response-skill/SKILL.md
Load this skill immediately if you suspect or confirm a security exploit.
EOF
  echo "Created .claude/CLAUDE.md with skill reference"
fi

echo ""
echo "solana-incident-response-skill installed successfully!"
echo ""
echo "Skill location: $SKILL_DIR"
echo ""
echo "Quick start:"
echo "  Active exploit:      Load agents/incident-commander.md"
echo "  Freeze program:      Run /freeze-checklist"
echo "  Post incident:       Load skill/post-mortem-analysis.md"
echo "  Draft notice:        Run /draft-incident-notice"
echo ""
echo "Repo: $REPO_URL"
echo ""
