#!/bin/bash
# Stop hook
# code-explorer 会话结束时：输出统计信息，清理临时文件

INPUT=$(cat)

if command -v jq &>/dev/null; then
  SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "global"' 2>/dev/null)
else
  SESSION_ID=$(echo "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('session_id','global'))" 2>/dev/null)
fi

MARKER="/tmp/code-explorer-session-${SESSION_ID}"
COUNTER="/tmp/code-explorer-reads-${SESSION_ID}"

# 只在 code-explorer 会话中执行
[ -f "$MARKER" ] || exit 0

COUNT=$(cat "$COUNTER" 2>/dev/null || echo 0)
echo "[code-explorer] 分析完成 — 本次会话共读取 $COUNT 个文件" >&2

# 清理临时文件
rm -f "$MARKER" "$COUNTER"