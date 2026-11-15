# 定制说明（本 fork 的增量）

这是 [davidmonterocrespo24/velxio](https://github.com/davidmonterocrespo24/velxio) 的
**个人 fork**，在保留上游全部功能的前提下，加了一块自己画的板卡。

- 上游源码 **零修改**（唯一动过的既有文件是 `README.md`，只加了一段指向本文件的说明）
- 全部增量都是**新增文件**，集中在 `frontend/src/pro/`
- 修改声明：**[MODIFICATIONS.md](MODIFICATIONS.md)**（AGPLv3 §5 要求）
- 机制与扩板说明：**[docs/OVERLAY.md](docs/OVERLAY.md)**

## 增量清单

```
frontend/src/pro/
  index.ts                 mountPro()：注册板卡 + 挂板载 LED 订阅
  desktop_index.ts         Vite 静态解析的分支，必须存在
  boards/
    AcmeUnoElement.ts      板卡 Web Component：SVG 外观 + pinInfo（26 个焊盘）
    acmeUno.ts             ProBoardDef：标签 / FQBN / 引脚表 / 种子代码
  data/proExamples.ts      空示例列表（OSS 构建无条件引用）
  seoRoutes.ts             空 SEO 路由
  i18n/register.ts         空 i18n 注册
  pages/marketing.ts       空营销页
setup.bat                  一键还原依赖 / Monaco / Python venv
start-custom.bat           一键启动后端 8001 + 前端 5173
docs/OVERLAY.md            机制说明
MODIFICATIONS.md           AGPLv3 修改声明
```

## 新板：Acme Uno R3

不是换个标签的 Uno —— 外观是手写 Web Component + SVG，引脚表独立，
FQBN 走 `arduino:avr:uno` 并自动路由到 `avr8js`（浏览器内逐条执行真固件）。

实测（无头浏览器驱动真实 App，非截图伪造）：

```
选择器搜 "acme" → Acme Uno R3 → 放板 → Run

Starting compilation for Acme Uno R3 (arduino:avr:uno)
Sketch uses 2402 bytes (7%) of program storage space
✓ Compilation successful

SERIAL:  Acme Uno R3 online
         F_CPU = 16000000 Hz
         blink 1  millis() = 500
         blink 2  millis() = 1001
```

## 跑起来（Windows）

```bat
setup.bat          :: 首次：装依赖 + 补 Monaco + 建 venv + 检查 arduino-cli
start-custom.bat   :: 启动，自动开浏览器
```

打开 <http://localhost:5173/editor>，选择器里搜 `acme`。

> Vite 7 在部分 Windows 环境只绑 `::1`，**必须用 `localhost`，不能用 `127.0.0.1`**。

前置：Node 18+、Python 3.10+、`arduino-cli`（放 `tools\arduino-cli.exe` 或加进 `PATH`）。
首次编译时后端会自动安装 `arduino:avr` 内核（约 400MB，等 2–3 分钟）。

## 已知边界

- **板载 LED 没有官方通道**：画布只给它认识的板传 `onboardLeds`，`ProBoardDef.render`
  拿不到。这里用 `getBusBinding().pins.onPinChange` 自行订阅 D13，属绕过而非官方 API。
- ESP32 / 树莓派需要后端 QEMU 二进制与 ESP-IDF，本 fork 未包含。
- 改名只需两处：`boards/acmeUno.ts` 的 `label`/`kind`，与 `AcmeUnoElement.ts` 的丝印文字。

## 许可证

上游为 **AGPLv3**（见 `LICENSE`），商业授权见 `COMMERCIAL_LICENSE.md`。
若把本 fork 作为网络服务对外提供，须一并开源对应源码。
