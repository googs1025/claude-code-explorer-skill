#!/bin/bash
# 检测项目主要编程语言，输出语言标识符

detect() {
  if [ -f "go.mod" ]; then
    LANG="go"
    VERSION=$(grep "^go " go.mod | awk '{print $2}')
    echo "lang=go"
    echo "version=$VERSION"
    echo "module=$(head -1 go.mod | awk '{print $2}')"
  elif [ -f "Cargo.toml" ]; then
    echo "lang=rust"
    echo "version=$(grep '^edition' Cargo.toml | head-1 | awk -F'"' '{print $2}')"
  elif [ -f "package.json" ]; then
    HAS_TS=$(find . -name "tsconfig.json" -maxdepth 3 | head -1)
    if [ -n "$HAS_TS" ]; then
      echo "lang=typescript"
    else
      echo "lang=javascript"
    fi
    echo "version=$(node -p "require('./package.json').version" 2>/dev/null)"
    echo "framework=$(node -p "Object.keys(require('./package.json').dependencies||{}).filter(d=>['react','vue','next','express','fastify'].includes(d)).join(',')" 2>/dev/null)"
  elif [ -f "pyproject.toml" ] || [ -f "requirements.txt" ] || [ -f "setup.py" ]; then
    echo "lang=python"
    echo "version=$(python3 --version 2>/dev/null | awk '{print $2}')"
  elif [ -f "pom.xml" ]; then
    echo "lang=java"
  else
    # 统计文件扩展名猜测
    TOP=$(find . -maxdepth 4 -type f \( -name "*.go" -o -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.rs" \) \
          2>/dev/null | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')
    echo "lang=${TOP:-unknown}"
  fi
}

detect