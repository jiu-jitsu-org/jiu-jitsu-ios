# 수정 담당 공통 지침

QA 점검 결과(docs/qa/2026-11-26/findings/*.md, 이 파일과 같은 폴더)에서 **화면 모양이 바뀌지 않는 기능·접근성 결함**만 고친다.
결과 파일은 /Users/swimming_moon/Documents/HansolDev/jiu-jitsu-ios-qa/docs/qa/2026-11-26/findings/ 에 있다(읽기만).

## 규칙
1. **고치기 전에 결함이 진짜인지 코드로 다시 확인한다.** 점검자도 틀릴 수 있다. 오탐이거나, 의도된 설계(주석·`git log -S`/커밋 메시지에 이유가 있음)거나,
   고치려면 화면 모양·흐름이 바뀌어야 하면 **고치지 말고** 이유를 기록한다. (팀 규칙: 화면이 바뀌는 건 구현 전에 논의)
   접근성 라벨(VoiceOver가 읽는 한국어 문구)·접근성 특성 추가는 보이는 화면이 안 바뀌므로 고쳐도 된다.
2. 고칠 때는 최소 변경. JiuJitsuConnect/CLAUDE.md 컨벤션(TCA Action 분류, CancelID, 주석은 한국어로 '왜'를 짧게)을 따른다. 리팩터링·이름 바꾸기·상관없는 정리는 하지 않는다.
3. **빌드 확인 필수.** 네 worktree에서:
   `cd JiuJitsuConnect && tuist install && tuist generate --no-open` (brew tuist 4.214.0, mise 없음. 가짜 시크릿은 이미 놓여 있음)
   `xcodebuild -workspace JiuJitsuConnect.xcworkspace -scheme App -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath <네 DD 경로> build 2>&1 | tail -40`
   경고-에러(warnings as errors)를 켠 기본 설정으로 먼저 빌드한다. 기존 코드 때문에 경고-에러로 깨지면(네 변경 전에도 깨지는지 확인) `SWIFT_TREAT_WARNINGS_AS_ERRORS=NO GCC_TREAT_WARNINGS_AS_ERRORS=NO`로 빌드하되, **네 변경이 새 경고를 만들지 않았는지** 로그에서 네 파일 경고를 grep해 확인한다.
4. 커밋: 결함 하나(또는 아주 가까운 묶음)마다 커밋 하나. 형식은 이 레포 관례 `fix(<영역>): 한국어로 무엇을 고쳤는지` (예: `fix(my): …`, `fix(settings): …`, `fix(a11y): …`). 본문에 `QA: A3-1` 처럼 결함 ID를 적는다. **Co-Authored-By 등 AI 트레일러는 넣지 않는다**(프로젝트 규칙). 푸시는 하지 않는다. 네 브랜치에만 커밋한다.
5. 다른 수정 담당 두 명이 다른 worktree에서 다른 파일을 고치고 있다. 네 담당 목록 밖의 파일은 꼭 필요할 때만 건드리고 결과에 적는다.
6. 끝나면 결과를 /Users/swimming_moon/Documents/HansolDev/jiu-jitsu-ios-qa/docs/qa/2026-11-26/findings/FIX-<번호>.md 에 쓴다(이 파일만 qa worktree에 쓴다):
   결함 ID마다 `고침(커밋 해시·한 줄 설명) | 안 고침(이유: 오탐/의도된 설계/UI논의필요/서버확인필요)` 와 빌드 결과(경고-에러 켠 상태 성공 여부).
최종 답변: 고친 것·안 고친 것 개수, 빌드 결과, 커밋 목록(`git log --oneline origin/develop..HEAD`).
