import Foundation

@MainActor
class ExerciseDatabase: ObservableObject {
    static let shared = ExerciseDatabase()
    
    @Published private(set) var exercises: [ExerciseType] = []
    
    private init() {
        loadDefaultExercises()
    }
    
    private func loadDefaultExercises() {
        exercises = [
            // 어깨
            ExerciseType(name: "숄더 프레스 머신", bodyPart: "어깨", equipment: .machine, category: .compound),
            ExerciseType(name: "리버스 펙 덱 플라이", bodyPart: "어깨", equipment: .machine, category: .isolation),
            ExerciseType(name: "케이블 사이드 레터럴 레이즈", bodyPart: "어깨", equipment: .cable, category: .isolation),
            ExerciseType(name: "케이블 페이스 풀", bodyPart: "어깨", equipment: .cable, category: .isolation),
            ExerciseType(name: "오버헤드 프레스", bodyPart: "어깨", equipment: .barbell, category: .compound),
            ExerciseType(name: "바벨 슈러그", bodyPart: "어깨", equipment: .barbell, category: .isolation),
            ExerciseType(name: "덤벨 숄더 프레스", bodyPart: "어깨", equipment: .dumbbell, category: .compound),
            ExerciseType(name: "덤벨 사이드 레터럴 레이즈", bodyPart: "어깨", equipment: .dumbbell, category: .isolation),
            
            // 가슴
            ExerciseType(name: "체스트 프레스 머신", bodyPart: "가슴", equipment: .machine, category: .compound),
            ExerciseType(name: "펙 덱 플라이 머신", bodyPart: "가슴", equipment: .machine, category: .isolation),
            ExerciseType(name: "케이블 크로스 오버", bodyPart: "가슴", equipment: .cable, category: .isolation),
            ExerciseType(name: "벤치 프레스", bodyPart: "가슴", equipment: .barbell, category: .compound),
            ExerciseType(name: "인클라인 벤치 프레스", bodyPart: "가슴", equipment: .barbell, category: .compound),
            ExerciseType(name: "덤벨 프레스", bodyPart: "가슴", equipment: .dumbbell, category: .compound),
            ExerciseType(name: "덤벨 플라이", bodyPart: "가슴", equipment: .dumbbell, category: .isolation),
            ExerciseType(name: "푸시업", bodyPart: "가슴", equipment: .bodyweight, category: .compound),
            
            // 등
            ExerciseType(name: "랫 풀 다운", bodyPart: "등", equipment: .machine, category: .compound),
            ExerciseType(name: "시티드 로우 머신", bodyPart: "등", equipment: .machine, category: .compound),
            ExerciseType(name: "케이블 로우", bodyPart: "등", equipment: .cable, category: .compound),
            ExerciseType(name: "바벨 로우", bodyPart: "등", equipment: .barbell, category: .compound),
            ExerciseType(name: "데드리프트", bodyPart: "등", equipment: .barbell, category: .compound),
            ExerciseType(name: "덤벨 로우", bodyPart: "등", equipment: .dumbbell, category: .compound),
            ExerciseType(name: "풀업", bodyPart: "등", equipment: .bodyweight, category: .compound),
            
            // 하체
            ExerciseType(name: "레그 프레스", bodyPart: "하체", equipment: .machine, category: .compound),
            ExerciseType(name: "레그 익스텐션", bodyPart: "하체", equipment: .machine, category: .isolation),
            ExerciseType(name: "레그 컬", bodyPart: "하체", equipment: .machine, category: .isolation),
            ExerciseType(name: "백 스쿼트", bodyPart: "하체", equipment: .barbell, category: .compound),
            ExerciseType(name: "루마니안 데드리프트", bodyPart: "하체", equipment: .barbell, category: .compound),
            ExerciseType(name: "덤벨 스쿼트", bodyPart: "하체", equipment: .dumbbell, category: .compound),
            ExerciseType(name: "덤벨 런지", bodyPart: "하체", equipment: .dumbbell, category: .compound),
            ExerciseType(name: "에어 스쿼트", bodyPart: "하체", equipment: .bodyweight, category: .compound),
            
            // 팔
            ExerciseType(name: "바이셉 컬 머신", bodyPart: "팔", equipment: .machine, category: .isolation),
            ExerciseType(name: "트라이셉 딥스 머신", bodyPart: "팔", equipment: .machine, category: .isolation),
            ExerciseType(name: "케이블 바이셉 컬", bodyPart: "팔", equipment: .cable, category: .isolation),
            ExerciseType(name: "케이블 트라이셉 푸시다운", bodyPart: "팔", equipment: .cable, category: .isolation),
            ExerciseType(name: "바벨 컬", bodyPart: "팔", equipment: .barbell, category: .isolation),
            ExerciseType(name: "덤벨 바이셉 컬", bodyPart: "팔", equipment: .dumbbell, category: .isolation),
            ExerciseType(name: "덤벨 트라이셉 익스텐션", bodyPart: "팔", equipment: .dumbbell, category: .isolation),
            ExerciseType(name: "딥스", bodyPart: "팔", equipment: .bodyweight, category: .compound)
        ]
    }
    
    // MARK: - Query Methods
    
    func getExercises(for bodyPart: String) -> [ExerciseType] {
        exercises.filter { $0.bodyPart == bodyPart }
    }
    
    func getExercises(for equipment: Equipment) -> [ExerciseType] {
        exercises.filter { $0.equipment == equipment }
    }
    
    func getExercises(for bodyPart: String, equipment: Equipment) -> [ExerciseType] {
        exercises.filter { $0.bodyPart == bodyPart && $0.equipment == equipment }
    }
    
    func getExercises(for category: ExerciseCategory) -> [ExerciseType] {
        exercises.filter { $0.category == category }
    }
    
    func searchExercises(query: String) -> [ExerciseType] {
        guard !query.isEmpty else { return exercises }
        return exercises.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
    
    var allBodyParts: [String] {
        Array(Set(exercises.map { $0.bodyPart })).sorted()
    }
    
    var allEquipment: [Equipment] {
        Equipment.allCases
    }
    
    // MARK: - Management Methods
    
    func addCustomExercise(_ exercise: ExerciseType) {
        exercises.append(exercise)
    }
    
    func removeExercise(_ exercise: ExerciseType) {
        exercises.removeAll { $0.id == exercise.id }
    }
}