import Foundation

struct ExerciseType: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let bodyPart: String
    let equipment: Equipment
    let category: ExerciseCategory?
    let instructions: String?
    
    private enum CodingKeys: String, CodingKey {
        case name, bodyPart, equipment, category, instructions
    }
    
    init(name: String, bodyPart: String, equipment: Equipment, category: ExerciseCategory? = nil, instructions: String? = nil) {
        self.id = UUID()
        self.name = name
        self.bodyPart = bodyPart
        self.equipment = equipment
        self.category = category
        self.instructions = instructions
    }
    
    // Decodable 구현
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID() // 항상 새 UUID 생성
        self.name = try container.decode(String.self, forKey: .name)
        self.bodyPart = try container.decode(String.self, forKey: .bodyPart)
        self.equipment = try container.decode(Equipment.self, forKey: .equipment)
        self.category = try container.decodeIfPresent(ExerciseCategory.self, forKey: .category)
        self.instructions = try container.decodeIfPresent(String.self, forKey: .instructions)
    }
    
    // 자동으로 난이도 계산
    var difficulty: Difficulty {
        switch (equipment, category) {
        case (.bodyweight, .compound): return .intermediate
        case (.bodyweight, _): return .beginner
        case (.barbell, .compound): return .advanced
        case (.dumbbell, .compound): return .intermediate
        case (.machine, _): return .beginner
        default: return .intermediate
        }
    }
    
    // 자동으로 세부 근육군 제공
    var muscleGroups: [String] {
        switch bodyPart {
        case "가슴":
            return equipment == .barbell || equipment == .dumbbell ?
                   ["상부 가슴", "중부 가슴", "하부 가슴"] : ["가슴 전체"]
        case "등":
            return ["광배근", "승모근", "능형근", "기립근"]
        case "어깨":
            return ["전면 삼각근", "중간 삼각근", "후면 삼각근"]
        case "팔":
            return category == .isolation ? ["이두근", "삼두근"] : ["팔 전체"]
        case "하체":
            return ["대퇴사두근", "햄스트링", "둔근", "종아리"]
        case "코어":
            return ["복직근", "복사근", "척추기립근"]
        default:
            return [bodyPart]
        }
    }
    
    // 자동으로 권장 세트/반복 수 제안
    var recommendedSets: ClosedRange<Int> {
        switch category {
        case .compound: return 3...5
        case .isolation: return 2...4
        case .cardio: return 1...3
        default: return 3...4
        }
    }
    
    var recommendedReps: ClosedRange<Int> {
        switch (category, difficulty) {
        case (.compound, .advanced): return 3...6
        case (.compound, _): return 6...10
        case (.isolation, _): return 8...15
        case (.cardio, _): return 15...25
        default: return 8...12
        }
    }
}

enum Equipment: String, CaseIterable, Codable {
    case machine = "머신"
    case cable = "케이블"
    case barbell = "바벨"
    case dumbbell = "덤벨"
    case bodyweight = "맨몸"
}

enum ExerciseCategory: String, CaseIterable, Codable {
    case compound = "복합"
    case isolation = "고립"
    case cardio = "유산소"
    case stretch = "스트레칭"
}

enum Difficulty: String, CaseIterable, Codable {
    case beginner = "초급"
    case intermediate = "중급"
    case advanced = "고급"
}

struct Exercise: Identifiable, Codable {
    let id: UUID
    let name: String
    var sets: [WorkoutSet]
    let exerciseType: ExerciseType
    let datePerformed: Date
    
    private enum CodingKeys: String, CodingKey {
        case name, sets, exerciseType, datePerformed
    }
    
    init(exerciseType: ExerciseType, sets: [WorkoutSet] = [], datePerformed: Date = Date()) {
        self.id = UUID()
        self.name = exerciseType.name
        self.exerciseType = exerciseType
        self.sets = sets
        self.datePerformed = datePerformed
    }
    
    // Decodable 구현
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID() // 항상 새 UUID 생성
        self.name = try container.decode(String.self, forKey: .name)
        self.sets = try container.decode([WorkoutSet].self, forKey: .sets)
        self.exerciseType = try container.decode(ExerciseType.self, forKey: .exerciseType)
        self.datePerformed = try container.decode(Date.self, forKey: .datePerformed)
    }
}

struct WorkoutSet: Identifiable, Codable {
    let id: UUID
    let weight: Double
    let reps: Int
    let restTime: TimeInterval
    let completedAt: Date
    
    private enum CodingKeys: String, CodingKey {
        case weight, reps, restTime, completedAt
    }
    
    init(weight: Double, reps: Int, restTime: TimeInterval = 60, completedAt: Date = Date()) {
        self.id = UUID()
        self.weight = weight
        self.reps = reps
        self.restTime = restTime
        self.completedAt = completedAt
    }
    
    // Decodable 구현
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID() // 항상 새 UUID 생성
        self.weight = try container.decode(Double.self, forKey: .weight)
        self.reps = try container.decode(Int.self, forKey: .reps)
        self.restTime = try container.decode(TimeInterval.self, forKey: .restTime)
        self.completedAt = try container.decode(Date.self, forKey: .completedAt)
    }
}
