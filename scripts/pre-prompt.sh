#!/bin/bash
# UserPromptSubmit hook
# 检测深度分析意图，向用户确认分析范围后注入结构化配置到 Claude 上下文

INPUT=$(cat)

# 解析 prompt 文本
if command -v jq &>/dev/null; then
  PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)
else
  PROMPT=$(echo "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('prompt',''))" 2>/dev/null)
fi

# ── 关键词检测：判断是否为深度分析请求 ───────────────────────────────────────
DEEP_KEYWORDS="架构|整体|全项目|梳理|模块关系|整个|设计|overview|architecture|project"
EXPLORE_KEYWORDS="解释|理解|追踪|流程|实现|怎么|如何|为什么|explain|trace|how|why|code-explorer"

IS_DEEP=0
IS_EXPLORE=0

echo "$PROMPT" | grep -qiE "$DEEP_KEYWORDS"    && IS_DEEP=1
echo "$PROMPT" | grep -qiE "$EXPLORE_KEYWORDS" && IS_EXPLORE=1

# 既不是深度也不是探索请求，直接退出（不注入任何内容）
[ $IS_DEEP -eq 0 ] && [ $IS_EXPLORE -eq 0 ] && exit 0

# ── 检测 TTY 是否可用 ────────────────────────────────────────────────────────
HAS_TTY=0
if [ -t 0 ] || [ -c /dev/tty ] 2>/dev/null; then
  # 尝试用超短超时测试 TTY 是否真的可读
  if echo "" | timeout 1 cat </dev/tty >/dev/null 2>&1; then
    HAS_TTY=1
  fi
fi

READ_TIMEOUT=10  # 每个交互问题的超时秒数

if [ "$HAS_TTY" -eq 1 ]; then
  # ── TTY 可用：交互式选择（带超时保护）──────────────────────────────────────
  echo "" >&2
  echo "┌─ code-explorer 分析配置 ─────────────────────────────┐" >&2

  echo "│" >&2
  echo "│  ① 分析范围" >&2
  echo "│     [1] 全项目（所有模块）  [2] 指定目录  [3] 单个文件" >&2
  printf "│  选择 (默认 1, ${READ_TIMEOUT}s 超时): " >&2
  read -r -t "$READ_TIMEOUT" SCOPE_CHOICE </dev/tty 2>/dev/null || true
  SCOPE_CHOICE="${SCOPE_CHOICE:-1}"

  case "$SCOPE_CHOICE" in
    2)
      printf "│  输入目录路径: " >&2
      read -r -t "$READ_TIMEOUT" SCOPE_PATH </dev/tty 2>/dev/null || true
      SCOPE="指定目录: ${SCOPE_PATH:-.}"
      ;;
    3)
      printf "│  输入文件路径: " >&2
      read -r -t "$READ_TIMEOUT" SCOPE_PATH </dev/tty 2>/dev/null || true
      SCOPE="单个文件: ${SCOPE_PATH}"
      ;;
    *)
      SCOPE="全项目（所有模块）"
      ;;
  esac

  echo "│" >&2
  echo "│  ② 关注重点" >&2
  echo "│     [1] 整体架构与模块关系  [2] 数据流与调用链  [3] 性能与潜在风险" >&2
  printf "│  选择 (默认 1, ${READ_TIMEOUT}s 超时): " >&2
  read -r -t "$READ_TIMEOUT" FOCUS_CHOICE </dev/tty 2>/dev/null || true
  FOCUS_CHOICE="${FOCUS_CHOICE:-1}"

  case "$FOCUS_CHOICE" in
    2) FOCUS="数据流与调用链" ;;
    3) FOCUS="性能与潜在风险" ;;
    *) FOCUS="整体架构与模块关系" ;;
  esac

  echo "│" >&2
  echo "│  ③ 输出详细度" >&2
  echo "│     [1] 简洁摘要  [2] 标准分析（推荐）  [3] 完整深度报告" >&2
  printf "│  选择 (默认 2, ${READ_TIMEOUT}s 超时): " >&2
  read -r -t "$READ_TIMEOUT" DETAIL_CHOICE </dev/tty 2>/dev/null || true
  DETAIL_CHOICE="${DETAIL_CHOICE:-2}"

  case "$DETAIL_CHOICE" in
    1) DETAIL="简洁摘要（省略图表，输出要点）" ;;
    3) DETAIL="完整深度报告（含所有图表、Git 洞察、风险列表）" ;;
    *) DETAIL="标准分析（含 Mermaid 图表）" ;;
  esac

  echo "│" >&2
  echo "└──────────────────────────────────────────────────────┘" >&2
  echo "" >&2
else
  # ── TTY 不可用：静默使用默认值 ─────────────────────────────────────────────
  SCOPE="全项目（所有模块）"
  FOCUS="整体架构与模块关系"
  DETAIL="标准分析（含 Mermaid 图表）"
  echo "[code-explorer] TTY 不可用，使用默认配置（全项目/架构/标准分析）" >&2
fi

# ── 将配置注入到 stdout（追加到用户消息作为上下文）──────────────────────────
cat <<EOF

[code-explorer 分析配置 - 用户已确认]
- 分析范围: $SCOPE
- 关注重点: $FOCUS
- 输出详细度: $DETAIL

请严格按照以上配置执行分析，无需再次询问用户范围。
EOF
