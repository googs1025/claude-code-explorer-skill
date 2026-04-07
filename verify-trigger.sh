#!/bin/bash
# verify-trigger.sh
# 模拟用户提问，验证 code-explorer skill 是否被正确触发
# 用法：bash verify-trigger.sh [prompt]
#   - 无参数：运行完整模拟对话
#   - 有参数：测试单条 prompt

DEEP_KEYWORDS="架构|整体|全项目|梳理|模块关系|整个|设计|overview|architecture|project"
EXPLORE_ACTION="解释|理解|追踪|流程|实现|怎么|如何|为什么|explain|trace|how|why"
EXPLORE_CONTEXT="代码|函数|模块|文件|项目|架构|类|接口|类型|代码库|codebase|class|function|module|file|code"

detect_trigger() {
  local PROMPT="$1"
  local IS_DEEP=0 IS_EXPLORE=0

  echo "$PROMPT" | grep -qiE "$DEEP_KEYWORDS" && IS_DEEP=1

  if echo "$PROMPT" | grep -qiE "code-explorer"; then
    IS_EXPLORE=1
  elif echo "$PROMPT" | grep -qiE "$EXPLORE_ACTION" && echo "$PROMPT" | grep -qiE "$EXPLORE_CONTEXT"; then
    IS_EXPLORE=1
  fi

  if [ $IS_DEEP -eq 1 ] || [ $IS_EXPLORE -eq 1 ]; then
    local REASON=""
    [ $IS_DEEP -eq 1 ]    && REASON="深度关键词"
    [ $IS_EXPLORE -eq 1 ] && REASON="${REASON:+$REASON + }探索意图"
    echo "TRIGGER|$REASON"
  else
    echo "SKIP|"
  fi
}

simulate() {
  local PROMPT="$1"
  local EXPECTED="$2"   # TRIGGER | SKIP

  local RESULT REASON STATUS
  RESULT=$(detect_trigger "$PROMPT")
  STATUS="${RESULT%%|*}"
  REASON="${RESULT##*|}"

  printf "\033[90m  User ›\033[0m %s\n" "$PROMPT"

  if [ "$STATUS" = "TRIGGER" ]; then
    printf "  \033[36mClaude ›\033[0m \033[32m[code-explorer 已触发]\033[0m  \033[90m← %s\033[0m\n" "$REASON"
  else
    printf "  \033[36mClaude ›\033[0m \033[90m[跳过，普通回复]\033[0m\n"
  fi

  # 回归断言
  if [ "$STATUS" != "$EXPECTED" ]; then
    printf "  \033[31m⚠ 断言失败：期望 %s，实际 %s\033[0m\n" "$EXPECTED" "$STATUS"
    return 1
  fi
  return 0
}

# ── 单条模式 ────────────────────────────────────────────────────────────────
if [ $# -ge 1 ]; then
  simulate "$*" "$(detect_trigger "$*" | cut -d'|' -f1)"
  exit 0
fi

# ── 模拟对话 ────────────────────────────────────────────────────────────────
PASS=0; FAIL=0

run() {
  simulate "$1" "$2" && PASS=$((PASS+1)) || FAIL=$((FAIL+1))
  echo ""
}

echo ""
printf "\033[1m╔══════════════════════════════════════════════════════╗\033[0m\n"
printf "\033[1m║        code-explorer  触发验证 · 模拟对话            ║\033[0m\n"
printf "\033[1m╚══════════════════════════════════════════════════════╝\033[0m\n"

echo ""
printf "\033[33m▸ 场景一：代码理解 / 深度分析\033[0m\n\n"
run "帮我梳理这个项目的架构"              TRIGGER
run "这段代码怎么工作的"                  TRIGGER
run "帮我解释这个函数"                    TRIGGER
run "追踪这个接口的调用流程"              TRIGGER
run "我想理解这个模块的实现"              TRIGGER
run "为什么这段代码这样写"               TRIGGER

echo ""
printf "\033[33m▸ 场景二：英文提问\033[0m\n\n"
run "give me an overview of this repo"    TRIGGER
run "what is the architecture here"       TRIGGER
run "can you explain this function"       TRIGGER
run "how does this code work"             TRIGGER
run "trace the flow through the module"   TRIGGER

echo ""
printf "\033[33m▸ 场景三：显式命令\033[0m\n\n"
run "/code-explorer main.go"              TRIGGER

echo ""
printf "\033[33m▸ 场景四：无关请求（不应触发）\033[0m\n\n"
run "帮我写一个排序函数"                  SKIP
run "fix the null pointer bug"            SKIP
run "generate unit tests for this"        SKIP
run "帮我提交代码"                        SKIP
run "你好"                                SKIP
run "please deploy the service"           SKIP

# ── 汇总 ────────────────────────────────────────────────────────────────────
TOTAL=$((PASS+FAIL))
printf "\033[1m──────────────────────────────────────────────────────\033[0m\n"
if [ $FAIL -eq 0 ]; then
  printf "  \033[32m✓ 全部通过 %d/%d\033[0m\n" "$PASS" "$TOTAL"
else
  printf "  \033[31m✗ 失败 %d 条\033[0m，通过 %d/%d\n" "$FAIL" "$PASS" "$TOTAL"
fi
printf "\033[1m──────────────────────────────────────────────────────\033[0m\n"
echo ""