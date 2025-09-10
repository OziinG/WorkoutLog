import Foundation

public struct SetRecord: Identifiable, Codable, Equatable {
    public let id: UUID
    public let weightKg: Double?
    public let reps: Int
    public let isWarmUp: Bool
    public let isFailure: Bool
    public let restSecondsBeforeNext: Int?
    public let timestamp: Date
    
    public init(id: UUID = UUID(),
                weightKg: Double?,
                reps: Int,
                isWarmUp: Bool = false,
                isFailure: Bool = false,
                restSecondsBeforeNext: Int? = nil,
                timestamp: Date = Date(),
                equipment: EquipmentType) throws {
        
        if equipment.requiresPositiveWeight {
            guard let weight = weightKg, weight > 0 else {
                throw SetRecordError.invalidWeight("중량이 필요한 운동에서는 0보다 큰 중량을 입력해야 합니다")
            }
        }
        
        guard reps > 0 else {
            throw SetRecordError.invalidReps("반복수는 1회 이상이어야 합니다")
        }
        
        self.id = id
        self.weightKg = weightKg
        self.reps = reps
        self.isWarmUp = isWarmUp
        self.isFailure = isFailure
        self.restSecondsBeforeNext = restSecondsBeforeNext
        self.timestamp = timestamp
    }
    
    public init(id: UUID = UUID(),
                weightKg: Double?,
                reps: Int,
                isWarmUp: Bool = false,
                isFailure: Bool = false,
                restSecondsBeforeNext: Int? = nil,
                timestamp: Date = Date()) {
        self.id = id
        self.weightKg = weightKg
        self.reps = reps
        self.isWarmUp = isWarmUp
        self.isFailure = isFailure
        self.restSecondsBeforeNext = restSecondsBeforeNext
        self.timestamp = timestamp
    }
}

// MARK: - SetRecord Errors
public enum SetRecordError: Error, LocalizedError {
    case invalidWeight(String)
    case invalidReps(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidWeight(let message):
            return message
        case .invalidReps(let message):
            return message
        }
    }
}
