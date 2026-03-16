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

## 推荐 Mermaid 图类型

- 组件树 → `flowchart TD`
- API 请求流 → `sequenceDiagram`
- 路由结构 → `flowchart LR`
- Redux/Zustand 状态流 → `stateDiagram-v2`