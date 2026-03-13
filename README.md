# code-explorer — Claude Code 源码解读 Skill

一个为 [Claude Code](https://claude.ai/code) 设计的源码探索 Skill，帮助你快速读懂陌生代码库。

## 功能特点

- **三种分析模式**：快速解答（单函数）/ 标准分析（单模块）/ 深度探索（整项目）
- **多语言专项策略**：Go、Python、JavaScript/TypeScript 各有专属分析套路
- **参考脚本自动化**：自动检测语言、查找入口点、获取 Git 历史上下文
- **Mermaid 可视化**：自动生成架构图、时序图、状态机图
- **Git 洞察**：结合提交历史解释代码演变背景

## 安装

### 方式一：一键脚本（推荐）

```bash
git clone https://github.com/googs1025/claude-code-explorer-skill.git
cd claude-code-explorer-skill
bash install.sh
```

### 方式二：手动安装

```bash
mkdir -p ~/.claude/skills/code-explorer/lang ~/.claude/skills/code-explorer/scripts

cp SKILL.md ~/.claude/skills/code-explorer/
cp lang/*.md ~/.claude/skills/code-explorer/lang/
cp scripts/*.sh ~/.claude/skills/code-explorer/scripts/
chmod +x ~/.claude/skills/code-explorer/scripts/*.sh
```

## 使用方式

安装后，在 Claude Code 中用以下任意方式触发：

```
# 显式调用
/code-explorer src/main.go
/code-explorer handleRequest

# 自然语言触发（自动识别）
帮我理解 handleRequest 的执行流程
解释这个项目的架构
这段代码的核心逻辑是什么
为什么这里要用 goroutine？
```

## 分析模式

| 模式 | 触发条件 | 输出 |
|------|---------|------|
| **快速模式** | 单函数、单变量、单行疑问 | 简洁解释 + 注意点 |
| **标准模式** | 单个文件、单个模块 | 完整四阶段分析 + Mermaid 图 |
| **深度模式** | 整个项目、架构梳理 | 宏观扫描 → 确认范围 → 深入分析 |

## 支持语言

| 语言 | 策略文件 | 特色检查 |
|------|---------|---------|
| **Go** | `lang/go.md` | goroutine 泄漏、channel 死锁、interface 边界 |
| **Python** | `lang/python.md` | 框架识别、循环导入、装饰器追踪 |
| **JavaScript/TypeScript** | `lang/javascript.md` | XSS 风险、类型安全、框架路由 |
| 其他语言 | 通用策略 | 基础架构分析 |

## 参考脚本

| 脚本 | 功能 |
|------|------|
| `scripts/detect_lang.sh` | 检测项目语言、版本、框架 |
| `scripts/find_entry.sh <lang>` | 按语言查找入口点和路由注册 |
| `scripts/git_context.sh [file]` | 获取 Git 历史、活跃文件、贡献者 |

## 输出示例

**标准模式输出结构：**

```
## 🧭 核心功能摘要
[≤50 字概括]

## 🏗️ 架构/流程图
[Mermaid 图表]

## 🔍 关键逻辑拆解
入口点 → 核心流程 → 数据流向

## 💡 深度洞察
设计意图 / 关键依赖 / Git 背景 / 注意事项

## ❓ 建议深入探索
[引导性问题]
```

## 项目结构

```
claude-code-explorer-skill/
├── SKILL.md               # Claude Code skill 主文件
├── install.sh             # 一键安装脚本
├── lang/
│   ├── go.md              # Go 专项分析策略
│   ├── python.md          # Python 专项分析策略
│   └── javascript.md      # JS/TS 专项分析策略
└── scripts/
    ├── detect_lang.sh     # 语言检测脚本
    ├── git_context.sh     # Git 上下文脚本
    └── find_entry.sh      # 入口点查找脚本
```

## 卸载

```bash
rm -rf ~/.claude/skills/code-explorer
```

## License

MIT
