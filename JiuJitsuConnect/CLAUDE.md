# JiuJitsuConnect 코드 컨벤션

## 아키텍처

- **레이어 순서**: App → Presentation (TCA) → Domain → Data → CoreKit / DesignSystem
- **상태 관리**: The Composable Architecture (TCA) 전용. MVVM/MVC 혼용 금지.

### UseCase 레이어를 사용하지 않는 이유

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

---

## TCA Feature 구조

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

---

## Action 설계 규칙

### 1. 프로토콜 채택
- 최상위 `Action`은 반드시 `Sendable` 채택. `Equatable` 사용 금지.
- `@Reducer` 매크로가 `Action`에 `CasePathable`을 자동 합성하므로 수동 `@CasePathable` 추가 불필요.

```swift
// ✅ 올바름
public enum Action: Sendable { ... }

// ❌ 잘못됨
public enum Action: Equatable { ... }
```

### 2. 중첩 enum에 @CasePathable
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

### 3. Action 분류
```swift
public enum Action: Sendable {
    case view(ViewAction)        // 사용자 UI 이벤트
    case `internal`(InternalAction) // 내부 상태 전환
    case delegate(DelegateAction)   // 부모 Feature에 위임
    case destination(PresentationAction<Destination.Action>)
    case sheet(PresentationAction<Sheet.Action>)
}
```

---

## Reducer 합성 패턴

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

---

## @Presents 프로퍼티 네이밍

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

---

## BindableAction 채택 기준

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

---

## 에러 처리 패턴

모든 Feature에서 에러 처리는 `DomainErrorMapper.toDisplayError(from:)`를 경유한다.  
공통 헬퍼 이름은 `handleError`로 통일한다.

```swift
// ✅ 공통 패턴
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

---

## Client 정의 규칙

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

---

## 비동기 패턴

| 상황 | 패턴 |
|------|------|
| 단일 비동기 작업 | `TaskResult { try await client.method() }` |
| 병렬 실행이 필요한 경우 (ex. 스플래시 딜레이 + 자동로그인) | `async let` |

병렬화가 필요 없는 일반 API 호출에는 `async let`을 사용하지 않는다.
