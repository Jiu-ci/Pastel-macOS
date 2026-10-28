<div align="center">
  <img src="https://github.com/user-attachments/assets/f302f5d2-730c-44d2-a2c1-63cdd75804f2" width="120" alt="Pastel 图标">
  <h1>Pastel · macOS 15 适配版</h1>
  <p>在 Mac 上搜索 App、浏览历史版本，并从 Apple 下载 IPA。</p>
  <p>
    <a href="https://github.com/Jiu-ci/Pastel-macOS/releases/latest"><strong>下载最新版</strong></a>
    · <a href="https://github.com/Jiu-ci/Pastel-macOS/issues">报告问题</a>
    · <a href="https://github.com/EEliberto/Pastel-macOS">原仓库</a>
  </p>
</div>

## 项目来源

本项目是 [EEliberto/Pastel-macOS](https://github.com/EEliberto/Pastel-macOS) 的 **fork**，由 [Jiu-ci](https://github.com/Jiu-ci) 维护。主要目标是将原项目要求的 **macOS 26** 降至 **macOS 15.0 及以上**，让使用 macOS 15 的 Apple 芯片 Mac 也能运行 Pastel。

**本 fork 的适配、修复、文档整理与发布配置工作，全程由 Codex GPT-6-Astra 完成。** 原项目及其既有功能由原作者和贡献者开发；上述说明仅指本 fork 的改动。

<p align="center">
  <img width="900" alt="Pastel 界面（原仓库截图，macOS 15 外观有所不同）" src="https://github.com/user-attachments/assets/2807691d-7f1d-4060-89b5-ae90839d37d5">
</p>

## 系统要求与下载

- macOS **15.0 或更高版本**；已在 macOS **15.7.3 / M4 Pro** 上进行实际登录和下载验证。
- **Apple 芯片（arm64）实体 Mac**。不提供 Intel 或 Universal 安装包。
- 已开通 App Store 的 Apple 账户；付费 App 需要该账户已购买。

从 [本 fork 的 Releases](https://github.com/Jiu-ci/Pastel-macOS/releases/latest) 下载 DMG，将 Pastel 拖入“应用程序”。在“设置 → Apple 账户”登录，再选择 App 和版本下载。

每个 Release 只提供 **一个 DMG**，格式与原仓库一致：`Pastel-<版本>-build-<构建号>.dmg`。同一个安装包支持 macOS 15 及更高系统。安装包使用本地临时签名（ad-hoc），未经过 Apple 公证；macOS 可能要求在“系统设置 → 隐私与安全性”中允许打开。

应用内“检查更新”会打开 **本 fork 的 Releases 页面**，由用户下载并安装更新。此版本不使用原仓库的 Sparkle 自动更新源，避免更新回要求 macOS 26 的上游版本。

## 主要功能与适配内容

- 搜索 App、选择商店地区，按 App ID 和版本 ID 下载历史版本。
- 汇集 Timbrd、Agzy、Bilin 和 Apple 的版本信息；IPA 文件由 Apple 提供。
- 管理下载资料库，支持在访达中显示、共享与隔空投送。
- macOS 26 保留 Liquid Glass；macOS 15 使用兼容的材质、按钮和布局。
- macOS 15 停用可能触发 `TooltipResponder / AttributeGraph` 崩溃的 SwiftUI 悬停提示，保留辅助功能提示。
- 设备 GUID 在进程内缓存，减少重复钥匙串读取；登录成功需确认加密会话已保存，取消后的旧登录回调不会干扰新登录。
- 下载接口的空 HTTP 403 不再被一律判定为“账户会话失效”，日志保留接口名称、状态码等诊断信息。

账户密码存放在 macOS 钥匙串，会话数据加密保存。更新临时签名的安装包后，钥匙串可能要求重新授权；设备标识、账户密码和会话密钥是不同的条目，可能分别提示。

### 特定版本下载失败

历史版本列表有记录，不代表 Apple 仍允许该账户下载该版本。如果同一账户能下载其他 App，却在某个版本上收到空 HTTP 403，请先尝试该 App 的其他版本，不必反复重新登录或重新获取许可。

本次验证中，京东 `16.0.0 / 890808313` 返回空 HTTP 403，其他下载已由用户确认正常。该现象不足以断定版本已下架或账户缺少许可。

报告问题时请附上系统版本、Pastel 版本、App ID、版本 ID 和 `[Store]` 诊断行；不要公开密码、验证码、Token 或 Cookie。

## 从源码构建

需要 **Xcode 26.2 或更高版本**（macOS 26 SDK）和联网环境。编译 SDK 与最低运行系统不同：生成的 App 最低支持 macOS 15.0。仓库内置 Node.js 24，构建时根据锁文件安装依赖，无需单独安装 Node.js。

```bash
open Pastel.xcodeproj
```

在 Xcode 中选择 `Pastel` 方案构建，或生成完整 DMG：

```bash
sh Scripts/BuildAdHocDMG.sh
```

脚本使用 `xcode-select -p` 选择的 Xcode，可通过 `DEVELOPER_DIR` 指定其他版本。安装包输出至 `dist/`；`PASTEL_DERIVED_DATA` 和 `PASTEL_OUTPUT_DIR` 可分别指定构建目录和输出目录。打包前会执行 Node 回归测试、签名校验和内置 Node JIT 检查。

## GitHub Releases 自动发布

[Release 工作流](.github/workflows/release.yml) 使用 GitHub 托管的 **macOS 15 ARM** 构建机和 **Xcode 26.2**，只构建一个 arm64 DMG，不需要 Apple 开发者证书或额外的签名 Secrets。工作流使用 GitHub 提供的 `GITHUB_TOKEN` 发布到当前仓库。

发布步骤：

1. 同时更新 `Pastel.xcodeproj/project.pbxproj` 中 Debug 和 Release 的 `MARKETING_VERSION`、`CURRENT_PROJECT_VERSION`。
2. 添加 `release-notes/<版本>/release-notes.md`，提交并推送代码。
3. 推送 `Pastel<版本>` 标签，自动触发构建、测试和 Release 发布。例如当前版本：

```bash
git tag Pastel20261028.1
git push origin Pastel20261028.1
```

也可在 Actions 中选择 **Release → Run workflow**，输入已推送的标签。标签必须与代码中的版本匹配；构建或校验失败时不会发布。成功后 Release 只有一个 DMG 附件，SHA-256 校验值写入发布说明。已发布的 Release 不会被自动覆盖。

工作流文件推送到 GitHub 后才生效；首次使用 fork 的 Actions 时，如 GitHub 提示禁用，请先在 Actions 页面启用。

## 更新记录

- [20261028.1：macOS 15 适配版与自动发布](release-notes/20261028.1/release-notes.md)
- `release-notes/` 中较早的版本记录来自原仓库，保留用于追溯上游历史。

## 致谢与许可证

- 原作者：[EEliberto](https://github.com/EEliberto)，原仓库：[Pastel-macOS](https://github.com/EEliberto/Pastel-macOS)。
- 本 fork 维护：Jiu-ci；适配开发：Codex GPT-6-Astra。
- Apple 登录与下载实现参考 [ipatool](https://github.com/majd/ipatool)、[ipatool.ts](https://github.com/beer-psi/ipatool.ts)、[SideStore](https://github.com/SideStore/SideStore) 和 [Asspp](https://github.com/Lakr233/Asspp)。上游多语言翻译由 Claude 协助完成。

沿用 [Apache License 2.0](LICENSE)。Pastel 与 Apple Inc. 无隶属关系，相关商标归各自所有者所有。
