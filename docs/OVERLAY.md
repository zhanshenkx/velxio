# 我们的二次开发层（overlay）

Velxio 本身留了一个官方扩展接缝：`@pro` 别名 + `mountPro()`。开源构建里它指向
`src/__pro_stub__/`（空实现），设了 `VITE_PRO_BUILD=true` + `PRO_OVERLAY_PATH` 之后
就指向真正的 overlay 目录。

**我们的全部改动都在这一个目录里，上游源码一行没动**（`git status` 干净），
所以拉 Velxio 新版本是 fast-forward，不是 merge。

```
frontend/src/pro/
  index.ts                  mountPro()：注册板卡 + 挂 LED 订阅
  desktop_index.ts          Vite 会静态解析的这个分支，必须存在
  boards/
    ZhanshenkxUnoElement.ts       板卡 Web Component：SVG 外观 + pinInfo
    zhanshenkxUno.ts              板卡数据（ProBoardDef）：标签/FQBN/引脚表/种子代码
  data/proExamples.ts       空示例列表（OSS 必需）
  seoRoutes.ts              空 SEO 路由（OSS 必需）
  i18n/register.ts          空 i18n 注册（OSS 必需）
  pages/marketing.ts        空营销页（OSS 必需）
```

## 加一块新板要动哪里

只改 `boards/` 下的两个文件，其余流程 Velxio 自己会接上：

| 你提供 | 框架自动完成 |
|---|---|
| `kind` / `label` / `description` | 出现在元件选择器（`allBoards = [...ALL_BOARDS, ...listProBoards()]`） |
| `fqbn` | 编译器按 FQBN 选内核；**`arduino:avr:*` 自动路由到 avr8js**（`useSimulatorStore.createSimulator`） |
| `tag` + 自定义元素 | 画布渲染、选择框、缩略图 |
| 元素上的 `pinInfo` | 引脚焊盘、连线端点、示波器通道、SPICE 节点全从这一个数组来 |
| `pinToNumber` | 丝印名 → Arduino 引脚号（`boardPinToNumber` 优先读这里） |
| `defaultFiles.arduino` | 新板第一次打开时的种子代码 |

要换成 RP2040/ESP32 板，FQBN 换成对应的核（需要额外装内核 / ESP-IDF + QEMU），
不需要改我们的代码。

## 已知边界

- **板载 LED 没有官方通道**：画布把 `onboardLeds` 只传给它认识的板（Uno/Nano/Mega/ESP32），
  `ProBoardDef.render` 拿不到。我们用 `useSimulatorStore.getState().getBusBinding().pins.onPinChange`
  自己订阅 D13 补上了（`ZhanshenkxUnoElement.watchPin`）。这是绕过，不是官方 API。
- **AGPLv3**：对外提供网络服务时，改过的源码要一起开源；不想开源就得买商业授权。
- ESP32 / 树莓派需要后端 QEMU 与 ESP-IDF，本机没有 Docker，这条没通。

## 启动

```
setup.bat          :: 首次：装依赖 + 补 Monaco + 建 Python venv
start-custom.bat   :: 每次启动
```

后端 8001、前端 5173（注意：Vite 7 只绑 `::1`，必须用 `localhost`，`127.0.0.1` 连不上）。

前置：`arduino-cli` 放在 `tools\arduino-cli.exe` 或加进 `PATH`（后端启动时会自动装
`arduino:avr` 内核，约 400MB，首次 2–3 分钟）。
