#!/bin/bash
# install.sh — 安装 code-explorer 到 Claude Code / Codex
#
# 默认行为保持兼容：不传参时仅执行 Claude Code Legacy 安装。
# 可选参数：
#   --claude  仅安装 Claude Code Legacy skill + hooks
#   --codex   仅安装 Codex skill
#   --all     同时安装 Claude Code Legacy 和 Codex
#   --help    显示帮助

set -e

CLAUDE_SKILL_DIR="$HOME/.claude/skills/code-explorer"
CLAUDE_HOOKS_DIR="$HOME/.claude/hooks/code-explorer"
CLAUDE_SETTINGS_FILE="$HOME/.claude/settings.json"
CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
CODEX_SKILL_DIR="$CODEX_HOME_DIR/skills/code-explorer"

INSTALL_CLAUDE=false
INSTALL_CODEX=false

usage() {
  cat <<'EOF'
用法：
  bash install.sh           # 兼容旧行为，仅安装 Claude Code Legacy 版本
  bash install.sh --claude  # 仅安装 Claude Code Legacy 版本
  bash install.sh --codex   # 仅安装 Codex skill
  bash install.sh --all     # 同时安装 Claude Code Legacy 和 Codex
EOF
}

backup_dir_if_needed() {
  local target_dir="$1"

  if [ -d "$target_dir" ]; then
    local backup
    backup="$target_dir.backup.$(date +%Y%m%d%H%M%S)"
    echo "  ⚠️  检测到已有版本，备份至 $backup"
    mv "$target_dir" "$backup"
  fi
}

install_claude() {
  echo ""
  echo "💡 推荐使用 Claude Plugin 方式安装（自动更新 + 版本管理）："
  echo "   claude plugin add github:googs1025/claude-code-explorer-skill"
  echo ""
  echo "   以下继续执行 Claude Code Legacy 安装..."
  echo ""
  echo "🔍 安装 Claude Code Legacy skill..."

  backup_dir_if_needed "$CLAUDE_SKILL_DIR"

  mkdir -p "$CLAUDE_SKILL_DIR/lang" "$CLAUDE_SKILL_DIR/scripts"
  cp skills/code-explorer/SKILL.md "$CLAUDE_SKILL_DIR/"
  cp skills/code-explorer/lang/*.md "$CLAUDE_SKILL_DIR/lang/"
  cp skills/code-explorer/scripts/*.sh "$CLAUDE_SKILL_DIR/scripts/"
  chmod +x "$CLAUDE_SKILL_DIR/scripts/"*.sh

  sed -i.bak "s|\${CLAUDE_SKILL_DIR}|$CLAUDE_SKILL_DIR|g" "$CLAUDE_SKILL_DIR/SKILL.md"
  rm -f "$CLAUDE_SKILL_DIR/SKILL.md.bak"

  echo "  ✅ Skill 安装完成：$CLAUDE_SKILL_DIR"

  if [ -d ".git" ]; then
    echo ""
    echo "🪝 安装 Git Hooks..."

    cp git-hooks/pre-commit .git/hooks/pre-commit
    cp git-hooks/commit-msg .git/hooks/commit-msg
    chmod +x .git/hooks/pre-commit .git/hooks/commit-msg

    echo "  ✅ pre-commit  → shellcheck 检查暂存的 .sh 文件"
    echo "  ✅ commit-msg  → Conventional Commits 格式验证"
  else
    echo ""
    echo "  ℹ️  未检测到 .git 目录，跳过 Git Hooks 安装"
  fi

  echo ""
  echo "🪝 安装 Claude Code Hooks..."

  mkdir -p "$CLAUDE_HOOKS_DIR"
  cp scripts/post-bash.sh "$CLAUDE_HOOKS_DIR/"
  cp scripts/post-read.sh "$CLAUDE_HOOKS_DIR/"
  cp scripts/on-stop.sh "$CLAUDE_HOOKS_DIR/"
  cp scripts/pre-prompt.sh "$CLAUDE_HOOKS_DIR/"
  chmod +x "$CLAUDE_HOOKS_DIR/"*.sh

  echo "  ✅ Hooks 复制至：$CLAUDE_HOOKS_DIR"

  echo ""
  echo "⚙️  注册 Hooks 到 $CLAUDE_SETTINGS_FILE ..."

  python3 - <<PYEOF
import json
from pathlib import Path

settings_file = Path("$CLAUDE_SETTINGS_FILE")
hooks_dir = "$CLAUDE_HOOKS_DIR"

try:
    settings = json.loads(settings_file.read_text()) if settings_file.exists() else {}
except (json.JSONDecodeError, OSError):
    settings = {}

hooks = settings.setdefault("hooks", {})

def remove_ce(hook_list):
    return [
        h for h in hook_list
        if not any("code-explorer" in hk.get("command", "") for hk in h.get("hooks", []))
    ]

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

prompt_hooks = remove_ce(hooks.get("UserPromptSubmit", []))
prompt_hooks += [
    {
        "hooks": [{"type": "command", "command": f"{hooks_dir}/pre-prompt.sh"}]
    }
]
hooks["UserPromptSubmit"] = prompt_hooks

stop_hooks = remove_ce(hooks.get("Stop", []))
stop_hooks += [
    {
        "hooks": [{"type": "command", "command": f"{hooks_dir}/on-stop.sh"}]
    }
]
hooks["Stop"] = stop_hooks

settings["hooks"] = hooks
settings_file.parent.mkdir(parents=True, exist_ok=True)
settings_file.write_text(json.dumps(settings, indent=2, ensure_ascii=False) + "\n")
print("  ✅ settings.json 更新成功")
PYEOF

  echo ""
  echo "Claude Code 用法："
  echo "  /code-explorer <文件路径或函数名>"
  echo "  或直接描述：「帮我理解 [函数名] 的执行流程」"
}

install_codex() {
  echo ""
  echo "🤖 安装 Codex skill..."

  backup_dir_if_needed "$CODEX_SKILL_DIR"

  mkdir -p "$CODEX_SKILL_DIR/agents" "$CODEX_SKILL_DIR/lang" "$CODEX_SKILL_DIR/scripts"
  cp codex-skills/code-explorer/SKILL.md "$CODEX_SKILL_DIR/"
  cp codex-skills/code-explorer/context-mgmt.md "$CODEX_SKILL_DIR/"
  cp codex-skills/code-explorer/error-handling.md "$CODEX_SKILL_DIR/"
  cp codex-skills/code-explorer/suggestion-mode.md "$CODEX_SKILL_DIR/"
  cp codex-skills/code-explorer/lang/*.md "$CODEX_SKILL_DIR/lang/"
  cp codex-skills/code-explorer/scripts/*.sh "$CODEX_SKILL_DIR/scripts/"
  cp codex-skills/code-explorer/agents/openai.yaml "$CODEX_SKILL_DIR/agents/"
  chmod +x "$CODEX_SKILL_DIR/scripts/"*.sh

  echo "  ✅ Skill 安装完成：$CODEX_SKILL_DIR"
  echo ""
  echo "Codex 用法："
  echo "  使用 \$code-explorer 帮我梳理这个仓库的架构、关键调用链和设计意图"
  echo "  或直接描述：「帮我解释 handleRequest 的执行流程」"
}

if [ $# -eq 0 ]; then
  INSTALL_CLAUDE=true
else
  while [ $# -gt 0 ]; do
    case "$1" in
      --claude)
        INSTALL_CLAUDE=true
        ;;
      --codex)
        INSTALL_CODEX=true
        ;;
      --all)
        INSTALL_CLAUDE=true
        INSTALL_CODEX=true
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

if [ "$INSTALL_CLAUDE" = false ] && [ "$INSTALL_CODEX" = false ]; then
  usage >&2
  exit 1
fi

if [ "$INSTALL_CLAUDE" = true ]; then
  install_claude
fi

if [ "$INSTALL_CODEX" = true ]; then
  install_codex
fi

echo ""
echo "🎉 安装完成！"
