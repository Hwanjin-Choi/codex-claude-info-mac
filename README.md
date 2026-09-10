<div align="center">
  <img src="Resources/AppIcon.svg" width="112" alt="Codex & Claude Info 아이콘">
  <h1>Codex & Claude Info</h1>
  <p>macOS 메뉴 막대와 Windows 시스템 트레이에서 Codex·Claude 정보를 확인하세요.</p>
  <p><a href="https://github.com/Hwanjin-Choi/codex-claude-info-mac/releases/latest"><strong>최신 설치 파일 다운로드</strong></a> · <a href="docs/INSTALL.md"><strong>처음부터 따라 하는 설치 가이드</strong></a></p>
</div>

## 다운로드

**사용자는 소스를 빌드할 필요가 없습니다.** 아래 설치 파일 하나를 받으세요.

| 내 컴퓨터 | v1.0.0 설치 파일 | 요구 사항 |
|---|---|---|
| Mac — Apple Silicon 또는 Intel | [macOS 공용 DMG](https://github.com/Hwanjin-Choi/codex-claude-info-mac/releases/download/v1.0.0/Codex-Claude-Info-1.0.0-macos-universal.dmg) | macOS 14 Sonoma 이상 |
| Windows — Intel/AMD 64비트 | [Windows setup.exe](https://github.com/Hwanjin-Choi/codex-claude-info-mac/releases/download/v1.0.0/Codex-Claude-Info-1.0.0-windows-x64-setup.exe) | Windows 10 22H2 / Windows 11, x64 |
| Mac — 압축본이 필요한 경우 | [macOS ZIP](https://github.com/Hwanjin-Choi/codex-claude-info-mac/releases/download/v1.0.0/Codex-Claude-Info-1.0.0-macos-universal.zip) | DMG와 동일한 앱 |

Windows ARM64 전용 파일은 제공하지 않습니다. Mac에는 두 CPU용 실행 파일이 함께 들어 있습니다. GitHub의 **Source code (zip)**는 설치 파일이 아닙니다.

이 앱은 OpenAI·Anthropic의 공식 제품이 아닌 독립적인 정보 표시 앱입니다. Apple Developer ID 공증 및 Windows 게시자 서명은 아직 없으므로 첫 실행 시 OS 경고가 나올 수 있습니다. [macOS 경고 안내](docs/INSTALL.md#macos-first-run)와 [Windows 경고 안내](docs/INSTALL.md#windows-first-run)를 확인하세요.

## 3단계 설치

**Mac**

1. DMG를 열고 `Codex & Claude Info.app`을 `Applications`로 드래그합니다.
2. Finder의 **응용 프로그램**에서 앱을 실행합니다.
3. 화면 오른쪽 위 메뉴 막대의 계기판 아이콘을 누릅니다.

**Windows**

1. `Codex-Claude-Info-1.0.0-windows-x64-setup.exe`를 실행합니다.
2. 한국어 설치 안내에 따라 **설치 → 마침**을 누릅니다. 필요한 WebView2는 설치 프로그램이 설치를 시도하며 인터넷 연결이 필요할 수 있습니다.
3. 시작 메뉴에서 앱을 실행합니다. 이후 작업 표시줄 오른쪽 계기판 아이콘 또는 `^` 안에서 다시 열 수 있습니다.

앱 설치와 Codex 로그인은 별개입니다. **Codex 정보를 보려면 이 PC에 Codex가 설치되고 본인의 ChatGPT 계정으로 로그인되어 있어야 합니다.** Windows에서는 Windows용 CLI를 설치해 주세요. WSL 안에만 설치된 CLI는 자동 연결되지 않습니다. [로그인·연동 가이드](docs/INSTALL.md#codex-setup)를 참고하세요.

## 어떤 정보가 보이나요?

| 기능 | macOS | Windows |
|---|---|---|
| Codex / Claude 전환 | 지원 | 지원 |
| Codex 사용률·리셋 시각 | app-server가 제공하면 표시 | app-server가 제공하면 표시 |
| Codex 어제·최근 7일 토큰 | 지원하는 Codex 버전에서 표시 | 지원하는 Codex 버전에서 표시 |
| Codex 모델 | 최근 로컬 작업 → 설정 → 기본 모델 | 설정 파일의 모델 |
| Codex 작업 상태·주간 차트·사용량 알림 | 지원 | 미지원 |
| 최근 초기화 감지 이력 | 지원 | 미지원 |
| Claude Desktop 사용률·최근 모델 | 로컬 기록이 있으면 표시 | 로컬 기록이 있으면 표시 |
| Claude Code 상태줄·hooks 연동 | 앱에서 연동 설치 | 미지원 |
| Claude 정확한 리셋·컨텍스트 | Code 연동 데이터에 값이 있으면 표시 | 미지원 |
| Claude 로컬 토큰 집계 | 지원하는 로컬 JSONL이 있으면 표시 | 미지원 — 확인 불가 표시 |
| 사용자 펫 PNG/JPG/WebP/GIF | 지원 | 지원 |

Windows v1.0.0은 설치 가능한 트레이 버전이며, macOS의 모든 기능을 동일하게 제공하지는 않습니다.

사용률은 **계정 한도의 사용률**이고 토큰은 별도 통계입니다. 값이 없으면 연결 대기·확인 불가로 표시될 수 있습니다. 연결됨은 해당 수집에 성공했다는 뜻이며, 모든 API의 정상 작동을 보장하지는 않습니다. 초기화 기록은 사용률 감소·리셋 시각 변화로 추정하며, 누가 초기화했는지를 판별하거나 초기화를 실행하지 않습니다.

Claude 펫은 이 앱의 장식이며 Claude 자체의 공식 펫 기능과 연결되지는 않습니다.

## 가이드

- [상세 설치·로그인·첫 실행](docs/INSTALL.md)
- [업데이트·자동 시작·삭제](docs/INSTALL.md#update)
- [연결 실패·0 토큰·아이콘 문제 해결](docs/INSTALL.md#troubleshooting)
- [메모리·CPU 진단](docs/INSTALL.md#performance)
- [개발·검증·릴리스 방법](docs/DEVELOPMENT.md)
- [v1.0.0 변경 사항](docs/RELEASE_NOTES.md)

## 개인정보와 저장 위치

배포 파일에는 제작자의 계정·로그인 정보·사용량이 포함되지 않습니다. 인포 앱은 인증 파일을 직접 읽거나 자체 서버로 업로드하지 않습니다. Codex 조회는 설치된 `codex app-server`를 통해 이루어지며, 이 보조 프로그램은 본인의 Codex 인증과 네트워크 연결을 사용합니다.

Claude Desktop 조회는 로컬 파일을 읽습니다. Mac에서 **연동 설치**를 누르면 `~/.claude/settings.json`을 백업한 뒤 상태줄과 hooks를 추가합니다. 기존 hooks를 보존하고, 기존 상태줄 명령이 있으면 그 출력도 전달합니다.

펫과 설정은 해당 기기에 저장됩니다. [데이터 관리·연동 해제 안내](docs/INSTALL.md#uninstall)를 확인하세요.

## 아이콘과 펫

[Lucide Gauge](https://lucide.dev/icons/gauge)를 사용하며 [라이선스 고지](Resources/THIRD_PARTY_NOTICES.txt)를 포함합니다. 기본 펫은 저장소에 포함된 캐릭터 리소스입니다. 사용자 이미지·캐릭터의 권리는 각 권리자에게 있으며, 이 저장소가 해당 캐릭터의 별도 재배포 권리를 부여하는 것은 아닙니다.
