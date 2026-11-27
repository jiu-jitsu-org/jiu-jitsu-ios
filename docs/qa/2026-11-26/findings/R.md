# R 화면 점검 결과

## 빌드 결과

| 빌드 | 설정 | 결과 |
|---|---|---|
| Debug · iPhone 17 Pro 시뮬레이터 · **경고-에러 켠 상태**(Project.swift:194-195 기본값 그대로, 덮어쓰기 없음) · 하네스 넣기 **전** 원본 코드 | `tuist install && tuist generate` → `xcodebuild … build` | **BUILD SUCCEEDED**. 프로젝트 Swift 소스에서 나온 경고 0건. 남은 경고는 libtool "has no symbols", appintents 메타데이터 건너뜀, `AccentColor` 없음뿐이라 에러로 바뀌지 않음 |
| Debug · 경고-에러 끔(`SWIFT/GCC_TREAT_WARNINGS_AS_ERRORS=NO`) · 하네스 넣은 상태 | 같은 DerivedData | BUILD SUCCEEDED (캡처용) |

- 예전에 깨졌던 Kakao SDK deprecated 경고는 **지금은 재현되지 않음**. 다만 `kakao-ios-sdk` 가 여전히 `branch: master` 추적이다(Tuist/Package.resolved:140-145, revision 2a68ca0). 출시 빌드 시점에 master가 바뀌면 같은 코드가 경고-에러로 다시 깨질 수 있다 → 출시 전 버전(tag) 고정 권장. (A7·빌드 담당이 판단)
- Beta·Release 구성은 빌드하지 않았다(범위 밖, 시간 절약).

## 하는 법 (환경)

- 로컬 하네스(커밋 안 함, 끝나고 원상복구함): `Presentation/Sources/QAHarness.swift` 를 임시로 추가하고 `JiuJitsuConnectApp` 에 실행 인자 `-QAScreen <화면>` 분기를 넣어, 실제 `AppTabView`·`LoginView`·`SplashView` 등을 **실제 표시 경로 그대로**(MY의 `destination`/`sheet`/`path`, 로그인의 `sheet`/`path`를 초기 상태로 채움) 띄웠다. 의존성은 `context = .preview` + previewValue가 없는 `firebaseClient`·`userClient` 는 testValue.
- 스크롤·카드 펼침은 손으로 못 하므로 `MyProfileView`·`UserProfileView` 스크롤에 `.defaultScrollAnchor`, 최애 카드 `isOpen` 초깃값에 실행 인자 훅을 임시로 넣었다(모두 원상복구).
- 기기: iPhone 17 Pro(402pt), iPhone 17e(390pt), iPhone 17 Pro Max(440pt) + **iPhone SE 3세대(375×667, 홈 버튼)** — 17e가 생각보다 크지 않아(390×844) iOS 26이 지원하는 가장 작은 화면을 보려고 임시 시뮬레이터를 만들어 쓰고 지웠다.
- 큰 글씨: `content_size accessibility-extra-extra-extra-large`(AX3). 원래 값이 `large` 여서 끝나고 `large` 로 되돌렸다(지시의 `medium` 이 아니라 원래 값으로 복구).
- 주의(다른 세션 영향): 공유 기기 **iPhone 17 Pro(F032C239…)** 를 같은 번들 ID로 다른 세션도 쓰고 있었다. 02:12쯤 다른 세션이 깐 앱을 내 하네스 빌드가 덮어썼을 수 있다(02:19 설치). 이후 내 캡처는 따로 만든 17 Pro 시뮬레이터로 옮겼다. 17 Pro·17e·17 Pro Max에는 지금 하네스가 든 Debug 빌드가 깔려 있다(실행 인자 없이 켜면 원래 앱과 같게 동작). 기기 지우기(erase)는 하지 않았다.
- 머신 부하(load avg 600대)로 몇 장이 런치 화면으로 찍혀 다시 찍었다. 표에 남은 것은 모두 내용 확인함.

## 점검한 흐름

- 스플래시 / 연결 실패 안내 — OK
- 로그인(기본·최근 로그인 배지) — OK (SE는 위 문구가 상태 막대에 바짝 붙음, O-3)
- 약관 동의 시트(기본·예전 수단 안내) — OK
- 닉네임 설정(가입) — OK
- 가입 완료 — 문제(R-5)
- 인사 장면 — OK(첫 프레임만)
- MY 빈 프로필 / 비로그인 — OK, 스크롤하면 R-1
- MY 꽉 찬 프로필(검은띠 4그랄·12자 닉네임·긴 도장명·대회 6건·고정 부문 묶음) — 긴 글자는 OK, 스크롤하면 R-1
- MY 불러오기 실패 — 문제(R-9)
- 남의 프로필(꽉 참·빈) — 문제(R-2), 빈 상태 OK
- 띠 설정 시트 / 띠 승급 축하 — OK
- 도장 추가·긴 도장 수정 / 닉네임 수정 — OK
- 프로필 사진 시트 — OK
- 대회 기록 1~4단계와 완료(SE 포함) — OK
- 관장 인증 시트(신청 전·심사 중·반려·승인) — 반려 문제(R-3), 나머지 OK
- 최애 기술 고르기(띠 5색, 미선택) — 문제(R-4 SE, R-8)
- 최애 카드 앞면(MY·남의 프로필, 띠 5색) / 뒷면(덮인 더미) — 카드 자체는 OK, 블랙≈화이트(O-2)
- 설정 / 알림 설정 / 이용 통계 / 로그아웃·탈퇴 알럿 — 레이아웃 OK, 문구 R-7
- 홈·대회 탭 웹 실패(오프라인) 오버레이 — 레이아웃 OK, 문구 R-6
- 큰 글씨(AX3) 17e 30화면·SE 6화면 — 글자가 전혀 커지지 않음(O-1). 그래서 큰 글씨로 깨지는 레이아웃은 없음
- 넓은 글자 닉네임(W×12) MY·남의 프로필·인증 승인·가입 완료 — 가입 완료만 문제(R-5)

## 결함

### R-1 [P2] MY·남의 프로필을 내리면 내용이 상태 막대(시계·다이내믹 아일랜드) 밑으로 그대로 지나가 겹친다
- 페르소나: P6 접근성(작은 화면), P1 처음이
- 재현: 1) MY 탭(띠·대회 기록이 있는 프로필) 2) 아래로 끝까지 내림 3) 상태 막대 자리를 봄
- 기대 / 실제: 기대 — 헤더가 올라가면 상태 막대 뒤에 바탕이 깔리거나 흐려져 글자가 겹치지 않음. 실제 — 띠 카드("블랙 4그랄")와 시계가 겹치고(myFull-bottom-17pro, myWhite-bottom-17e: 시계가 띠 아이콘 위), SE에서는 "대회 기록" 제목과 "+"(대회 추가)가 통신사·시계 줄과 겹친다(myFull-bottom-se3). 빈 프로필에서는 "도장 정보 입력하기" 버튼이 다이내믹 아일랜드 밑으로 들어간다(myEmpty-bottom-17pro). 남의 프로필도 닉네임이 시계와 겹친다(userProfile-cardsOpen-17pro).
- 근거: JiuJitsuConnect/Targets/Presentation/Sources/Features/MyProfile/MyProfileView.swift:176 (`.ignoresSafeArea(edges: .top)`, 상단 scroll edge 처리 없음), Features/UserProfile/UserProfileView.swift:138 (같음)
- 고치는 방향: 헤더가 화면 밖으로 나가면 상태 막대 자리에 띠 색 바탕(또는 `scrollEdgeEffectStyle(.hard, for: .top)` 류)을 깐다. 화면 모양이 바뀌므로 논의 먼저 · 분류: UI논의필요
- 확신도: 높음 (캡처 4장)

### R-2 [P2] 남의 프로필(·커뮤니티에서 연 MY)의 떠 있는 뒤로가기 "<"가 스크롤하면 내용 위에 겹치고, 밝은 바탕에선 흰색이라 안 보인다
- 페르소나: P6 접근성, P2 급한 손
- 재현: 1) 커뮤니티에서 검은띠(또는 파랑·보라·갈색) 회원 프로필 열기 2) 아래로 내림 3) 왼쪽 위 "<" 확인
- 기대 / 실제: 기대 — 뒤로가기가 늘 보이고 내용과 겹치지 않음. 실제 — 17 Pro에서는 "<"가 도장명 글자 위에 겹치고(userProfile-bottom-17pro), SE처럼 더 많이 내려가면 회색(#EEE) 바탕 위에 흰 "<"만 남아 거의 보이지 않는다(userProfile-bottom-se3). 색은 헤더 띠 색 기준으로 한 번 정해지고 스크롤에 따라 바뀌지 않는다.
- 근거: Features/UserProfile/UserProfileView.swift:38-46 (ZStack 위에 고정 HStack), :164-178 (`onHeader ? headerForeground`), :159-161 (`myHeaderForeground` — 어두운 띠면 흰색). 커뮤니티에서 쌓은 MY도 같은 방식: Features/MyProfile/MyProfileView.swift:84-89, 95-107
- 고치는 방향: 뒤로가기에 바탕(원형 유리 등)을 주거나 스크롤 위치에 따라 색을 바꾼다. R-1의 상태 막대 바탕과 함께 정하면 한 번에 풀린다 · 분류: UI논의필요
- 확신도: 높음

### R-3 [P2] 관장 인증 반려 사유가 2줄에서 "…"로 잘려 끝까지 읽을 수 없다
- 페르소나: P4 검은띠 관장
- 재현: 1) 관리자가 두 줄을 넘는 반려 사유를 남김 2) MY → 관장 인증 시트 열기
- 기대 / 실제: 기대 — 왜 반려됐는지 전부 읽고 다시 찍음. 실제 — "…사진이 흐리거나 일부가 가려져 있으면 확…"에서 잘린다(ivRejected-17pro·17e-ax·se3). 사유를 다 볼 방법이 없다. 시트 높이도 반려 상태는 430으로 고정이라 줄 수만 풀면 아래가 잘린다.
- 근거: Features/MyProfile/InstructorVerification/InstructorVerificationView.swift:320-324 (`.lineLimit(2)`), :40-41 (`case .rejected: return 430`), MyProfileView.swift:572-575 (고정 detent)
- 고치는 방향: lineLimit을 풀고 사유 길이만큼 시트 높이를 잡는다(측정값으로 detent, 또는 본문만 스크롤). 시트가 길어질 수 있어 높이 정책만 확인 · 분류: 코드수정(시트 높이가 사유 길이에 따라 늘어남)
- 확신도: 높음 (서버 사유 길이 제한이 짧으면 발생 빈도는 낮음 — 웹/서버 확인 필요)

### R-4 [P2] iPhone SE(375×667)에서 최애 기술 고르기 아래 선택 칸(없음·탑·가드)이 "설정 완료" 버튼과 그라데이션에 반쯤 가려진다
- 페르소나: P6 작은 화면, P1 처음이
- 재현: 1) iPhone SE 2·3세대 2) MY → 최애 포지션 카드 누름 3) 첫 화면 아래 확인
- 기대 / 실제: 기대 — 고를 칸이 다 보임. 실제 — 큰 카드(262×394 고정) 아래 선택 줄이 버튼 뒤로 들어가 "가드" 칸 아래쪽과 "없음·탑"의 반이 가려진다(style-black-se3). 스크롤하면 보이겠지만 스크롤할 수 있다는 표시가 없다. 17e 이상에서는 문제 없음.
- 근거: Features/MyProfile/MyStyleSetting/MyStyleSettingView.swift:75 (`cardSize` 고정), :82-111 (본문 아래 59pt만 비우고 버튼·73pt 그라데이션을 ZStack 위에 얹음), :170 (`.scrollClipDisabled()`)
- 고치는 방향: 화면 높이가 낮으면 큰 카드를 줄이거나 선택 줄을 버튼 위 고정 영역으로 뺀다 · 분류: UI논의필요
- 확신도: 중간 (SE 3세대 시뮬레이터 1장. 손가락 스크롤로 보이는지는 실기기 확인)

### R-5 [P3] 가입 완료 "{닉네임}님!" 줄에 좌우 여백이 없어, 넓은 글자 닉네임이면 "님!"만 다음 줄로 떨어진다
- 페르소나: P5 극단 입력
- 재현: 1) 닉네임을 넓은 영문 12자(예: WWWWWWWWWWWW)로 가입 2) 가입 완료 화면
- 기대 / 실제: 기대 — 다른 화면처럼 20pt 여백 안에서 자연스럽게 줄바꿈. 실제 — 17 Pro에서 글자가 화면 양끝 4pt까지 붙고(signupDone-wideNick-17pro, signupDone-17pro), SE에서는 "님!"만 둘째 줄로 떨어진다(signupDone-wideNick-se3).
- 근거: Features/SignupComplete/SignupCompleteView.swift:54-56 (Text에 가로 padding·minimumScaleFactor 없음; :96의 `.padding(.horizontal, 20)` 은 버튼 쪽)
- 고치는 방향: 텍스트 묶음에 가로 여백 20을 주고 `minimumScaleFactor`(MY 헤더처럼 0.8) 또는 닉네임과 "님!" 사이 줄바꿈 금지 · 분류: 코드수정-화면변화없음(일반 닉네임은 그대로)
- 확신도: 높음

### R-6 [P3] 같은 "다시 하기" 버튼이 화면마다 "재시도" / "다시 시도"로 다르다
- 페르소나: P3 지하철
- 재현: 1) 비행기 모드로 홈·대회 탭 → "재시도"(home-17pro, competitionTab-17pro) 2) 같은 상태로 앱 재실행 → 스플래시 "다시 시도"(splashFail-17pro) 3) MY 불러오기 실패 → "다시 시도"(myLoadFail-17pro)
- 기대 / 실제: 한 말로 통일 / 섞여 있음
- 근거: "재시도" — Features/Community/CommunityView.swift:192, CommunityDetailView.swift:170, CompetitionTab/CompetitionTabView.swift:143, UserProfile/UserProfileView.swift:150, TermsWebView/TermsWebViewView.swift:95. "다시 시도" — Splash/SplashView.swift:32, MyProfile/MyStyleSetting/MyProfileCardComponents.swift:102, Settings/NotificationSetting/NotificationSettingFeature.swift:260
- 고치는 방향: 앱 말투(해요체)에 맞춰 "다시 시도"로 통일 · 분류: 코드수정-화면변화없음(문구만) — A7 문구 통일과 합칠 것
- 확신도: 높음

### R-7 [P3] 탈퇴 확인 알럿·관장 인증 안내만 "-합니다"체다
- 페르소나: P8 떠나는 사람
- 재현: 설정 → 회원 탈퇴 / MY → 관장 인증
- 기대 / 실제: 앱 나머지는 "-해요"체 / "영구 삭제됩니다… 취소됩니다… 한 번 더 열립니다"(withdrawal-17pro), "관리자가 확인합니다… 확인할 수 있습니다… 노출되지 않습니다"(ivNone-17pro)
- 근거: Features/Settings/SettingsView.swift:223-224, Features/MyProfile/InstructorVerification/InstructorVerificationView.swift:268-270 부근
- 고치는 방향: 해요체로 바꿈(법적 고지 문구라 일부러 둔 것인지 먼저 확인) · 분류: 코드수정-화면변화없음(문구) — A7과 합칠 것
- 확신도: 중간 (의도 여부 미확인)

### R-8 [P3] 이미 고른 최애를 다시 고르는 "수정" 화면에도 오른쪽 위가 "나중에 하기"다
- 페르소나: P1 처음이
- 재현: 1) 최애 포지션을 이미 고른 MY 2) 카드를 눌러 고르기 화면(수정 모드) 3) 오른쪽 위
- 기대 / 실제: 수정 중엔 "취소" 같은 말 / "나중에 하기"(style-white~black-17pro). 눌러도 실제로는 저장 없이 닫힘(`delegate(.cancel)`).
- 근거: Features/MyProfile/MyStyleSetting/MyStyleSettingView.swift:139-142 (mode와 관계없이 `resetButton`), :286-291, MyStyleSettingFeature.swift:488-490
- 고치는 방향: `mode == .edit` 이면 "취소"로, 또는 숨김 · 분류: UI논의필요(문구)
- 확신도: 중간 (하네스에서 `mode: .edit` 로 띄움. MY에서 여는 실제 mode 값은 A6가 확인)

### R-9 [P3] MY 불러오기 실패 화면에 "도장 정보 입력하기" 버튼이 함께 보인다
- 페르소나: P3 지하철
- 재현: 1) 망이 끊긴 채 처음 MY 진입(프로필 조회 실패) 2) 헤더 확인
- 기대 / 실제: 기대 — 실패 동안은 내 정보 입력 유도를 숨김. 실제 — 카드 자리엔 "프로필을 불러오지 못했어요 / 다시 시도"인데 헤더엔 기본 파란 바탕 + "도장 정보 입력하기"가 보인다(myLoadFail-17pro). 도장을 이미 등록한 사람도 "없다"로 보이고, 눌러 새로 입력하게 된다.
- 근거: Features/MyProfile/MyStyleSetting/MyProfileHeaderComponents.swift:205-213 (`academyName == nil` 이면 버튼 — 실패로 프로필이 nil이어도 nil), MyProfileView.swift:71-74 (`isProfileLoadFailed`)
- 고치는 방향: `isProfileLoadFailed` 일 때 도장 버튼(과 닉네임 연필)을 숨김. 실패 상태에서 도장 저장이 어떻게 처리되는지는 A2가 코드로 확인 · 분류: 코드수정-화면변화없음(실패 상태에서만)
- 확신도: 중간

## 관찰 (결함 아님 · 논의거리)

- **O-1 큰 글씨(Dynamic Type) 미지원 — 의도된 설계.** AX3로 올려도 모든 글자가 그대로다(…-ax.png 전부). 폰트가 `Font.custom(_, fixedSize:)` 고정이다(DesignSystem/Sources/Typography/Font+.swift:54-, 커밋 6041858 "폰트 fixed size 로 변경"). 그래서 큰 글씨로 깨지는 레이아웃은 없지만, 시력이 낮은 사용자(P6)는 글자를 키울 방법이 없다. 고정 높이 시트(관장 인증·띠·약관 등 `contentHeight`)가 많아 나중에 지원하려면 시트 높이부터 손봐야 한다. 출시 전 결정만 남김.
- **O-2 검은띠 카드 앞면 바탕이 흰띠와 거의 같은 회색.** style-black vs style-white, myFull-cardsOpen vs myWhite-cardsOpen. 커밋 c477767 에 "흰띠는 은색, 검정띠는 밝은 회색", "앞면 구성은 디자인을 받으면 다시 바꾼다"로 적혀 있어 의도됨. 캐릭터 띠로만 구분된다.
- **O-3 SE 로그인·약관 화면에서 위 문구 "주짓수하는 사람들의 공간"이 상태 막대에 바짝 붙고 OSS 로고 밑이 캐릭터 말풍선과 닿는다**(login-se3, terms-se3). 겹치진 않음.
- **O-4 남의 프로필 빈 칸 "아직 안 골랐어요"가 17 Pro(402pt)에서도 두 줄로 꺾인다**(userProfileEmpty-17pro). MY의 "지정해 주세요"는 #400에서 띄어쓰기 줄바꿈을 맞췄는데 이 문구는 안 맞춤. 읽는 데 문제는 없음.
- **O-5 MY "대회 기록" 제목 옆엔 메달 수가 없고 남의 프로필엔 있다**(myFull vs userProfile). 의도인지 확인.
- O-6 닉네임 설정(가입) 첫 화면에서 빈 값인데 "확인" 버튼이 파란(활성) 모양(nickname-17pro). 누르면 길이 검사로 막히는 구조(NicknameSettingFeature.swift:152-160)라 동작 문제는 아님.

## 건너뛴 화면과 이유

- 사진 자르기(ProfileImageCrop)·카메라·앨범 — 실제 사진 데이터·권한 창이 필요해 하네스로 의미 있는 상태를 못 만듦.
- 관장 인증 "사진 고른 뒤"(확인 단계) — 미리보기 이미지가 필요해 생략(신청 전·심사 중·반려·승인은 찍음).
- 대회 줄 동작 시트·머리줄 무늬 시트 — View의 `@State` 로만 열려 초기 상태로 띄울 수 없음.
- 띠 묻기 시트(BeltPrompt)·알림 권한 안내·로그인 유도 알럿 — 시간 부족으로 우선순위에서 뺌.
- 웹이 그리는 화면(커뮤니티·대회 상세·약관 웹) — 가짜 시크릿이라 웹이 안 뜸. 실패 오버레이만 찍음.
- Beta·Release 구성, 다크 모드 — 범위 밖.

## 실기기에서 사람이 확인할 것

- [ ] R-1·R-2: 실기기 MY·남의 프로필을 끝까지 내렸을 때 상태 막대·뒤로가기 겹침 (특히 iPhone SE 2·3세대가 지원 기기인지와 함께)
- [ ] R-4: iPhone SE에서 최애 고르기 아래 선택 줄을 손가락으로 스크롤해 다 볼 수 있는지
- [ ] 키보드가 올라온 상태의 닉네임·도장·대회명 입력 화면(시뮬레이터는 하드웨어 키보드라 소프트 키보드를 못 봄) — 버튼이 키보드 위로 붙는지, SE에서 제목과 입력칸이 가려지지 않는지
- [ ] 최애 카드 뒤집기·스와이프 애니메이션, 카드 들썩임 힌트, 동작 줄이기 켰을 때
- [ ] 인사 장면·띠 승급·대회 완료 꽃가루 움직임(정지 캡처로는 첫 프레임만 봄)
- [ ] VoiceOver로 MY 헤더·최애 카드(접힘/펼침 라벨)·관장 인증 시트 읽기 순서
- [ ] 큰 글씨 미지원(O-1)을 출시 전에 받아들일지 팀 결정
- [ ] 출시 빌드 전 Kakao SDK를 tag로 고정할지(branch master 추적)

## 캡처 목록

스크린샷 213장은 저장소에 넣지 않았다(약 21MB, 가로 900px 이하로 줄임). 작성자 로컬에 보관하고, 대표 캡처는 시각화 보고서 페이지에 있다. 기기 표기: 17pro·17e·17promax·se3(iPhone SE 3세대 임시 시뮬레이터), `-ax` = AX3 글자 크기. 관찰은 화면 기준으로 같은 화면이면 기기 간 같은 내용을 적었다(기기별 차이는 따로 적음).

| 파일명 | 화면 | 기기 | 한 줄 관찰 |
|---|---|---|---|
| academy-17e.png | 도장 추가 | iPhone 17e | 빈 입력 — 정상 |
| academy-17pro.png | 도장 추가 | iPhone 17 Pro | 빈 입력 — 정상 |
| academy-17promax.png | 도장 추가 | iPhone 17 Pro Max | 빈 입력 — 정상 |
| academyLong-17e.png | 도장 수정(긴 이름) | iPhone 17e | 두 줄 가운데 정렬, "본/관"처럼 단어 중간 줄바꿈 |
| academyLong-17e-ax.png | 도장 수정(긴 이름) | iPhone 17e · AX3 | AX3 글자 크기에서도 기본과 같은 크기(O-1). 두 줄 가운데 정렬, "본/관"처럼 단어 중간 줄바꿈 |
| academyLong-17pro.png | 도장 수정(긴 이름) | iPhone 17 Pro | 두 줄 가운데 정렬, "본/관"처럼 단어 중간 줄바꿈 |
| academyLong-17promax.png | 도장 수정(긴 이름) | iPhone 17 Pro Max | 두 줄 가운데 정렬, "본/관"처럼 단어 중간 줄바꿈 |
| analyticsSetting-17e.png | 이용 통계 설정 | iPhone 17e | 정상 |
| analyticsSetting-17e-ax.png | 이용 통계 설정 | iPhone 17e · AX3 | AX3 글자 크기에서도 기본과 같은 크기(O-1). 정상 |
| analyticsSetting-17pro.png | 이용 통계 설정 | iPhone 17 Pro | 정상 |
| analyticsSetting-17promax.png | 이용 통계 설정 | iPhone 17 Pro Max | 정상 |
| beltPromotion-17e.png | 띠 승급 축하 | iPhone 17e | 정상 |
| beltPromotion-17e-ax.png | 띠 승급 축하 | iPhone 17e · AX3 | AX3 글자 크기에서도 기본과 같은 크기(O-1). 정상 |
| beltPromotion-17pro.png | 띠 승급 축하 | iPhone 17 Pro | 정상 |
| beltPromotion-17promax.png | 띠 승급 축하 | iPhone 17 Pro Max | 정상 |
| beltSetting-17e.png | 띠 설정 시트 | iPhone 17e | 정상 |
| beltSetting-17e-ax.png | 띠 설정 시트 | iPhone 17e · AX3 | AX3 글자 크기에서도 기본과 같은 크기(O-1). 정상 |
| beltSetting-17pro.png | 띠 설정 시트 | iPhone 17 Pro | 정상 |
| beltSetting-17promax.png | 띠 설정 시트 | iPhone 17 Pro Max | 정상 |
| beltSetting-se3.png | 띠 설정 시트 | iPhone SE 3세대(임시) | 정상 |
| compDivision-17e.png | 대회 기록 4단계(체급·도복·출전 띠) | iPhone 17e | 정상, SE도 들어감 |
| compDivision-17e-ax.png | 대회 기록 4단계(체급·도복·출전 띠) | iPhone 17e · AX3 | AX3 글자 크기에서도 기본과 같은 크기(O-1). 정상, SE도 들어감 |
| compDivision-17pro.png | 대회 기록 4단계(체급·도복·출전 띠) | iPhone 17 Pro | 정상, SE도 들어감 |
| compDivision-17promax.png | 대회 기록 4단계(체급·도복·출전 띠) | iPhone 17 Pro Max | 정상, SE도 들어감 |
| compDivision-se3.png | 대회 기록 4단계(체급·도복·출전 띠) | iPhone SE 3세대(임시) | 정상, SE도 들어감 |
| compDone-17e.png | 대회 기록 완료 | iPhone 17e | 긴 대회명 2부문이 두 줄씩 — 정상 |
| compDone-17e-ax.png | 대회 기록 완료 | iPhone 17e · AX3 | AX3 글자 크기에서도 기본과 같은 크기(O-1). 긴 대회명 2부문이 두 줄씩 — 정상 |
| compDone-17pro.png | 대회 기록 완료 | iPhone 17 Pro | 긴 대회명 2부문이 두 줄씩 — 정상 |
| compDone-17promax.png | 대회 기록 완료 | iPhone 17 Pro Max | 긴 대회명 2부문이 두 줄씩 — 정상 |
| compDone-se3.png | 대회 기록 완료 | iPhone SE 3세대(임시) | 긴 대회명 2부문이 두 줄씩 — 정상 |
| compDone-se3-ax.png | 대회 기록 완료 | iPhone SE 3세대(임시) · AX3 | AX3 글자 크기에서도 기본과 같은 크기(O-1). 긴 대회명 2부문이 두 줄씩 — 정상 |
| compName-17e.png | 대회 기록 2단계(대회명) | iPhone 17e | 시뮬레이터 키보드 숨김 상태, 정상 |
| compName-17e-ax.png | 대회 기록 2단계(대회명) | iPhone 17e · AX3 | AX3 글자 크기에서도 기본과 같은 크기(O-1). 시뮬레이터 키보드 숨김 상태, 정상 |
| compName-17pro.png | 대회 기록 2단계(대회명) | iPhone 17 Pro | 시뮬레이터 키보드 숨김 상태, 정상 |
| compName-17promax.png | 대회 기록 2단계(대회명) | iPhone 17 Pro Max | 시뮬레이터 키보드 숨김 상태, 정상 |
| compResult-17e.png | 대회 기록 1단계(메달) | iPhone 17e | 정상 |
| compResult-17e-ax.png | 대회 기록 1단계(메달) | iPhone 17e · AX3 | AX3 글자 크기에서도 기본과 같은 크기(O-1). 정상 |
| compResult-17pro.png | 대회 기록 1단계(메달) | iPhone 17 Pro | 정상 |
| compResult-17promax.png | 대회 기록 1단계(메달) | iPhone 17 Pro Max | 정상 |
| compYear-17e.png | 대회 기록 3단계(연도) | iPhone 17e | 정상 |
| compYear-17pro.png | 대회 기록 3단계(연도) | iPhone 17 Pro | 정상 |
| compYear-17promax.png | 대회 기록 3단계(연도) | iPhone 17 Pro Max | 정상 |
| competitionTab-17e.png | 대회 탭(웹 실패) | iPhone 17e | "연결이 불안정해요 / 재시도" 오버레이 — 버튼 문구 R-6 |
| competitionTab-17pro.png | 대회 탭(웹 실패) | iPhone 17 Pro | "연결이 불안정해요 / 재시도" 오버레이 — 버튼 문구 R-6 |
| competitionTab-17promax.png | 대회 탭(웹 실패) | iPhone 17 Pro Max | "연결이 불안정해요 / 재시도" 오버레이 — 버튼 문구 R-6 |
| greeting-17e.png | 인사 장면 | iPhone 17e | 첫 프레임 — 정상 |
| greeting-17pro.png | 인사 장면 | iPhone 17 Pro | 첫 프레임 — 정상 |
| greeting-17promax.png | 인사 장면 | iPhone 17 Pro Max | 첫 프레임 — 정상 |
| home-17e.png | 홈 탭(웹 실패) | iPhone 17e | 오프라인 오버레이 "재시도"(R-6), 탭 바 정상 |
| home-17e-ax.png | 홈 탭(웹 실패) | iPhone 17e · AX3 | AX3 글자 크기에서도 기본과 같은 크기(O-1). 오프라인 오버레이 "재시도"(R-6), 탭 바 정상 |
| home-17pro.png | 홈 탭(웹 실패) | iPhone 17 Pro | 오프라인 오버레이 "재시도"(R-6), 탭 바 정상 |
| home-17promax.png | 홈 탭(웹 실패) | iPhone 17 Pro Max | 오프라인 오버레이 "재시도"(R-6), 탭 바 정상 |
| home-se3.png | 홈 탭(웹 실패) | iPhone SE 3세대(임시) | 오프라인 오버레이 "재시도"(R-6), 탭 바 정상 |
| imageEdit-17e.png | 프로필 사진 시트 | iPhone 17e | 정상 |
| imageEdit-17e-ax.png | 프로필 사진 시트 | iPhone 17e · AX3 | AX3 글자 크기에서도 기본과 같은 크기(O-1). 정상 |
| imageEdit-17pro.png | 프로필 사진 시트 | iPhone 17 Pro | 정상 |
| imageEdit-17promax.png | 프로필 사진 시트 | iPhone 17 Pro Max | 정상 |
| ivApproved-17e.png | 관장 인증 — 승인 | iPhone 17e | 정상 |
| ivApproved-17e-ax.png | 관장 인증 — 승인 | iPhone 17e · AX3 | AX3 글자 크기에서도 기본과 같은 크기(O-1). 정상 |
| ivApproved-17pro.png | 관장 인증 — 승인 | iPhone 17 Pro | 정상 |
| ivApproved-17promax.png | 관장 인증 — 승인 | iPhone 17 Pro Max | 정상 |
| ivApproved-wideNick-17pro.png | 관장 인증 — 승인(넓은 닉네임) | iPhone 17 Pro | 한 줄에 들어감 |
| ivApproved-wideNick-se3.png | 관장 인증 — 승인(넓은 닉네임) | iPhone SE 3세대(임시) | 한 줄에 들어감 |
| ivNone-17e.png | 관장 인증 — 신청 전 | iPhone 17e | 정상, 안내문 합니다체(R-7) |
| ivNone-17e-ax.png | 관장 인증 — 신청 전 | iPhone 17e · AX3 | AX3 글자 크기에서도 기본과 같은 크기(O-1). 정상, 안내문 합니다체(R-7) |
| ivNone-17pro.png | 관장 인증 — 신청 전 | iPhone 17 Pro | 정상, 안내문 합니다체(R-7) |
| ivNone-17promax.png | 관장 인증 — 신청 전 | iPhone 17 Pro Max | 정상, 안내문 합니다체(R-7) |
| ivNone-se3.png | 관장 인증 — 신청 전 | iPhone SE 3세대(임시) | 정상, 안내문 합니다체(R-7) |
| ivNone-se3-ax.png | 관장 인증 — 신청 전 | iPhone SE 3세대(임시) · AX3 | AX3 글자 크기에서도 기본과 같은 크기(O-1). 정상, 안내문 합니다체(R-7) |
| ivPending-17e.png | 관장 인증 — 심사 중 | iPhone 17e | 정상 |
| ivPending-17e-ax.png | 관장 인증 — 심사 중 | iPhone 17e · AX3 | AX3 글자 크기에서도 기본과 같은 크기(O-1). 정상 |
| ivPending-17pro.png | 관장 인증 — 심사 중 | iPhone 17 Pro | 정상 |
| ivPending-17promax.png | 관장 인증 — 심사 중 | iPhone 17 Pro Max | 정상 |
| ivRejected-17e.png | 관장 인증 — 반려 | iPhone 17e | 반려 사유가 2줄에서 "…"로 잘림(R-3) |
| ivRejected-17e-ax.png | 관장 인증 — 반려 | iPhone 17e · AX3 | AX3 글자 크기에서도 기본과 같은 크기(O-1). 반려 사유가 2줄에서 "…"로 잘림(R-3) |
| ivRejected-17pro.png | 관장 인증 — 반려 | iPhone 17 Pro | 반려 사유가 2줄에서 "…"로 잘림(R-3) |
| ivRejected-17promax.png | 관장 인증 — 반려 | iPhone 17 Pro Max | 반려 사유가 2줄에서 "…"로 잘림(R-3) |
| ivRejected-se3.png | 관장 인증 — 반려 | iPhone SE 3세대(임시) | 반려 사유가 2줄에서 "…"로 잘림(R-3) |
| login-17e.png | 로그인 | iPhone 17e | 정상 |
| login-17e-ax.png | 로그인 | iPhone 17e · AX3 | AX3 글자 크기에서도 기본과 같은 크기(O-1). 정상 |
| login-17pro.png | 로그인 | iPhone 17 Pro | 정상 |
| login-17promax.png | 로그인 | iPhone 17 Pro Max | 정상 |
| login-se3.png | 로그인 | iPhone SE 3세대(임시) | 정상 |
| login-se3-ax.png | 로그인 | iPhone SE 3세대(임시) · AX3 | AX3 글자 크기에서도 기본과 같은 크기(O-1). 정상 |
| loginRecent-17e.png | 로그인(최근 카카오) | iPhone 17e | "최근 로그인" 배지 정상 |
| loginRecent-17e-ax.png | 로그인(최근 카카오) | iPhone 17e · AX3 | AX3 글자 크기에서도 기본과 같은 크기(O-1). "최근 로그인" 배지 정상 |
| loginRecent-17pro.png | 로그인(최근 카카오) | iPhone 17 Pro | "최근 로그인" 배지 정상 |
| loginRecent-17promax.png | 로그인(최근 카카오) | iPhone 17 Pro Max | "최근 로그인" 배지 정상 |
| logout-17e.png | 로그아웃 알럿 | iPhone 17e | 정상 |
| logout-17pro.png | 로그아웃 알럿 | iPhone 17 Pro | 정상 |
| logout-17promax.png | 로그아웃 알럿 | iPhone 17 Pro Max | 정상 |
| myBlue-cardsOpen-17pro.png | MY 최애 카드 앞면(블루) | iPhone 17 Pro | 카드 정상, 위쪽 도장명이 상태 막대 밑(R-1) |
| myBrown-cardsOpen-17pro.png | MY 최애 카드 앞면(브라운) | iPhone 17 Pro | 카드 정상, R-1 |
| myEmpty-17e.png | MY 빈 프로필 | iPhone 17e | 정상 |
| myEmpty-17e-ax.png | MY 빈 프로필 | iPhone 17e · AX3 | AX3 글자 크기에서도 기본과 같은 크기(O-1). 정상 |
| myEmpty-17pro.png | MY 빈 프로필 | iPhone 17 Pro | 정상 |
| myEmpty-17promax.png | MY 빈 프로필 | iPhone 17 Pro Max | 정상 |
| myEmpty-bottom-17e.png | MY 빈 프로필(스크롤) | iPhone 17e | "도장 정보 입력하기"가 다이내믹 아일랜드 밑(R-1) |
| myEmpty-bottom-17pro.png | MY 빈 프로필(스크롤) | iPhone 17 Pro | "도장 정보 입력하기"가 다이내믹 아일랜드 밑(R-1) |
| myEmpty-bottom-17promax.png | MY 빈 프로필(스크롤) | iPhone 17 Pro Max | "도장 정보 입력하기"가 다이내믹 아일랜드 밑(R-1) |
| myEmpty-cardsOpen-17pro.png | MY 빈 프로필(스크롤) | iPhone 17 Pro | 예시 카드, R-1 |
| myEmpty-se3.png | MY 빈 프로필 | iPhone SE 3세대(임시) | 정상 |
| myFull-17e.png | MY 꽉 찬 프로필(검은띠·12자 닉네임·긴 도장명) | iPhone 17e | 긴 이름 모두 들어감 — 정상 |
| myFull-17e-ax.png | MY 꽉 찬 프로필(검은띠·12자 닉네임·긴 도장명) | iPhone 17e · AX3 | AX3 글자 크기에서도 기본과 같은 크기(O-1). 긴 이름 모두 들어감 — 정상 |
| myFull-17pro.png | MY 꽉 찬 프로필(검은띠·12자 닉네임·긴 도장명) | iPhone 17 Pro | 긴 이름 모두 들어감 — 정상 |
| myFull-17promax.png | MY 꽉 찬 프로필(검은띠·12자 닉네임·긴 도장명) | iPhone 17 Pro Max | 긴 이름 모두 들어감 — 정상 |
| myFull-bottom-17e.png | MY 꽉 찬 프로필(맨 아래) | iPhone 17e | 띠 카드·"대회 기록" 제목이 상태 막대와 겹침(R-1) |
| myFull-bottom-17e-ax.png | MY 꽉 찬 프로필(맨 아래) | iPhone 17e · AX3 | AX3 글자 크기에서도 기본과 같은 크기(O-1). 띠 카드·"대회 기록" 제목이 상태 막대와 겹침(R-1) |
| myFull-bottom-17pro.png | MY 꽉 찬 프로필(맨 아래) | iPhone 17 Pro | 띠 카드·"대회 기록" 제목이 상태 막대와 겹침(R-1) |
| myFull-bottom-17promax.png | MY 꽉 찬 프로필(맨 아래) | iPhone 17 Pro Max | 띠 카드·"대회 기록" 제목이 상태 막대와 겹침(R-1) |
| myFull-bottom-se3.png | MY 꽉 찬 프로필(맨 아래) | iPhone SE 3세대(임시) | 띠 카드·"대회 기록" 제목이 상태 막대와 겹침(R-1) |
| myFull-cardsOpen-17e-ax.png | MY 최애 카드 앞면(블랙) | iPhone 17e · AX3 | AX3 글자 크기에서도 기본과 같은 크기(O-1). 검은띠 바탕이 흰띠와 거의 같은 회색(O-2), R-1 |
| myFull-cardsOpen-17pro.png | MY 최애 카드 앞면(블랙) | iPhone 17 Pro | 검은띠 바탕이 흰띠와 거의 같은 회색(O-2), R-1 |
| myFull-cardsOpen-se3.png | MY 최애 카드 앞면(블랙) | iPhone SE 3세대(임시) | 검은띠 바탕이 흰띠와 거의 같은 회색(O-2), R-1 |
| myFull-mid-17e.png | MY 꽉 찬 프로필(중간 스크롤) | iPhone 17e | 정상 |
| myFull-mid-17pro.png | MY 꽉 찬 프로필(중간 스크롤) | iPhone 17 Pro | 정상 |
| myFull-mid-17promax.png | MY 꽉 찬 프로필(중간 스크롤) | iPhone 17 Pro Max | 정상 |
| myFull-se3.png | MY 꽉 찬 프로필(검은띠·12자 닉네임·긴 도장명) | iPhone SE 3세대(임시) | 긴 이름 모두 들어감 — 정상 |
| myFull-se3-ax.png | MY 꽉 찬 프로필(검은띠·12자 닉네임·긴 도장명) | iPhone SE 3세대(임시) · AX3 | AX3 글자 크기에서도 기본과 같은 크기(O-1). 긴 이름 모두 들어감 — 정상 |
| myFull-wideNick-17pro.png | MY(넓은 닉네임 W×12) | iPhone 17 Pro | 글자를 줄여 한 줄에 들어감 |
| myFull-wideNick-se3.png | MY(넓은 닉네임 W×12) | iPhone SE 3세대(임시) | 글자를 줄여 한 줄에 들어감 |
| myGuest-17e.png | MY 비로그인 | iPhone 17e | 정상 |
| myGuest-17pro.png | MY 비로그인 | iPhone 17 Pro | 정상 |
| myGuest-17promax.png | MY 비로그인 | iPhone 17 Pro Max | 정상 |
| myLoadFail-17pro.png | MY 불러오기 실패 | iPhone 17 Pro | 실패 카드 위에 "도장 정보 입력하기"가 보임(R-9) |
| myPurple-cardsOpen-17pro.png | MY 최애 카드 앞면(퍼플) | iPhone 17 Pro | 카드 정상, R-1 |
| myWhite-bottom-17e.png | MY 흰띠(맨 아래, 카드 덮임) | iPhone 17e | 시계가 띠 아이콘 위에 겹침(R-1) |
| myWhite-bottom-17pro.png | MY 흰띠(맨 아래, 카드 덮임) | iPhone 17 Pro | 시계가 띠 아이콘 위에 겹침(R-1) |
| myWhite-bottom-17promax.png | MY 흰띠(맨 아래, 카드 덮임) | iPhone 17 Pro Max | 시계가 띠 아이콘 위에 겹침(R-1) |
| myWhite-cardsOpen-17pro.png | MY 최애 카드 앞면(화이트) | iPhone 17 Pro | 카드 정상, R-1 |
| nickname-17e.png | 닉네임 설정(가입) | iPhone 17e | 정상 |
| nickname-17e-ax.png | 닉네임 설정(가입) | iPhone 17e · AX3 | AX3 글자 크기에서도 기본과 같은 크기(O-1). 정상 |
| nickname-17pro.png | 닉네임 설정(가입) | iPhone 17 Pro | 정상 |
| nickname-17promax.png | 닉네임 설정(가입) | iPhone 17 Pro Max | 정상 |
| nicknameEdit-17e.png | 닉네임 수정(12자) | iPhone 17e | 정상 |
| nicknameEdit-17pro.png | 닉네임 수정(12자) | iPhone 17 Pro | 정상 |
| nicknameEdit-17promax.png | 닉네임 수정(12자) | iPhone 17 Pro Max | 정상 |
| notifSetting-17e.png | 알림 설정 | iPhone 17e | 기기 알림 꺼짐 배너 — 정상 |
| notifSetting-17e-ax.png | 알림 설정 | iPhone 17e · AX3 | AX3 글자 크기에서도 기본과 같은 크기(O-1). 기기 알림 꺼짐 배너 — 정상 |
| notifSetting-17pro.png | 알림 설정 | iPhone 17 Pro | 기기 알림 꺼짐 배너 — 정상 |
| notifSetting-17promax.png | 알림 설정 | iPhone 17 Pro Max | 기기 알림 꺼짐 배너 — 정상 |
| settings-17e.png | 설정 | iPhone 17e | 정상(SE는 아래 두 줄 스크롤) |
| settings-17e-ax.png | 설정 | iPhone 17e · AX3 | AX3 글자 크기에서도 기본과 같은 크기(O-1). 정상(SE는 아래 두 줄 스크롤) |
| settings-17pro.png | 설정 | iPhone 17 Pro | 정상(SE는 아래 두 줄 스크롤) |
| settings-17promax.png | 설정 | iPhone 17 Pro Max | 정상(SE는 아래 두 줄 스크롤) |
| settings-se3.png | 설정 | iPhone SE 3세대(임시) | 정상(SE는 아래 두 줄 스크롤) |
| settings-se3-ax.png | 설정 | iPhone SE 3세대(임시) · AX3 | AX3 글자 크기에서도 기본과 같은 크기(O-1). 정상(SE는 아래 두 줄 스크롤) |
| signupDone-17e.png | 가입 완료(12자 닉네임) | iPhone 17e | 이름 줄이 화면 끝까지 꽉 참(R-5) |
| signupDone-17e-ax.png | 가입 완료(12자 닉네임) | iPhone 17e · AX3 | AX3 글자 크기에서도 기본과 같은 크기(O-1). 이름 줄이 화면 끝까지 꽉 참(R-5) |
| signupDone-17pro.png | 가입 완료(12자 닉네임) | iPhone 17 Pro | 이름 줄이 화면 끝까지 꽉 참(R-5) |
| signupDone-17promax.png | 가입 완료(12자 닉네임) | iPhone 17 Pro Max | 이름 줄이 화면 끝까지 꽉 참(R-5) |
| signupDone-se3.png | 가입 완료(12자 닉네임) | iPhone SE 3세대(임시) | 이름 줄이 화면 끝까지 꽉 참(R-5) |
| signupDone-wideNick-17pro.png | 가입 완료(넓은 닉네임) | iPhone 17 Pro | "님!"만 다음 줄로 떨어짐(R-5) |
| signupDone-wideNick-se3.png | 가입 완료(넓은 닉네임) | iPhone SE 3세대(임시) | "님!"만 다음 줄로 떨어짐(R-5) |
| splash-17e.png | 스플래시 | iPhone 17e | 정상 |
| splash-17pro.png | 스플래시 | iPhone 17 Pro | 정상 |
| splash-17promax.png | 스플래시 | iPhone 17 Pro Max | 정상 |
| splashFail-17e.png | 스플래시 연결 실패 | iPhone 17e | "다시 시도" — 정상 |
| splashFail-17e-ax.png | 스플래시 연결 실패 | iPhone 17e · AX3 | AX3 글자 크기에서도 기본과 같은 크기(O-1). "다시 시도" — 정상 |
| splashFail-17pro.png | 스플래시 연결 실패 | iPhone 17 Pro | "다시 시도" — 정상 |
| splashFail-17promax.png | 스플래시 연결 실패 | iPhone 17 Pro Max | "다시 시도" — 정상 |
| style-black-17e.png | 최애 고르기 카드 앞면(블랙) | iPhone 17e | R-8, SE에서 아래 선택 칸이 버튼에 가려짐(R-4) |
| style-black-17e-ax.png | 최애 고르기 카드 앞면(블랙) | iPhone 17e · AX3 | AX3 글자 크기에서도 기본과 같은 크기(O-1). R-8, SE에서 아래 선택 칸이 버튼에 가려짐(R-4) |
| style-black-17pro.png | 최애 고르기 카드 앞면(블랙) | iPhone 17 Pro | R-8, SE에서 아래 선택 칸이 버튼에 가려짐(R-4) |
| style-black-17promax.png | 최애 고르기 카드 앞면(블랙) | iPhone 17 Pro Max | R-8, SE에서 아래 선택 칸이 버튼에 가려짐(R-4) |
| style-black-se3.png | 최애 고르기 카드 앞면(블랙) | iPhone SE 3세대(임시) | R-8, SE에서 아래 선택 칸이 버튼에 가려짐(R-4) |
| style-blue-17e.png | 최애 고르기 카드 앞면(블루) | iPhone 17e | R-8 |
| style-blue-17pro.png | 최애 고르기 카드 앞면(블루) | iPhone 17 Pro | R-8 |
| style-blue-17promax.png | 최애 고르기 카드 앞면(블루) | iPhone 17 Pro Max | R-8 |
| style-brown-17e.png | 최애 고르기 카드 앞면(브라운) | iPhone 17e | R-8 |
| style-brown-17pro.png | 최애 고르기 카드 앞면(브라운) | iPhone 17 Pro | R-8 |
| style-brown-17promax.png | 최애 고르기 카드 앞면(브라운) | iPhone 17 Pro Max | R-8 |
| style-purple-17e.png | 최애 고르기 카드 앞면(퍼플) | iPhone 17e | R-8 |
| style-purple-17pro.png | 최애 고르기 카드 앞면(퍼플) | iPhone 17 Pro | R-8 |
| style-purple-17promax.png | 최애 고르기 카드 앞면(퍼플) | iPhone 17 Pro Max | R-8 |
| style-white-17e.png | 최애 고르기 카드 앞면(화이트) | iPhone 17e | 수정 모드인데 "나중에 하기"(R-8) |
| style-white-17pro.png | 최애 고르기 카드 앞면(화이트) | iPhone 17 Pro | 수정 모드인데 "나중에 하기"(R-8) |
| style-white-17promax.png | 최애 고르기 카드 앞면(화이트) | iPhone 17 Pro Max | 수정 모드인데 "나중에 하기"(R-8) |
| styleSub-17e.png | 최애 고르기 — 미선택(서브미션) | iPhone 17e | "선택하기" 빈 카드 — 정상 |
| styleSub-17pro.png | 최애 고르기 — 미선택(서브미션) | iPhone 17 Pro | "선택하기" 빈 카드 — 정상 |
| styleSub-17promax.png | 최애 고르기 — 미선택(서브미션) | iPhone 17 Pro Max | "선택하기" 빈 카드 — 정상 |
| terms-17e.png | 약관 동의 시트 | iPhone 17e | 정상 |
| terms-17e-ax.png | 약관 동의 시트 | iPhone 17e · AX3 | AX3 글자 크기에서도 기본과 같은 크기(O-1). 정상 |
| terms-17pro.png | 약관 동의 시트 | iPhone 17 Pro | 정상 |
| terms-17promax.png | 약관 동의 시트 | iPhone 17 Pro Max | 정상 |
| terms-se3.png | 약관 동의 시트 | iPhone SE 3세대(임시) | 정상 |
| terms-se3-ax.png | 약관 동의 시트 | iPhone SE 3세대(임시) · AX3 | AX3 글자 크기에서도 기본과 같은 크기(O-1). 정상 |
| termsRecent-17e.png | 약관 동의 시트(예전 수단 안내) | iPhone 17e | 정상 |
| termsRecent-17e-ax.png | 약관 동의 시트(예전 수단 안내) | iPhone 17e · AX3 | AX3 글자 크기에서도 기본과 같은 크기(O-1). 정상 |
| termsRecent-17pro.png | 약관 동의 시트(예전 수단 안내) | iPhone 17 Pro | 정상 |
| termsRecent-17promax.png | 약관 동의 시트(예전 수단 안내) | iPhone 17 Pro Max | 정상 |
| userProfile-17e.png | 남의 프로필(검은띠·관장) | iPhone 17e | 정상 |
| userProfile-17e-ax.png | 남의 프로필(검은띠·관장) | iPhone 17e · AX3 | AX3 글자 크기에서도 기본과 같은 크기(O-1). 정상 |
| userProfile-17pro.png | 남의 프로필(검은띠·관장) | iPhone 17 Pro | 정상 |
| userProfile-17promax.png | 남의 프로필(검은띠·관장) | iPhone 17 Pro Max | 정상 |
| userProfile-bottom-17e.png | 남의 프로필(맨 아래) | iPhone 17e | 뒤로가기가 도장명 위에 겹치고 SE에선 회색 바탕에 흰 "<"가 거의 안 보임(R-2) |
| userProfile-bottom-17pro.png | 남의 프로필(맨 아래) | iPhone 17 Pro | 뒤로가기가 도장명 위에 겹치고 SE에선 회색 바탕에 흰 "<"가 거의 안 보임(R-2) |
| userProfile-bottom-17promax.png | 남의 프로필(맨 아래) | iPhone 17 Pro Max | 뒤로가기가 도장명 위에 겹치고 SE에선 회색 바탕에 흰 "<"가 거의 안 보임(R-2) |
| userProfile-bottom-se3.png | 남의 프로필(맨 아래) | iPhone SE 3세대(임시) | 뒤로가기가 도장명 위에 겹치고 SE에선 회색 바탕에 흰 "<"가 거의 안 보임(R-2) |
| userProfile-cardsOpen-17pro.png | 남의 프로필 카드 앞면 | iPhone 17 Pro | 카드 정상, 닉네임이 상태 막대와 겹침(R-1·R-2) |
| userProfile-wideNick-17pro.png | 남의 프로필(넓은 닉네임) | iPhone 17 Pro | 정상 |
| userProfile-wideNick-se3.png | 남의 프로필(넓은 닉네임) | iPhone SE 3세대(임시) | 정상 |
| userProfileEmpty-17e.png | 남의 프로필(빈) | iPhone 17e | "아직 안 골랐어요"가 두 줄로 꺾임(17 Pro에서도) |
| userProfileEmpty-17pro.png | 남의 프로필(빈) | iPhone 17 Pro | "아직 안 골랐어요"가 두 줄로 꺾임(17 Pro에서도) |
| userProfileEmpty-17promax.png | 남의 프로필(빈) | iPhone 17 Pro Max | "아직 안 골랐어요"가 두 줄로 꺾임(17 Pro에서도) |
| withdrawal-17e.png | 탈퇴 확인 알럿 | iPhone 17e | 합니다체(R-7) |
| withdrawal-17pro.png | 탈퇴 확인 알럿 | iPhone 17 Pro | 합니다체(R-7) |
| withdrawal-17promax.png | 탈퇴 확인 알럿 | iPhone 17 Pro Max | 합니다체(R-7) |
| withdrawalApple-17e.png | 탈퇴 확인 알럿(Apple) | iPhone 17e | 합니다체(R-7) |
| withdrawalApple-17e-ax.png | 탈퇴 확인 알럿(Apple) | iPhone 17e · AX3 | AX3 글자 크기에서도 기본과 같은 크기(O-1). 합니다체(R-7) |
| withdrawalApple-17pro.png | 탈퇴 확인 알럿(Apple) | iPhone 17 Pro | 합니다체(R-7) |
| withdrawalApple-17promax.png | 탈퇴 확인 알럿(Apple) | iPhone 17 Pro Max | 합니다체(R-7) |
| withdrawalApple-se3.png | 탈퇴 확인 알럿(Apple) | iPhone SE 3세대(임시) | 합니다체(R-7) |
