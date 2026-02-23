# Contributing to ContextSwitcher

Thanks for your interest in contributing!

## Getting Started

1. Fork and clone the repository
2. Install dev dependencies: `brew bundle`
3. Build from source: `./scripts/install.sh`
4. Grant Accessibility permission in **System Settings → Privacy & Security → Accessibility**

## Development

- **Language:** Swift 6.0
- **Platform:** macOS 14+ (Sonoma)
- **Build system:** Swift Package Manager
- **Code style:** Enforced by SwiftLint + SwiftFormat

### Code Quality

Before submitting, run:

```bash
swiftlint lint
swiftformat --lint .
```

These checks also run automatically in CI on pull requests.

## Submitting Changes

1. Create a feature branch from `main`
2. Make your changes
3. Run lint checks
4. Test thoroughly on macOS
5. Submit a pull request with a clear description

### Commit & PR Convention

PR titles must follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` — New features
- `fix:` — Bug fixes
- `docs:` — Documentation changes
- `chore:` — Maintenance tasks
- `refactor:` — Code refactoring
- `ci:` — CI/CD changes
- `test:` — Test changes
- `style:` — Code style changes
- `perf:` — Performance improvements

Examples:
- `feat: add workspace reordering via drag and drop`
- `fix: resolve window matching issue with Chrome profiles`

## Reporting Issues

Use [GitHub Issues](https://github.com/minsang-alt/contextSwitcher/issues) with the provided templates:

- **Bug Report** — Include macOS version, steps to reproduce, and screenshots
- **Feature Request** — Describe the problem and proposed solution

## Architecture Overview

```
ContextSwitcher/
├── Models/      # Data models
├── Services/    # Core business logic (Accessibility, Shortcuts, Workspace)
├── Views/       # SwiftUI views
├── Panel/       # AppKit floating panel
├── Utilities/   # Helpers
└── Resources/   # Info.plist, AppIcon
```

## License

By contributing, you agree that your contributions will be licensed under GPL-3.0.
