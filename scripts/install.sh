#!/usr/bin/env bash
# Installs the Frontend Agent (Cursor skill) and the framework subagents you choose.
#
# Usage:
#   scripts/install.sh                          interactive: asks scope and subagents
#   scripts/install.sh --project [DIR]          install into DIR/.cursor (default: current dir)
#   scripts/install.sh --global                 install into ~/.cursor
#
# Subagent selection (install):
#   --subagents nextjs,angular                  install these subagents (folder names)
#   --all                                       install every available subagent
#   --none                                      install only the main agent
#
# Maintenance (uses the manifest of the chosen scope):
#   --add nextjs                                add subagents to an existing install
#   --remove nextjs                             remove subagents from an existing install
#   --update                                    git pull this repo and reapply the install
#   --uninstall                                 remove the agent, subagents and manifest
#   --list                                      show available and installed subagents
#
# Other options:
#   --copy                                      global scope: copy files instead of symlinking
#   -y, --yes                                   never prompt; use flags, manifest and detection
#   -h, --help                                  show this help
#
# Project installs always copy files (so they can be committed and shared with the team).
# Global installs symlink to this repo by default, so `git pull` updates them.

set -euo pipefail

SKILL_NAME="frontend-agent"
MARKER=".installed-by-frontend-agent"
MANIFEST_NAME="frontend-agent.json"
GLOBAL_SKILL_PATH="~/.cursor/skills/$SKILL_NAME/"
PROJECT_SKILL_PATH=".cursor/skills/$SKILL_NAME/"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

scope=""
project_dir=""
mode=""
action="install"
selection=""
changes=""
assume_yes=0

usage() {
  sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
}

die() {
  echo "Error: $*" >&2
  exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    --global) scope="global" ;;
    --project)
      scope="project"
      if [ $# -gt 1 ] && [ "${2#-}" = "$2" ]; then
        project_dir="$2"
        shift
      fi
      ;;
    --copy) mode="copy" ;;
    --subagents)
      [ $# -gt 1 ] || die "--subagents needs a value"
      selection="$2"
      shift
      ;;
    --all) selection="all" ;;
    --none) selection="none" ;;
    --add | --remove)
      [ $# -gt 1 ] || die "$1 needs a value"
      action="${1#--}"
      changes="$2"
      shift
      ;;
    --update) action="update" ;;
    --uninstall) action="uninstall" ;;
    --list) action="list" ;;
    -y | --yes) assume_yes=1 ;;
    -h | --help)
      usage
      exit 0
      ;;
    *) die "unknown option: $1 (see --help)" ;;
  esac
  shift
done

interactive() {
  [ "$assume_yes" -eq 0 ] && [ -t 0 ]
}

# ---------- subagents ----------

available_subagents() {
  local dir
  for dir in "$REPO_DIR"/subagents/*/; do
    if [ -f "$dir/agent.md" ]; then basename "$dir"; fi
  done
}

subagent_name() {
  awk '/^---$/ { c++; next } c == 1 && /^name:/ { sub(/^name:[[:space:]]*/, ""); print; exit }' \
    "$REPO_DIR/subagents/$1/agent.md"
}

is_available() {
  [ -f "$REPO_DIR/subagents/$1/agent.md" ]
}

contains() {
  local needle="$1" item
  shift
  for item in "$@"; do
    [ "$item" = "$needle" ] && return 0
  done
  return 1
}

detect_subagents() {
  local pkg_json="$1" folder pkg
  [ -f "$pkg_json" ] || return 0
  for folder in $(available_subagents); do
    [ -f "$REPO_DIR/subagents/$folder/detect" ] || continue
    while IFS= read -r pkg || [ -n "$pkg" ]; do
      [ -n "$pkg" ] || continue
      if grep -q "\"$pkg\"[[:space:]]*:" "$pkg_json"; then
        echo "$folder"
        break
      fi
    done < "$REPO_DIR/subagents/$folder/detect"
  done
}

# Validates a comma/space separated list and prints it one per line.
parse_list() {
  local item
  for item in $(echo "$1" | tr ',' ' '); do
    is_available "$item" || die "unknown subagent '$item'. Available: $(available_subagents | tr '\n' ' ')"
    echo "$item"
  done
}

# ---------- scope and paths ----------

ask_scope() {
  local answer
  echo "Where do you want to install the Frontend Agent?"
  echo "  1) This project ($PWD/.cursor): copied, can be committed and shared with the team"
  echo "  2) Global (~/.cursor): available in every project on this machine"
  read -r -p "> [1] " answer
  case "${answer:-1}" in
    1) scope="project" ;;
    2) scope="global" ;;
    *) die "invalid choice: $answer" ;;
  esac
}

resolve_scope() {
  if [ -z "$scope" ]; then
    if [ "$action" != "install" ] && [ -f "$PWD/.cursor/$MANIFEST_NAME" ]; then
      scope="project"
    elif [ "$action" != "install" ] && [ -f "$HOME/.cursor/$MANIFEST_NAME" ]; then
      scope="global"
    elif [ "$action" = "install" ] && interactive; then
      ask_scope
    else
      die "choose a scope with --project [DIR] or --global"
    fi
  fi

  if [ "$scope" = "project" ]; then
    project_dir="${project_dir:-$PWD}"
    [ -d "$project_dir" ] || die "project directory not found: $project_dir"
    project_dir="$(cd "$project_dir" && pwd)"
    [ "$project_dir" != "$REPO_DIR" ] || die "run the project install from the target project, not from this repo"
    CURSOR_DIR="$project_dir/.cursor"
    SKILLS_DIR="$CURSOR_DIR/skills"
    AGENTS_DIR="$CURSOR_DIR/agents"
    mode="copy"
  else
    SKILLS_DIR="${CURSOR_SKILLS_DIR:-$HOME/.cursor/skills}"
    AGENTS_DIR="${CURSOR_AGENTS_DIR:-$HOME/.cursor/agents}"
    CURSOR_DIR="$(dirname "$SKILLS_DIR")"
  fi

  SKILL_TARGET="$SKILLS_DIR/$SKILL_NAME"
  MANIFEST="$CURSOR_DIR/$MANIFEST_NAME"
}

# ---------- manifest ----------

manifest_value() {
  [ -f "$MANIFEST" ] || return 0
  sed -n "s/^[[:space:]]*\"$1\": \"\([^\"]*\)\".*/\1/p" "$MANIFEST"
}

manifest_subagents() {
  [ -f "$MANIFEST" ] || return 0
  sed -n 's/^[[:space:]]*"subagents": \[\(.*\)\].*/\1/p' "$MANIFEST" | tr -d '" ' | tr ',' '\n' | sed '/^$/d'
}

write_manifest() {
  local version list="" item
  version="$(git -C "$REPO_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"
  for item in "$@"; do
    list="${list:+$list, }\"$item\""
  done
  mkdir -p "$CURSOR_DIR"
  cat > "$MANIFEST" <<EOF
{
  "version": "$version",
  "scope": "$scope",
  "mode": "$mode",
  "subagents": [$list]
}
EOF
}

# ---------- selection ----------

ask_subagents() {
  local suggested=("$@") all=() folder i answer n marks
  while IFS= read -r folder; do all+=("$folder"); done < <(available_subagents)
  [ ${#all[@]} -gt 0 ] || return 0

  echo >&2
  echo "Which subagents do you want to install?" >&2
  i=1
  for folder in "${all[@]}"; do
    marks=""
    if contains "$folder" ${suggested[@]+"${suggested[@]}"}; then marks=" (suggested)"; fi
    echo "  $i) $(subagent_name "$folder") [$folder]$marks" >&2
    i=$((i + 1))
  done
  echo "Numbers separated by spaces, 'a' for all, 'n' for none, Enter for the suggested ones." >&2
  read -r -p "> " answer

  case "$answer" in
    "") printf '%s\n' ${suggested[@]+"${suggested[@]}"} ;;
    a | A) printf '%s\n' "${all[@]}" ;;
    n | N) ;;
    *)
      for n in $answer; do
        case "$n" in
          *[!0-9]* | "") die "invalid choice: $n" ;;
        esac
        [ "$n" -ge 1 ] && [ "$n" -le ${#all[@]} ] || die "invalid choice: $n"
        echo "${all[$((n - 1))]}"
      done
      ;;
  esac
}

resolve_install_selection() {
  local suggested=() folder
  case "$selection" in
    all) available_subagents; return ;;
    none) return ;;
    "") ;;
    *) parse_list "$selection"; return ;;
  esac

  while IFS= read -r folder; do suggested+=("$folder"); done < <(manifest_subagents)
  if [ "$scope" = "project" ]; then
    while IFS= read -r folder; do
      contains "$folder" ${suggested[@]+"${suggested[@]}"} || suggested+=("$folder")
    done < <(detect_subagents "$project_dir/package.json")
  fi

  if interactive; then
    ask_subagents ${suggested[@]+"${suggested[@]}"} | awk '!seen[$0]++'
  else
    printf '%s\n' ${suggested[@]+"${suggested[@]}"}
  fi
}

# ---------- removal (only what this installer created) ----------

remove_skill() {
  if [ -L "$SKILL_TARGET" ]; then
    rm "$SKILL_TARGET"
  elif [ -d "$SKILL_TARGET" ]; then
    [ -f "$SKILL_TARGET/$MARKER" ] || die "refusing to remove $SKILL_TARGET: it was not created by this installer"
    rm -rf "$SKILL_TARGET"
  elif [ -e "$SKILL_TARGET" ]; then
    die "refusing to remove $SKILL_TARGET: unexpected file type"
  fi
}

# Removes an installed subagent file; foreign files are kept (and reported).
remove_subagent_file() {
  local target="$AGENTS_DIR/$1.md"
  if [ -L "$target" ]; then
    rm "$target"
  elif [ -f "$target" ]; then
    if grep -qF "<!-- $MARKER -->" "$target"; then
      rm "$target"
    else
      echo "Keeping $target: it was not created by this installer." >&2
      return 1
    fi
  fi
}

remove_all_subagents() {
  local folder
  for folder in $(available_subagents); do
    remove_subagent_file "$(subagent_name "$folder")" || true
  done
}

# ---------- install ----------

rewrite_paths() {
  [ "$scope" = "project" ] || return 0
  local file
  while IFS= read -r file; do
    sed "s#$GLOBAL_SKILL_PATH#$PROJECT_SKILL_PATH#g" "$file" > "$file.tmp" && mv "$file.tmp" "$file"
  done < <(find "$@" -type f -name '*.md')
}

install_skill() {
  local folder
  remove_skill
  mkdir -p "$SKILLS_DIR"
  if [ "$mode" = "link" ]; then
    [ -e "$REPO_DIR/SKILL.md" ] || ln -s agent.md "$REPO_DIR/SKILL.md"
    ln -s "$REPO_DIR" "$SKILL_TARGET"
    echo "Linked $SKILL_TARGET -> $REPO_DIR"
    return
  fi

  mkdir -p "$SKILL_TARGET/subagents"
  cp "$REPO_DIR/agent.md" "$SKILL_TARGET/SKILL.md"
  cp "$REPO_DIR/agent.md" "$SKILL_TARGET/agent.md"
  cp -R "$REPO_DIR/principles" "$REPO_DIR/architecture" "$SKILL_TARGET/"
  for folder in "$@"; do
    cp -R "$REPO_DIR/subagents/$folder" "$SKILL_TARGET/subagents/"
  done
  touch "$SKILL_TARGET/$MARKER"
  rewrite_paths "$SKILL_TARGET"
  echo "Copied the Frontend Agent to $SKILL_TARGET"
}

install_subagent() {
  local folder="$1" name source target
  name="$(subagent_name "$folder")"
  [ -n "$name" ] || die "subagents/$folder/agent.md has no 'name' in its frontmatter"
  source="$REPO_DIR/subagents/$folder/agent.md"
  target="$AGENTS_DIR/$name.md"

  mkdir -p "$AGENTS_DIR"
  remove_subagent_file "$name" || die "cannot install $name: $target already exists"
  if [ "$mode" = "link" ]; then
    ln -s "$source" "$target"
    echo "Linked $target -> $source"
  else
    # The marker goes after the frontmatter so the YAML header stays on line 1.
    awk -v marker="<!-- $MARKER -->" '
      { print }
      /^---$/ && ++count == 2 { print marker }
    ' "$source" > "$target"
    rewrite_paths "$target"
    echo "Copied $name to $target"
  fi
}

check_conflicts() {
  local folder target
  if [ -e "$SKILL_TARGET" ] && [ ! -L "$SKILL_TARGET" ] && [ ! -f "$SKILL_TARGET/$MARKER" ]; then
    die "$SKILL_TARGET exists and was not created by this installer"
  fi
  for folder in "$@"; do
    target="$AGENTS_DIR/$(subagent_name "$folder").md"
    if [ -f "$target" ] && [ ! -L "$target" ] && ! grep -qF "<!-- $MARKER -->" "$target"; then
      die "$target exists and was not created by this installer; nothing was changed"
    fi
  done
}

apply_install() {
  local folder
  [ -f "$REPO_DIR/agent.md" ] || die "agent.md not found in $REPO_DIR"
  mode="${mode:-link}"

  check_conflicts "$@"
  remove_all_subagents
  install_skill "$@"
  for folder in "$@"; do
    install_subagent "$folder"
  done
  write_manifest "$@"

  echo
  if [ $# -gt 0 ]; then
    echo "Installed ($scope): $SKILL_NAME + $*"
  else
    echo "Installed ($scope): $SKILL_NAME (no subagents)"
  fi
  if [ "$scope" = "project" ]; then
    echo "Commit $CURSOR_DIR/skills/$SKILL_NAME, the files in $AGENTS_DIR and $MANIFEST to share with the team."
  fi
  echo "Reload the Cursor window. Invoke the agent with /$SKILL_NAME."
}

require_manifest() {
  [ -f "$MANIFEST" ] || die "no installation found at $CURSOR_DIR (missing $MANIFEST_NAME)"
  [ -n "$mode" ] || mode="$(manifest_value mode)"
}

# Command substitution (not process substitution) so `die` in the producer aborts the script.
lines_to_selected() {
  local line
  selected=()
  while IFS= read -r line; do
    if [ -n "$line" ]; then selected+=("$line"); fi
  done <<< "$1"
}

# ---------- main ----------

resolve_scope
selected=()

case "$action" in
  install)
    [ -n "$mode" ] || mode="$(manifest_value mode)"
    output="$(resolve_install_selection)"
    lines_to_selected "$output"
    apply_install ${selected[@]+"${selected[@]}"}
    ;;

  add)
    require_manifest
    output="$({ manifest_subagents; parse_list "$changes"; } | awk '!seen[$0]++')"
    lines_to_selected "$output"
    apply_install ${selected[@]+"${selected[@]}"}
    ;;

  remove)
    require_manifest
    removing="$(parse_list "$changes")"
    output="$(manifest_subagents | while IFS= read -r item; do
      echo "$removing" | grep -qxF "$item" || echo "$item"
    done)"
    lines_to_selected "$output"
    apply_install ${selected[@]+"${selected[@]}"}
    ;;

  update)
    require_manifest
    if git -C "$REPO_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      echo "Updating $REPO_DIR..."
      git -C "$REPO_DIR" pull --ff-only || echo "git pull failed; reapplying the current version." >&2
    fi
    list="$(manifest_subagents | paste -sd, -)"
    args=("--$scope")
    if [ "$scope" = "project" ]; then args+=("$project_dir"); fi
    if [ "$scope" = "global" ] && [ "$mode" = "copy" ]; then args+=("--copy"); fi
    if [ -n "$list" ]; then args+=("--subagents" "$list"); else args+=("--none"); fi
    # Re-exec so the freshly pulled installer does the work.
    exec bash "$REPO_DIR/scripts/install.sh" "${args[@]}" --yes
    ;;

  uninstall)
    remove_all_subagents
    remove_skill
    rm -f "$MANIFEST"
    rmdir "$AGENTS_DIR" "$SKILLS_DIR" 2>/dev/null || true
    echo "Removed the Frontend Agent from $CURSOR_DIR"
    ;;

  list)
    installed=()
    while IFS= read -r item; do installed+=("$item"); done < <(manifest_subagents)
    echo "Subagents ($scope, $CURSOR_DIR):"
    for folder in $(available_subagents); do
      status="available"
      if contains "$folder" ${installed[@]+"${installed[@]}"}; then status="installed"; fi
      echo "  $folder ($(subagent_name "$folder")): $status"
    done
    ;;
esac
