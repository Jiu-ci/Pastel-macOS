# Pastel 20261028.1 · macOS 15 适配版

本版本由 Jiu-ci 维护，fork 自 [EEliberto/Pastel-macOS](https://github.com/EEliberto/Pastel-macOS)。本 fork 的适配、修复和发布配置全程由 Codex GPT-6-Astra 完成。

- 最低运行系统调整为 macOS 15.0，支持 Apple 芯片 Mac；macOS 26 保留 Liquid Glass 外观。
- 规避 macOS 15 的 SwiftUI 悬停提示崩溃路径，减少重复钥匙串读取。
- 登录完成前确认会话已加密保存，隔离取消后旧登录进程的回调。
- 区分下载接口空 HTTP 403 与明确的会话失效，提供不含凭据的接口诊断信息。
- 项目、作者与检查更新入口改为本 fork；检查更新打开本仓库 Releases，不再使用上游 Sparkle 更新源。
- GitHub Actions 自动构建、测试并发布一个 arm64 DMG。

已在 macOS 15.7.3 / M4 Pro 上验证此前兼容构建的登录和下载。特定 App 的历史版本可能返回 HTTP 403，版本列表中有记录并不保证仍可下载。

安装：打开 DMG，将 Pastel 拖入“应用程序”。安装包使用 ad-hoc 签名，未经过 Apple 公证；更新后钥匙串可能要求重新授权。
