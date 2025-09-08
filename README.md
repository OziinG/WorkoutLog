# WorkoutLog 개발 문서 (v0.1)

## 1. 목표
- 단일/슈퍼세트 기반 웨이트 세션 기록, 최소 세트 기준(4) 유효성, 자동 저장·복구, 12시간 만료.
- 오프라인 중심(로컬 우선), 문자열 로그 생성. 확장: 구조화 통계.

## 2. 지원 환경
- iOS 18 (최신) / 최소 타겟 제안: iOS 17.
- Swift 5.10+, SwiftUI + Concurrency.
- 저장: 초기 JSON(Local File) + SwiftData/ CoreData 전환 가능 구조.

## 3. 모듈 / 폴더 구조 (제안)
```
Workoutlog/
  App/
    WorkoutlogApp.swift
    AppRouter.swift
  Core/
    Model/
      WorkoutSession.swift
      ExerciseEntry.swift
      SupersetGroup.swift
      SetRecord.swift
    Persistence/
      StorageService.swift
      SessionRepository.swift
    Services/
      AutosaveService.swift
      ExpireService.swift
      RecoveryService.swift
      IDGenerator.swift
    Logging/
      LogFormatter.swift
  Features/
    Main/
      MainView.swift
      MainViewModel.swift
    Selection/
      BodyPartSelectionView.swift
      EquipmentSelectionView.swift
      ExerciseSelectionView.swift
    Logging/
      SetLoggingView.swift
      SupersetSwitchBar.swift
      RestInputSheet.swift
    Summary/
      SummaryView.swift
      SummaryViewModel.swift
    Components/
      PrimaryButton.swift
      Badge.swift
  DesignSystem/
    Colors.swift
    Typography.swift
    Spacing.swift
  Tests/
    SessionRepositoryTests.swift
    AutosaveTests.swift
```

## 4. 데이터 모델 (Value Type 우선)
```
struct WorkoutSession: Identifiable, Codable {
  enum Status: String, Codable { case active, completed }
  let id: UUID
  var startTime: Date
  var endTime: Date?
  var status: Status
  var exercises: [ExerciseEntry]          // order 포함
  var supersets: [SupersetGroup]
  var lastUpdated: Date
}

struct ExerciseEntry: Identifiable, Codable {
  let id: UUID
  var bodyPart: String
  var equipment: Equipment
  var name: String
  var sets: [SetRecord]
  var supersetGroupId: UUID?              // nil = 단일
  var order: Int
}

enum Equipment: Codable { case machine, cable(lines:Int), barbell, dumbbell, bodyweight, custom(String) }

struct SupersetGroup: Identifiable, Codable {
  let id: UUID
  var exerciseIds: [UUID]                 // length 2
  var order: Int
  var isCompleted: Bool
}

struct SetRecord: Identifiable, Codable {
  let id: UUID
  var weightKg: Double?                   // bodyweight -> nil / 0
  var reps: Int
  var isWarmUp: Bool
  var isFailure: Bool
  var restSecondsBeforeNext: Int?
  var timestamp: Date
}
```

## 5. 상태/규칙 요약
- 버튼 활성: 단일(세트 ≥4), 슈퍼세트(각 운동 ≥4).
- 동일 운동 비연속 선택 → 팝업(이어쓰기 / 새로).
- 자동저장: 세트 CRUD, 휴식 입력, 재정렬 직후.
- 만료: lastUpdated +12h → 폐기.
- 복구: 가장 최근 active 1개. 실패 시 새 세션.
- 케이블 1/2줄 구분 → Equipment.cable(lines:1|2) 기록.
- 슈퍼세트: Page2 토글 → (A,B) 선택 → 라디오 전환 + 자동 번갈림 옵션.

## 6. 네비게이션 전략 (SwiftUI)
- AppRouter: Observable NavigationPath(or enum RouterState) + @EnvironmentObject.
- 주요 화면 순서: Main -> BodyPart -> (Equipment -> Exercise)* -> Logging -> Summary.
- 슈퍼세트 시: (A선택) -> (B선택) 후 Logging 진입.
- DeepLink / 복구: App start 시 RecoveryService -> active 세션 있으면 LoggingView push.

## 7. 세션 관리 흐름
1. MainView appear → RecoveryService.queryActive() → 존재 시 "이어서" 버튼.
2. New Session 시작 시 Repository.startSession().
3. Logging 단계: ViewModel 내부 actor 보장 (SessionActor) → mutation.
4. AutosaveService.debounce(0.4s) 파일 write.
5. 백그라운드 진입 scenePhase change → force flush.
6. 만료 체크 ExpireService.schedule(background task) or launch-time prune.

## 8. 동시성 / Actor 설계
```
actor SessionActor {
  private var session: WorkoutSession
  func apply(_ mutation: (inout WorkoutSession) -> Void) -> WorkoutSession
  func current() -> WorkoutSession
}
```
- ViewModel 은 SessionActor 에서 snapshot 받아 @Published 렌더링.
- Autosave 는 actor 호출 후 최신 스냅샷.

## 9. 저장소
- 초기: FileManager.documentDirectory /Sessions/active.json (싱글 active) + completed/*.json.
- SessionRepository
  - loadActive(), saveActive(_), deleteActive()
  - saveCompleted(log:String, session:WorkoutSession)
- 후속: SwiftData / CloudKit layer 추가 시 Repository 프로토콜 추상화.

## 10. 로그 포맷 (예)
```
2025-09-08 07:36~08:12
1) 숄더프레스 (머신)
  W 20x10
  30x10
  35x8(F)
[S1] 숄더프레스(머신) ^ 랫풀다운(케이블2)
  A 30x10(W)
  B 40x10
  A 35x8(F) (Rest 90s)
```

## 11. ViewModel 핵심 (의사코드)
```
final class LoggingViewModel: ObservableObject {
  @Published var uiSession: WorkoutSession
  @Published var currentExerciseId: UUID
  @Published var autosaveState: AutosaveState
  private let sessionActor: SessionActor
  private let repo: SessionRepository
  private let autosave: AutosaveService

  func addSet(weight:Double?, reps:Int, warm:Bool, fail:Bool) { ... }
  func recordRest(seconds:Int) { ... }
  func canFinish() -> Bool { ... }
  func finishSession() { ... }
}
```

## 12. Autosave 전략
- addSet / modify / reorder → markDirty → debounce write (DispatchQueue.main.asyncAfter / Task sleep).
- App background / terminate 시 immediate flush.
- 파일 버전 필드 추가(마이그레이션 대비): `{ "version":1, ... }`.

## 13. 에러 처리
| 상황 | 대응 |
|------|------|
| 파일 쓰기 실패 | 재시도 3회 + 사용자 경고(배너) |
| JSON Decode 오류(복구) | active.json 이동 -> corrupted/ + 새 세션 |
| 만료 세션 | active.json 삭제 |

## 14. 테스트 (우선)
- SessionRepositoryTests: create/save/load roundtrip.
- AutosaveTests: debounce 후 파일 생성 확인.
- Finish 조건 테스트:
  - 단일: 3세트 false / 4세트 true.
  - 슈퍼세트: (4,3) false / (4,4) true.

## 15. 접근성/현지화
- Text 최소 Dynamic Type Large 대응, SF Symbols 사용.
- LocalizedStringKey 확장 (후속).

## 16. Git 전략
- main(배포), develop(통합), feature/*, hotfix/*.
- Conventional Commits: feat:, fix:, refactor:, chore:, docs:, test:.

## 17. 빌드 설정 체크리스트
- App Group 필요 없음(초기). iCloud 비활성.
- Background Modes(선택): Background fetch(만료 prune 필요 시). 현재 생략.
- App Icon: 제공된 에셋 적용(AppIcon.appiconset 교체).

## 18. 성능/메모리
- 세트 수 적음 → 메모리 우려 낮음.
- 큰 세션(>200 sets) 대비: 뷰 diff 최소화를 위해 Exercise 단위 LazyVStack + id 안정.

## 19. 보안/프라이버시
- 퍼스널 데이터 없음(날짜/운동만). 민감 아님 → AppTrackingTransparency 불필요.

## 20. 향후 확장 로드맵
- 구조화 로그(JSON v2) & 통계(총 볼륨, PR 탐지)
- HealthKit 연동(워밍업/칼로리 추정)
- CloudKit 동기화
- 운동 템플릿(프로그래밍 루틴) 및 즐겨찾기
- 위젯: 오늘 세션 진행도

## 21. 시작 순서(실행 플랜)
1) 모델 + Repository + Actor 초안.
2) MainView & Recovery.
3) Selection 플로우 (단일 → 슈퍼세트 토글).
4) LoggingView (세트 CRUD + 슈퍼세트 전환 + 휴식 입력).
5) SummaryView (CRUD + 재정렬 + 로그 저장).
6) Autosave/만료/복구 통합 테스트.
7) UI Polish & 접근성.

## 22. 간단 UI 상태 다이어그램 키워드
- Idle(Main) → Selecting → Logging(active) ↔ Autosave(pending) → Finishing → Summary → Completed(Main)

---
문서 종료.
