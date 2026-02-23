# ContextSwitcher

## Project Overview
macOS menu bar utility for managing development contexts by hiding/showing app windows.
- **Language:** Swift 6.0 (Swift tools version)
- **Platform:** macOS 14.0+ (Sonoma)
- **Build System:** Swift Package Manager
- **Bundle ID:** com.minsang.ContextSwitcher
- **License:** GPL-3.0
- **GitHub:** `minsang-alt/contextSwitcher` (camelCase)

## Architecture
```
ContextSwitcher/
├── ContextSwitcherApp.swift   # @main entry point (SwiftUI)
├── Models/                     # Data models (KeyShortcut, WindowIdentifier, WorkspaceConfiguration)
├── Services/                   # Core business logic
│   ├── AccessibilityService    # macOS Accessibility API wrapper
│   ├── ShortcutService         # Global keyboard shortcuts (CGEvent)
│   ├── WorkspaceSwitchService  # Workspace switching logic
│   └── WorkspaceStore          # Persistence (JSON-based)
├── Views/                      # SwiftUI views
├── Panel/                      # Floating HUD panel (AppKit)
├── Utilities/                  # Helpers (IntelliJ title parser)
└── Resources/                  # Info.plist, AppIcon.icns
```

## Build & Run
```bash
./scripts/install.sh          # Build + install to /Applications
./scripts/release.sh <ver>    # Build + DMG + GitHub release
swift build -c release        # Release build only
swift build                   # Debug build only
brew bundle                   # Install dev dependencies (swiftlint, swiftformat)
```

## CI/CD
- `.github/workflows/build.yml` — Build check on push to main + PRs
- `.github/workflows/quality.yml` — SwiftLint + SwiftFormat on PRs
- `.github/workflows/pr.yml` — Conventional Commits PR title validation
- `fastlane/Fastfile` — Release automation (build → bundle → DMG → optional notarization)

## Code Quality
- **SwiftLint** config: `.swiftlint.yml` (line length 150, file length 500)
- **SwiftFormat** config: `.swiftformat` (4-space indent, max width 150)
- Run before committing: `swiftlint lint && swiftformat --lint .`

## Conventions
- Commit messages follow Conventional Commits: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `ci:`
- PR titles must follow the same convention
- Issue templates enforce structured bug reports and feature requests
- Menu bar app (LSUIElement = true, no dock icon)

## Important Notes
- Accessibility permission resets after each rebuild (re-toggle in System Settings)
- Window identification: bundleID + windowID (stable across tab switches)
- Browser profiles extracted from window titles (Chrome, Brave, Edge)
- JetBrains IDE project names parsed from window titles
- Homebrew formula at `HomebrewFormula/contextswitcher.rb`
