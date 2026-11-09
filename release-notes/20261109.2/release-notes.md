# Pastel 20261109.2 · macOS 15 适配版

修复首次登录或下载时，准备 Apple 认证资源出现 `403 Forbidden without byte-range support` 的问题。

- 已复现 Apple CDN 对 Go 默认 User-Agent 返回 403、带应用标识的同一分段请求返回 206；修复公共镜像探测及后续分段读取请求。
- 保持上游固定的 Apple 镜像地址、范围及长度检查、资源 SHA-256 校验，不修改 Store 登录请求头。
- 构建时在临时依赖副本应用受版本和源码摘要约束的补丁，更新 helper 二进制；新增对应回归测试和可选公共资源在线测试。
- App 与 helper 最低系统仍为 macOS 15.0、Apple 芯片 arm64。错误中出现的 macOS 27 指认证运行时的框架版本，无需为此升级系统。

真实账户登录、验证码和授权 IPA 下载仍需在 App 内验证。

已在 macOS 15.7.3 完成公共认证资源在线验证：从 Apple 镜像分段下载、提取全部 7 个资源并通过 SHA-256 校验，用时约 128 秒。资源回归测试与 helper 竞态测试通过。

Debug、Release 构建及打包内的 71 项 Node 测试通过；App、Node、SAP signer、helper 的 arm64/最低系统版本检查、签名校验和 DMG 完整性检查通过。
