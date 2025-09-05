# WorkoutLog

> **SwiftUI 기반 운동 기록 및 관리 앱**

WorkoutLog는 iOS 16.0 이상을 지원하는 SwiftUI 기반의 운동 기록 앱입니다. 체계적인 도메인 아키텍처와 NavigationStack을 활용한 현대적인 네비게이션 시스템을 구현했습니다.

## 📱 주요 기능

### 🏋️‍♂️ 운동 관리
- **운동 세션 관리**: 시작/중지/완료 기능
- **운동 선택**: 40개 이상의 운동 데이터베이스
- **부위별 분류**: 가슴, 등, 어깨, 팔, 하체, 코어
- **기구별 분류**: 머신, 케이블, 바벨, 덤벨, 맨몸

### 🔍 검색 및 필터링
- **실시간 검색**: 운동명 기반 즉시 검색
- **다중 필터**: 부위와 기구 조합 필터링
- **난이도 표시**: 초급/중급/고급 자동 분류
- **권장 세트/반복수**: 운동별 맞춤 가이드

### 📊 세션 추적
- **운동 시간 측정**: 시작부터 완료까지 자동 기록
- **세트 기록**: 무게, 반복수, 휴식시간 관리
- **진행 상태**: 실시간 운동 상태 표시
- **완료 요약**: 총 운동시간 및 수행한 운동 목록

## 🏗 아키텍처

### 도메인 기반 설계 (DDD)
```
Domains/
├── Core/           # 핵심 비즈니스 로직
├── Exercise/       # 운동 관련 기능
├── Rest/          # 휴식 관련 기능 (예정)
├── Shared/        # 공통 컴포넌트
└── Type/          # 타입 정의 (예정)
```

### MVVM 패턴
각 도메인은 Model-View-ViewModel 구조로 구성:
- **Model**: 데이터 모델 및 비즈니스 로직
- **View**: SwiftUI 뷰 컴포넌트
- **ViewModel**: 뷰와 모델 간 중재자 역할

## 🧩 핵심 컴포넌트

### Core 도메인
- **SessionModels.swift**: 운동 세션 상태 관리
- **Route enum**: NavigationStack 기반 타입 안전 네비게이션
- **Session ObservableObject**: 전역 세션 상태 관리

### Exercise 도메인
- **ExerciseDatabase**: 40개 이상 운동 데이터베이스
- **ExerciseModels**: 운동 타입, 세트, 난이도 모델
- **ExerciseSelectionView**: 운동 검색 및 선택 UI
- **ExerciseSelectionViewModel**: 필터링 및 검색 로직

## 🚀 기술 스택

### 플랫폼
- **iOS**: 16.0 이상
- **macOS**: 빌드 및 테스트 지원
- **Swift**: 5.x
- **SwiftUI**: 최신 기능 활용

### 주요 기술
- **NavigationStack**: iOS 16+ 네비게이션 시스템
- **NavigationPath**: 타입 안전 경로 관리
- **@MainActor**: 메인 스레드 안전성
- **ObservableObject**: 반응형 상태 관리
- **Combine**: 데이터 바인딩 및 이벤트 처리

## 📱 사용자 플로우

```
홈 화면
    ↓ [운동 시작]
부위 선택 (구현 예정)
    ↓ [부위 선택]
기구 선택 (구현 예정)
    ↓ [기구 선택]
운동 선택 (완료)
    ↓ [운동 선택]
운동 기록 (구현 예정)
    ↓ [운동 완료]
요약 화면 (완료)
```

## 🔧 개발 환경 설정

### 요구사항
- **Xcode**: 15.0 이상
- **iOS Simulator**: iOS 16.0 이상
- **macOS**: 13.0 이상 (개발 환경)

### 설치 및 실행
```bash
# 프로젝트 클론
git clone [repository-url]
cd WorkoutLog

# Xcode에서 프로젝트 열기
open WorkoutLog.xcodeproj

# 또는 Xcode workspace 사용
open WorkoutLog.xcworkspace
```

### 빌드 설정
1. **Team 설정**: Xcode > Signing & Capabilities에서 개발 팀 선택
2. **Bundle Identifier**: 고유한 번들 ID로 변경
3. **Deployment Target**: iOS 16.0 이상 확인

## 🎨 디자인 시스템

### 앱 아이콘
- **iOS/iPadOS**: 다양한 해상도 지원
- **macOS**: Catalyst 지원 아이콘
- **테마**: 덤벨 모티브의 미니멀 디자인

### UI 컴포넌트
- **필터 칩**: 둥근 모서리의 선택 가능한 칩
- **운동 카드**: 정보가 풍부한 리스트 아이템
- **검색바**: 실시간 검색 지원
- **빈 상태**: 사용자 친화적 빈 화면 디자인

## 📊 데이터 모델

### ExerciseType
```swift
struct ExerciseType {
    let name: String           // 운동명
    let bodyPart: String      // 운동 부위
    let equipment: Equipment  // 사용 기구
    let category: ExerciseCategory?  // 운동 분류
    let difficulty: Difficulty       // 자동 계산된 난이도
}
```

### Session
```swift
class Session: ObservableObject {
    @Published var state: SessionState
    @Published var navPath: NavigationPath
    @Published var exercises: [Exercise]
    @Published var startTime: Date?
}
```

## 🧪 테스트

### 단위 테스트
```bash
# Xcode에서 테스트 실행
⌘ + U

# 터미널에서 테스트 실행
xcodebuild test -project WorkoutLog.xcodeproj -scheme WorkoutLog -destination 'platform=iOS Simulator,name=iPhone 15'
```

### UI 테스트
- **WorkoutLogUITests**: 전체 사용자 플로우 테스트
- **Navigation**: 화면 전환 및 상태 변화 테스트

## 🚧 개발 현황

### ✅ 완료된 기능
- [x] 도메인 아키텍처 구축
- [x] NavigationStack 기반 네비게이션
- [x] 운동 데이터베이스 (40개 이상)
- [x] 운동 검색 및 필터링
- [x] 세션 상태 관리
- [x] 앱 아이콘 및 에셋

### 🔄 개발 중
- [ ] 부위 선택 화면 구현
- [ ] 기구 선택 화면 구현
- [ ] 운동 기록 화면 구현
- [ ] 세트 관리 기능

### 📋 계획된 기능
- [ ] 데이터 지속성 (Core Data)
- [ ] 운동 히스토리
- [ ] 통계 및 분석
- [ ] 사용자 설정
- [ ] 다크모드 지원

## 🤝 기여 가이드

### 브랜치 전략
- `main`: 안정화된 릴리스 브랜치
- `dev`: 개발 통합 브랜치
- `feature/[기능명]`: 기능별 개발 브랜치

### 커밋 컨벤션
```
feat: 새로운 기능 추가
fix: 버그 수정
docs: 문서 수정
style: 코드 포맷팅
refactor: 코드 리팩토링
test: 테스트 추가/수정
```

### 코드 스타일
- **SwiftLint**: 코드 스타일 일관성 유지
- **MARK 주석**: 코드 섹션 구분
- **문서 주석**: public API 문서화 필수

---

**WorkoutLog** - 당신의 운동 여정을 함께합니다 💪
