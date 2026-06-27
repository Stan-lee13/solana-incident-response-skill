#!/usr/bin/env bash
# Solana Incident Response Skill — Installer

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

REPO_OWNER="Stan-lee13"
REPO_NAME="solana-incident-response-skill"
REPO_REF="main"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || pwd)"
SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
SKILL_PATH="$SKILLS_DIR/solana-incident-response"
CLAUDE_MD_PATH="$HOME/.claude/CLAUDE.md"
SKIP_CONFIRM=false
TARGET_KIND="claude"
TMP_DIR=""

cleanup() {
  if [ -n "$TMP_DIR" ] && [ -d "$TMP_DIR" ]; then
    rm -rf "$TMP_DIR"
  fi
}
trap cleanup EXIT

usage() {
  cat <<EOF
Usage: ./install.sh [options]

Options:
  -y, --yes          Skip confirmation
  --agents           Install into ~/.agents/skills for Zed or other agent tools
  -d, --dir <dir>    Custom skills directory
  --ref <git-ref>    GitHub ref for remote curl installs (default: main)
  -h, --help         Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -y|--yes) SKIP_CONFIRM=true; shift ;;
    --agents) TARGET_KIND="agents"; SKILLS_DIR="$HOME/.agents/skills"; SKILL_PATH="$SKILLS_DIR/solana-incident-response"; shift ;;
    -d|--dir)
      [ $# -ge 2 ] || { echo -e "${RED}Missing value for --dir${NC}"; exit 1; }
      SKILLS_DIR="$2"; SKILL_PATH="$SKILLS_DIR/solana-incident-response"; shift 2 ;;
    --ref)
      [ $# -ge 2 ] || { echo -e "${RED}Missing value for --ref${NC}"; exit 1; }
      REPO_REF="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo -e "${RED}Unknown option: $1${NC}"; usage; exit 1 ;;
  esac
done

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo -e "${RED}Missing required command: $1${NC}"; exit 1; }
}

resolve_source_dir() {
  if [ -f "$SCRIPT_DIR/SKILL.md" ] && [ -d "$SCRIPT_DIR/skill" ] && [ -d "$SCRIPT_DIR/commands" ]; then
    echo "$SCRIPT_DIR"
    return
  fi

  need_cmd tar
  TMP_DIR="$(mktemp -d)"
  local archive="$TMP_DIR/source.tar.gz"
  local url="https://github.com/${REPO_OWNER}/${REPO_NAME}/archive/refs/heads/${REPO_REF}.tar.gz"

  echo -e "${CYAN}Local checkout not found; downloading ${REPO_OWNER}/${REPO_NAME}@${REPO_REF}...${NC}" >&2
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$archive"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$archive" "$url"
  else
    echo -e "${RED}Need curl or wget for remote install.${NC}" >&2
    exit 1
  fi

  tar -xzf "$archive" -C "$TMP_DIR" --strip-components=1
  if [ ! -f "$TMP_DIR/SKILL.md" ] || [ ! -d "$TMP_DIR/skill" ]; then
    echo -e "${RED}Downloaded archive does not look like a skill repo.${NC}" >&2
    exit 1
  fi
  echo "$TMP_DIR"
}

SOURCE_DIR="$(resolve_source_dir)"

cat <<EOF

${RED}╔══════════════════════════════════════════════════════════════╗${NC}
${RED}║${NC}  ${WHITE}⚔  Solana Incident Response Skill${NC}                          ${RED}║${NC}
${RED}║${NC}  ${CYAN}The playbook no one wants — and everyone needs.${NC}             ${RED}║${NC}
${RED}╚══════════════════════════════════════════════════════════════╝${NC}

  ${CYAN}Source:${NC} $SOURCE_DIR
  ${CYAN}Target:${NC} $SKILL_PATH
EOF

if [ "$SKIP_CONFIRM" = false ]; then
  read -r -p "Proceed? [Y/n] " reply
  case "$reply" in
    [Nn]*) echo "Cancelled."; exit 0 ;;
  esac
fi

mkdir -p "$SKILLS_DIR"
if [ "$TARGET_KIND" = "claude" ]; then
  mkdir -p "$HOME/.claude"
fi

echo -e "${CYAN}[1/3]${NC} Installing skill files..."
if [ -d "$SKILL_PATH" ]; then
  BACKUP_PATH="${SKILL_PATH}.backup.$(date +%Y%m%d%H%M%S)"
  cp -R "$SKILL_PATH" "$BACKUP_PATH"
  echo -e "  ${YELLOW}→${NC} Existing install backed up to $BACKUP_PATH"
else
  mkdir -p "$SKILL_PATH"
fi

for dir in skill agents commands rules docs; do
  rm -rf "$SKILL_PATH/$dir"
  cp -R "$SOURCE_DIR/$dir" "$SKILL_PATH/"
done

for file in SKILL.md CLAUDE.md README.md LICENSE ecosystem-signals.md .markdownlint.json .lychee.toml; do
  if [ -f "$SOURCE_DIR/$file" ]; then
    cp "$SOURCE_DIR/$file" "$SKILL_PATH/"
  fi
done

echo -e "  ${GREEN}✓${NC} Files installed"

if [ "$TARGET_KIND" = "claude" ]; then
  echo -e "${CYAN}[2/3]${NC} Registering in CLAUDE.md..."
  CLAUDE_BLOCK="## Incident Response Skill
Playbook: ${SKILL_PATH}/SKILL.md
Load immediately when you detect or suspect a security exploit."

  if [ -f "$CLAUDE_MD_PATH" ]; then
    if ! grep -q "Incident Response Skill" "$CLAUDE_MD_PATH"; then
      printf "\n%s\n" "$CLAUDE_BLOCK" >> "$CLAUDE_MD_PATH"
      echo -e "  ${GREEN}✓${NC} Added to CLAUDE.md"
    else
      echo -e "  ${YELLOW}→${NC} Already registered"
    fi
  else
    printf "# Claude Configuration\n\n%s\n" "$CLAUDE_BLOCK" > "$CLAUDE_MD_PATH"
    echo -e "  ${GREEN}✓${NC} Created CLAUDE.md"
  fi
else
  echo -e "${CYAN}[2/3]${NC} Skipping Claude registration for --agents install"
fi

echo -e "${CYAN}[3/3]${NC} Verifying..."
ALL_OK=true
REQUIRED_FILES=(
  SKILL.md
  CLAUDE.md
  README.md
  ecosystem-signals.md
  .markdownlint.json
  .lychee.toml
  docs/markdown-validation.md
  skill/active-exploit-response.md
  skill/program-freeze-and-pause.md
  skill/bridge-incident-response.md
  commands/incident-triage.md
  commands/incident-readiness-drill.md
  agents/incident-commander.md
  agents/recovery-engineer.md
  rules/incident-safety.md
)

for f in "${REQUIRED_FILES[@]}"; do
  if [ -f "$SKILL_PATH/$f" ]; then
    echo -e "  ${GREEN}✓${NC} $f"
  else
    echo -e "  ${RED}✗${NC} MISSING: $f"
    ALL_OK=false
  fi
done

echo ""
if [ "$ALL_OK" = true ]; then
  echo -e "${GREEN}Installation complete. ✓${NC}"
else
  echo -e "${RED}Installation incomplete.${NC}"
  exit 1
fi

cat <<EOF

${WHITE}During an incident:${NC}
  ${CYAN}"Load skill/active-exploit-response.md + skill/program-freeze-and-pause.md"${NC}
  ${CYAN}"Run /incident-triage — suspicious transactions on [PROGRAM_ADDRESS]"${NC}
  ${CYAN}"Run /freeze-checklist — program [PROGRAM_ID], Squads 3-of-5"${NC}
  ${CYAN}"Run /incident-readiness-drill — tabletop for [PROGRAM_ID]"${NC}
EOF
