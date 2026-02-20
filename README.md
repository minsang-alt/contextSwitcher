<p align="center">
  <img src="image 1 (2).png" alt="ContextSwitcher" width="128">
</p>

<h1 align="center">ContextSwitcher</h1>

<p align="center">A macOS menu bar utility for managing multiple development contexts by hiding/showing app windows.</p>

## Demo

https://github.com/user-attachments/assets/010d90dd-5c32-4f04-9d9f-1386d15954ed

## Features

- Save current window layouts as named workspaces
- Switch between workspaces instantly from the menu bar
- Selectively show/hide individual windows (e.g., specific IntelliJ projects)
- Floating HUD panel for quick access
- Restore all hidden apps with one click

## Download

| Platform | Download |
|----------|----------|
| macOS 14+ (Apple Silicon) | [ContextSwitcher-1.0.0-arm64.dmg](https://github.com/minsang-alt/contextSwitcher/releases/latest/download/ContextSwitcher-1.0.0-arm64.dmg) |

> After downloading, open the DMG and drag `ContextSwitcher.app` to `/Applications`.

## Build from Source

```bash
git clone https://github.com/minsang-alt/contextSwitcher.git
cd ContextSwitcher
./scripts/install.sh
```

## Setup

After launching, grant Accessibility permission:

1. Open **System Settings → Privacy & Security → Accessibility**
2. Add **ContextSwitcher** and toggle it ON

> Note: Accessibility permission resets after each rebuild. Toggle it OFF then ON again.

## Usage

1. Arrange your windows, then click the menu bar icon → **+** to capture a workspace
2. Name it and select which apps/windows to include
3. Click a workspace name to switch contexts
4. Click **Show All Apps** to restore everything

## License

GPL-3.0. See [LICENSE](LICENSE) for details.
