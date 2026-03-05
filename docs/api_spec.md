# API 명세서

> BookIt 프로젝트에서 사용하는 모든 외부 API를 정의합니다.
> Firebase Cloud Functions (자체 API)와 외부 서비스 API를 포함합니다.

---

## 목차
1. [Cloud Functions API](#1-cloud-functions-api)
2. [외부 인증 API (Google OAuth)](#2-외부-인증-api-google-oauth)
3. [이메일 인증 API (자체 서버)](#3-이메일-인증-api-자체-서버)
4. [API 설정 위치](#4-api-설정-위치)

---

## 1. Cloud Functions API

**런타임:** Node.js (Firebase Functions v2)
**리전:** `us-central1`
**Base URL 패턴:** `https://{function-name}-o4apuahgma-uc.a.run.app`

---

### 1.1 `askToChatGPT` — AI 도서 추천 (부기)

**트리거:** `onCall` (Flutter 클라이언트 직접 호출)
**파일:** `functions/index.js`
**모델:** `gpt-4o-mini`

#### 역할
클라이언트에서 받은 사용자 질문과 보유 도서 목록을 OpenAI GPT에 전달하여
도서 1권을 추천합니다. API 키를 클라이언트에 노출하지 않고 서버에서 안전하게 처리합니다.

#### 요청

```dart
// Flutter 호출 예시
FirebaseFunctions.instance
    .httpsCallable('askToChatGPT')
    .call({
        'userText': '요즘 우울한데 위로가 되는 책 추천해줘',
        'bookList': 'ID: abc123, 제목: 채식주의자\nID: def456, 제목: 나미야 잡화점의 기적',
    });
```

| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|:----:|------|
| `userText` | String | O | 사용자가 입력한 자연어 질문 |
| `bookList` | String | O | 현재 보유 도서 목록 (ID + 제목 포함 텍스트) |

#### 응답

```json
{
  "result": "우울할 때 읽으면 좋은 책으로 '나미야 잡화점의 기적'을 추천해드릴게요! ...\n[BOOK_ID:def456]"
}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| `result` | String | GPT 응답 텍스트. 마지막 줄에 `[BOOK_ID:{id}]` 포함 |

#### 응답 파싱 규칙

클라이언트는 응답 문자열에서 아래 패턴을 정규식으로 추출합니다:

```dart
final regex = RegExp(r'\[BOOK_ID:([^\]]+)\]');
final match = regex.firstMatch(result);
final bookId = match?.group(1); // 추출된 bookId로 상세 페이지 이동
```

#### 에러

| 상황 | Firebase Functions 에러 코드 | 메시지 |
|------|------------------------------|--------|
| OpenAI 통신 실패 | `internal` | `"GPT 서버 통신 실패"` |

#### 시크릿 관리

`OPENAI_API_KEY`는 Firebase Secret Manager에 저장됩니다.
`defineSecret('OPENAI_API_KEY')`로 참조하며 환경 변수나 소스 코드에 노출되지 않습니다.

---

## 2. 외부 인증 API (Google OAuth)

**서비스:** Google Sign-In
**패키지:** `google_sign_in`, `firebase_auth`

### 2.1 플랫폼별 처리 방식

| 플랫폼 | 방식 | 설명 |
|--------|------|------|
| Web | `signInWithPopup(GoogleAuthProvider)` | 팝업 창에서 구글 계정 선택 |
| Android/iOS | `GoogleSignIn.authenticate()` → `signInWithCredential()` | 네이티브 구글 로그인 |

### 2.2 설정 값

| 설정 | 값 위치 |
|------|---------|
| `serverClientId` | `AppConfig.googleServerClientId` |
| Android 설정 | `android/app/google-services.json` |
| iOS 설정 | `ios/Runner/GoogleService-Info.plist` |
| Web 설정 | `lib/firebase_options.dart` |

### 2.3 Firestore 동기화 규칙

구글 로그인 성공 후 `_syncGoogleUserToFirestore(user)` 호출:

| 상황 | 처리 |
|------|------|
| `/users/{uid}` 문서 없음 (신규) | 문서 생성 — `{ email, name, nickname, photoUrl, role: 'user', createdAt }` |
| `/users/{uid}` 문서 있음 (기존) | `photoUrl`만 업데이트 |

---

## 3. 이메일 인증 API (자체 서버)

클라이언트는 Firebase Cloud Functions가 아닌 별도의 자체 서버 엔드포인트를 호출합니다.
HTTP 클라이언트로 `package:http`를 사용합니다.

---

### 3.1 인증 코드 발송

**URL:** `AppConfig.sendVerificationCodeUrl`
`https://sendverificationcode-o4apuahgma-uc.a.run.app`

**Method:** `POST`
**Content-Type:** `application/json`

#### 요청

```json
{
  "email": "user@example.com"
}
```

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `email` | String | 인증 코드를 받을 이메일 (소문자 trim 처리 후 전송) |

#### 응답

| HTTP 상태 | 의미 |
|-----------|------|
| `200` | 인증 코드 발송 성공 |
| 그 외 | 발송 실패 — `response.body`를 Exception 메시지로 throw |

#### Flutter 호출 코드

```dart
// auth_service.dart — sendEmailVerificationCode()
final response = await http.post(
    Uri.parse(AppConfig.sendVerificationCodeUrl),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'email': email.trim().toLowerCase()}),
);

if (response.statusCode != 200) {
    throw Exception(response.body);
}
```

---

### 3.2 코드 검증 + 최종 회원가입

**URL:** `AppConfig.verifyCodeAndFinalizeSignupUrl`
`https://verifycodeandfinalizesignup-o4apuahgma-uc.a.run.app`

**Method:** `POST`
**Content-Type:** `application/json`

#### 요청

```json
{
  "email": "user@example.com",
  "password": "password123!",
  "name": "홍길동",
  "nickname": "책벌레123",
  "code": "482910"
}
```

| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|:----:|------|
| `email` | String | O | 이메일 (소문자 trim 처리) |
| `password` | String | O | 비밀번호 |
| `name` | String | O | 실명 |
| `nickname` | String | O | 닉네임 |
| `code` | String | O | 사용자가 입력한 6자리 인증 코드 |

#### 응답

| HTTP 상태 | 의미 | Flutter 처리 |
|-----------|------|-------------|
| `200` | 회원가입 성공 | 가입 완료 처리 후 로그인 화면으로 이동 |
| `409` | 이미 가입된 이메일 | 중복 이메일 안내 메시지 표시 |
| 그 외 | 서버 오류 | `response.body`를 Exception으로 throw |

#### Flutter 호출 코드

```dart
// auth_service.dart — verifyCodeAndFinalizeSignup()
final response = await http.post(
    Uri.parse(AppConfig.verifyCodeAndFinalizeSignupUrl),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
        'email': email.trim().toLowerCase(),
        'password': password,
        'name': name,
        'nickname': nickname,
        'code': code,
    }),
);

if (response.statusCode == 200 || response.statusCode == 409) {
    return response.statusCode; // 호출자에서 상태코드로 분기
} else {
    throw Exception(response.body);
}
```

---

## 4. API 설정 위치

| 설정 항목 | 파일 | 상수/키 |
|-----------|------|---------|
| Cloud Functions 인증 코드 발송 URL | `lib/core/constants/app_config.dart` | `AppConfig.sendVerificationCodeUrl` |
| Cloud Functions 회원가입 URL | `lib/core/constants/app_config.dart` | `AppConfig.verifyCodeAndFinalizeSignupUrl` |
| Google OAuth Server Client ID | `lib/core/constants/app_config.dart` | `AppConfig.googleServerClientId` |
| Firebase 프로젝트 설정 (전체 플랫폼) | `lib/firebase_options.dart` | `DefaultFirebaseOptions` |
| OpenAI API Key | Firebase Secret Manager | `OPENAI_API_KEY` (서버 전용) |

> `AppConfig`는 버전 관리에 포함됩니다. 민감한 값(API Key 등)은 절대 이 파일에 넣지 않습니다.
> OpenAI API Key는 Firebase Secret Manager에서만 관리합니다.
