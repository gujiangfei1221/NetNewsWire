<img src=Technotes/Images/icon_1024.png height=128 width=128 style="display: block; margin: auto;"> 
 
 # NetNewsWire（个人增强版）
 
 这是基于 NetNewsWire 的个人二次开发版本，在原有 RSS 阅读体验基础上新增了 **AI 翻译** 与 **AI 总结** 功能（macOS）。
 
 ## 新增功能
 
 - **AI 翻译（原文 + 译文并存）**
   - 工具栏新增 `Translate` 按钮。
   - 点击后在文章底部追加译文，使用分隔线区分。
   - 再次点击可切回仅显示原文。
   - 支持缓存（同一篇文章重复点击不会重复调用 API）。
 
 - **AI 总结（追加到文章最下方）**
   - 工具栏新增 `Summarize` 按钮。
   - 点击后在文章底部追加 AI 总结，使用分隔线区分。
   - 若已执行过翻译，再点总结会显示：**原文 → 翻译 → 总结**。
   - 同样支持缓存。
 
 - **加载交互**
   - 翻译/总结进行中，工具栏按钮会显示转圈（spinner），避免误以为没有点击。
 
 ## 下载
 
 - **方式 A：从源码构建（推荐）**
   - 适合想自己在本机使用、并能接受用 Xcode 构建的用户。
 
 - **方式 B：下载打包产物（如有）**
   - 如果你在本仓库的 Releases 页看到了作者发布的 `.zip`/`.dmg`，可直接下载使用。
   - 若没有 Releases，请使用方式 A 构建。
 
 ## 安装与运行（从打包产物）
 
 1. 下载 `.zip` 或 `.dmg`。
 2. 将 `NetNewsWire.app` 拖到 `Applications`。
 3. 首次打开若被 Gatekeeper 拦截：
    - 在 **系统设置 -> 隐私与安全性** 里选择“仍要打开”。
 
 ## 使用说明（AI 翻译 / 总结）
 
 1. 打开任意文章。
 2. 点击工具栏的 **Translate** 或 **Summarize**。
 3. 首次使用会提示你设置 API Key（不会写入仓库，只保存在本机）。
 
 ### API Key 配置
 
 - **入口**：首次点击翻译/总结且未配置时，会弹窗要求填写。
 - **存储**：仅保存在本机 `UserDefaults`，键为 `AITranslationAPIKey`。
 - **安全**：请勿把你的 key 写入源码或提交到 GitHub。
 
 ## 构建（macOS）
 
 你可以在没有付费开发者账号的情况下进行本地构建和调试。
 
 1. 克隆代码：
 
 ```bash
 git clone <your fork repo url>
 ```
 
 2. 配置本地签名（不提交到仓库）
 
 通过在本地创建 `DeveloperSettings.xcconfig` 来覆盖 Xcode 代码签名设置。
 目录结构如下（注意：`SharedXcodeSettings` 与仓库目录同级）：
 
 ```
 directory/
   SharedXcodeSettings/
     DeveloperSettings.xcconfig
   NetNewsWire/
     NetNewsWire.xcodeproj
 ```
 
 你可以参考模板文件：`SharedXcodeSettings/DeveloperSettings.example.xcconfig`。
 
 3. 打开 Xcode 工程并运行
 
 - 打开 `NetNewsWire.xcodeproj`
 - 选择 `My Mac`
 - `⌘R`
 
 ## 说明
 
 - 上游项目：NetNewsWire（更多信息见 https://netnewswire.com/ ）
 - 许可证：本仓库根目录包含 `LICENSE.txt`，发布/分发请保留许可证文本。
