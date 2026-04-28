# JiuJitsuConnect — 코딩 컨벤션 & 아키텍처 가이드

> 이 문서는 `JiuJitsuConnect`(SwiftUI + TCA + Tuist 기반 BJJ 커뮤니티 iOS 앱)의
> **코딩 컨벤션과 아키텍처 원칙**을 정리한다. AI 협업자(Claude/Cursor)와 신규 합류자가
> 코드를 작성·리뷰할 때 이 문서를 단일 기준으로 사용한다.
>
> 빌드 명령·환경 세팅은 §10에 보조 자료로 두며, 핵심은 §3~§9 컨벤션이다.

---

## 1. 프로젝트 개요

| 항목 | 값 |
|---|---|
| 앱 정체성 | BJJ 커뮤니티 / 프로필 / 소셜로그인(Google·Kakao) |
| 번들 표시명 | `Oss` (`com.jiujitsulab.connect`) |
| 지원 언어 | ko (한국어 단일) |
| 화면 방향 | Portrait 전용, Light 테마 전용 |
| 최소 iOS 타겟 | **iOS 26.0** (iPhone 전용) |
| Swift / Xcode | **6.0** / upToNextMajor("26.0") |
| 기술 스택 | SwiftUI + TCA(ComposableArchitecture) 1.22.2+ |
| 패키지 관리 | SPM (Tuist `Tuist/Package.swift`) |
| 빌드 시스템 | **Tuist 4.46.1** (mise로 핀) |
| 경고 정책 | Warnings as Errors (Swift / GCC 모두 ON) |

**주요 외부 의존성:** `swift-composable-architecture` 1.22.2+, `firebase-ios-sdk` 12.12.1+,
`kakao-ios-sdk`, `GoogleSignIn-iOS`, `Pulse`, `Lottie` 4.5.2+, `Kingfisher`.

---

## 2. Tuist 운영 원칙

- 프로젝트는 `Project.swift`로 선언되며 `.xcodeproj` / `.xcworkspace`는 **생성물**(gitignore 대상).
- **`.xcodeproj`/`.xcworkspace` 직접 편집 금지.** 모든 타겟·의존성 변경은 `Project.swift` 또는 `Tuist/Package.swift`에서 이뤄진다.
- 의존성/구성을 바꾼 뒤 **반드시 `tuist generate`로 검증**한 상태에서 커밋한다.
- Asset 추가 시 SwiftGen(`swiftgen`)으로 `Targets/DesignSystem/Sources/Asset/Assets.swift`를 갱신한다. 이미지·컬러 이름을 문자열로 직접 사용하지 않는다.
- SwiftLint는 스킴 `SwiftLint`로만 동작하며, 일반 앱 빌드에는 영향을 주지 않는다.

### 타겟 의존성 그래프

```
App (executable)
├── Presentation (framework)         # TCA Feature/View
│   ├── Domain                       # Entity / Repository protocol
│   └── DesignSystem                 # 공유 UI 컴포넌트
├── Data (staticFramework)           # API/Local 구현
│   ├── Domain
│   └── CoreKit
├── CoreKit (framework, no deps)     # Log, 상수, 공통 유틸
└── DesignSystem (framework)
    └── CoreKit
+ SwiftLint (스킴 전용, 앱에 링크되지 않음)
```

빌드 구성은 `Debug` / `Beta` / `Release` 3종이며, `Beta`는 컴파일 조건 `BETA`와 전용 스킴 `App-Beta`를 가진다.

---

## 3. 아키텍처 — TCA 기반

### 3.1 레이어 순서

`App → Presentation (TCA) → Domain → Data → CoreKit / DesignSystem`

상태 관리는 **The Composable Architecture(TCA) 전용**. MVVM/MVC 혼용 금지.

### 3.2 UseCase 레이어를 사용하지 않는 이유

이 프로젝트는 **UseCase 레이어를 의도적으로 생략**한다.

```
// ❌ UseCases/ 폴더 없음 (제거됨)
Domain/
├── Entities/      ← 도메인 모델
└── Repositories/  ← Repository 프로토콜
```

**이유:**
- TCA Reducer가 비즈니스 흐름을 이미 명확하게 표현 (UseCase의 역할을 대체)
- Repository 프로토콜 + `DependencyContainer` + TCA Client 조합으로 레이어 분리 충분
- 현재 앱 규모에서 UseCase 추가는 오버엔지니어링

**비즈니스 로직 위치 기준:**

| 로직 종류 | 위치 |
|----------|------|
| UI 상태 전환, 화면 흐름 | TCA Reducer |
| 단순 데이터 변환 (DTO → Entity) | Data Mapper |
| 외부 API 조합 (ex. FCM 토큰 조립 후 등록) | DependencyContainer 클로저 |
| 도메인 규칙이 매우 복잡해지는 경우 | 그때 UseCase 도입 검토 |

### 3.3 TCA Feature 구조

Feature 파일 순서를 아래 순서로 고정한다.

```swift
@Reducer
public struct XxxFeature: Sendable {
    private enum CancelID { ... }         // 1. Cancel ID

    @ObservableState
    public struct State: Equatable { ... } // 2. State

    public enum Action: Sendable { ... }   // 3. Action

    @Reducer public enum Destination { }   // 4. 네비게이션 (필요 시)
    @Reducer public enum Sheet { }         // 5. 시트 (필요 시)
    @Reducer public enum Path { }          // 6. 스택 (필요 시)

    @Dependency(...) var ...               // 7. Dependencies

    public var body: some ReducerOf<Self> { ... } // 8. Reducer Body
}
```

### 3.4 Action 설계 규칙

#### 3.4.1 프로토콜 채택
- 최상위 `Action`은 반드시 `Sendable` 채택. **최상위 `Action`에 `Equatable` 채택 금지** (`State`는 `Equatable` 필수, 별개).
- `@Reducer` 매크로가 `Action`에 `CasePathable`을 자동 합성하므로 수동 `@CasePathable` 추가 불필요.

```swift
// ✅ 올바름
public enum Action: Sendable { ... }

// ❌ 잘못됨
public enum Action: Equatable { ... }
```

#### 3.4.2 중첩 enum에 @CasePathable
- 중첩 enum(`ViewAction`, `InternalAction` 등)에는 해당 enum의 케이스 키패스가
  `.sending()`, `CaseLet` 등에서 **실제로 사용될 때만** 붙인다.

```swift
// ✅ \.view.tabSelected 키패스를 .sending()에서 실사용하는 경우에만
@CasePathable
public enum ViewAction: Sendable { case tabSelected(Tab) }

// ❌ 실사용 없이 예방적으로 붙이는 것 금지
@CasePathable
public enum InternalAction: Sendable { case showLoginModal }
```

#### 3.4.3 Action 분류

```swift
public enum Action: Sendable {
    case view(ViewAction)        // 사용자 UI 이벤트
    case `internal`(InternalAction) // 내부 상태 전환
    case delegate(DelegateAction)   // 부모 Feature에 위임
    case destination(PresentationAction<Destination.Action>)
    case sheet(PresentationAction<Sheet.Action>)
}
```

### 3.5 Reducer 합성 패턴

| 상황 | 사용 API | 예시 |
|------|---------|------|
| 항상 존재하는 child state (탭 구조 등) | `Scope(state:action:)` | 탭 바의 main/community/myPage |
| 옵셔널 단일 네비게이션 (`@Presents var destination`) | `.ifLet(\.$destination, action: \.destination)` | push 이동, sheet 표시 |
| 스택 기반 네비게이션 (`StackState<Path.State>`) | `.forEach(\.path, action: \.path)` | NavigationStack 흐름 |

```swift
// ✅ 탭 구조 — Scope
public var body: some ReducerOf<Self> {
    Scope(state: \.main, action: \.main) { MainFeature() }
    Scope(state: \.community, action: \.community) { CommunityFeature() }
    Reduce { ... }
}

// ✅ 옵셔널 네비게이션 — .ifLet
Reduce { ... }
    .ifLet(\.$destination, action: \.destination)
    .ifLet(\.$sheet, action: \.sheet)

// ✅ 스택 — .forEach
Reduce { ... }
    .ifLet(\.$sheet, action: \.sheet)
    .forEach(\.path, action: \.path)
```

### 3.6 @Presents 프로퍼티 네이밍

| 용도 | 이름 | 타입 |
|------|------|------|
| 다중 케이스 push 네비게이션 | `destination` | `@Reducer enum Destination` |
| 다중 케이스 시트 | `sheet` | `@Reducer enum Sheet` |
| 단일 Feature `.fullScreenCover` | `{feature}Cover` | `XxxFeature.State?` |
| 단일 Feature `.sheet` | `{feature}Sheet` | `XxxFeature.State?` |
| 인라인 Alert | `alert` | `AlertState<...>?` |

```swift
// ✅
@Presents var destination: Destination.State?   // 다중 push
@Presents var sheet: Sheet.State?               // 다중 sheet
@Presents var loginCover: LoginFeature.State?   // 단일 fullScreenCover
@Presents var alert: AlertState<Alert>?         // 인라인 alert
```

### 3.7 BindableAction 채택 기준

TextField / TextEditor에서 `$store.property`를 **직접 바인딩**할 때만 채택한다.
Toggle, Slider, Picker는 `Binding(get:set:)` + 명시적 `store.send()`를 사용한다.

```swift
// ✅ TextField 직접 바인딩 → BindableAction 필요
public enum Action: BindableAction, Sendable {
    case binding(BindingAction<State>)
    ...
}
// View
TextField("", text: $store.nickname)

// ✅ Toggle → 명시적 send, BindableAction 불필요
Toggle("", isOn: Binding(
    get: { store.isWeightHidden },
    set: { store.send(.view(.weightHiddenToggled($0))) }
))
```

### 3.8 에러 처리 패턴

모든 Feature에서 에러 처리는 `DomainErrorMapper.toDisplayError(from:)`를 경유한다.
공통 헬퍼 이름은 `handleError`로 통일한다.

```swift
private func handleError(_ error: Error) -> Effect<Action> {
    guard let domainError = error as? DomainError else {
        return .send(.internal(.showToast(.init(message: APIErrorCode.unknown.displayMessage, style: .info))))
    }
    let displayError = DomainErrorMapper.toDisplayError(from: domainError)
    switch displayError {
    case .toast(let message), .info(let message), .alert(let message):
        return .send(.internal(.showToast(.init(message: message, style: .info))))
    case .none:
        return .none
    }
}
```

도메인 특화 에러 코드(닉네임 중복 등)는 `handleError` 호출 전에 먼저 분기한다.

### 3.9 Client 정의 규칙

클로저 속성 선언 순서: `@Sendable @escaping` (이 순서 고정).

```swift
// ✅
public init(
    fetch: @Sendable @escaping () async throws -> Model
)

// ❌
public init(
    fetch: @escaping @Sendable () async throws -> Model
)
```

모든 TCA Client는 `liveValue` / `testValue` / `previewValue` 셋 다 정의한다.
`testValue`는 `unimplemented`, `previewValue`는 mock 데이터 반환.

### 3.10 비동기 패턴

| 상황 | 패턴 |
|------|------|
| 단일 비동기 작업 | `TaskResult { try await client.method() }` |
| 병렬 실행이 필요한 경우 (ex. 스플래시 딜레이 + 자동로그인) | `async let` |

병렬화가 필요 없는 일반 API 호출에는 `async let`을 사용하지 않는다.

---

## 4. 폴더 & 파일 컨벤션

### 4.1 레이어 ↔ 위치 매핑

| 레이어 | 위치 |
|---|---|
| 앱 진입점 | `Targets/App/Sources/` (`JiuJitsuConnectApp.swift`, `AppDelegate.swift`, `DependencyContainer.swift`) |
| Feature/View (TCA) | `Targets/Presentation/Sources/Features/{App,AppTab,Splash,Login,Community,MyProfile,Settings,…}` |
| TCA Client (Dependency) | `Targets/Presentation/Sources/Dependencies/` |
| Domain Entity | `Targets/Domain/Sources/Entities/` |
| Repository Protocol | `Targets/Domain/Sources/Repositories/` |
| Repository 구현 | `Targets/Data/Sources/Repositories/` |
| Endpoint / NetworkService | `Targets/Data/Sources/Network/`, `…/Network/Endpoints/` |
| DTO ↔ Entity Mapper | `Targets/Data/Sources/Mappers/` |
| 로컬 저장소 | `Targets/Data/Sources/Local/` (TokenStorage 등) |
| 색상/타이포 토큰 | `Targets/DesignSystem/Sources/Color/`, `…/Typography/` |
| 공통 UI 컴포넌트 | `Targets/DesignSystem/Sources/Component/` (Button, Toast, Alert, BottomSheet, Picker) |
| Log/상수 | `Targets/CoreKit/Sources/Constants/Log.swift` |
| Asset enum (SwiftGen 산출) | `Targets/DesignSystem/Sources/Asset/Assets.swift` |

### 4.2 Feature 분리 / 파일 네이밍

- **Feature 분리 단위:** 화면(스크린) 단위. 한 폴더 = 한 Feature(`XxxFeature.swift` + `XxxView.swift`). Sub-screen은 같은 폴더 내에 둔다.
- **Reducer:** `XxxFeature.swift`
- **View:** `XxxView.swift`
- **TCA Dependency Client:** `XxxClient.swift` (`Presentation/Sources/Dependencies/`)
- **Repository:** `XxxRepository.swift`(프로토콜) + `XxxRepositoryImpl.swift`(구현)
- **Endpoint:** `XxxEndpoint.swift`
- **Mapper:** `XxxMapper.swift`

---

## 5. 브랜치 & 커밋 컨벤션

### 5.1 표준 형식 (`.gitmessage_template.txt`)

```
[플랫폼] type: 간결한 제목 (50자 이내)

상세 설명 (선택)
- 무엇을, 왜, 어떤 영향이 있는지

Closes #123 / Fixes #123 / Refs #123
```

- **플랫폼:** `[BE]` / `[FE]` / `[iOS]` / `[Android]` / `[All]` — 단일 플랫폼 작업 시 생략 가능
- **type:** `feat` / `fix` / `refactor` / `chore` / `docs` / `test` / `style`
- **제목:** 한국어, 50자 이내, 명령형/명사형, **첫 글자 소문자, 마침표 없음**

### 5.2 실 운용 형식 (이 레포 기준)

iOS 단일 레포이므로 플랫폼 prefix는 생략, **`type: 한글 제목`** 패턴이 우세.

```
feat: Beta 구성 및 로깅 지원 추가
fix: MyProfile 설정 버튼을 toolbar에서 헤더 오버레이로 변경
chore: LaunchScreen 추가
refactor: FCM 동기화 로직 개선
```

### 5.3 브랜치

- 베이스: `main`
- 기능 브랜치 → PR → main 병합

---

## 6. 네트워크 / 데이터 레이어

### 6.1 추상화 계층

```
Presentation (Feature)
   ↓ @Dependency(\.xxxClient)
TCA Client (Presentation/Sources/Dependencies/XxxClient.swift)
   ↓ DependencyContainer 주입
Repository Protocol (Domain/Sources/Repositories/)
   ↓ 구현
Repository Impl (Data/Sources/Repositories/)
   ↓
NetworkService (Data/Sources/Network/NetworkService.swift)
   ↓
Endpoint (Data/Sources/Network/Endpoints/)
```

현재 네트워크 구현은 **`URLSession` 직접 사용**(외부 네트워크 라이브러리 미사용).
새로운 네트워크 라이브러리 도입은 별도 합의를 거친다.

### 6.2 TCA Client 작성 규칙

```swift
extension XxxClient: DependencyKey {
    public static let liveValue: Self = .unimplemented   // DependencyContainer에서 실제 주입
    public static let testValue: XxxClient = XxxClient(...)
    public static let previewValue: XxxClient = XxxClient(...)
}

extension DependencyValues {
    public var xxxClient: XxxClient {
        get { self[XxxClient.self] }
        set { self[XxxClient.self] = newValue }
    }
}
```

### 6.3 인증/토큰 저장

`Targets/Data/Sources/Local/TokenStorage.swift`:
- **access / refresh 토큰** → Keychain (`kSecClassGenericPassword`)
- **provider, autoLoginEnabled** 등 메타 → UserDefaults

토큰을 직접 다루지 말고 `TokenStorage` 인터페이스를 경유한다.

### 6.4 로깅

`Targets/CoreKit/Sources/Constants/Log.swift`의 `Log.trace(_:category:level:)` 사용.

```swift
Log.trace("Failed to load profile: \(error)", category: .network, level: .error)
Log.trace("닉네임 저장 요청: \(nickname)", category: .debug, level: .info)
```

- **카테고리:** `.debug`, `.network`, `.storage`, `.view`, `.system`, `.custom(...)`
- **Pulse**(디버그 콘솔)는 `App` 타겟에서 `Log.handler`로 연결되며, 시뮬레이터/디버그 빌드에서 흔들기 제스처(Simulator 메뉴 `Device > Shake` / `Ctrl+Cmd+Z`)로 호출.

---

## 7. 코드 스타일

- **주석:** 한글 허용. WHAT이 아닌 **WHY** 중심으로 작성. 잘 명명된 식별자가 설명할 수 있는 내용은 주석으로 반복하지 않는다.
- **View 분리 기준:** 하위 뷰가 **자체 상태/액션을 가지거나 다른 화면에서 재사용 가능**하면 별 파일로 분리한다. (라인 수 같은 정량 기준은 두지 않는다.)
- **컬러:** `DesignSystem`의 Semantic / Component / Primitive Color 토큰만 사용. 하드코딩 hex 금지.
- **폰트:** `DesignSystem`의 Typography 토큰만 사용. (실 폰트 파일은 Pretendard / CookieRun, Info.plist `UIAppFonts`에 등록되어 있으나 코드에서 폰트 이름 문자열을 직접 사용하지 않는다.)
- **이미지/Asset:** SwiftGen 생성 결과(`Assets.xxx`)만 사용. 이름 문자열 직접 사용 금지.
- **Preview:** 신규 View는 `#Preview`를 작성한다. mock store는 `XxxClient.previewValue` 활용.
- **`@ViewAction` 매크로:** 현재 미사용. 도입 시 코드 일관성을 위해 별도 합의를 거친다.

---

## 8. 테스트 원칙

> 현재 테스트 타겟은 구성되어 있지 않다. 모든 TCA Client에 `testValue` / `previewValue`가 마련되어 있어 도입 시 점진 확장이 가능하다.

도입 시 가이드:
- **Reducer 단위 테스트:** TCA `TestStore`로 Feature 단위 작성.
- **Repository:** 프로토콜 모킹으로 격리. 실제 네트워크는 호출하지 않는다.
- **Effect 테스트:** 시계 의존성은 `@Dependency(\.continuousClock)` 등으로 주입해 결정적으로 진행.
- **점진적 도입 권장:** 새 Feature 추가 시 최소 1개의 `TestStore` 시나리오를 함께 작성하는 흐름을 권장.

---

## 9. 금지 / 강제 사항

> 이 섹션은 코드 리뷰에서 **막아야 할 것**과 **반드시 따라야 할 것**을 모은 체크리스트다.
> 합리적 예외가 필요하면 PR 본문에 사유를 명시하고 합의를 거친다.

### 9.1 Swift 일반
- `print()` 사용 금지 → `Log.trace()`
- 강제 언래핑(`!`) 사용 금지 → `guard let` / 옵셔널 체이닝
- 전역 변수 사용 금지 → `@Dependency` / TCA Store를 통한 상태 전달
- 하드코딩 hex 컬러 사용 금지 → `DesignSystem` Color 토큰
- 의미가 모호한 매직 넘버는 적절히 상수/`enum`으로 추출 (UI padding 같이 일회성·통일 기준이 없는 값은 예외)

### 9.2 iOS 버전
- deployment target = 26.0이므로 `#available(iOS …, *)` 분기는 **불필요**. (외부 SDK 호환 등 정당한 사유가 있을 때만 추가하고 사유를 주석으로 남긴다.)

### 9.3 TCA / 상태 관리
- 최상위 `Action`에 `Equatable` 채택 금지 (`Sendable`만)
- 중첩 Action enum에 예방적 `@CasePathable` 추가 금지
- `BindableAction` 채택은 TextField / TextEditor 직접 바인딩 시에만 한정 (그 외 위젯은 `Binding(get:set:)` + `store.send()`)
- `@EnvironmentObject` 사용 금지 → TCA Store / `@Dependency`로 대체
- `NotificationCenter` **신규** 사용 금지 → TCA Effect 또는 Combine `PassthroughSubject`
- View가 Repository / NetworkService를 직접 참조 금지 → 항상 TCA Client(`@Dependency`) 경유

### 9.4 빌드 시스템
- `.xcodeproj` / `.xcworkspace` 직접 편집 금지 (Tuist 생성물)
- 의존성/타겟 변경 후 `tuist generate`로 검증한 상태에서만 커밋
- Asset 추가 후 SwiftGen 미실행 상태로 코드 푸시 금지

---

## 10. 로컬 개발 환경 세팅 (보조)

> 컨벤션 본체는 §3~§9. 이 섹션은 신규 합류자의 첫 빌드까지를 보조한다.

### 10.1 필수 도구

| 도구 | 버전 | 설치 |
|---|---|---|
| Xcode | 26.x | Mac App Store / Apple Developer |
| mise | 최신 | `brew install mise` |
| Tuist | 4.46.1 | `mise install` (자동) |
| SwiftLint | 최신 | `brew install swiftlint` |

### 10.2 최초 세팅 순서

```sh
# 1) 도구 설치
mise install                                      # → tuist 4.46.1

# 2) 시크릿 배치 (별도 채널로 받은 파일)
#    템플릿: JiuJitsuConnect/Configs/Secrets.xcconfig.example.md
cp <받은 파일> JiuJitsuConnect/Configs/Secrets.xcconfig
cp <받은 파일> JiuJitsuConnect/Secrets/GoogleService-Info.plist

# 3) 의존성 + 프로젝트 생성
cd JiuJitsuConnect
tuist install
tuist generate

# 4) 워크스페이스 오픈
open JiuJitsuConnect.xcworkspace
```

### 10.3 스킴 / 디바이스

- **스킴:** `App` (Debug/Release) 또는 `App-Beta` (Beta)
- **디바이스:** iPhone 시뮬레이터 (iOS 26.0+)
- **Pulse 디버그 콘솔:** Debug 빌드에서 시뮬레이터 흔들기(`Device > Shake` / `Ctrl+Cmd+Z`)로 호출

### 10.4 트러블슈팅

| 증상 | 조치 |
|---|---|
| `Project.swift` 변경이 Xcode에 반영되지 않음 | `tuist generate` 재실행 |
| Asset이 코드에서 인식되지 않음 | `swiftgen` 실행 후 `tuist generate` |
| Firebase / Kakao / Google 관련 빌드 에러 | `Configs/Secrets.xcconfig` 및 `Secrets/GoogleService-Info.plist` 배치 확인 |
| Pulse 콘솔이 뜨지 않음 | Debug 빌드인지 확인, 시뮬레이터 흔들기 제스처 |

---

## 부록 A. CI / 자동화

`.github/workflows/Project Automation.yml` — 이슈/PR ↔ GitHub Project V2 자동 동기화 (라벨, 상태, 우선순위, Epic, 플랫폼 라벨링).
빌드/테스트/배포 자동화 job은 현재 미구성.

## 부록 B. AI 도구 설정

- `.cursor/rules/commit-messages.mdc` — Cursor IDE용 커밋 메시지 규칙
- `.claude/settings.local.json` — Claude Code Bash 화이트리스트 (`tuist`, `xcodebuild`, `git diff` 등)
