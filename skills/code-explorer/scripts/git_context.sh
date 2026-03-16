#!/bin/bash
# 获取目标文件/目录的 Git 历史上下文
# 用法: ./git_context.sh [文件路径]

FILE="${1:-}"

if ! git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
  echo "（不在 git 仓库中）"
  exit 0
fi

echo "=== 仓库最近 10 次提交 ==="
git log --oneline -10 2>/dev/null

echo ""
echo "=== 近期活跃文件（最近 30 天）==="
git log --since="30 days ago" --name-only --format="" 2>/dev/null \
  | grep -v '^$' | sort | uniq -c | sort -rn | head -10

if [ -n "$FILE" ] && [ -e "$FILE" ]; then
  echo ""
  echo "=== $FILE 的变更历史（最近 5 次）==="
  git log --oneline -5 -- "$FILE" 2>/dev/null

  echo ""
  echo "=== $FILE 的主要贡献者 ==="
  git log --format="%an" -- "$FILE" 2>/dev/null | sort | uniq -c | sort -rn | head -5
fi