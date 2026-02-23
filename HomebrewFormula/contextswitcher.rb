cask "contextswitcher" do
  version "1.2.0"
  sha256 :no_check

  url "https://github.com/minsang-alt/contextSwitcher/releases/download/v#{version}/ContextSwitcher-#{version}-arm64.dmg"
  name "ContextSwitcher"
  desc "macOS menu bar utility for managing development contexts"
  homepage "https://github.com/minsang-alt/contextSwitcher"

  depends_on macos: ">= :sonoma"
  depends_on arch: :arm64

  app "ContextSwitcher.app"

  zap trash: [
    "~/Library/Application Support/ContextSwitcher",
    "~/Library/Preferences/com.minsang.ContextSwitcher.plist",
  ]
end
