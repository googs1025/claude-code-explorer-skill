#!/bin/bash
# PostToolUse → Read
# 追踪 code-explorer 会话中读取的文件数，在接近约束上限时提醒
#
# Phase 1 上限：5 个文件（仅读签名和注释）
# 总体上限：超过 10 个文件时主动告知用户

INPUT=$(cat)

if command -v jq &>/dev/null; then
  SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "global"' 2>/dev/null)
else
  SESSION_ID=$(echo "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('session_id','global'))" 2>/dev/null)
fi

MARKER="/tmp/code-explorer-session-${SESSION_ID}"
COUNTER="/tmp/code-explorer-reads-${SESSION_ID}"

# 只在 code-explorer 会话中计数（需要 post-bash.sh 先创建标记）
[ -f "$MARKER" ] || exit 0

COUNT=$(cat "$COUNTER" 2>/dev/null || echo 0)
COUNT=$((COUNT + 1))
echo "$COUNT" > "$COUNTER"

case $COUNT in
  5)
    echo "📊 [code-explorer] Phase 1 提醒：已读取 5 个文件，建议后续按需深读" >&2
    ;;
  11)
    echo "⚠️  [code-explorer] 已读取超过 10 个文件，请确认是否需要告知用户分步分析" >&2
    ;;
esac