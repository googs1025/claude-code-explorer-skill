# JavaScript / TypeScript 源码分析专项策略

## 核心阅读顺序

1. `package.json` → `main`/`exports`/`scripts` 字段，了解入口和构建流程
2. `tsconfig.json` → 路径别名（`paths`），了解模块解析规则
3. `src/index.ts` 或 `src/main.ts` → 应用入口
4. `src/types/` 或 `*.d.ts` → 全局类型定义，理解核心数据结构
5. 框架配置文件（`next.config.js` / `vite.config.ts`）→ 构建和路由配置

## 模块系统判断

| 特征 | 类型 |
|------|------|
| `import/export` | ESM |
| `require/module.exports` | CommonJS |
| `"type": "module"` in package.json | 纯 ESM |
| 混用两者 | 注意 interop 问题 |

## 关键语法模式识别

| 模式 | 含义 | 搜索方式 |
|------|------|---------|
| `async/await` | 异步控制流 | Grep `async function\|async \(` |
| `Promise.all/race` | 并发处理 | Grep `Promise\.(all\|race\|allSettled)` |
| `useEffect/useState` | React 副作用和状态 | Grep `useEffect\|useState` |
| `createSlice/createStore` | Redux 状态管理 | Grep `createSlice\|configureStore` |
| `z.object\|z.string` | Zod 校验 | Grep `z\.object\|z\.string` |
| `@Injectable` | NestJS 依赖注入 | Grep `@Injectable\|@Controller` |

## 框架快速识别

- **Next.js**：`pages/` 或 `app/` 目录，`getServerSideProps`，`layout.tsx`
- **React SPA**：`src/App.tsx`，`ReactDOM.render`，`BrowserRouter`
- **Express/Fastify**：`app.use`/`app.get`，中间件链
- **NestJS**：`@Module`，`@Controller`，`@Injectable` 三件套
- **Vue**：`*.vue` SFC，`<script setup>`，`defineComponent`

## 依赖关系追踪

```bash
# 找所有导入关系
grep -r "^import\|^const.*require" --include="*.ts" --include="*.js" . \
  | grep -v "node_modules" | head -30

# 找路径别名使用
grep -r "from '@/" --include="*.ts" . | grep -v node_modules | head -20
```

## 性能与安全热点

- `Grep "dangerouslySetInnerHTML"` → XSS 风险
- `Grep "eval("` → 代码注入风险
- `Grep "JSON.parse"` → 大数据解析，考虑流式
- `Grep "setTimeout\|setInterval"` → 计时器泄漏（是否清理？）
- `Grep "localStorage\|sessionStorage"` → 敏感数据存储位置

## 类型安全检查

```bash
# TypeScript 严格模式
grep '"strict"' tsconfig.json

# any 类型滥用
grep -r ": any\|as any" --include="*.ts" . | grep -v node_modules | wc -l
```

## 改进建议检测模式

以下 Grep 模式用于**建议模式**下检测 JS/TS 项目的常见改进点：

### 🐛 代码质量
- `Grep ": any\|as any"` → TypeScript `any` 类型滥用，建议用具体类型或 `unknown` 替代
- `Grep "console\.log\|console\.debug"` → 调试日志残留，建议移除或用 logger 替代
- `Grep "var "` → 使用 `var` 声明，建议改用 `const`/`let`
- `Grep "== \| != "` + 非 `===`/`!==` → 宽松比较，建议用严格比较

### 🔒 安全加固
- `Grep "dangerouslySetInnerHTML"` → XSS 风险，建议用安全的渲染方式或 sanitize
- `Grep "eval("` → 代码注入风险，建议移除
- `Grep "localStorage\|sessionStorage"` + 敏感数据 → 建议用 httpOnly cookie 或加密
- `Grep "cors.*origin.*\*\|Access-Control-Allow-Origin.*\*"` → CORS 过于宽松

### ⚡ 性能优化
- `Grep "useEffect\("` 无依赖数组或依赖过多 → 可能触发不必要的重渲染
- `Grep "\.map(\|\.filter(\|\.reduce("` 链式调用 → 大数组可合并为单次遍历
- `Grep "new Date()\|Date\.now()"` 在渲染函数中 → 建议提取到 memo/useMemo
- `Grep "JSON\.parse\|JSON\.stringify"` 在热路径 → 大对象考虑流式处理

### 🧪 测试覆盖
- `Glob "**/*.test.{ts,tsx,js,jsx}"` / `Glob "**/*.spec.{ts,tsx,js,jsx}"` → 检查核心模块是否有测试
- 缺少 `jest.config` / `vitest.config` → 建议配置测试框架
- React 组件缺少 Error Boundary → 建议为关键 UI 区域增加错误边界

### 📝 文档与 DX
- 缺少 `.eslintrc` / `eslint.config` → 建议配置 ESLint
- 缺少 `.prettierrc` → 建议配置 Prettier 统一代码风格
- `Grep "// TODO\|// FIXME\|// HACK"` → 未完成的实现，建议跟踪解决
- `tsconfig.json` 中 `"strict": false` 或缺失 → 建议开启 TypeScript 严格模式

## 推荐 ASCII art 图类型

- 组件树 → 树形缩进图（`├──` / `└──` 连线）
- API 请求流 → ASCII 时序图（竖线 + 箭头）
- 路由结构 → ASCII 水平流程图（方框 + `-->` 箭头）
- Redux/Zustand 状态流 → ASCII 状态转换图