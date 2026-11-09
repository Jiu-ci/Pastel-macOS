# 本 fork 的本地打包与签名

本 fork 通过 `Scripts/BuildAdHocDMG.sh` 生成一个支持 macOS 15.0 及以上的 arm64 DMG。默认使用临时签名，不需要 Apple 开发者账户、证书或上游作者的本地签名身份。

```sh
sh Scripts/BuildAdHocDMG.sh
```

脚本先签名 SAP signer、Node 和 store-helper，再签名 App，最后检查签名与最低系统版本。Node 保留 JIT 权限；store-helper 保留其认证运行时所需的独立权限。它们都必须通过 `Scripts/VerifyMacOSCompatibility.py`。

已有稳定签名身份的维护者可以显式指定自己的身份，例如：

```sh
PASTEL_SIGNING_IDENTITY="panghu Release Signing" sh Scripts/BuildAdHocDMG.sh
```

切换签名身份可能使钥匙串再次要求授权。构建脚本不删除用户凭据或替换保险库密钥，不访问上游作者的证书备份。临时签名不等于 Apple 公证。

本 fork 不包含 Sparkle、上游 appcast 或上游更新签名密钥。应用内“检查更新”打开 `Jiu-ci/Pastel-macOS` 的 Releases；发布由本 fork 的工作流负责，构建本身不会推送或发布。
