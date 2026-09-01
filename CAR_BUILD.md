# PiliPlus 车机适配版

本分支为 Android 车机与分屏窗口增加以下行为：

- 播放器“全屏”只铺满 PiliPlus 当前窗口，不再请求 Android 沉浸模式或改变横竖屏。
- 根界面统一避让 Android 上报的顶部状态栏、底部系统栏与显示缺口，避免画面可见但触控被车机系统层拦截。
- 使用透明状态栏的 edge-to-edge 绘制，让主题背景延伸到车机状态条区域；SafeArea 只约束交互内容。
- 设置 → 样式设置中增加“车机窗口模式”和顶部/底部最低安全边距；车机专用 Action 产物默认启用。
- 专用 APK 使用 `com.example.piliplus.car` 包名和 `PiliPlus Car` 名称，可与官方 PiliPlus 同时安装。

## 构建

运行 GitHub Actions 中的 **Build Car Android arm64-v8a**。工作流只构建 `arm64-v8a`（V8A）APK，并上传为 `PiliPlus-Car-arm64-v8a` artifact。

如果车机没有正确上报系统栏高度，可在“设置 → 样式设置”中逐级调大顶部或底部最低安全边距；修改后重启应用。

