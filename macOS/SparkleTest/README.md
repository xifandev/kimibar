# Sparkle 本地测试说明

## 已准备好的文件

- `Old/KimiCodeBar.app`：旧版本（`1.1.0-test-old`），用来运行并触发更新检查
- `New/KimiCodeBar-1.1.1-test-new.zip`：新版本更新包，已用 EdDSA 私钥签名
- `appcast.xml`：Sparkle 更新源（指向 `http://127.0.0.1:8765/`）

## 测试步骤

1. 在 `macOS/SparkleTest/` 目录启动本地 HTTP 服务器：

   ```bash
   python3 -m http.server 8765
   ```

2. 运行旧版本 App：

   ```bash
   open macOS/SparkleTest/Old/KimiCodeBar.app
   ```

3. 点击菜单栏图标，选择「检查更新…」，应弹出 Sparkle 更新窗口，检测到 `1.1.1-test-new`。

4. 点击「安装更新」，下载完成后 App 会自动重启为新版本。

## 重新生成测试包

如需修改版本重新测试：

```bash
# 1. 修改 macOS/KimiCodeBar/Info.plist 的版本号为旧版，编译
# 2. 复制 .app 到 SparkleTest/Old/
# 3. 修改版本号为新版，编译，打包 zip
# 4. 使用 Sparkle 工具签名并生成 appcast
./Tools/bin/sign_update KimiCodeBar-1.x.x.zip
./Tools/bin/generate_appcast --download-url-prefix "http://127.0.0.1:8765/" .
```

> 注意：`Tools/` 目录下的 Sparkle 二进制工具较大，未提交到仓库。可从 [Sparkle Releases](https://github.com/sparkle-project/Sparkle/releases) 下载。
