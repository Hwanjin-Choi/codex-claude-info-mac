macOS와 Windows에서 설치 파일을 받아 실행할 수 있는 v1.0.0 배포입니다.

## 받을 파일

- **Mac:** `Codex-Claude-Info-1.0.0-macos-universal.dmg` — macOS 14 이상, Apple Silicon·Intel 공용. 앱을 Applications로 드래그하세요.
- **Windows:** `Codex-Claude-Info-1.0.0-windows-x64-setup.exe` — Windows 10 22H2 / Windows 11 x64. 한국어 설치 안내와 WebView2 bootstrapper가 포함됩니다.
- **Mac ZIP:** DMG 대신 사용할 수 있는 동일 앱의 압축본.
- **SHA256SUMS.txt:** 설치 파일 무결성 확인용.

[처음부터 따라 하는 상세 설치·로그인·업데이트 가이드](https://github.com/Hwanjin-Choi/codex-claude-info-mac/blob/main/docs/INSTALL.md)

## 이번 배포

- Windows NSIS 설치 파일 배포 및 설치·실행·중복 실행·삭제 자동 검사
- macOS arm64/x86_64 공용 빌드, 기본 펫·아이콘의 재현 가능한 패키징
- Codex 연결 응답 제한 시간, Windows 수집 프로세스 종료·회수, Mac 동시 초기화·중복 폴링 보완
- Windows 사용자 펫 표시, 로컬 텍스트 이스케이프, 어제 토큰의 날짜 기준 집계
- 조회할 수 없는 Windows 토큰을 확인 불가로 표시
- 기존 Mac 펫 재디코딩·Claude 반복 파싱 최적화 포함

## 설치 전에 확인

이 앱은 OpenAI·Anthropic 공식 제품이 아닙니다. Codex 정보에는 본인의 Codex 설치·로그인이 필요하며, Windows는 Windows용 Codex CLI를 사용합니다. WSL 자동 연결은 지원하지 않습니다.

Windows에는 Mac의 모든 기능이 포함되어 있지 않습니다. Windows Claude 토큰·정확한 리셋·컨텍스트·Code hooks와 차트·알림·리셋 이력은 미지원입니다. [기능 비교표](https://github.com/Hwanjin-Choi/codex-claude-info-mac#어떤-정보가-보이나요)를 확인하세요.

Apple Developer ID 공증 및 Windows 게시자 서명이 없어 첫 실행 경고가 나올 수 있습니다. 해제 절차는 설치 가이드에 설명했습니다. WebView2 설치 시 인터넷 연결이 필요할 수 있습니다. 여러 시간·며칠의 메모리 안정성은 별도 검증 대상입니다.
