# 发布维护

1. 修改 `Resources/Info.plist` 中的版本号和构建号，更新 CHANGELOG、安装说明及 README 下载文件名。
2. 运行 `./scripts/package.sh`。检查测试、Universal 架构、签名和 DMG 挂载结果。
3. 验证实际界面，包括开始／暂停、重置、时分秒设置、预览、到时提醒、锁定与解锁。
4. 将源码提交至 GitHub，确认自动构建通过，再创建版本标签和 GitHub Release。
5. 上传 `dist/` 中的 DMG、ZIP 和 `SHA256SUMS.txt`。下载回读并核对校验值。

## Apple 签名与公证

默认构建仅进行 ad-hoc 签名，不是 Apple 认证的发行签名。不要将默认产物描述为已经公证。

维护者拥有 Developer ID Application 证书后，可用环境变量 `SIGNING_IDENTITY` 让构建脚本执行 hardened runtime 签名。不要把证书、私钥、密码或令牌放进仓库。之后按照 [Apple 公证文档](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution) 提交应用、检查公证结果并附加票据，再重新包装最终下载包和校验值；不要在附加票据之后重新编译应用。

本仓库 CI 只构建与验证，不持有发行证书，也不自动上传公开 Release。
