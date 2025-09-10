import Foundation

public struct WorkoutSession: Identifiable, Codable, Equatable {
    public let id: UUID
    public let startTime: Date
    public var endTime: Date?
    public var status: SessionStatus
    public var exercises: [ExerciseEntry]
    public var supersets: [SupersetGroup]
    public var lastUpdated: Date
    
    public init(id: UUID = UUID(),
                startTime: Date = Date(),
                endTime: Date? = nil,
                status: SessionStatus = .active,
                exercises: [ExerciseEntry] = [],
                supersets: [SupersetGroup] = [],
                lastUpdated: Date = Date()) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.status = status
        self.exercises = exercises
        self.supersets = supersets
        self.lastUpdated = lastUpdated
    }
    
    public mutating func addExercise(_ exercise: ExerciseEntry) {
        exercises.append(exercise)
        updateLastUpdated()
    }
    
    public mutating func addSetToExercise(exerciseId: UUID, set: SetRecord) {
        if let index = exercises.firstIndex(where: { $0.id == exerciseId }) {
            exercises[index].addSet(set)
            updateLastUpdated()
        }
    }
    
    public mutating func addSuperset(_ superset: SupersetGroup) {
        supersets.append(superset)
        updateLastUpdated()
    }
    
    public mutating func complete() {
        status = .completed
        endTime = Date()
        updateLastUpdated()
    }
    
    public var activeSuperset: SupersetGroup? {
        return supersets.first { !$0.isCompleted && $0.isReady(exercises: exercises) == false }
    }
    
    public var durationInMinutes: Int? {
        guard let end = endTime else { return nil }
        return Int(end.timeIntervalSince(startTime) / 60)
    }
    
    public var isExpired: Bool {
        let twelveHoursAgo = Date().addingTimeInterval(-12 * 60 * 60)
        return lastUpdated < twelveHoursAgo
    }
    
    public var totalSets: Int {
        exercises.reduce(0) { $0 + $1.totalSets }
    }
    
    private mutating func updateLastUpdated() {
        lastUpdated = Date()
    }
}

// MARK: - SessionStatus
public enum SessionStatus: String, Codable, CaseIterable {
    case active     // 진행 중
    case completed  // 완료됨
    case expired    // 만료됨
    
    public var displayName: String {
        switch self {
        case .active: return "진행 중"
        case .completed: return "완료됨"
        case .expired: return "만료됨"
        }
    }
}
