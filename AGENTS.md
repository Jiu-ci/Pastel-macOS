# 项目维护约定

## 项目定位

- 上游是 `EEliberto/Pastel-macOS`，上游 App 最低要求 **macOS 26**。
- 本仓库是 `Jiu-ci/Pastel-macOS`，必须保持 **macOS 15.0 及以上、Apple 芯片 arm64** 支持。
- Xcode/SDK/CI 构建主机版本不等于最低运行系统。可以使用 Xcode 26.2、macOS 26 SDK 和 macOS 26 构建机，但不能因此提高部署目标。
- 根目录 `AGENTS.md` 是长期维护文档；同步上游或改变构建、兼容层、认证流程后应同步更新相关约定和 README。

## 同步上游

1. 检查工作区和分支状态，保留用户未提交的改动。
2. 每次 fetch、pull、push 或创建远端标签前，检查 `git config --get remote.origin.url` 和 `git remote get-url origin`。本仓库的实际 origin 必须使用 `git@github-jiuci:Jiu-ci/`。不要切换 GitHub CLI HTTPS 凭据或修改公司仓库 remote。
3. `upstream` 指向 `https://github.com/EEliberto/Pastel-macOS.git`；拉取并比较共同基点、提交和代码后，在本地合并并处理冲突。不要用上游整树覆盖 fork，也不要把 GitHub Sync fork 当作兼容性验证。
4. 同时保留上游功能修复与下面列出的 fork 约束。尤其检查 Xcode 工程对象 ID 冲突、新增的高版本 API，以及打包脚本中的 Sparkle 引用。
5. 本地构建、测试和兼容性校验通过后再报告结果。除非用户要求，否则不推送、不打远端标签、不发布 Release。

## 必须保留的 fork 约束

- `Pastel.xcodeproj/project.pbxproj` 的 Debug、Release 部署目标均为 `15.0`；`Info.plist` 的 `LSMinimumSystemVersion` 跟随部署目标。
- SwiftUI 高版本功能通过 `Pastel/AppearanceCompatibility.swift` 封装，或使用明确的 `#available` 分支并提供 macOS 15 回退。不得给整个 App 添加 macOS 26 的可用性限制来绕过编译错误。
- 业务界面使用 `.pastelHelp()`，避免 macOS 15 的 `TooltipResponder / AttributeGraph` 崩溃；不要重新直接调用 `.help()`。
- 保留设备 GUID 缓存、稳定设备标识和迁移逻辑，不生成随机设备 GUID，不把钥匙串拒绝授权当作条目不存在。
- 登录结果必须确认加密会话已保存；失败不得报告登录成功。取消或重试后的旧异步回调不得覆盖当前认证状态。保持验证码界面和下载认证错误映射一致。
- 不把任意 HTTP 403、包含 token/session 的错误文本一律判定为会话过期。明确的 `TOKEN_EXPIRED` 可以自动重新认证一次，包括刚获取的令牌过期。
- 账户密码、验证码、令牌、Cookie 不得进入命令行参数、日志或仓库。测试使用隔离临时目录和虚构账户；真实登录由用户在 App 内完成，不从钥匙串提取密码用于自动测试。
- “检查更新”打开本 fork Releases。保持移除上游 Sparkle 依赖、feed、签名密钥和本地化脚本，避免更新回仅支持高版本 macOS 的上游包。
- 保留 fork 自动发布、arm64 单 DMG 和临时签名方案，不要求上游作者的证书或签名身份。

## 认证组件与构建

- 活跃登录/下载路径为 Swift → Node → `StoreHelper`。上游新认证流程依赖 helper；不能只合并 Swift/JS 而遗漏 helper 或继续运行旧二进制。
- `StoreHelper/go.mod` 固定 Go 工具链及 ipatool 依赖；更新源码或依赖后执行 `sh Scripts/BuildStoreHelper.sh`，提交重新生成的 `node/bin/store-helper.gz`。
- `Scripts/StoreHelperGo.py` 在临时源码副本中应用 `StoreHelper/patches/ipatool-v2.8.0-assets.patch`，修正 Apple 公共镜像对 Go 默认 User-Agent 返回 403 的问题；不修改 Go 模块缓存。构建和测试必须使用该入口，直接 `go build` 会遗漏补丁。升级依赖时重新审查补丁、固定源码摘要和资源下载测试，不能跳过校验；保留 Range、长度、SHA-256 校验，不修改全局 HTTP transport 或 Store 认证请求头。
- helper 构建必须显式指定 macOS 15 的 C 编译和链接目标。上游预编译文件即使能启动，也不能直接当作 macOS 15 兼容文件使用。
- `Scripts/VerifyMacOSCompatibility.py` 检查 App、Node、SAP signer 和 store-helper 的 arm64 架构及 Mach-O 最低系统版本，不能通过修改 Mach-O 头或跳过检查掩盖不兼容。
- 保留内嵌 Node 的 JIT 权限、helper 所需权限及从内向外的签名顺序；不要给所有可执行文件套用同一份权限。

## 验证与交付

- Node：在 `NodeProject` 执行 Node 24 的 `node --test`；正式打包会针对实际内嵌代码和依赖再次运行测试。
- Go：在仓库根目录执行 `MACOSX_DEPLOYMENT_TARGET=15.0 python3 Scripts/StoreHelperGo.py test -mod=readonly -race ./...`。
- 认证资源：执行 `python3 Scripts/StoreHelperGo.py --upstream test -mod=readonly -race ./internal/sap/assets`；显式添加 `PASTEL_TEST_APPLE_ASSETS=1` 并使用 `-run '^TestPanghuLiveAssets$' -count=1 -timeout 12m` 可验证公共资源在线准备和完整性，不读取账户凭据。
- Swift 元数据：用 `swiftc Pastel/IPAMetadata.swift Scripts/Tests/IPAMetadataTests.swift` 编译到临时目录后运行。
- 构建：`sh Scripts/BuildAdHocDMG.sh`；通过 `PASTEL_DERIVED_DATA`、`PASTEL_OUTPUT_DIR` 指定独立构建和输出目录，不覆盖旧安装包。
- 同时验证 Debug 和 Release，避免遗漏仅 Debug 编译的登录模拟代码；模拟说明见 `docs/LOGIN_SIMULATION.md`。
- 执行 `sh Scripts/TestLoginSimulation.sh` 验证真实 AccountStore 的隔离模拟，覆盖验证码重试、成功确认、取消和旧回调；不加载用户账户或读取钥匙串。
- 真实登录、验证码与授权下载不能由离线单元测试证明。报告应明确区分编译/自动测试、应用启动、真实账户验证，不能把无效输入测试或模拟登录宣称为真实登录成功。
- fork 版本与上游版本区分，例如上游 `20261109` 对应 fork `20261109.1`；Debug/Release 版本和构建号保持一致，并添加 fork 自己的发布说明。
- Git 提交使用 Conventional Commits，描述使用中文。新增示例品牌、测试账户和示例标识使用 `panghu`，不改真实协议字段、生产标识和历史记录。
