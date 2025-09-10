import Foundation

public struct SupersetGroup: Identifiable, Codable, Equatable {
    public let id: UUID
    public let exerciseIds: [UUID]
    public var order: Int
    public var isCompleted: Bool
    
    public init(id: UUID = UUID(),
                exerciseIds: [UUID],
                order: Int = 0,
                isCompleted: Bool = false) {
        precondition(exerciseIds.count == 2, "슈퍼세트는 정확히 2개 운동을 포함해야 합니다")
        self.id = id
        self.exerciseIds = exerciseIds
        self.order = order
        self.isCompleted = isCompleted
    }
    
    public func isReady(exercises: [ExerciseEntry]) -> Bool {
        let supersetExercises = exercises.filter { exerciseIds.contains($0.id) }
        guard supersetExercises.count == 2 else { return false }
        return supersetExercises.allSatisfy { $0.sets.count >= 4 }
    }
    
    /// 첫 번째 운동 ID
    public var firstExerciseId: UUID {
        exerciseIds[0]
    }
    
    /// 두 번째 운동 ID
    public var secondExerciseId: UUID {
        exerciseIds[1]
    }
}
