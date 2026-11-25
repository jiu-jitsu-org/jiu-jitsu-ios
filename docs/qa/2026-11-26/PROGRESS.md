# QA 진행 상태 (세션이 끊기면 여기서 이어감)

worktree: /Users/swimming_moon/Documents/HansolDev/jiu-jitsu-ios-qa · 브랜치 qa/ios-release-qa

- [x] 1. 계획 — PLAN.md
- [x] 2. 점검 — A1~A7(83건) + R(캡처 213장, 9건)
- [x] 3. 검증 — 수정 담당이 고치기 전 재확인, 오탐은 FIX-n.md에 기록 — findings/VERIFIED.md
- [x] 4. 수정 — worktree ../jiu-jitsu-ios-fix{1,2,3} (브랜치 qa/fix-1..3, develop 기준). 1=MY·대회 데이터, 2=앱틀·로그인·설정, 3=접근성·최애. 끝나면 결과 findings/FIX-n.md → qa/ios-release-qa 로 cherry-pick
- [x] 5. 빌드 확인(경고-에러 켬 성공) · 적대적 리뷰(2건 중 1건 반영, 1건 오탐) · 커밋 · 푸시
- [x] 6. 보고서 — REPORT.md + https://claude.ai/artifact/1e61hXAbcTrCGMmBZkC3Xg

## 메모
- 02:1x 점검자 8명(A1~A7 코드, R 화면) 백그라운드로 출발. 재개 예약: 매시 17분.
- 완료: A2(19) A3(10) A4(11) A5(7) A6(11). 대기: A1 A7 R.
- 검증 메모: A3-1 확인됨(MY 대회 저장이 캐시 프로필로 목록 전체 교체 → 수정 1순위). A5-1 확인됨(모달 안에 로그인 안내 알럿·로그인 창 없음). A5-2는 Kakao 앱 전환 후 돌아오지 않는 경우 버튼이 영구 잠길 위험 때문에 가드를 안 둔 것으로 보여 보류.
- 주의: R 점검자가 끝날 때 `git checkout -- JiuJitsuConnect`로 하네스를 지우므로 R 완료 전에는 소스 수정 금지.
- 세션이 끊겨 점검자가 사라졌다면: findings/ 에 없는 묶음만 _BRIEF.md 로 다시 띄운다.
- fix-2 완료(11건, 빌드 성공, FIX-2.md) · fix-3 완료(10건, 빌드 성공, FIX-3.md). 대기: fix-1, R.
- 다음: fix-1·R 끝나면 qa/ios-release-qa 에 fix-2 → fix-3 → fix-1 순 cherry-pick, 충돌 해결, 빌드(경고-에러 켬), 적대적 리뷰(sonnet).
- fix-1 완료(13건). 통합: ../jiu-jitsu-ios-fix1 의 qa/fix-1 에 fix-2·fix-3 cherry-pick (28커밋, 충돌 없음), 경고-에러 켠 Debug 빌드 성공.
- 적대적 리뷰(sonnet) 진행 중. R 진행 중. R 끝나면 qa 워크트리에서 `git merge --ff-only qa/fix-1` 후 docs 커밋 → push.
- 완료. qa/ios-release-qa 푸시됨. 재개 예약 삭제.
