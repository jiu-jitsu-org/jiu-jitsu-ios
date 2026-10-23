import SwiftUI

public extension View {
    /// 진한 바탕(파란 스플래시·로그인) 위에서 맨 위 시계·배터리 글자를 흰색으로 띄운다.
    ///
    /// SwiftUI에는 상태 막대 색만 바꾸는 API가 없어, 창의 색 모드를 어둡게 요청해 흰 글자를 얻는다.
    /// 대신 이 뷰 안쪽은 밝은 모드로 고정해 색 토큰이 어두운 값으로 바뀌지 않게 한다.
    /// `isActive`가 false면 요청을 거둬 원래(밝은) 상태 막대로 돌아간다.
    func lightStatusBar(_ isActive: Bool = true) -> some View {
        environment(\.colorScheme, .light)
            .preferredColorScheme(isActive ? .dark : nil)
    }
}
