# Go 源码分析专项策略

## 核心阅读顺序

1. `go.mod` → 确认模块名、Go 版本、关键依赖
2. `cmd/` 目录 → 多二进制项目的各入口
3. `internal/` → 私有核心逻辑（外部不可引用）
4. `pkg/` → 可复用库代码
5. `main.go` → 程序起点，看 `init()` 和 `main()`

## 关键语法模式识别

| 模式 | 含义 | 搜索方式 |
|------|------|---------|
| `interface { ... }` | 抽象契约，理解系统边界 | Grep `type \w+ interface` |
| `func (r *Receiver)` | 方法挂载，理解对象职责 | Grep `func \(\w+ \*\w+\)` |
| `go func()` | goroutine，注意并发安全 | Grep `go func` |
| `chan ` | 通道通信，追踪数据流 | Grep `chan ` |
| `context.Context` | 生命周期管理，找取消/超时逻辑 | Grep `ctx context.Context` |
| `sync.Mutex` / `sync.RWMutex` | 锁，关注竞态条件 | Grep `sync\.` |

## 架构模式判断

- **标准库风格**：`net/http` + handler，看 `ServeHTTP`
- **gRPC 服务**：`.proto` 文件 + `pb.go` 生成代码，看 `Register*Server`
- **CLI 工具**：`cobra` / `flag`，看 `rootCmd` 或 `flag.Parse()`
- **微服务框架**：`gin`/`echo`/`fiber`，看路由注册

## 并发陷阱检查点

```
- goroutine 泄漏：go func() 是否有退出条件？
- 数据竞争：共享变量是否都加锁？
- channel 死锁：发送/接收是否配对？
- context 传播：是否所有 goroutine 都接收 ctx？
```

## 性能热点

- `Grep "for .* range"` → 找循环，关注 O(n²) 嵌套
- `Grep "append("` → 频繁扩容？考虑预分配
- `Grep "json.Marshal\|json.Unmarshal"` → 热路径上的序列化开销
- `Grep "db.Query\|db.Exec"` → N+1 查询问题

## 测试覆盖情况

```bash
# 查看测试文件
find . -name "*_test.go" | grep -v vendor

# 覆盖率（如果能运行）
go test ./... -coverprofile=coverage.out
go tool cover -func=coverage.out | tail -1
```

## 改进建议检测模式

以下 Grep 模式用于**建议模式**下检测 Go 项目的常见改进点：

### 🐛 代码质量
- `Grep "if err != nil {\s*return err\s*}"` → 错误无上下文包装，建议用 `fmt.Errorf("...: %w", err)` 包装
- `Grep "interface {"` + 方法数 > 5 → 接口过大，建议拆分为更小的接口（接口隔离原则）
- `Grep "func \w+\("` + 参数数 > 5 → 函数参数过多，建议用结构体封装

### 🔒 安全加固
- `Grep "sql\.Query.*\+\|Sprintf.*sql"` → SQL 拼接注入风险，建议用参数化查询
- `Grep "http\.ListenAndServe\("` → 无 TLS，建议用 `ListenAndServeTLS`
- `Grep "os\.Getenv\("` → 环境变量未校验，建议增加默认值和类型检查

### ⚡ 性能优化
- `Grep "for .* range"` 嵌套 → O(n²) 风险，建议用 map 优化
- `Grep "json\.Marshal\|json\.Unmarshal"` 在热路径 → 考虑 `easyjson`/`sonic`
- `Grep "append("` 在循环中 → 建议预分配 slice 容量

### 🧪 测试覆盖
- `Glob "**/*_test.go"` → 检查核心包是否有对应测试文件
- 缺少 `TestMain` → 建议增加测试初始化/清理
- 缺少 table-driven tests → 建议对核心函数使用表驱动测试

### 📝 文档与 DX
- `Grep "^func [A-Z]"` 无 `//` 注释前缀 → 导出函数缺少 godoc 注释
- 缺少 `Makefile` 或 `go generate` → 建议增加构建自动化
- 缺少 `.golangci.yml` → 建议配置 golangci-lint

## 推荐 ASCII art 图类型

- 包依赖关系 → ASCII 垂直流程图（方框 + `-->` 箭头）
- 请求处理链 → ASCII 时序图（竖线 + 箭头）
- goroutine 生命周期 → ASCII 状态转换图（方框 + 带条件箭头）
- 错误传播路径 → ASCII 水平流程图（方框 + `-->` 箭头）
