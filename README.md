<div align="center">
  <img src="Resources/AppIcon.svg" width="128" alt="Codex Info icon">
  <h1>Codex Info for macOS</h1>
  <p>Codex 사용량, 리셋 시각, 모델과 작업 상태를 메뉴바에서 확인하는 작은 앱입니다.</p>
  <p>
    <a href="https://github.com/Hwanjin-Choi/codex-info-mac/releases/latest">
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
- 30초 자동 갱신

## 설치 방법

1. [Releases](https://github.com/Hwanjin-Choi/codex-info-mac/releases/latest)에서
   `Codex-Info-0.1.0.dmg`를 다운로드합니다.
2. DMG를 열고 `Codex Info.app`을 `Applications` 폴더로 드래그합니다.
3. 응용 프로그램 폴더에서 **Codex Info**를 실행합니다.
4. 메뉴바의 계기판 아이콘을 누르면 사용량을 확인할 수 있습니다.

이 앱은 Apple Developer ID로 공증되지 않았습니다. macOS에서 개발자를 확인할
수 없다는 메시지가 나오면 앱을 `Control`-클릭하고 **열기**를 선택한 뒤 다시
**열기**를 누르세요.

## 요구 사항

- macOS 14 Sonoma 이상
- ChatGPT 또는 Codex 앱/CLI 설치
- Codex에 ChatGPT 계정으로 로그인된 상태

## 데이터와 개인정보

앱은 인증 토큰을 직접 읽거나 외부 서버로 전송하지 않습니다. 설치된
`codex app-server`의 공식 `account/rateLimits/read`, `account/usage/read`,
`model/list` 인터페이스를 사용합니다.

리셋 이력과 펫 설정은 해당 Mac의 `UserDefaults`에만 저장됩니다. 배포 파일에는
제작자의 계정, 로그인 정보 또는 사용량이 포함되지 않습니다.

## 소스에서 빌드

```bash
zsh scripts/build-app.sh
open "dist/Codex Info.app"
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
