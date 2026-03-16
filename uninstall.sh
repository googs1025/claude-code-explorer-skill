#!/bin/bash
# uninstall.sh — 卸载 code-explorer skill，仅移除自身内容，不影响其他配置
#
# 如果你使用 Plugin 方式安装，请改用：
#   claude plugin remove code-explorer

set -e

SKILL_DIR="$HOME/.claude/skills/code-explorer"
HOOKS_DIR="$HOME/.claude/hooks/code-explorer"
SETTINGS_FILE="$HOME/.claude/settings.json"

echo ""
echo "💡 如果你使用 Plugin 方式安装，请改用："
echo "   claude plugin remove code-explorer"
echo ""

echo "🗑  卸载 code-explorer skill（Legacy 方式）..."

# ── 1. 移除 Skill 文件 ──────────────────────────────────────────────────────

if [ -d "$SKILL_DIR" ]; then
  rm -rf "$SKILL_DIR"
  echo "  ✅ 已删除 Skill 目录：$SKILL_DIR"
else
  echo "  ℹ️  Skill 目录不存在，跳过"
fi

# 清理备份目录
for backup in "$HOME/.claude/skills"/code-explorer.backup.*; do
  [ -d "$backup" ] || continue
  rm -rf "$backup"
  echo "  ✅ 已删除备份：$backup"
done

# ── 2. 移除 Claude Code Hooks 文件 ──────────────────────────────────────────

if [ -d "$HOOKS_DIR" ]; then
  rm -rf "$HOOKS_DIR"
  echo "  ✅ 已删除 Hooks 目录：$HOOKS_DIR"
else
  echo "  ℹ️  Hooks 目录不存在，跳过"
fi

# ── 3. 从 settings.json 中移除 code-explorer 相关 hooks ────────────────────

if [ -f "$SETTINGS_FILE" ]; then
  echo ""
  echo "⚙️  清理 $SETTINGS_FILE 中的 code-explorer hooks..."

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
    """移除包含 code-explorer 的 hook 条目，保留其他条目"""
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
        # 该事件下已无任何 hook，移除整个 key
        del hooks[key]

if not hooks:
    del settings["hooks"]

if changed:
    settings_file.write_text(json.dumps(settings, indent=2, ensure_ascii=False) + "\n")
    print("  ✅ settings.json 已清理（仅移除 code-explorer 条目，保留其他配置）")
else:
    print("  ℹ️  settings.json 中未找到 code-explorer hooks，无需修改")
PYEOF

else
  echo "  ℹ️  $SETTINGS_FILE 不存在，跳过"
fi

# ── 4. 移除 Git Hooks（仅删除本项目安装的）──────────────────────────────────

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

# ── 5. 清理临时文件 ────────────────────────────────────────────────────────

rm -f /tmp/code-explorer-session-* /tmp/code-explorer-reads-* 2>/dev/null
echo ""
echo "  ✅ 已清理临时文件"

# ── 完成 ──────────────────────────────────────────────────────────────────

echo ""
echo "🎉 卸载完成！code-explorer 已完全移除，其他配置未受影响。"
