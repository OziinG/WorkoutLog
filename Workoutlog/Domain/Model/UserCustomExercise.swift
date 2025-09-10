import Foundation

/// 사용자 지정 운동 도메인 모델
public struct UserCustomExercise: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var bodyPart: BodyPart
    public var equipment: EquipmentType
    public var createdAt: Date
    
    public init(id: UUID = UUID(),
                name: String,
                bodyPart: BodyPart,
                equipment: EquipmentType,
                createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.bodyPart = bodyPart
        self.equipment = equipment
        self.createdAt = createdAt
    }
}
