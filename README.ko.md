<p align="center">
  <img src="appicon.png" alt="ContextSwitcher" width="128">
</p>

<h1 align="center">ContextSwitcher</h1>

<p align="center">
  <a href="https://github.com/minsang-alt/contextSwitcher/actions/workflows/build.yml"><img src="https://github.com/minsang-alt/contextSwitcher/actions/workflows/build.yml/badge.svg" alt="Build"></a>
  <a href="https://github.com/minsang-alt/contextSwitcher/releases/latest"><img src="https://img.shields.io/github/v/release/minsang-alt/contextSwitcher" alt="Release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/minsang-alt/contextSwitcher" alt="License"></a>
  <img src="https://img.shields.io/badge/platform-macOS%2014%2B-blue" alt="Platform">
  <img src="https://img.shields.io/badge/swift-6.0-orange" alt="Swift">
</p>

<p align="center">
  <a href="README.md">English</a> | <a href="README.ko.md">한국어</a>
</p>

<p align="center">
  여러 프로젝트를 오가는 개발자를 위한 가벼운 macOS 메뉴바 유틸리티.<br>
  윈도우 배치를 워크스페이스로 저장하고 즉시 전환하세요.
</p>

---

## 데모

https://github.com/user-attachments/assets/010d90dd-5c32-4f04-9d9f-1386d15954ed

## 주요 기능

- **워크스페이스 관리** — 현재 윈도우 배치를 이름 있는 워크스페이스로 저장
- **즉시 전환** — 메뉴바에서 워크스페이스 간 즉시 전환
- **글로벌 단축키** — 어떤 앱에서든 키보드 단축키로 워크스페이스 전환
- **윈도우 단위 제어** — 개별 윈도우를 선택적으로 표시/숨김 (예: 특정 IntelliJ 프로젝트)
- **플로팅 HUD** — 빠른 접근을 위한 플로팅 패널
- **전체 복원** — 한 번의 클릭으로 숨긴 모든 앱 복원

## 설계 철학

ContextSwitcher는 명확한 원칙을 따릅니다:

- **성능** — 애니메이션 지연 없는 즉시 전환
- **단순함** — 컨텍스트 전환 하나만 잘합니다
- **비침습적** — 기존 워크플로를 방해하지 않습니다
- **투명함** — 메뉴바에 살며, 방해하지 않습니다

### 동작 방식

ContextSwitcher는 macOS Accessibility API를 사용하여 **앱 윈도우를 숨기고 표시**합니다. 워크스페이스로 전환하면, 해당 워크스페이스에 속하지 않는 앱은 숨겨지고 속하는 앱이 전면으로 나옵니다. 가상 데스크톱과는 근본적으로 다릅니다 — 윈도우는 같은 Space에 그대로 있습니다.

### 왜 타일링이 없나요?

ContextSwitcher는 의도적으로 윈도우 위치나 타일링을 관리하지 **않습니다**. 그건 전용 도구(Rectangle, Magnet, yabai)가 훨씬 잘합니다. ContextSwitcher는 **어떤 앱이 보이는지**에만 집중하여, 어떤 윈도우 매니저와도 조합할 수 있습니다.

## 설치

### 바이너리 다운로드

| 플랫폼 | 다운로드 |
|--------|----------|
| macOS 14+ (Apple Silicon) | [ContextSwitcher-1.2.0-arm64.dmg](https://github.com/minsang-alt/contextSwitcher/releases/latest/download/ContextSwitcher-1.2.0-arm64.dmg) |

> DMG를 열고 `ContextSwitcher.app`을 `/Applications`로 드래그하세요.
>
> **macOS Gatekeeper 경고:** 아직 공증되지 않은 앱이라 경고가 뜰 수 있습니다:
> - Finder에서 `ContextSwitcher.app`을 **우클릭 → 열기**
> - 또는: `xattr -cr /Applications/ContextSwitcher.app`

### Homebrew (준비 중)

```bash
brew install --cask minsang-alt/tap/contextswitcher
```

### 소스에서 빌드

```bash
git clone https://github.com/minsang-alt/contextSwitcher.git
cd ContextSwitcher
./scripts/install.sh
```

**요구사항:** Xcode 15+ 또는 Swift 6.0 툴체인

## 설정

실행 후 접근성 권한을 부여하세요:

1. **시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용** 열기
2. **ContextSwitcher**를 추가하고 토글 ON

> **참고:** 접근성 권한은 다시 빌드할 때마다 초기화됩니다. OFF 후 다시 ON 하세요.

## 사용법

1. 프로젝트에 맞게 **윈도우를 배치**
2. 메뉴바 아이콘 → **"+"** 클릭하여 워크스페이스 캡처
3. **이름을 지정**하고 포함할 앱/윈도우 선택
4. **워크스페이스 이름**을 클릭하여 컨텍스트 전환
5. **"Show All Apps"**를 클릭하여 모든 앱 복원

### 키보드 단축키

워크스페이스에 글로벌 단축키를 할당하여 즉시 전환:

1. 메뉴바 → 워크스페이스 설정 열기
2. 단축키 필드를 클릭하고 원하는 키 조합 입력
3. 어떤 앱에서든 단축키로 즉시 전환

### 팁

- **JetBrains IDE**: 개별 프로젝트 윈도우를 인식하여, 특정 IntelliJ/WebStorm 프로젝트만 워크스페이스에 포함 가능
- **브라우저**: Chrome, Brave, Edge 프로필을 개별 인식
- **조합 사용**: Rectangle/Magnet과 함께 사용하여 완전한 윈도우 관리 가능

## 아키텍처

```
ContextSwitcher/
├── Models/          # 데이터 모델 (KeyShortcut, WindowIdentifier, WorkspaceConfiguration)
├── Services/        # 핵심 로직 (Accessibility, Shortcuts, WorkspaceSwitch, Store)
├── Views/           # SwiftUI 뷰 (MenuBar, WorkspaceList, Capture, HUD, ShortcutRecorder)
├── Panel/           # AppKit 플로팅 패널 (HUD, Capture 컨트롤러)
├── Utilities/       # 헬퍼 (IntelliJ 타이틀 파서)
└── Resources/       # Info.plist, AppIcon
```

## 기여

[CONTRIBUTING.md](CONTRIBUTING.md)를 참조하세요.

**빠른 시작:**

```bash
# 개발 의존성 설치
brew bundle

# 빌드 및 설치
./scripts/install.sh

# 린트
swiftlint lint
swiftformat --lint .
```

PR 제목은 [Conventional Commits](https://www.conventionalcommits.org/)를 따라야 합니다: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `ci:`

## 라이선스

GPL-3.0. 자세한 내용은 [LICENSE](LICENSE)를 참조하세요.
