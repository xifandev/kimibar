cask "kimicodebar" do
  version "1.0.0"
  sha256 "809f2b9c3763db1d20fe57cc120ad5c3381330d8b83b8362c2e613e3b135e02e"

  url "https://github.com/xifandev/KimiCodeBar/releases/download/v#{version}/KimiCodeBar-v#{version}.zip"
  name "KimiCodeBar"
  desc "Kimi Code 用量实时监控菜单栏工具"
  homepage "https://github.com/xifandev/KimiCodeBar"

  livecheck do
    url :url
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  app "KimiCodeBar.app"

  zap trash: [
    "~/Library/Preferences/com.kimicodebar.app.plist",
  ]
end
