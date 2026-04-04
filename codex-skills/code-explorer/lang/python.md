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

## 改进建议检测模式

以下 Grep 模式用于**建议模式**下检测 Python 项目的常见改进点：

### 🐛 代码质量
- `Grep "except:"` → 裸异常捕获，建议指定具体异常类型
- `Grep "def \w+\([^)]*\):"` 无类型注解 → 公开函数缺少类型注解，建议添加
- `Grep "class \w+:"` 无 `dataclass`/`Pydantic` → 纯数据类可用 `@dataclass` 或 `BaseModel` 替代
- `Grep "global "` → 全局变量使用，建议用类或闭包替代

### 🔒 安全加固
- `Grep "eval(\|exec("` → 代码注入风险，建议用 `ast.literal_eval` 或其他安全替代
- `Grep "subprocess\.call\|os\.system"` + 字符串拼接 → 命令注入风险，建议用参数列表
- `Grep "pickle\.load"` → 反序列化不受信数据风险，建议校验来源
- `Grep "DEBUG\s*=\s*True"` → 生产环境调试模式未关闭

### ⚡ 性能优化
- `Grep "for .* in .*:"` 嵌套 → O(n²) 风险，建议用集合或字典优化
- `Grep "requests\.\(get\|post\)"` → 同步 HTTP 调用，高并发建议用 `aiohttp`/`httpx`
- `Grep "time\.sleep"` → 阻塞等待，建议用异步或事件驱动
- `Grep "SELECT \*\|\.all()"` → ORM 全表查询，建议限制字段和分页

### 🧪 测试覆盖
- `Glob "**/test_*.py"` / `Glob "**/*_test.py"` → 检查核心模块是否有对应测试
- 缺少 `conftest.py` → 建议增加共享 fixture
- 缺少 `pytest.ini` / `pyproject.toml [tool.pytest]` → 建议统一测试配置

### 📝 文档与 DX
- `Grep "def \w+\("` 无 docstring（下一行非 `\"\"\"`）→ 公开函数缺少 docstring
- `Grep "__all__"` 在 `__init__.py` 中缺失 → 建议定义 `__all__` 明确公开 API
- 缺少 `py.typed` 标记文件 → 建议增加以支持类型检查
- 缺少 `ruff.toml` / `.flake8` → 建议配置 linter

## 推荐 ASCII art 图类型

- 类继承关系 → ASCII 树形图（缩进 + 连线表示继承层级）
- 请求/任务处理流 → ASCII 时序图（竖线 + 箭头）
- 状态机（状态模式）→ ASCII 状态转换图（方框 + 带条件箭头）