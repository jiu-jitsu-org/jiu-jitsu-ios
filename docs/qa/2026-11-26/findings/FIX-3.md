# FIX-3 — 접근성(VoiceOver · 동작 줄이기) · 최애 기술(MyStyleSetting)

worktree `jiu-jitsu-ios-fix3`, 브랜치 `qa/fix-3` (origin/develop = b1b40b6 기준). 푸시 안 함.

## 결과

| ID | 결과 | 커밋 · 설명 |
|---|---|---|
| A7-1 | 고침 | `2ffc901` 뒤로 버튼 7곳(설정 · 알림 설정 · MY(쌓인) · 남의 프로필 · 웹 상세 · 최애 고르는 화면 · **회원 탈퇴**(QA 목록 밖, 같은 모양이라 함께))에 "뒤로 가기", 홈 검색에 "검색", 대회 기록 +에 "대회 기록 추가". 이용 통계 "뒤로" → "뒤로 가기"로 맞춤(TopHeader 관례). DesignSystem에 공용 뒤로 버튼은 TopHeader뿐이고(이미 라벨 있음) 각 화면이 직접 그려서 화면마다 붙임 |
| A2-5 | 고침 | `2ffc901` (A7-1과 같은 커밋 — UserProfileView · MyProfileView 뒤로) |
| A4-6 | 고침 | `2ffc901` (같은 커밋 — SettingsView · NotificationSettingView). 문구는 QA 제안 "뒤로"가 아니라 앱 다수 관례 "뒤로 가기" |
| A5-4 | 고침 | `3204705` 약관 행 왼쪽 묶음을 한 요소로 묶어 "제목, 필수/선택" + 버튼 특성 + 체크 시 선택됨, 기본 동작 = 체크. `>` 버튼은 "○○ 전문 보기" (DesignSystem `TermsAgreementSheetRowView.swift`) |
| A2-17 | 고침 | `ab5332b` 사진 요소를 "프로필 사진, 블루 띠 2그랄"(띠 없으면 "프로필 사진") + 힌트 "띠 링이 다시 돌아요"로(MY · 남의 프로필 공용 함수). MY 닉네임 라벨에 인증 시 "관장·사범 인증" 추가. 남의 프로필 벨트 카드의 띠 그림 · 인증 뱃지 그림은 옆 글자가 읽으니 숨김(에셋 이름 읽힘 방지) |
| A6-3 | 고침 | `2a903ac` 아래 줄 카드(없음 포함)를 한 요소로 묶어 온이름(`tabTitle`, 예 "조르기") + 버튼 + 고른 것은 선택됨. 접근성 동작으로도 고르기 |
| A6-4 | 고침 | `ca76a7a` 큰 카드 앞면 캐릭터 그림 · 뒷면 로고 숨김, FlippableStyleCard를 `.combine`으로 한 요소로 묶어 '카드 뒤집기' 동작이 그 요소에 붙음(안 보이는 면은 FlipCard가 이미 숨김). MY 빈 화면 장식 카드 4장 숨김. 뒤로 버튼은 `2ffc901` |
| A6-7 | 고침 | `c504b29` `flip(by:)` · `handleDragEnded`를 `reduceMotion ? nil : .spring(...)`로(등장 회전과 같은 방식). 손으로 끄는 동안 손가락을 따라 기우는 건 직접 조작이라 그대로 둠 |
| A6-11 | 고침 | `8b740c6` 읽기 전용 + 셋 다 비었으면 버튼 특성 제거, 힌트 없음 |
| A6-6 | 고침 | `de187de` 포갠 카드를 눌러 펼친 뒤 0.6초 동안 카드 누름 무시(`openedAt`). 코드로 재확인: SwiftUI는 애니메이션 중에도 최종 배치로 누름을 맞추므로 포갠 맨 위 자리(x=1.84w)가 펼친 가운데(기술) 카드에 걸림 — 결함 맞음. 화면 변화 없음. 실기기 연타 확인 필요 |
| A6-1 | 안 고침 (서버확인필요) | 아래 참고 |
| A6-2 | 안 고침 (서버확인필요) | 아래 참고 |

고친 것 10 / 안 고친 것 2.

## A6-1 · A6-2 — 서버로 가는 것 (코드만 읽음)

경로: MyStyleSettingFeature `.completeButtonTapped` → delegate `didConfirmStyle(type, best, favorite)` → MyProfileFeature `.savePosition/.saveSubmission/.saveTechnique` → `profile.updatingPosition(best:favorite:)` → `CommunityRepositoryImpl.updateProfile(_, section:)` → `PostCommunityProfileRequestDTO(from:section:)` → `POST /api/community/profile`, 본문은 기본 `JSONEncoder()`(합성 Encodable → Optional nil은 `encodeIfPresent`로 **키 자체가 빠짐**, `null`을 보내지 않음).

- 요청은 **그 섹션 값만이 아니라 프로필 전체**를 싣는다(`profileRequestType`만 섹션). 예외: `competitions`는 COMPETITION 저장에서만, `backgroundPattern`은 BACKGROUND_PATTERN 저장에서만.
- **A6-1** — 최애 포지션 '탑' → '없음' 저장(특기 bestPosition은 원래 없음, 블루 2그랄 · 기술 SWEEPS · 서브미션 CHOKES인 회원 예):
  ```json
  {"profileRequestType":"POSITION","beltRank":"BLUE","beltStripe":"STRIPE_2","gender":"MALE","weightKg":70,
   "academyName":"…","favoriteSubmission":"CHOKES","favoriteTechnique":"SWEEPS","isWeightHidden":false}
  ```
  `favoritePosition`(와 nil인 `bestPosition`) 키가 **없다**. TECHNIQUE · SUBMISSION도 같음(`favoriteTechnique` / `favoriteSubmission` 키 빠짐). 서버가 '키 없음 = 그대로 둠'이면 지워지지 않음(앱은 응답 프로필을 그대로 반영하므로 화면도 '탑'으로 남음). 도장 삭제는 같은 이유로 `""`를 보냄(MyProfileFeature 도장 삭제 주석) — 서버 방식 확인 후 같은 처리(빈 값 또는 명시적 null)가 필요한지 결정.
- **A6-2** — 응답 디코딩에서 `TechniqueType(rawValue:)` 등이 모르는 코드면 nil(`CommunityProfileResponseDTO.toDomain`, 공개 프로필 DTO도 같음). 그 뒤 어떤 섹션이든 저장하면 프로필 전체를 다시 보내므로, 모르는 값이었던 `best*` · `favorite*` 키가 **그 섹션이 아니어도** 빠진 채 나간다(예: 서버 `favoriteTechnique:"BACK_TAKES"` 회원이 포지션을 저장하면 요청에 `favoriteTechnique` 키 없음). 서버가 profileRequestType 밖 필드를 무시하는지, 키 없음을 삭제로 보는지에 따라 영향이 다름. 서버 · 웹이 앱 enum 밖 코드를 쓸 계획이 있는지 확인 필요.

## 다른 담당과 겹칠 수 있는 파일

View 파일 접근성 수식어만 건드림(Reducer 변경 없음): SettingsView, NotificationSettingView, AnalyticsSettingView(라벨 문구 1줄), MyProfileView, UserProfileView, CommunityView, CommunityDetailView, WithdrawalView, MyProfileHeaderComponents, MyProfileCompetitionComponents, DesignSystem TermsAgreementSheetRowView. 나머지는 MyStyleSetting 폴더.

## 빌드

경고-에러 켠 기본 설정(`SWIFT_TREAT_WARNINGS_AS_ERRORS` 덮어쓰기 없음)으로 `App` 스킴 Debug, generic iOS Simulator: **BUILD SUCCEEDED**. 바뀐 파일을 touch해 다시 컴파일한 빌드에서도 성공, `Targets/` 아래 경고 없음.

## 실기기에서 확인할 것

- VoiceOver: 약관 행이 "서비스 이용약관, 필수, 선택됨, 버튼"처럼 읽히고 두 번 탭으로 체크되는지
- VoiceOver: 고르는 화면 아래 줄 카드 · 큰 카드(앞/뒷면, '카드 뒤집기' 뒤 초점 유지)
- MY 포갠 카드 빠른 두 번 탭이 펼치기만 하는지, 0.6초가 너무 길거나 짧지 않은지
