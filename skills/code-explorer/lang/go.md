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

## 推荐 Mermaid 图类型

- 包依赖关系 → `flowchart TD`
- 请求处理链 → `sequenceDiagram`
- goroutine 生命周期 → `stateDiagram-v2`
- 错误传播路径 → `flowchart LR`
