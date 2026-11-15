# 修改声明（AGPLv3 §5）

本仓库是 **[Velxio](https://github.com/davidmonterocrespo24/velxio)** 的修改版本（fork）。
依据 GNU AGPLv3 第 5 条，此文件声明修改内容、日期与范围。

- **上游项目**：`https://github.com/davidmonterocrespo24/velxio`
- **fork 基点**：commit `5b303464`（上游 `master`，2026-11-14）
- **上游许可证**：AGPLv3（见 `LICENSE`），商业授权另见 `COMMERCIAL_LICENSE.md`
- **修改日期**：2026-11-15
- **修改人**：`zhanshenkx`

## 修改范围

上游源码**零逻辑修改**。改动分两类：

### 1. 修改的既有文件（仅 3 个）

| 文件 | 改动 |
|---|---|
| `README.md` | 顶部新增一段说明，指向 `CUSTOM.md`；其余内容保持上游原样 |
| `.gitignore` | 追加 2 行，忽略 `tools/*.exe`（本机 arduino-cli 二进制） |
| `Dockerfile.standalone` | frontend-builder 阶段加 2 个 `ENV`（`VITE_PRO_BUILD`、`PRO_OVERLAY_PATH`），让镜像烘进本 fork 的 overlay |

### 2. 新增文件

| 新增文件 | 作用 |
|---|---|
| `frontend/src/pro/index.ts` | `mountPro()` 入口：注册自定义板卡、挂载板载 LED 订阅 |
| `frontend/src/pro/desktop_index.ts` | 桌面构建分支，Vite 静态解析要求存在 |
| `frontend/src/pro/boards/ZhanshenkxUnoElement.ts` | 板卡 Web Component（SVG 外观 + `pinInfo` 26 个焊盘） |
| `frontend/src/pro/boards/zhanshenkxUno.ts` | 板卡定义 `ProBoardDef`（标签 / FQBN / 引脚映射 / 种子代码） |
| `frontend/src/pro/data/proExamples.ts` | 示例列表的空实现（OSS 构建无条件引用） |
| `frontend/src/pro/seoRoutes.ts` | SEO 路由的空实现 |
| `frontend/src/pro/i18n/register.ts` | i18n 注册的空实现 |
| `frontend/src/pro/pages/marketing.ts` | 营销页的空实现 |
| `setup.bat` | 一键还原依赖、Monaco 静态资源、Python venv |
| `start-custom.bat` | 一键启动后端 + 前端（带 overlay 环境变量） |
| `start-lan.bat` | 同上，但前端绑 `0.0.0.0`，供同局域网设备访问 |
| `docs/OVERLAY.md` | overlay 机制与扩板说明 |
| `tools/README.md` | 占位说明：`arduino-cli.exe` 放这里（目录本身需提交才能存在） |
| `.gitattributes` | 强制 `*.bat` 以 CRLF 检出（`goto` 标签在纯 LF 下不稳） |
| `CUSTOM.md` | 本 fork 的增量说明 |
| `MODIFICATIONS.md` | 本文件 |

## 关于 `frontend/src/pro` 与 `.gitignore`

上游 `.gitignore` 显式忽略 `frontend/src/pro`（为私有 overlay 留的规矩）。
本 fork **保持该 `.gitignore` 不变**，因此这些文件是用 `git add -f` 强制纳入跟踪的。
上游若调整该规则，本 fork 需重新评估，但已提交的文件不受影响。

## 未包含的内容

上游本身也不提交、本 fork 同样排除（需按 `setup.bat` 还原）：
`node_modules/`、Python `venv/`、`frontend/public/monaco/`、`frontend/dist/`、
QEMU 运行时二进制（`libqemu-*`）、Pro 专有 ROM 等。

## 分发义务

若将本仓库（或其修改版）作为网络服务对外提供，AGPLv3 要求向使用者提供对应的完整源码。
若不愿承担该义务，请向原作者购买商业授权。
