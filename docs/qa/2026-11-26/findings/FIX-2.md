# FIX-2 — 앱 틀 · 로그인 · 설정 수정 결과

브랜치 `qa/fix-2` (worktree `jiu-jitsu-ios-fix2`), 기준 `origin/develop` @ b1b40b6. 푸시 안 함.

## 빌드

- `tuist install && tuist generate --no-open` 후 `xcodebuild -scheme App -configuration Debug -destination 'generic/platform=iOS Simulator'` — **경고-에러 켠 기본 설정으로 BUILD SUCCEEDED**.
- 바꾼 파일 10개 모두 이 빌드에서 컴파일됨(오브젝트가 소스보다 새것), 바꾼 파일에서 나온 경고 없음.
- 실기기 · 시뮬레이터 실행 확인은 하지 않았다(아래 '사람이 확인할 것').

## 결함별 결과

| ID | 결과 |
|---|---|
| **A1-02 = A5-1** (P1) | **고침** `e26d85b` — `AppTabView`에서 로그인 안내 알럿과 로그인 창(`loginCover`)을 세션 만료 알럿과 같은 `isInCover` 방식으로 바꿈: 상세 모달이 떠 있으면 모달 안, 아니면 탭 화면 위 한 곳에만 띄운다. 로그인 창 바인딩은 지금 맡은 쪽만 값을 쓰게 해서, 모달이 닫히거나 열려 자리가 바뀔 때 가려지는 쪽이 nil을 써 창을 닫지 않는다. 대기 행위(pendingAction) 처리는 state(`pendingWebLoginTab` → `home.session(.loginCancelled/.loggedIn)`)에서 하므로 그대로다. 변형 B(모달 위 만료 알럿 → [로그인]) · C(모달 안 대회 '내 기록에 남기기')도 같은 바인딩을 쓴다. |
| A1-01 | **안 고침 (의도된 설계 + 서버확인필요)** — #367 커밋(`2008c85`) 본문이 "세션 종료 코드일 때만 로그인 화면", 코드 주석도 "그 밖엔 토큰을 지키고 다시 시도를 묻는다"로 지금 동작과 같다. 막다른 길이 되려면 서버가 refresh에 끝나지 않는 비-세션종료 코드(U0004/U0005/U0011 등)를 줘야 하는데 앱 코드로는 확인할 수 없다. 서버 응답 코드를 확인한 뒤 분류를 좁힐지, 알럿에 두 번째 버튼을 둘지(UI논의) 정해야 한다. |
| A1-03 | 안 고침 (사람이 확인 — `AppStoreLink.appID` 값 넣기) |
| A1-04 | **고침** `d570d4b` — `HomeFeedPreloadRecorder`가 `webViewWebContentProcessDidTerminate`를 `.terminated`로 받아 두고, `handOff`할 때 코디네이터의 종료 처리를 불러 홈 · 대회 목록과 같은 복구(#479)를 탄다. 아직 창에 안 붙었으면 붙을 때(`onMovedToWindow`) 다시 불러온다. |
| A1-05 | 안 고침 (UI논의필요 — 기존 만료 알럿을 글 위에 띄울지) |
| A1-06 | 안 고침 (담당 지시: 로그아웃 진행 표시는 화면이 바뀜) |
| A1-07 | **고침** `dce9b6d` — 새로고침 상태 정리(`isRefreshing` · `refreshNavigation` · `finishRefreshing(success: false)`)를 목록 경로에서 `webViewWebContentProcessDidTerminate` 맨 앞으로 옮겨 상세에도 적용. |
| A1-08 | 안 고침 (UI논의필요/설계) — 스플래시 실패는 5xx · 시간 초과처럼 연결은 살아 있는 경우도 포함한다. 웹의 `WebConnectionRetry.watchEffect`를 그대로 쓰면 이미 연결됨 상태에서 1초마다 저절로 다시 시도가 반복될 수 있다. '연결 문제였을 때만' 지켜보려면 A1-01의 실패 분류가 먼저 필요하다. |
| A1-09 | **고침** `c113c30` — 스플래시 자동 로그인이 세션 종료 코드로 끝나면 `autoLoginFinished` 전에 `WebSessionCookie.clear()`. 둘러보기와 링크로 연 게스트 탭 둘 다 탭을 만들기 전에 지워진다. |
| A1-10 | **고침** `1bef0b6` — Store를 `static` 저장소에 처음 본문을 그릴 때 한 번만 만든다. 만드는 시점(첫 본문 평가)은 그대로라 Firebase 설정 순서는 바뀌지 않는다. |
| A4-1 | 안 고침 (UI논의필요 + 서버확인필요) |
| A4-2 | 안 고침 (담당 밖 — MyProfile 폴더, fix-1 영역) |
| A4-3 | 안 고침 (담당 지시: 화면 바뀜) |
| A4-4 | **고침** `689ef0a` — `UserRepositoryImpl.withdrawal`에서 U0004(`alreadyWithdrawn`)를 받으면 `lastLoginProvider`를 지우고 `true`를 돌려준다 → 설정은 그대로 `didWithdrawSuccessfully`로 게스트 전환 · 로컬 정리 · 탈퇴 안내를 한다. 리포지토리에서 처리해야 성공 응답과 같은 '최근 로그인' 정리까지 맞출 수 있어 Data 파일 하나를 고쳤다(담당 목록 밖). 서버가 재요청에 실제로 U0004를 주는지는 서버 확인 필요(401이면 기존 세션 만료 경로를 탄다). |
| A4-5 | **고침** `f608c15` — `sceneBecameActive`에서 `!isLoaded`면 서버 값도 다시 조회. 상시 재시도 버튼은 안 넣음(UI). |
| A4-6 | 안 고침 (담당 지시: 접근성 라벨은 fix-3) |
| A4-7 | 안 고침 (UI논의필요 + 서버확인필요) |
| A4-8 | **고침** `fc72655` — 기존 실패 화면("잠시 문제가 생겼어요" + 재시도, `onLoadFail`)이 있어서 그걸 쓴다. `TermsWKWebView.Coordinator`에 `decidePolicyFor navigationResponse` 추가: 메인 프레임 200..<400 밖이면 취소하고 실패 처리, 뒤따르는 중단 실패 알림은 한 번 걸러 낸다(BridgeWebView `isAwaitingHTTPCancel`과 같은 방식). |
| A4-9 | 안 고침 (UI논의필요 — 문구) |
| A4-10 | **일부 고침** `29e8d6a` — 재현 B(취소된 앞 요청이 서버에 닿은 뒤 뒤 요청 실패): 실패해서 되돌린 뒤 `fetchSetting`을 한 번 다시 부른다. 실패하면 이미 불러온 상태라 로그만 남고, 그사이 다시 토글하면 generation이 달라져 버려진다. 재현 A(MY가 대신 저장하는 중에 다시 연 화면이 먼저 조회)는 MyProfile 쪽 대신 저장과 순서를 맞춰야 해서 안 고침(fix-1 영역). |
| A4-11 | **일부 고침** `fe9779a` — `withdrawalCleanupFinished`에서 `authInfo.isGuest`일 때만 탈퇴 안내를 띄운다(복구 직후 정반대 안내 제거). 정리 중 로그인한 세션이 곧 폐기될 FCM 토큰을 등록할 수 있는 경합은 안 고침: 막으려면 정리 중 로그인 창을 미뤄야 하고, 그러면 누른 로그인이 반응하지 않는 흐름 변화가 생긴다(UI논의). |
| A5-2 | **고침** `02185ad` — `socialLoginResponse`(성공 · 실패 둘 다)에서 `state.isSigningUp`(서버 로그인 중 · 약관 시트 · 가입 스택)이면 버린다. 버튼 잠금은 그대로 서버 단계에만 걸리고 소셜 단계엔 걸지 않으므로, 카카오톡에서 그냥 돌아와 SDK가 응답하지 않아도 영구히 막히는 일은 없다(새로 거는 잠금 없음, 결과를 버리기만 함). 남는 틈: 먼저 로그인이 서버 단계를 다 끝내고 화면이 그대로인 상태에서 늦은 결과가 오면 그대로 진행된다. 기존 회원이면 로그인 화면이 닫혀 그 효과가 취소된다. |
| A5-3 | 안 고침 (UI논의필요 — 정책 · 법무) |
| A5-4 | 안 고침 (담당 지시: 접근성은 fix-3) |
| A5-5 | 안 고침 (서버확인필요) |
| A5-6 | 안 고침 (의도된 설계/UI논의필요) — `.networkError`를 placeholder 색 묶음에 넣은 건 정책 커밋 `b23119b` "[iOS] feat: 닉네임 최초 설정 정책 수정"에서 정한 것이라, 색을 바꾸면 보이는 화면이 바뀐다. 수정 모드의 `.saveFailed`처럼 진한 색으로 둘지 디자인과 정할 것. |
| A5-7 | 안 고침 (서버확인필요) |

요약: **고침 11건**(A1-02/A5-1, A1-04, A1-07, A1-09, A1-10, A4-4, A4-5, A4-8, A5-2 + 일부 고침 A4-10, A4-11), **안 고침 나머지**(이유는 위 표).

## 담당 목록 밖에서 고친 파일

- `Data/Sources/Repositories/UserRepositoryImpl.swift` (A4-4) — 탈퇴 성공 응답에서만 하던 '최근 로그인' 정리를 U0004에서도 같이 하려고.
- `Presentation/Sources/WebBridge/BridgeWebView.swift`, `HomeFeedPreloader.swift` (A1-04, A1-07) — WebBridge는 담당 범위 안.

## 사람이 확인할 것

- [ ] 게스트로 웹이 `OPEN_SUBVIEW(modal)`로 연 상세 안에서 좋아요 · 댓글 → 모달 위에 로그인 안내 → [로그인] → 모달 위에 로그인 창 → 로그인하면 원래 행위 이어짐 / 닫기 · 둘러보기면 대기 행위 버려짐 (A1-02)
- [ ] 위 로그인 창(모달 위 모달)에서 Google · Apple · 카카오 로그인 창이 정상으로 뜨는지 — Google은 key window의 rootViewController를 넘긴다(`AuthRepositoryImpl.findRootViewController`)
- [ ] 로그인 상태로 상세 모달을 보다 세션 만료 → 만료 알럿 [로그인] → 모달 위 로그인 창 (A5-1 변형 B)
- [ ] 스플래시 중 홈 버튼 → 메모리 압박으로 웹 프로세스 종료 → 복귀 시 홈이 다시 불러와지는지 (A1-04)
- [ ] 약관 · 공지 주소를 404/502 주는 주소로 바꿔 열면 "잠시 문제가 생겼어요" + 재시도 (A4-8)
- [ ] 카카오 → Google 연달아 누르기: 먼저 서버 단계에 들어간 계정으로만 들어가는지 (A5-2)
- [ ] 서버: 탈퇴 재요청에 U0004를 주는지 (A4-4)
