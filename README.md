# ContextSwitcher

A macOS menu bar utility for managing multiple development contexts by hiding/showing app windows.

## Demo

https://github.com/user-attachments/assets/010d90dd-5c32-4f04-9d9f-1386d15954ed

## Features

- Save current window layouts as named workspaces
- Switch between workspaces instantly from the menu bar
- Selectively show/hide individual windows (e.g., specific IntelliJ projects)
- Floating HUD panel for quick access
- Restore all hidden apps with one click

## Requirements

- macOS 14 (Sonoma) or later
- Swift 5.9+
- Accessibility permission

## Installation

```bash
git clone https://github.com/minsang-alt/contextSwitcher.git
cd ContextSwitcher
./scripts/install.sh
```

This builds the app, installs it to `/Applications`, and launches it.

To build manually:

```bash
swift build -c release
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
