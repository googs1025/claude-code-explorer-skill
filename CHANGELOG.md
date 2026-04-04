# Changelog

## [1.1.0] - 2026-04-04

### Added

- 新增 `codex-skills/code-explorer/`，提供 Codex 专用 Skill 目录
- 新增 `codex-skills/code-explorer/agents/openai.yaml`，补充 Codex UI 元数据

### Changed

- `install.sh` 新增 `--claude`、`--codex`、`--all` 参数，支持双端安装
- `uninstall.sh` 新增 `--claude`、`--codex`、`--all` 参数，支持双端卸载
- `README.md` 更新为同时覆盖 Claude Code 与 Codex 的安装和使用方式

## [1.0.0] - 2026-03-16

### Changed

- **项目重构为 Claude Code Plugin 格式**
  - 新增 `.claude-plugin/plugin.json` 和 `marketplace.json` 插件清单
  - Skill 文件移至 `skills/code-explorer/` 目录
  - Hook 脚本从 `claude-hooks/` 移至 `scripts/`
  - 新增 `hooks/hooks.json` 声明式 Hook 配置

- **SKILL.md 路径引用改为变量**
  - 所有 `~/.claude/skills/code-explorer/` 硬编码路径替换为 `${CLAUDE_SKILL_DIR}/`
  - 支持 Plugin 运行时自动解析路径

- **Hook 脚本优化**
  - `post-bash.sh` grep 匹配模式从完整路径简化为脚本文件名
  - 兼容 Plugin 和 Legacy 两种安装方式

- **安装方式更新**
  - Plugin 安装为推荐方式：`claude plugin add github:googs1025/claude-code-explorer-skill`
  - `install.sh` / `uninstall.sh` 保留为 Legacy 方式，添加 Plugin 推荐提示
  - Legacy 安装时自动将 `${CLAUDE_SKILL_DIR}` 替换为实际路径

### Added

- `.claude-plugin/plugin.json` — 插件清单
- `.claude-plugin/marketplace.json` — 市场目录
- `hooks/hooks.json` — 声明式 Hook 配置
- `CHANGELOG.md` — 变更日志

## [0.1.0] - 2025-xx-xx

### Added

- 初始版本发布
- 三种分析模式：快速/标准/深度
- Go、Python、JavaScript/TypeScript 语言专项策略
- 三个辅助脚本：detect_lang.sh、find_entry.sh、git_context.sh
- 四个 Claude Code Hooks：pre-prompt、post-bash、post-read、on-stop
- Git Hooks：pre-commit（shellcheck）、commit-msg（Conventional Commits）
