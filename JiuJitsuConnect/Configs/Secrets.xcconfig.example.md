// ⚠️ URL 값의 `//` 는 반드시 `/$()/` 로 이스케이프할 것.
// xcconfig는 `//` 부터 줄 끝까지를 주석으로 처리해서, 그냥 쓰면 값이 스킴만 남고 잘린다.
//   ❌ BASE_URL = https://api.example.com   → 실제 값 "https:"
//   ✅ BASE_URL = https:/$()/api.example.com → 실제 값 "https://api.example.com"
// `$()` 는 빈 문자열로 치환되는 xcconfig 변수 참조라, 파서가 `//` 를 못 보게 끊어줄 뿐
// 최종 값에는 아무 영향이 없다.
// BASE_URL / WEB_URL 은 Endpoint에서 path를 이어붙이므로 끝에 슬래시를 붙이지 않는다.

// Google
GOOGLE_CLIENT_ID = 
GIDClientID =

// Kakao
KAKAO_NATIVE_APP_KEY =

// API URLs — 구성별 매핑(Debug·Beta → DEV, Release → PROD)은 Project.swift에서 한다.
BASE_URL_DEV =
BASE_URL_PROD =

// Web URLs
WEB_URL_DEV =
WEB_URL_PROD =

// ImageKit (https://imagekit.io)
IMAGEKIT_PUBLIC_KEY =

// Signing — Apple Developer Team ID (Xcode > Settings > Accounts 의 Team ID, 10자리)
// 비워두면 tuist generate 후 Xcode UI에서 매번 Team을 다시 잡아야 함.
DEVELOPMENT_TEAM =
