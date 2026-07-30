# Codex & Claude Info — Windows POC

Windows 10/11 시스템 트레이에서 Codex와 Claude 사용량을 확인하는 Tauri 2 기반
1차 POC입니다.

## 현재 구현

- 트레이 아이콘을 클릭해 390px 대시보드 열기
- Codex와 Claude 탭 전환
- Codex `app-server`의 사용률, 리셋 시각, 토큰 사용량 표시
- `%USERPROFILE%\.codex\config.toml`에서 Codex 모델 감지
- Claude Desktop의 최신 세션 모델, effort, 작업 제목 감지
- Claude Desktop의 5시간·7일 사용률 표시
- 기존 짱구 코디 펫 표시
- 창을 닫아도 트레이에서 계속 실행
- NSIS `setup.exe`와 WiX `.msi` 패키징

## 요구 사항

- Windows 10/11
- WebView2 Runtime
- Windows용 Codex CLI가 설치되어 있고 `codex`가 `PATH`에 등록된 상태
- Claude 정보 사용 시 Claude Desktop 또는 Claude Code
- Node.js 22 이상
- Rust stable 및 Microsoft C++ Build Tools

## 개발 실행

PowerShell에서:

```powershell
cd windows
npm install
npm run tauri dev
```

앱은 처음에 창을 숨긴 상태로 시작합니다. 작업 표시줄 알림 영역의 아이콘을
클릭하면 대시보드가 열립니다.

## 설치 파일 만들기

```powershell
cd windows
npm ci
npm run tauri build
```

결과물:

- `src-tauri\target\release\bundle\nsis\*-setup.exe`
- `src-tauri\target\release\bundle\msi\*.msi`

GitHub의 **Windows POC** Actions 워크플로를 수동 실행해도 두 설치 파일을
Artifact로 받을 수 있습니다.

## POC 한계

- Claude Desktop의 로컬 저장 구조는 공식 API가 아니므로 Desktop 업데이트에
  따라 경로 또는 필드가 달라질 수 있습니다.
- Claude 리셋 시각은 Desktop의 사용률 기록에 포함되지 않아 `확인 중`으로
  표시합니다.
- Claude CLI가 WSL 안에만 설치된 경우 WSL 경로 자동 탐색은 다음 단계에서
  추가해야 합니다.
- Windows 코드 서명 인증서가 없으므로 배포 설치 파일에 SmartScreen 경고가
  표시될 수 있습니다.
