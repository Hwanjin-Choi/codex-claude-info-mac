# Codex & Claude Info 설치 가이드

**v1.0.0** 기준입니다. 일반 사용자는 개발 도구 없이 설치 파일로 설치할 수 있습니다.

## 목차

- [받을 파일 고르기](#download)
- [Mac 설치](#macos)
- [Windows 설치](#windows)
- [Codex 로그인 및 연결](#codex-setup)
- [Claude 연결](#claude-setup)
- [펫과 사용 방법](#usage)
- [업데이트·자동 시작](#update)
- [삭제·연동 해제](#uninstall)
- [문제 해결](#troubleshooting)
- [메모리·CPU 진단](#performance)
- [다운로드 검증](#checksum)

<a id="download"></a>
## 1. 받을 파일 고르기

1. [최신 릴리스 페이지](https://github.com/Hwanjin-Choi/codex-claude-info-mac/releases/latest)를 엽니다. 공개 릴리스 파일은 GitHub 로그인 없이 받을 수 있습니다.
2. 아래쪽 **Assets**를 펼칩니다.
3. 자신의 컴퓨터에 해당하는 파일 하나를 클릭합니다.

| 파일 | 용도 |
|---|---|
| `Codex-Claude-Info-1.0.0-macos-universal.dmg` | Mac 설치용. M 시리즈·Intel 공용 |
| `Codex-Claude-Info-1.0.0-macos-universal.zip` | 동일한 Mac 앱의 압축본. DMG 대신 선택 가능 |
| `Codex-Claude-Info-1.0.0-windows-x64-setup.exe` | Windows 설치용. Intel/AMD 64비트 |
| `SHA256SUMS.txt` | 다운로드 검증용. 설치 프로그램이 아님 |
| `Source code (zip / tar.gz)` | 개발자용 소스. 일반 사용자는 필요 없음 |

Mac: Apple 메뉴 → **이 Mac에 관하여**에서 macOS 14 이상인지 확인합니다. Windows: 설정 → 시스템 → 정보 → **시스템 종류**에서 x64인지 확인합니다. Windows ARM64는 이번 릴리스의 검증 대상이 아닙니다.

<a id="macos"></a>
## 2. Mac 설치

### 응용 프로그램으로 복사

1. 다운로드 폴더에서 `.dmg`를 더블클릭합니다.
2. 열린 창의 `Codex & Claude Info.app`을 `Applications` 바로가기로 드래그합니다.
3. 복사가 끝날 때까지 기다립니다.
4. Finder → **응용 프로그램**에서 `Codex & Claude Info`를 더블클릭합니다. DMG 내부 앱을 계속 실행하지 마세요.
5. 화면 오른쪽 위 메뉴 막대의 계기판 아이콘을 누릅니다.
6. Finder 사이드바에서 설치 디스크 옆 꺼내기 버튼을 누릅니다. 다운로드한 DMG는 보관하거나 휴지통으로 옮겨도 설치된 앱에 영향이 없습니다.

ZIP을 받은 경우: 압축 해제 → 생성된 `.app`을 응용 프로그램 폴더로 이동 → 실행하면 됩니다. 두 형식을 모두 설치하지 않아도 됩니다.

### 앱 창이나 Dock 아이콘이 없는 이유

메뉴 막대 앱이므로 일반 앱처럼 큰 창이나 Dock 아이콘이 항상 나타나지는 않습니다. 메뉴 막대 아이콘을 눌러 정보 창을 여세요. 다시 실행하려면 응용 프로그램 폴더 또는 Spotlight에서 **Codex & Claude Info**를 검색합니다. Launchpad를 사용하는 macOS에서는 등록·검색 반영에 시간이 걸릴 수 있습니다.

<a id="macos-first-run"></a>
### 처음 실행할 때 개발자 확인 경고

이 릴리스는 ad-hoc 서명이며 **Apple Developer ID 서명·공증을 받지 않았습니다**.

1. 응용 프로그램 폴더에서 앱을 한 번 실행합니다.
2. 개발자 확인 불가 또는 Apple이 악성 소프트웨어 여부를 확인할 수 없다는 안내가 나오면 대화상자를 닫습니다.
3. **시스템 설정 → 개인정보 보호 및 보안**을 엽니다.
4. 아래 보안 영역의 앱 차단 항목에서 **확인 없이 열기 / Open Anyway**를 누릅니다. OS 버전에 따라 문구가 다를 수 있습니다.
5. Mac 암호 또는 Touch ID로 확인하고 앱을 엽니다.

이 GitHub 릴리스에서 직접 받은 파일인지 확인한 후 진행하세요. [Apple 공식 안내](https://support.apple.com/ko-kr/102445)를 참고할 수 있습니다. 회사 관리 정책으로 버튼이 없으면 관리자에게 문의하세요. 시스템 전체 보안 기능을 끄는 절차는 필요하지 않습니다.

<a id="windows"></a>
## 3. Windows 설치

### 설치 프로그램 실행

1. 다운로드 폴더에서 `Codex-Claude-Info-1.0.0-windows-x64-setup.exe`를 실행합니다.
2. 언어 선택 창에서 **Korean / 한국어**를 선택합니다.
3. 안내에 따라 다음 단계로 이동합니다. 기본 설치 위치를 그대로 사용해도 됩니다.
4. **설치**를 누릅니다. 현재 Windows 사용자 계정에 설치됩니다.
5. **마침**을 누르고 앱을 실행합니다. 실행 선택 항목이 없다면 시작 메뉴에서 **Codex & Claude Info**를 검색합니다.
6. 첫 실행 시 정보 창이 열립니다. 창의 `—` 버튼을 누르면 트레이로 숨길 수 있습니다.
7. 다시 열려면 작업 표시줄 오른쪽 계기판 아이콘을 누릅니다. 없으면 `^` 또는 숨겨진 아이콘 표시를 누릅니다.

여러 번 실행해도 새 인스턴스를 계속 만들지 않고 기존 창을 엽니다. 완전히 끄려면 정보 창의 **종료** 또는 트레이 아이콘 우클릭 → **종료**를 누릅니다.

### WebView2

Windows 화면은 Microsoft Edge WebView2 Runtime을 사용합니다. 작은 WebView2 설치 도구가 설치 파일에 포함되어 있으며, Runtime이 없으면 설치를 시도합니다. 다운로드에는 인터넷 연결이 필요합니다. 완전한 오프라인 설치 패키지는 아닙니다.

회사 정책·네트워크 때문에 실패하면 [Microsoft WebView2 공식 페이지](https://developer.microsoft.com/microsoft-edge/webview2/)에서 **Evergreen Standalone Installer → x64**를 받아 설치한 뒤 다시 실행합니다. 개발자용 SDK는 필요하지 않습니다.

### 개발 도구가 필요한가요?

일반 사용자는 **Rust, Visual Studio, C++ Build Tools, Git, Xcode가 필요 없습니다**. Codex 정보를 보려면 별도 Codex 설치·로그인이 필요합니다. 아래 공식 Windows CLI 설치 방식을 쓰면 Node.js도 필수가 아닙니다. npm 방식을 선택할 때만 Node.js가 필요합니다.

<a id="windows-first-run"></a>
### SmartScreen 경고

Windows 게시자 인증서로 서명되지 않아 **Windows의 PC 보호**가 표시될 수 있습니다. 이 저장소의 릴리스에서 받은 파일인지 확인하고 **추가 정보 → 실행**을 선택할 수 있습니다. OS·조직 정책에 따라 이 선택지가 없을 수도 있습니다.

조직 정책이나 악성 파일 탐지로 차단되면 보안 프로그램을 끄지 말고 차단 내용을 확인하세요. 파일이 손상되었다면 다시 다운로드하고 아래 SHA-256 검증을 이용합니다.

<a id="codex-setup"></a>
## 4. Codex 로그인 및 연결

인포 앱에는 자체 로그인 화면이 없습니다. **해당 OS 사용자 계정에 설치된 Codex**를 사용합니다. 친구에게 보내도 제작자의 계정으로 연결되지 않습니다.

### Mac

1. 공식 ChatGPT/Codex 데스크톱 앱을 설치하고 Codex에 로그인합니다. 인포 앱은 `/Applications/ChatGPT.app` 또는 `/Applications/Codex.app`의 내장 실행 파일을 우선 찾습니다.
2. CLI를 사용하는 경우 [공식 Codex CLI 안내](https://learn.chatgpt.com/docs/cli)를 따라 설치합니다.
3. 터미널에서 `codex`를 실행하고 **Sign in with ChatGPT**로 로그인할 수도 있습니다.
4. 인포 앱의 **Codex → 새로고침**을 누릅니다. 최초 연결에 수 초가 걸릴 수 있습니다.

CLI 탐색 위치는 Homebrew의 `/opt/homebrew/bin`, `/usr/local/bin`, `~/.local/bin` 및 앱이 받은 PATH를 포함합니다. 터미널에서만 설정한 PATH가 Finder로 실행한 앱에는 전달되지 않을 수 있습니다.

### Windows — 공식 CLI 설치 권장

1. 시작 메뉴에서 **PowerShell**을 엽니다.
2. [공식 Codex CLI 설치 안내](https://learn.chatgpt.com/docs/cli)의 Windows 명령을 실행합니다. 문서 확인일: 2026-09-10.

   ```powershell
   powershell -ExecutionPolicy ByPass -c "irm https://chatgpt.com/codex/install.ps1 | iex"
   ```

3. PowerShell을 닫고 다시 열어 PATH 변경을 반영합니다.
4. 설치 확인 후 로그인합니다.

   ```powershell
   codex --version
   codex
   ```

5. **Sign in with ChatGPT**를 선택하고 브라우저의 로그인을 마칩니다.
6. 인포 앱을 완전히 종료했다가 다시 실행하고 **Codex → 새로고침**을 누릅니다.

이미 Node.js/npm을 사용한다면 `npm install -g @openai/codex`로 설치해도 됩니다. PowerShell이 `codex.ps1`을 막으면 `codex.cmd`로 로그인할 수 있습니다. 인포 앱은 PATH·`%USERPROFILE%\.local\bin`·일반 npm 설치 위치의 네이티브 `codex.exe`를 탐색합니다.

**WSL에만 설치·로그인한 Codex는 자동 연결하지 않습니다.** Windows CLI에서 별도로 로그인하세요. Windows 공식 데스크톱 앱만 설치된 환경에서도 CLI를 추가하는 것이 현재 가장 확실한 연결 방법입니다.

### 정상 연결 확인

- 사용률·리셋 시간이 나타나면 한도 조회가 성공한 상태입니다.
- 토큰은 해당 Codex 버전이 토큰 조회 기능을 제공할 때만 표시됩니다. 다른 카드가 연결되어도 토큰은 확인 불가일 수 있습니다.
- ChatGPT 계정 한도와 API 키 종량제 결제는 별개입니다. API 키 로그인에서는 이 앱이 기대하는 계정 사용률이 없을 수 있습니다.
- Windows 모델 카드는 설정 파일에 지정된 모델입니다. 모든 세션의 실제 모델을 실시간으로 판별하는 기능은 아닙니다.

<a id="claude-setup"></a>
## 5. Claude 연결

### Claude Desktop — 두 OS 공통

1. [Claude Desktop](https://claude.ai/download)을 설치하고 본인의 계정으로 로그인합니다.
2. Claude에서 작업한 후 인포 앱의 **Claude** 탭을 엽니다.
3. 로컬 사용률·세션 기록이 생성되어 있으면 정보를 표시합니다.

로그인만으로 모든 정보가 생기지는 않습니다. 일반 채팅과 Code 세션 기록은 다르며 Desktop 버전에 따라 일부 파일이 없을 수 있습니다. 사용률만 있으면 모델은 대기 중일 수 있고, 모델만 있어도 사용률이 비어 있을 수 있습니다. Desktop 파일 구조는 공개된 안정적인 API가 아니므로 업데이트에 따라 감지가 달라질 수 있습니다.

### Claude Code 추가 연동 — Mac만 지원

1. Claude Code를 설치·로그인한 상태에서 인포 앱의 **Claude** 탭을 엽니다.
2. **연동 설치**를 한 번 누릅니다.
3. 앱은 `~/.claude/settings.json`을 `~/.claude/backups/`에 백업한 뒤 상태줄·hooks를 추가합니다.
4. Claude Code 세션을 종료하고 다시 실행합니다.
5. 새 메시지를 한 번 보내고 인포 앱에서 데이터가 들어오는지 확인합니다.

연동된 Code가 제공하는 경우 모델·컨텍스트·작업 상태·5시간/7일 한도·정확한 리셋 시각이 표시됩니다. 계정·Code 버전에 따라 일부 값이 없을 수 있습니다. 기존 설정은 유효한 JSON이어야 합니다.

Windows v1.0.0에는 연동 설치 버튼, Claude 토큰·컨텍스트·정확한 리셋 시각·Code hooks 지원이 없습니다. 미지원 토큰을 0으로 추측하지 않습니다.

<a id="usage"></a>
## 6. 펫과 사용 방법

- 위쪽 **Codex / Claude**로 전환합니다.
- Mac: **펫 설정 → 펫 이미지 선택**. Windows: 상단 **펫 변경**.
- PNG/JPG/WebP/GIF, 최대 15MB를 선택합니다. 이미지가 앱 로컬 저장소에 보관되며 업로드되지 않습니다.
- 큰 애니메이션은 압축 파일 용량보다 많은 메모리를 쓸 수 있습니다. 작은 해상도·적은 프레임의 이미지가 유리합니다.
- **기본 펫 복원 / 기본 펫**을 누르면 기본 캐릭터로 돌아갑니다.
- Mac은 애니메이션 토글을 지원합니다. 속도 설정은 기본 스프라이트에 적용되며 사용자 GIF 등의 속도는 원본 파일을 따릅니다. Windows에는 별도 애니메이션 토글이 없습니다.
- Codex 데이터는 기본 30초 간격으로 갱신합니다. Windows는 창이 숨김 상태로 보고되는 동안 주기 조회를 쉬고 다시 보일 때 갱신합니다.
- Mac Claude는 상태 파일 약 2초, Desktop 약 15초, 토큰 약 30초 간격입니다.
- Codex 요청은 응답이 없으면 요청당 약 15초 후 제한 시간이 끝납니다. Windows 최초 수집은 여러 요청을 순서대로 처리해 더 걸릴 수 있습니다.

<a id="update"></a>
## 7. 업데이트·자동 시작

### 업데이트

자동 업데이트 기능은 없습니다. [최신 릴리스](https://github.com/Hwanjin-Choi/codex-claude-info-mac/releases/latest)에서 새 파일을 받습니다.

**Mac:** 인포 앱 **종료** → 새 DMG → `.app`을 응용 프로그램으로 드래그 → **대치** → 실행. 기존 펫·설정·리셋 기록은 앱 외부에 저장되어 일반적인 앱 교체 시 유지됩니다. 연동 도구 자체도 갱신해야 한다면 [개발 안내](DEVELOPMENT.md)의 `ClaudeInfoBridge --install` 절차를 사용합니다.

**Windows:** 트레이에서 **종료** → 새 `setup.exe` → 기존 위치로 설치 → 실행. 같은 사용자·같은 앱 식별자로 업데이트하면 사용자 펫 저장소를 유지합니다. 삭제 시 앱 데이터를 지웠다면 유지되지 않습니다.

Codex 본체를 삭제하거나 로그아웃할 필요는 없습니다. Mac에 옛 `Codex Info.app`과 새 앱이 함께 있다면 새 앱을 확인한 뒤 옛 앱만 휴지통으로 옮겨 중복 실행을 피하세요.

### OS 로그인 시 시작

앱 자체 자동 시작 설정은 없습니다. 원할 때 OS 기능으로 등록합니다.

- **Mac:** 시스템 설정 → 일반 → 로그인 항목(및 확장 프로그램) → 로그인 시 열기에 `/Applications/Codex & Claude Info.app` 추가.
- **Windows:** `Win + R` → `shell:startup` → 확인. 시작 메뉴의 앱 바로가기를 이 폴더에 복사합니다. 시작 시 창을 숨기려면 바로가기 속성의 대상 끝, 경로 큰따옴표 바깥에 공백과 `--hidden`을 붙입니다.

  ```text
  "C:\실제 설치 경로\codex-claude-info.exe" --hidden
  ```

<a id="uninstall"></a>
## 8. 삭제·연동 해제

### 앱 삭제

- **Mac:** 인포 앱 종료 → 응용 프로그램의 앱을 휴지통으로 이동 → 등록한 로그인 항목 제거.
- **Windows:** 인포 앱 종료 → 설정 → 앱 → 설치된 앱 → **Codex & Claude Info → 제거**. `shell:startup`에 직접 만든 바로가기도 제거합니다.

Codex·Claude 본체와 계정·대화 기록은 별개이므로 삭제하지 않습니다.

### Mac Claude Code 연동 해제

앱을 삭제해도 외부에 복사한 연동 도구·hooks는 남습니다. 연동까지 해제하려면 Claude Code를 종료하고 진행합니다.

1. `~/.claude/settings.json`을 별도로 백업합니다.
2. JSON 편집기에서 `hooks`의 명령 중 `ClaudeInfoBridge`를 실행하는 항목만 제거합니다. 다른 도구의 hooks는 보존합니다.
3. `statusLine.command`가 `ClaudeInfoBridge`를 실행한다면 연동 전 상태줄로 복원하거나 해당 `statusLine` 항목을 제거합니다. 기존 명령은 `~/Library/Application Support/Claude Info/original-statusline-command.txt`에 보관되어 있을 수 있습니다.
4. JSON 쉼표·괄호를 확인하고 Claude Code를 다시 실행합니다.
5. 연동이 해제된 후 Finder의 **이동 → 폴더로 이동**에서 `~/Library/Application Support/Claude Info`를 열어 불필요한 연동 파일을 휴지통으로 옮길 수 있습니다.

`~/.claude/backups/settings-before-claude-info-*.json`은 연동 직전 설정입니다. 이후 다른 설정을 바꿨다면 백업으로 전체를 덮어쓸 때 그 변경을 잃을 수 있으므로 필요한 항목만 비교·복원하세요.

### 로컬 데이터 위치

| OS | 위치 | 내용 |
|---|---|---|
| Mac | `~/Library/Preferences/com.local.codexinfo.plist` | 펫 설정·리셋 이력 등 UserDefaults |
| Mac | `~/Library/Application Support/Codex & Claude Info/` | 사용자 펫 |
| Mac | `~/Library/Application Support/Claude Info/` | 연동 도구·상태·원래 상태줄 명령 |
| Windows | `%LOCALAPPDATA%\com.hwanjin.codex-claude-info\` | Tauri/WebView2·IndexedDB 펫 저장소 |

앱 삭제 후 데이터를 보관하면 재설치에 활용할 수 있습니다. 데이터까지 지우려면 앱 종료 후 해당 인포 앱 데이터만 백업·제거하세요. `.codex`·`.claude` 폴더 전체를 삭제할 필요는 없습니다.

<a id="troubleshooting"></a>
## 9. 문제 해결

| 증상 | 확인할 내용 |
|---|---|
| Mac에서 실행했는데 창이 없음 | 메뉴 막대 아이콘을 누르세요. Dock에 항상 표시되지 않습니다. |
| Windows 아이콘이 안 보임 | 오른쪽 `^`를 확인하거나 시작 메뉴에서 다시 실행하세요. |
| Windows에서 종료되거나 빈 창 | x64 파일인지, WebView2가 설치되었는지 확인하고 재실행하세요. |
| Codex를 찾을 수 없음 | CLI 설치·로그인 후 앱을 완전히 재시작하세요. Windows는 WSL이 아닌 Windows CLI가 필요합니다. |
| 사용률은 있고 토큰은 없음 | 해당 Codex 버전이 토큰 조회를 제공하지 않을 수 있습니다. 토큰과 계정 한도는 별도 조회입니다. |
| 어제 토큰이 0 | 해당 OS 날짜 기준 어제 기록이 없을 수 있습니다. Windows 미지원 Claude 토큰은 확인 불가로 표시합니다. |
| 모델이 현재 선택과 다름 | Windows는 Codex 설정 모델입니다. Mac도 최근 로컬 작업 또는 설정으로 추정합니다. 모든 세션 모델을 추적하지 않습니다. |
| Claude 로그인했는데 정보 없음 | Desktop의 로컬 사용률·Code 세션 파일이 있어야 합니다. 일반 채팅 로그인만으로 모든 정보가 생성되지 않습니다. |
| Claude 리셋 시각 확인 중 | Desktop 사용률만으로 정확한 시각을 알 수 없습니다. Mac Code 연동에서 제공될 때 표시됩니다. |
| Claude 연동 설치 실패 | 설정 JSON·파일 권한을 확인합니다. 앱을 응용 프로그램 폴더로 옮겨 재실행하세요. |
| 펫이 크거나 느림 | 작은 이미지로 바꾸거나 Mac에서 애니메이션을 끄고 비교하세요. |
| 화면 아래가 안 보임 | 창 안에서 스크롤하고 Windows 배율·해상도를 확인하세요. |
| 아이콘이 두 개 | Mac의 옛 앱·개발용 실행본이 함께 켜졌는지 확인하세요. Windows 배포 앱은 중복 실행을 제한합니다. |

초기화 이력은 앱이 관찰한 변화입니다. 앱이 꺼진 동안의 모든 리셋을 복원하거나 특정 자동화가 초기화했는지를 인증하지 않습니다.

<a id="performance"></a>
## 10. 메모리·CPU 진단

1. 버벅일 때 재시작 전에 활동 모니터/작업 관리자를 엽니다.
2. 인포 앱과 **그 자식 `codex` 프로세스**를 함께 확인합니다. 공식 Codex 본체와 구분합니다.
3. 시작 시각·문제 발생 시각·CPU·메모리·프로세스 수를 기록합니다. Mac RSS와 footprint는 다를 수 있으므로 같은 지표끼리 비교합니다.
4. 인포 앱만 종료했을 때 CPU·메모리 증가가 멈추는지 비교합니다. 다른 앱의 이미 할당된 메모리는 바로 줄지 않을 수 있습니다.
5. 인포 창 열림/닫힘·사용자 펫 유무를 비교합니다. Mac에서는 높은 CPU 프로세스의 **프로세스 샘플**을 저장할 수 있습니다.

빌드·짧은 실행 검증은 여러 시간·며칠 동안의 누수 부재를 보증하지 않습니다. [Issues](https://github.com/Hwanjin-Choi/codex-claude-info-mac/issues)에 OS·버전·재현 순서·각 프로세스 수치를 남겨 주세요. 계정 토큰·인증 파일·전체 대화는 첨부하지 마세요.

<a id="checksum"></a>
## 11. 다운로드 검증

릴리스의 설치 파일과 `SHA256SUMS.txt`를 받습니다. 체크섬은 동일 파일 여부를 확인하며 게시자 서명이나 공증을 대신하지 않습니다.

**Mac 터미널:**

```bash
cd ~/Downloads
shasum -a 256 Codex-Claude-Info-1.0.0-macos-universal.dmg
```

**Windows PowerShell:**

```powershell
cd "$env:USERPROFILE\Downloads"
Get-FileHash .\Codex-Claude-Info-1.0.0-windows-x64-setup.exe -Algorithm SHA256
```

출력 해시를 `SHA256SUMS.txt`에서 해당 파일의 해시와 비교합니다. 다르면 실행하지 말고 공식 릴리스에서 다시 받습니다.
