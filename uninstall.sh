#!/bin/bash
# uninstall.sh — 卸载 code-explorer 的 Claude Code / Codex 安装
#
# 默认行为保持兼容：不传参时仅卸载 Claude Code Legacy 版本。
# 可选参数：
#   --claude  仅卸载 Claude Code Legacy
#   --codex   仅卸载 Codex skill
#   --all     同时卸载 Claude Code Legacy 和 Codex
#   --help    显示帮助

set -e

CLAUDE_SKILL_DIR="$HOME/.claude/skills/code-explorer"
CLAUDE_HOOKS_DIR="$HOME/.claude/hooks/code-explorer"
CLAUDE_SETTINGS_FILE="$HOME/.claude/settings.json"
CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
CODEX_SKILL_DIR="$CODEX_HOME_DIR/skills/code-explorer"

REMOVE_CLAUDE=false
REMOVE_CODEX=false

usage() {
  cat <<'EOF'
用法：
  bash uninstall.sh           # 兼容旧行为，仅卸载 Claude Code Legacy 版本
  bash uninstall.sh --claude  # 仅卸载 Claude Code Legacy 版本
  bash uninstall.sh --codex   # 仅卸载 Codex skill
  bash uninstall.sh --all     # 同时卸载 Claude Code Legacy 和 Codex
EOF
}

remove_dir_if_exists() {
  local target_dir="$1"
  local label="$2"

  if [ -d "$target_dir" ]; then
    rm -rf "$target_dir"
    echo "  ✅ 已删除 $label：$target_dir"
  else
    echo "  ℹ️  $label 不存在，跳过"
  fi
}

remove_backups() {
  local pattern_root="$1"

  for backup in "$pattern_root"/code-explorer.backup.*; do
    [ -d "$backup" ] || continue
    rm -rf "$backup"
    echo "  ✅ 已删除备份：$backup"
  done
}

uninstall_claude() {
  echo ""
  echo "💡 如果你使用 Claude Plugin 方式安装，请改用："
  echo "   claude plugin remove code-explorer"
  echo ""
  echo "🗑  卸载 Claude Code Legacy 版本..."

  remove_dir_if_exists "$CLAUDE_SKILL_DIR" "Skill 目录"
  remove_backups "$HOME/.claude/skills"
  remove_dir_if_exists "$CLAUDE_HOOKS_DIR" "Hooks 目录"

  if [ -f "$CLAUDE_SETTINGS_FILE" ]; then
    echo ""
    echo "⚙️  清理 $CLAUDE_SETTINGS_FILE 中的 code-explorer hooks..."

    python3 - <<'PYEOF'
import json, sys
from pathlib import Path

settings_file = Path.home() / ".claude" / "settings.json"

try:
    settings = json.loads(settings_file.read_text())
except (json.JSONDecodeError, OSError, FileNotFoundError):
    print("  ℹ️  无法读取 settings.json，跳过")
    sys.exit(0)

hooks = settings.get("hooks", {})
if not hooks:
    print("  ℹ️  settings.json 中无 hooks 配置，跳过")
    sys.exit(0)

changed = False

def remove_ce(hook_list):
    return [
        h for h in hook_list
        if not any("code-explorer" in hk.get("command", "") for hk in h.get("hooks", []))
    ]

for key in list(hooks.keys()):
    original = hooks[key]
    cleaned = remove_ce(original)
    if len(cleaned) != len(original):
        changed = True
    if cleaned:
        hooks[key] = cleaned
    else:
        del hooks[key]

if not hooks and "hooks" in settings:
    del settings["hooks"]

if changed:
    settings_file.write_text(json.dumps(settings, indent=2, ensure_ascii=False) + "\n")
    print("  ✅ settings.json 已清理（仅移除 code-explorer 条目，保留其他配置）")
else:
    print("  ℹ️  settings.json 中未找到 code-explorer hooks，无需修改")
PYEOF
  else
    echo "  ℹ️  $CLAUDE_SETTINGS_FILE 不存在，跳过"
  fi

  if [ -d ".git" ]; then
    echo ""
    echo "🪝 检查 Git Hooks..."

    for hook in pre-commit commit-msg; do
      hook_file=".git/hooks/$hook"
      if [ -f "$hook_file" ] && grep -q "code-explorer\|shellcheck.*\.sh\|Conventional Commits" "$hook_file" 2>/dev/null; then
        rm -f "$hook_file"
        echo "  ✅ 已删除 .git/hooks/$hook"
      fi
    done
  else
    echo ""
    echo "  ℹ️  未检测到 .git 目录，跳过 Git Hooks 清理"
  fi

  rm -f /tmp/code-explorer-session-* /tmp/code-explorer-reads-* 2>/dev/null
  echo ""
  echo "  ✅ 已清理临时文件"
}

uninstall_codex() {
  echo ""
  echo "🗑  卸载 Codex skill..."

  remove_dir_if_exists "$CODEX_SKILL_DIR" "Skill 目录"
  remove_backups "$CODEX_HOME_DIR/skills"
}

if [ $# -eq 0 ]; then
  REMOVE_CLAUDE=true
else
  while [ $# -gt 0 ]; do
    case "$1" in
      --claude)
        REMOVE_CLAUDE=true
        ;;
      --codex)
        REMOVE_CODEX=true
        ;;
      --all)
        REMOVE_CLAUDE=true
        REMOVE_CODEX=true
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        echo "未知参数：$1" >&2
        echo ""
        usage >&2
        exit 1
        ;;
    esac
    shift
  done
fi

if [ "$REMOVE_CLAUDE" = false ] && [ "$REMOVE_CODEX" = false ]; then
  usage >&2
  exit 1
fi

if [ "$REMOVE_CLAUDE" = true ]; then
  uninstall_claude
fi

if [ "$REMOVE_CODEX" = true ]; then
  uninstall_codex
fi

echo ""
echo "🎉 卸载完成！code-explorer 已按所选目标移除。"
