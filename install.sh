#!/bin/bash
# install.sh — 一键安装 code-explorer skill 到 Claude Code

SKILL_DIR="$HOME/.claude/skills/code-explorer"

echo "🔍 安装 code-explorer skill..."

# 备份已有版本
if [ -d "$SKILL_DIR" ]; then
  BACKUP="$SKILL_DIR.backup.$(date +%Y%m%d%H%M%S)"
  echo "  ⚠️  检测到已有版本，备份至 $BACKUP"
  mv "$SKILL_DIR" "$BACKUP"
fi

# 复制文件
mkdir -p "$SKILL_DIR/lang" "$SKILL_DIR/scripts"
cp SKILL.md "$SKILL_DIR/"
cp lang/*.md "$SKILL_DIR/lang/"
cp scripts/*.sh "$SKILL_DIR/scripts/"
chmod +x "$SKILL_DIR/scripts/"*.sh

echo "  ✅ 安装完成：$SKILL_DIR"
echo ""
echo "使用方式："
echo "  在 Claude Code 中输入："
echo "  /code-explorer <文件路径或函数名>"
echo "  或直接描述：「帮我理解 [函数名] 的执行流程」"
