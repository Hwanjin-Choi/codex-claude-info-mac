# 개발 및 릴리스

설치만 하려면 [설치 가이드](INSTALL.md)를 이용하세요. 아래 도구들은 소스를 빌드할 개발자에게만 필요합니다.

## Mac

- macOS 14 이상, Swift 6 이상을 포함한 Xcode 또는 Command Line Tools
- 기본 펫과 아이콘은 저장소에 포함되어 있으며 개인 홈 디렉터리에서 복사하지 않습니다.
- Swift 실행 파일 두 개를 arm64·x86_64로 각각 컴파일한 뒤 lipo로 합칩니다.

```bash
git clone https://github.com/Hwanjin-Choi/codex-claude-info-mac.git
cd codex-claude-info-mac
zsh scripts/check-app-server.sh
zsh scripts/build-app.sh
open "dist/Codex & Claude Info.app"
```

app-server 검사는 Python 3 기반 로컬 가짜 서버로 동시 초기화·RPC 오류·응답 제한 시간·재연결을 확인합니다. 실제 계정에 연결하지 않습니다.

DMG·ZIP 만들기:

```bash
zsh scripts/package-release.sh
```

`dist/`에 공용 앱, DMG, ZIP, macOS 체크섬이 생성됩니다. 최소 macOS 버전은 `Package.swift`, `Resources/Info.plist`, 빌드 target triple의 14.0을 맞춥니다.

설치된 Claude 연동 도구 업데이트(기존 Claude 설정을 백업·수정하는 명령):

```bash
"/Applications/Codex & Claude Info.app/Contents/MacOS/ClaudeInfoBridge" --install
```

## Windows

- Windows x64
- Node.js 22.6 이상
- Rust stable (MSVC 도구 체인)
- Visual Studio Build Tools의 Desktop development with C++와 Windows SDK
- Microsoft WebView2 Runtime

PowerShell에서:

```powershell
git clone https://github.com/Hwanjin-Choi/codex-claude-info-mac.git
cd codex-claude-info-mac\windows
npm ci
npm test
npm run tauri -- dev
```

검증·배포 빌드:

```powershell
npm run build
cargo fmt --manifest-path src-tauri/Cargo.toml --check
cargo test --manifest-path src-tauri/Cargo.toml --locked
cargo clippy --manifest-path src-tauri/Cargo.toml --locked --all-targets -- -D warnings
npm run tauri -- build --ci --bundles nsis
```

결과는 `windows/src-tauri/target/release/bundle/nsis/*-setup.exe`입니다. npm·Cargo lockfile을 커밋해 CI에서도 같은 의존성을 사용합니다. 브라우저의 `npm run dev` 미리보기는 실제 Codex에 연결하지 않습니다.

## GitHub에서 배포

`.github/workflows/release.yml`의 **Build and release**를 사용합니다.

1. `Resources/Info.plist`, Mac app-server의 clientInfo, Windows `package.json`·`tauri.conf.json`·`Cargo.toml`, 화면 버전, lockfile의 앱 버전을 함께 올립니다.
2. README의 다운로드 파일 이름·설치 가이드·`docs/RELEASE_NOTES.md`를 새 버전에 맞춥니다.
3. Pull request를 만들면 macOS·Windows 검증이 실행됩니다. Windows는 설치 파일을 실제로 조용히 설치하고 실행·중복 실행·삭제를 검사합니다. Mac은 두 아키텍처·번들 서명·DMG·짧은 실행을 검사합니다.
4. 두 작업이 성공하면 PR을 기본 브랜치에 병합합니다.
5. 기본 브랜치의 해당 커밋에 버전 태그를 만들고 푸시합니다.

   ```bash
   git switch main
   git pull --ff-only
   git tag v1.0.0
   git push origin v1.0.0
   ```

6. 태그 빌드에서 두 OS가 모두 성공해야 Release가 공개됩니다. 설치 파일 세 개와 `SHA256SUMS.txt`가 첨부됩니다. 이미 공개한 태그는 다른 커밋으로 강제 이동하지 말고 새 버전을 만드세요.
7. 실패한 경우 Actions 로그를 확인합니다. Publish가 완료되기 전에는 사용자에게 다운로드 완료라고 안내하지 않습니다.

태그 없이 **Run workflow**를 실행하면 빌드와 Artifact만 생성되고 공개 릴리스는 만들지 않습니다. CI에는 제작자의 Codex·Claude 인증 정보가 없습니다. 따라서 설치·실행 검증과 실제 로그인 계정의 데이터 검증은 구분해야 합니다.

## 현재 배포 범위

- Mac 공용 바이너리는 두 CPU용으로 빌드하지만 CI의 실제 실행은 해당 러너 CPU에서만 수행합니다.
- Windows 검증은 GitHub Windows 러너에서 진행하며 모든 Windows 10/11 실제 기기의 수동 UI 검증을 대신하지 않습니다.
- 장시간 메모리 안정성은 별도 soak test가 필요합니다.
- 코드 서명·공증 인증서는 없으며 릴리스는 미공증/미서명 상태입니다. 인증서가 준비되면 배포 서명을 추가해야 첫 실행 경고를 줄일 수 있습니다.
