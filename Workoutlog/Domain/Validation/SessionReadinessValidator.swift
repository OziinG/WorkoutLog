import Foundation

// MARK: - 검증 오류 타입
public enum ValidationError: Error, LocalizedError {
    case invalidWeight(String)
    case invalidReps(String)
    case invalidSupersetCount(String)
    case duplicateExerciseInSuperset(String)
    case sessionExpired(String)
    case insufficientSets(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidWeight(let message),
             .invalidReps(let message),
             .invalidSupersetCount(let message),
             .duplicateExerciseInSuperset(let message),
             .sessionExpired(let message),
             .insufficientSets(let message):
            return message
        }
    }
}

public struct SessionReadinessValidator {
    
    // MARK: - 운동 준비 상태 검증
    
    public static func canCompleteExercise(_ exercise: ExerciseEntry) -> Bool {
        return exercise.sets.count >= 4
    }
    
    public static func canCompleteSuperset(_ superset: SupersetGroup, exercises: [ExerciseEntry]) -> Bool {
        let supersetExercises = exercises.filter { superset.exerciseIds.contains($0.id) }
        
        guard supersetExercises.count == 2 else { return false }
        
        return supersetExercises.allSatisfy { canCompleteExercise($0) }
    }
    
    public static func canProceedToNextExercise(in session: WorkoutSession) -> Bool {
        guard let lastExercise = session.exercises.last else { return false }
        
        if let supersetGroupId = lastExercise.supersetGroupId,
           let superset = session.supersets.first(where: { $0.id == supersetGroupId }) {
            return canCompleteSuperset(superset, exercises: session.exercises)
        }
        
        return canCompleteExercise(lastExercise)
    }
    
    public static func canCompleteSession(_ session: WorkoutSession) -> Bool {
        guard !session.exercises.isEmpty else { return false }
        
        let singleExercises = session.exercises.filter { $0.supersetGroupId == nil }
        let singleExercisesReady = singleExercises.allSatisfy { canCompleteExercise($0) }
        
        let supersetsReady = session.supersets.allSatisfy { superset in
            canCompleteSuperset(superset, exercises: session.exercises)
        }
        
        return singleExercisesReady && supersetsReady
    }
    
    // MARK: - 세트 입력 검증
    
    public static func validateSetRecord(weightKg: Double?, equipment: EquipmentType) throws -> Bool {
        if equipment.requiresPositiveWeight {
            guard let weight = weightKg, weight > 0 else {
                throw ValidationError.invalidWeight("기구 운동에서는 0보다 큰 중량을 입력해야 합니다.")
            }
        }
        return true
    }
    
    public static func validateReps(_ reps: Int) throws -> Bool {
        guard reps > 0 else {
            throw ValidationError.invalidReps("반복수는 1회 이상이어야 합니다.")
        }
        return true
    }
    
    // MARK: - 세션 상태 검증
    
    public static func isSessionExpired(_ session: WorkoutSession) -> Bool {
        let twelveHoursAgo = Date().addingTimeInterval(-12 * 60 * 60)
        return session.lastUpdated < twelveHoursAgo
    }
    
    public static func canRecoverSession(_ session: WorkoutSession) -> Bool {
        return session.status == .active && !isSessionExpired(session)
    }
    
    // MARK: - 슈퍼세트 검증
    
    public static func validateSupersetCreation(exerciseIds: [UUID]) throws -> Bool {
        guard exerciseIds.count == 2 else {
            throw ValidationError.invalidSupersetCount("슈퍼세트는 정확히 2개의 운동으로 구성되어야 합니다.")
        }
        
        guard Set(exerciseIds).count == 2 else {
            throw ValidationError.duplicateExerciseInSuperset("슈퍼세트에 동일한 운동을 중복으로 포함할 수 없습니다.")
        }
        
        return true
    }
    
    // MARK: - 운동 재선택 검증
    
    public static func isConsecutiveExerciseSelection(
        previousExerciseId: UUID?,
        currentExerciseId: UUID,
        exercises: [ExerciseEntry]
    ) -> Bool {
        guard let previousId = previousExerciseId else { return true }
        
        if previousId == currentExerciseId {
            return exercises.last?.id == currentExerciseId
        }
        
        return true
    }
}
