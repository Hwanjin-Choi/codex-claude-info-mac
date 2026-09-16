Codex 주간 사용량 표시를 바로잡은 v1.0.1 수정 배포입니다.

## 받을 파일

- **Mac:** `Codex-Claude-Info-1.0.1-macos-universal.dmg` — macOS 14 이상, Apple Silicon·Intel 공용. 앱을 Applications로 드래그하세요.
- **Windows:** `Codex-Claude-Info-1.0.1-windows-x64-setup.exe` — Windows 10 22H2 / Windows 11 x64. 한국어 설치 안내와 WebView2 bootstrapper가 포함됩니다.
- **Mac ZIP:** DMG 대신 사용할 수 있는 동일 앱의 압축본.
- **SHA256SUMS.txt:** 설치 파일 무결성 확인용.

[처음부터 따라 하는 상세 설치·로그인·업데이트 가이드](https://github.com/Hwanjin-Choi/codex-claude-info-mac/blob/main/docs/INSTALL.md)

## 이번 배포

- Mac 상태바·사용량 경고·리셋 임박 알림을 일반 `codex`의 7일 한도 기준으로 통일
- `base_model_inference`가 첫 항목으로 정렬되어 상태바에 예비 사용량 0%가 표시되던 오류 수정
- Mac·Windows 카드의 주간/5시간 등 제목을 실제 `windowDurationMins`로 판단하고 일반 Codex 주간 카드를 먼저 표시
- Luna Reserve는 `Luna Reserve (예비)`, Spark 등은 서버의 표시 이름으로 별도 구분
- 일반 Codex의 주간 데이터가 없으면 상태바에 `Codex 주간 —` 표시; 다른 모델·예비 한도의 0%로 대체하지 않음
- 주간 한도가 primary/secondary 어느 쪽에 오든 처리하며, 구형 단일 한도 응답과 설정·펫·리셋 기록 호환 유지
- 같은 응답 예제로 Swift·Rust 회귀 검사를 추가하고 두 OS 배포 검사에 포함

기존 사용량을 초기화하거나 계정 한도를 바꾸는 업데이트가 아닙니다. 인포 앱만 종료한 뒤 새 설치 파일로 덮어 설치하세요.

## 설치 전에 확인

이 앱은 OpenAI·Anthropic 공식 제품이 아닙니다. Codex 정보에는 본인의 Codex 설치·로그인이 필요하며, Windows는 Windows용 Codex CLI를 사용합니다. WSL 자동 연결은 지원하지 않습니다.

Windows에는 Mac의 모든 기능이 포함되어 있지 않습니다. Windows Claude 토큰·정확한 리셋·컨텍스트·Code hooks와 차트·알림·리셋 이력은 미지원입니다. [기능 비교표](https://github.com/Hwanjin-Choi/codex-claude-info-mac#어떤-정보가-보이나요)를 확인하세요.

Apple Developer ID 공증 및 Windows 게시자 서명이 없어 첫 실행 경고가 나올 수 있습니다. 해제 절차는 설치 가이드에 설명했습니다. WebView2 설치 시 인터넷 연결이 필요할 수 있습니다. 여러 시간·며칠의 메모리 안정성은 별도 검증 대상입니다.
