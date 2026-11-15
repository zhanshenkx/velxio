# 定制说明（本 fork 的增量）

这是 [davidmonterocrespo24/velxio](https://github.com/davidmonterocrespo24/velxio) 的
**个人 fork**，在保留上游全部功能的前提下，加了一块自己画的板卡。

- 上游源码 **零逻辑修改**（动过的既有文件只有两个：`README.md` 加了指向本文件的说明，
  `.gitignore` 加了 2 行忽略 `tools/*.exe`）
- 全部增量都是**新增文件**，集中在 `frontend/src/pro/`
- 修改声明：**[MODIFICATIONS.md](MODIFICATIONS.md)**（AGPLv3 §5 要求）
- 机制与扩板说明：**[docs/OVERLAY.md](docs/OVERLAY.md)**

## 增量清单

```
frontend/src/pro/
  index.ts                 mountPro()：注册板卡 + 挂板载 LED 订阅
  desktop_index.ts         Vite 静态解析的分支，必须存在
  boards/
    ZhanshenkxUnoElement.ts      板卡 Web Component：SVG 外观 + pinInfo（26 个焊盘）
    zhanshenkxUno.ts             ProBoardDef：标签 / FQBN / 引脚表 / 种子代码
  data/proExamples.ts      空示例列表（OSS 构建无条件引用）
  seoRoutes.ts             空 SEO 路由
  i18n/register.ts         空 i18n 注册
  pages/marketing.ts       空营销页
setup.bat                  一键还原依赖 / Monaco / Python venv
start-custom.bat           一键启动后端 8001 + 前端 5173（仅本机）
start-lan.bat              同上，前端监听 0.0.0.0:5173 供局域网访问
tools/README.md            arduino-cli.exe 的放置说明（占位，让目录能进仓库）
docs/OVERLAY.md            机制说明
MODIFICATIONS.md           AGPLv3 修改声明
```

## 新板：Zhanshenkx Uno R3

不是换个标签的 Uno —— 外观是手写 Web Component + SVG，引脚表独立，
FQBN 走 `arduino:avr:uno` 并自动路由到 `avr8js`（浏览器内逐条执行真固件）。

实测（无头浏览器驱动真实 App，非截图伪造）：

```
选择器搜 "zhanshenkx" → Zhanshenkx Uno R3 → 放板 → Run

Starting compilation for Zhanshenkx Uno R3 (arduino:avr:uno)
Sketch uses 2402 bytes (7%) of program storage space
✓ Compilation successful

SERIAL:  Zhanshenkx Uno R3 online
         F_CPU = 16000000 Hz
         blink 1  millis() = 500
         blink 2  millis() = 1001
```

另外用 `git archive` 导出一份**不含 `node_modules` / `venv` / Monaco 的干净检出**，
在全新浏览器 profile 下重跑同一条链路（`setup.bat` → `start-custom.bat` → 选择器 →
Run），结果一致：板卡 `kind` 为 `zhanshenkx-uno`，串口输出同上。

## 跑起来（Windows）

```bat
git clone https://github.com/zhanshenkx/velxio.git
cd velxio
setup.bat          :: 首次：装依赖 + 补 Monaco + 建 venv + 检查 arduino-cli
start-custom.bat   :: 启动，只监听本机，自动开浏览器
start-lan.bat      :: 同上，但 dev server 监听局域网，手机/平板也能开
```

打开 <http://localhost:5173/editor>，选择器里搜 `zhanshenkx`。

> Vite 7 在部分 Windows 环境只绑 `::1`，**必须用 `localhost`，不能用 `127.0.0.1`**。

### 局域网给别的设备用

`start-lan.bat` 会把 Vite 绑到 `0.0.0.0:5173` 并打印本机 IPv4，手机同 WiFi 打开
`http://<本机IPv4>:5173/editor` 即可。后端**仍只监听 `127.0.0.1:8001`**——浏览器请求
`/api/*` 由 Vite 在服务端反代过去，所以局域网只暴露 5173 一个口，接口不会被外人直连。

实测：从 `http://192.168.10.115:5173/editor` 走完 选择器 → 放板 → Run，编译与串口输出正常，
与 localhost 行为一致。手机打不开先看 Windows 防火墙有没有放行 Node.js（专用网络）。

### 能不能放公网

能，但**不能只丢静态文件**：AVR 仿真（avr8js）在浏览器里跑，编译却依赖后端
`arduino-cli` + ~400MB 的 `arduino:avr` 内核，纯静态托管（Pages / Vercel）会在编译那一步 404。
上游的做法是一个容器同时 serve 前端 `dist` 和 API：

```bat
docker compose up --build     :: 打开 http://localhost:3080
```

注意：镜像里前端构建走 `npm run build:docker`（上游 OSS 入口），**不含本 fork 的
`src/pro` overlay**。要部署带 Zhanshenkx Uno R3 的公网版，需在 `Dockerfile.standalone`
的 frontend-builder 阶段注入 `VITE_PRO_BUILD` 与 `PRO_OVERLAY_PATH`（容器内路径），
否则部署上去只是原版 Velxio。另外 AGPLv3 要求：对外提供网络服务时须提供对应源码。

前置：Node 18+、Python 3.10+、`arduino-cli`（放 `tools\arduino-cli.exe` 或加进 `PATH`）。

- **不需要 `--recursive`**：`third-party/` 下的 4 个子模块（avr8js / rp2040js /
  wokwi-elements / wokwi-features）只是源码参考，构建走 npm 上的 `avr8js@0.21.0`、
  `rp2040js@1.3.2`，普通 clone 即可。
- `tools\` 目录里只提交了 `README.md` 占位；下载的 `arduino-cli.exe` 被 `.gitignore`
  忽略，放进去不会把工作区弄脏。
- 首次编译时后端会自动安装 `arduino:avr` 内核（约 400MB，等 2–3 分钟），装在当前用户的
  Arduino 目录里，换机器才需要重装。

## 疑难：整页白屏 + `Failed to resolve import "@pro/desktop_index"`

Vite 的错误浮层报这个，说明 `@pro` 别名没指到 `frontend/src/pro`。最常见原因是
`PRO_OVERLAY_PATH` **尾部多了一个空格**（cmd 里写 `set VAR=value && cmd` 会把 `&&`
前的空格并进变量值）。本仓库的 `start-custom.bat` 已用 `set "VAR=value"` 并在父进程
导出、由 `start` 子进程继承，正常路径不会踩到；如果你手写启动命令，注意也这么写。


## 已知边界

- **板载 LED 没有官方通道**：画布只给它认识的板传 `onboardLeds`，`ProBoardDef.render`
  拿不到。这里用 `getBusBinding().pins.onPinChange` 自行订阅 D13，属绕过而非官方 API。
- ESP32 / 树莓派需要后端 QEMU 二进制与 ESP-IDF，本 fork 未包含。
- 改名只需两处：`boards/zhanshenkxUno.ts` 的 `label`/`kind`，与 `ZhanshenkxUnoElement.ts` 的丝印文字。

## 许可证

上游为 **AGPLv3**（见 `LICENSE`），商业授权见 `COMMERCIAL_LICENSE.md`。
若把本 fork 作为网络服务对外提供，须一并开源对应源码。
