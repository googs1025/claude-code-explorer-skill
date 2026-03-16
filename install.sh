#!/bin/bash
# install.sh — 一键安装 code-explorer skill 到 Claude Code
# 同时配置：Git Hooks（开发用）+ Claude Code Hooks（运行时增强）
#
# 推荐使用 Plugin 方式安装（自动更新、版本管理）：
#   claude plugin add github:googs1025/claude-code-explorer-skill
#
# 本脚本为 Legacy 安装方式，适用于不支持 Plugin 的旧版本 Claude Code。

set -e

SKILL_DIR="$HOME/.claude/skills/code-explorer"
HOOKS_DIR="$HOME/.claude/hooks/code-explorer"
SETTINGS_FILE="$HOME/.claude/settings.json"

# ── 0. Plugin 推荐提示 ─────────────────────────────────────────────────────
echo ""
echo "💡 推荐使用 Plugin 方式安装（自动更新 + 版本管理）："
echo "   claude plugin add github:googs1025/claude-code-explorer-skill"
echo ""
echo "   如果你使用的是最新版 Claude Code，建议使用上述命令安装。"
echo "   以下为 Legacy 安装方式，继续执行..."
echo ""

echo "🔍 安装 code-explorer skill..."

# ── 1. 安装 Skill 文件 ──────────────────────────────────────────────────────

if [ -d "$SKILL_DIR" ]; then
  BACKUP="$SKILL_DIR.backup.$(date +%Y%m%d%H%M%S)"
  echo "  ⚠️  检测到已有版本，备份至 $BACKUP"
  mv "$SKILL_DIR" "$BACKUP"
fi

mkdir -p "$SKILL_DIR/lang" "$SKILL_DIR/scripts"
cp skills/code-explorer/SKILL.md "$SKILL_DIR/"
cp skills/code-explorer/lang/*.md "$SKILL_DIR/lang/"
cp skills/code-explorer/scripts/*.sh "$SKILL_DIR/scripts/"
chmod +x "$SKILL_DIR/scripts/"*.sh

# Legacy 安装需要将 ${CLAUDE_SKILL_DIR} 替换为实际路径
sed -i.bak "s|\${CLAUDE_SKILL_DIR}|$SKILL_DIR|g" "$SKILL_DIR/SKILL.md"
rm -f "$SKILL_DIR/SKILL.md.bak"

echo "  ✅ Skill 安装完成：$SKILL_DIR"

# ── 2. 安装 Git Hooks（当前仓库开发用）────────────────────────────────────────

if [ -d ".git" ]; then
  echo ""
  echo "🪝 安装 Git Hooks..."

  cp git-hooks/pre-commit  .git/hooks/pre-commit
  cp git-hooks/commit-msg  .git/hooks/commit-msg
  chmod +x .git/hooks/pre-commit .git/hooks/commit-msg

  echo "  ✅ pre-commit  → shellcheck 检查暂存的 .sh 文件"
  echo "  ✅ commit-msg  → Conventional Commits 格式验证"
else
  echo ""
  echo "  ℹ️  未检测到 .git 目录，跳过 Git Hooks 安装"
fi

# ── 3. 安装 Claude Code Hooks ──────────────────────────────────────────────

echo ""
echo "🪝 安装 Claude Code Hooks..."

mkdir -p "$HOOKS_DIR"
cp scripts/post-bash.sh "$HOOKS_DIR/"
cp scripts/post-read.sh "$HOOKS_DIR/"
cp scripts/on-stop.sh   "$HOOKS_DIR/"
cp scripts/pre-prompt.sh "$HOOKS_DIR/"
chmod +x "$HOOKS_DIR/"*.sh

echo "  ✅ Hooks 复制至：$HOOKS_DIR"

# ── 4. 注册 Hooks 到 ~/.claude/settings.json ─────────────────────────────────

echo ""
echo "⚙️  注册 Hooks 到 $SETTINGS_FILE ..."

python3 - <<PYEOF
import json, sys
from pathlib import Path

settings_file = Path("$SETTINGS_FILE")
hooks_dir = "$HOOKS_DIR"

# 读取已有配置（容错处理）
try:
    settings = json.loads(settings_file.read_text()) if settings_file.exists() else {}
except (json.JSONDecodeError, OSError):
    settings = {}

hooks = settings.setdefault("hooks", {})

# 工具函数：移除已有的 code-explorer hooks（幂等）
def remove_ce(hook_list):
    return [
        h for h in hook_list
        if not any("code-explorer" in hk.get("command", "") for hk in h.get("hooks", []))
    ]

# PostToolUse hooks
post_hooks = remove_ce(hooks.get("PostToolUse", []))
post_hooks += [
    {
        "matcher": "Bash",
        "hooks": [{"type": "command", "command": f"{hooks_dir}/post-bash.sh"}]
    },
    {
        "matcher": "Read",
        "hooks": [{"type": "command", "command": f"{hooks_dir}/post-read.sh"}]
    }
]
hooks["PostToolUse"] = post_hooks

# UserPromptSubmit hooks
prompt_hooks = remove_ce(hooks.get("UserPromptSubmit", []))
prompt_hooks += [
    {
        "hooks": [{"type": "command", "command": f"{hooks_dir}/pre-prompt.sh"}]
    }
]
hooks["UserPromptSubmit"] = prompt_hooks

# Stop hooks
stop_hooks = remove_ce(hooks.get("Stop", []))
stop_hooks += [
    {
        "hooks": [{"type": "command", "command": f"{hooks_dir}/on-stop.sh"}]
    }
]
hooks["Stop"] = stop_hooks

settings["hooks"] = hooks

# 写回（保留已有其他配置）
settings_file.parent.mkdir(parents=True, exist_ok=True)
settings_file.write_text(json.dumps(settings, indent=2, ensure_ascii=False) + "\n")
print("  ✅ settings.json 更新成功")
PYEOF

# ── 5. 完成提示 ────────────────────────────────────────────────────────────

echo ""
echo "🎉 安装完成！"
echo ""
echo "Skill 用法："
echo "  /code-explorer <文件路径或函数名>"
echo "  或直接描述：「帮我理解 [函数名] 的执行流程」"
echo ""
echo "Claude Code Hooks 说明："
echo "  UserPromptSubmit  → 检测深度分析意图，向用户确认分析范围/关注重点/详细度"
echo "  PostToolUse(Bash) → 验证 detect_lang/find_entry/git_context 脚本输出"
echo "  PostToolUse(Read) → 追踪文件读取数，Phase 1 上限(5个)时提醒"
echo "  Stop              → 会话结束时输出读取统计并清理临时文件"
