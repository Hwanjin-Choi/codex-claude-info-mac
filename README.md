<div align="center">
  <img src="Resources/AppIcon.svg" width="128" alt="Codex & Claude Info icon">
  <h1>Codex & Claude Info for macOS</h1>
  <p>Codex와 Claude Code 사용량, 리셋 시각, 모델과 작업 상태를 메뉴바에서 확인하는 작은 앱입니다.</p>
  <p>
    <a href="https://github.com/Hwanjin-Choi/codex-claude-info-mac/releases/latest">
      <strong>최신 버전 다운로드</strong>
    </a>
  </p>
</div>

## 주요 기능

- 단기·주간 사용률과 초 단위 리셋 카운트다운
- 최근 사용량 초기화 감지 기록
- 어제 토큰 사용량과 최근 7일 차트
- 현재 작업 모델과 추론 강도
- 작업 중·최근 완료·대기·연결 오류 상태
- 사용량 80%·90% 및 리셋 임박 알림
- 상태에 반응하는 Codex 펫과 크기·속도 설정
- 한 앱에서 Codex와 Claude 탭 전환
- Claude Code 작업 중·승인 대기·완료·오류 감지
- Claude 5시간·7일 사용률, 모델, effort, 컨텍스트 표시
- 30초 자동 갱신

## 설치 방법

1. [Releases](https://github.com/Hwanjin-Choi/codex-claude-info-mac/releases/latest)에서
   최신 `Codex-Claude-Info-*.dmg`를 다운로드합니다.
2. DMG를 열고 `Codex & Claude Info.app`을 `Applications` 폴더로 드래그합니다.
3. 응용 프로그램 폴더에서 **Codex & Claude Info**를 실행합니다.
4. 메뉴바의 계기판 아이콘을 누르면 사용량을 확인할 수 있습니다.

이 앱은 Apple Developer ID로 공증되지 않았습니다. macOS에서 개발자를 확인할
수 없다는 메시지가 나오면 앱을 `Control`-클릭하고 **열기**를 선택한 뒤 다시
**열기**를 누르세요.

## 요구 사항

- macOS 14 Sonoma 이상
- ChatGPT 또는 Codex 앱/CLI 설치
- Codex에 ChatGPT 계정으로 로그인된 상태
- Claude 탭 사용 시 Claude Code 2.1.196 이상
- Claude 사용률은 Claude.ai Pro/Max 로그인 계정에서 제공

## 데이터와 개인정보

앱은 인증 토큰을 직접 읽거나 외부 서버로 전송하지 않습니다. 설치된
`codex app-server`의 공식 `account/rateLimits/read`, `account/usage/read`,
`model/list` 인터페이스를 사용합니다.

리셋 이력과 펫 설정은 해당 Mac의 `UserDefaults`에만 저장됩니다. 배포 파일에는
제작자의 계정, 로그인 정보 또는 사용량이 포함되지 않습니다.

Claude 탭에서 **연동 설치**를 누르면 `~/.claude/settings.json`을 먼저 백업한 뒤
status line과 hooks 항목을 추가합니다. 기존 hooks는 삭제하지 않으며, 기존 status
line 명령이 있으면 그 출력을 그대로 유지합니다.

## 소스에서 빌드

```bash
zsh scripts/build-app.sh
open "dist/Codex & Claude Info.app"
```

로컬에 `~/.codex/pets/jjanggu-codi/spritesheet.webp`가 있으면 빌드 시 펫으로
포함합니다. 파일이 없어도 앱은 기본 발바닥 이미지로 정상 실행됩니다.

배포용 DMG와 ZIP 생성:

```bash
zsh scripts/package-release.sh
```

## 아이콘

[Lucide Gauge](https://lucide.dev/icons/gauge)를 사용했으며 라이선스 고지는
`Resources/THIRD_PARTY_NOTICES.txt`에 포함되어 있습니다.
