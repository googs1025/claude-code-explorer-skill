# Python 源码分析专项策略

## 核心阅读顺序

1. `pyproject.toml` / `setup.py` / `requirements.txt` → 依赖和版本
2. `__init__.py` → 每个包的公开接口（`__all__`）
3. `main.py` / `app.py` / `__main__.py` → 程序入口
4. `config.py` / `settings.py` → 配置中心，理解运行参数
5. `models/` → 数据模型（ORM / Pydantic）

## 关键语法模式识别

| 模式 | 含义 | 搜索方式 |
|------|------|---------|
| `class Foo(Bar)` | 继承关系，理解多态 | Grep `class \w+\(` |
| `@decorator` | 装饰器，理解 AOP 层 | Grep `^@\w+` |
| `async def` | 异步函数，追踪事件循环 | Grep `async def` |
| `yield` / `yield from` | 生成器，注意惰性求值 | Grep `yield` |
| `__dunder__` | 魔法方法，理解对象行为 | Grep `def __\w+__` |
| `TypeVar` / `Generic` | 泛型，理解类型约束 | Grep `TypeVar\|Generic` |

## 框架判断

- **Django**：`urls.py` + `views.py` + `models.py`（MTV 模式）
- **FastAPI**：`@app.get/post` + `Pydantic` 模型
- **Flask**：`@app.route` + `Blueprint`
- **Celery**：`@app.task` + `delay()/apply_async()`
- **SQLAlchemy**：`Base = declarative_base()` + `Column`

## 依赖注入 / 依赖追踪

```bash
# 查看导入关系（谁依赖谁）
grep -r "^from\|^import" --include="*.py" . | grep -v ".venv" | sort | head -30

# 找循环导入风险
grep -r "^from \." --include="*.py" . | grep -v ".venv" | head -20
```

## 性能热点

- `Grep "for .* in "` → 大列表遍历？考虑生成器
- `Grep "requests\."` → 同步 HTTP？考虑 aiohttp
- `Grep "time.sleep"` → 阻塞等待？是否应改为异步
- `Grep "SELECT \*"` → ORM 全字段查询，关注 N+1

## 常见代码坏味道

- `except:` 裸异常捕获（吞掉所有错误）
- `global` 变量（隐式状态）
- 函数超过 50 行（职责不清）
- `__init__` 中做复杂计算（延迟初始化）

## 推荐 Mermaid 图类型

- 类继承关系 → `classDiagram`
- 请求/任务处理流 → `sequenceDiagram`
- 状态机（状态模式）→ `stateDiagram-v2`