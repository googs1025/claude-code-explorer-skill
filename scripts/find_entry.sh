#!/bin/bash
# 根据语言查找项目入口点
# 用法: ./find_entry.sh <lang>

LANG="${1:-unknown}"

echo "=== 入口点扫描 (lang=$LANG) ==="

case "$LANG" in
  go)
    echo "-- main.go 文件 --"
    find . -name "main.go" -not -path "*/vendor/*" | head -5
    echo "-- cmd/ 目录 --"
    find . -type d -name "cmd" -not -path "*/vendor/*" | head -3
    echo "-- 暴露的 HTTP 路由关键词 --"
    grep -rl "http.HandleFunc\|mux.Handle\|router.GET\|r.GET" --include="*.go" . 2>/dev/null \
      | grep -v vendor | head -5
    ;;
  python)
    echo "-- 入口脚本 --"
    find . -name "main.py" -o -name "app.py" -o -name "run.py" -o -name "__main__.py" \
      2>/dev/null | grep -v ".venv" | head -5
    echo "-- Flask/FastAPI 路由 --"
    grep -rl "@app.route\|@router\|@app.get\|@app.post" --include="*.py" . 2>/dev/null \
      | grep -v ".venv" | head -5
    ;;
  javascript|typescript)
    echo "-- package.json main/scripts --"
    node -e "
      const p = require('./package.json');
      console.log('main:', p.main || '(未定义)');
      console.log('scripts:', JSON.stringify(p.scripts, null, 2));
    " 2>/dev/null
    echo "-- 路由文件 --"
    find . -name "router*" -o -name "routes*" -o -name "index.ts" -o -name "index.js" \
      -not -path "*/node_modules/*" 2>/dev/null | head -5
    ;;
  rust)
    echo "-- main.rs --"
    find . -name "main.rs" -not -path "*/target/*" | head -5
    echo "-- lib.rs (库入口) --"
    find . -name "lib.rs" -not -path "*/target/*" | head -3
    ;;
  java)
    echo "-- @SpringBootApplication / main 方法 --"
    grep -rl "SpringBootApplication\|public static void main" --include="*.java" . \
      2>/dev/null | head -5
    ;;
  *)
    echo "未识别语言 '$LANG'，列出顶层文件供参考："
    ls -la | head -20
    ;;
esac
