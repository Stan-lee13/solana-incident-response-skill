#!/bin/bash
# Solana Incident Response Skill — Installer

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
SKILL_PATH="$SKILLS_DIR/solana-incident-response"
CLAUDE_MD_PATH="$HOME/.claude/CLAUDE.md"

SKIP_CONFIRM=false
while [[ $# -gt 0 ]]; do
  case $1 in
    -y|--yes)    SKIP_CONFIRM=true; shift ;;
    -d|--dir)    SKILLS_DIR="$2"; SKILL_PATH="$SKILLS_DIR/solana-incident-response"; shift 2 ;;
    -h|--help)
      echo "Usage: ./install.sh [-y] [-d <dir>]"
      echo "  -y    Skip confirmation"
      echo "  -d    Custom skills directory (default: ~/.claude/skills)"
      exit 0 ;;
    *)           echo -e "${RED}Unknown: $1${NC}"; exit 1 ;;
  esac
done

echo ""
echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC}  ${WHITE}⚔  Solana Incident Response Skill${NC}                          ${RED}║${NC}"
echo -e "${RED}║${NC}  ${CYAN}The playbook no one wants — and everyone needs.${NC}             ${RED}║${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${CYAN}Target:${NC} $SKILL_PATH"
echo ""

if [ "$SKIP_CONFIRM" = false ]; then
  read -p "Proceed? [Y/n] " -n 1 -r; echo
  [[ $REPLY =~ ^[Nn]$ ]] && echo "Cancelled." && exit 0
fi

mkdir -p "$SKILLS_DIR" "$HOME/.claude"

# Install
echo -e "${CYAN}[1/3]${NC} Installing skill files..."
[ -d "$SKILL_PATH" ] && echo "  Updating existing installation..." || mkdir -p "$SKILL_PATH"
for dir in skill agents commands rules; do
  [ -d "$SCRIPT_DIR/$dir" ] && cp -r "$SCRIPT_DIR/$dir" "$SKILL_PATH/"
done
cp "$SCRIPT_DIR/SKILL.md" "$SKILL_PATH/"
cp "$SCRIPT_DIR/CLAUDE.md" "$SKILL_PATH/"
echo -e "  ${GREEN}✓${NC} Files installed"

# Register in CLAUDE.md
echo -e "${CYAN}[2/3]${NC} Registering in CLAUDE.md..."
CLAUDE_BLOCK="## Incident Response Skill
Playbook: ${SKILL_PATH}/SKILL.md
Load immediately when you detect or suspect a security exploit."

if [ -f "$CLAUDE_MD_PATH" ]; then
  if ! grep -q "Incident Response Skill" "$CLAUDE_MD_PATH"; then
    echo -e "\n$CLAUDE_BLOCK" >> "$CLAUDE_MD_PATH"
    echo -e "  ${GREEN}✓${NC} Added to CLAUDE.md"
  else
    echo -e "  ${YELLOW}→${NC} Already registered"
  fi
else
  printf "# Claude Configuration\n\n%s\n" "$CLAUDE_BLOCK" > "$CLAUDE_MD_PATH"
  echo -e "  ${GREEN}✓${NC} Created CLAUDE.md"
fi

# Verify
echo -e "${CYAN}[3/3]${NC} Verifying..."
ALL_OK=true
for f in SKILL.md CLAUDE.md skill/active-exploit-response.md skill/program-freeze-and-pause.md agents/incident-commander.md rules/incident-safety.md; do
  if [ -f "$SKILL_PATH/$f" ]; then
    echo -e "  ${GREEN}✓${NC} $f"
  else
    echo -e "  ${RED}✗${NC} MISSING: $f"; ALL_OK=false
  fi
done

echo ""
if [ "$ALL_OK" = true ]; then
  echo -e "${GREEN}Installation complete. ✓${NC}"
else
  echo -e "${RED}Installation incomplete.${NC}"; exit 1
fi

echo ""
echo -e "${WHITE}During an incident:${NC}"
echo -e "  ${CYAN}\"We have an active exploit — load skill/active-exploit-response.md\"${NC}"
echo -e "  ${CYAN}\"Run /incident-triage — suspicious transactions on [PROGRAM_ADDRESS]\"${NC}"
echo -e "  ${CYAN}\"Draft /freeze-checklist for our program\"${NC}"
echo ""
