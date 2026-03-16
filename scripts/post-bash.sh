#!/bin/bash
# PostToolUse → Bash
# 检测 code-explorer 脚本调用，验证输出格式，并创建会话标记
#
# 会话标记路径: /tmp/code-explorer-session-<session_id>
# 该标记供 post-read.sh 和 on-stop.sh 判断是否处于 code-explorer 会话

INPUT=$(cat)

# 解析 JSON（优先用 jq，回退到 python3）
if command -v jq &>/dev/null; then
  SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "global"' 2>/dev/null)
  COMMAND=$(echo "$INPUT"   | jq -r '.tool_input.command // empty' 2>/dev/null)
  STDOUT=$(echo "$INPUT"    | jq -r '.tool_response.output // empty' 2>/dev/null)
else
  SESSION_ID=$(echo "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('session_id','global'))" 2>/dev/null)
  COMMAND=$(echo "$INPUT"   | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null)
  STDOUT=$(echo "$INPUT"    | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_response',{}).get('output',''))" 2>/dev/null)
fi

MARKER="/tmp/code-explorer-session-${SESSION_ID}"

# detect_lang.sh：验证语言识别结果，创建会话标记
if echo "$COMMAND" | grep -q "detect_lang\.sh"; then
  touch "$MARKER"
  if echo "$STDOUT" | grep -q "^lang="; then
    LANG=$(echo "$STDOUT" | grep "^lang=" | cut -d= -f2)
    echo "[code-explorer] 语言识别成功: $LANG" >&2
  else
    echo "⚠️  [code-explorer] detect_lang.sh 未能识别语言，请检查项目结构" >&2
  fi
fi

# find_entry.sh：记录入口点扫描完成
if echo "$COMMAND" | grep -q "find_entry\.sh"; then
  ENTRY_COUNT=$(echo "$STDOUT" | grep -c "^\./")
  echo "[code-explorer] 入口点扫描完成，找到 $ENTRY_COUNT 个候选路径" >&2
fi

# git_context.sh：记录 git 上下文获取完成
if echo "$COMMAND" | grep -q "git_context\.sh"; then
  COMMIT_COUNT=$(echo "$STDOUT" | grep -c "^[a-f0-9]\{7\}")
  echo "[code-explorer] Git 上下文已加载（最近 $COMMIT_COUNT 条提交）" >&2
fi