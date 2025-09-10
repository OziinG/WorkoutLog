import Foundation

public struct ExerciseEntry: Identifiable, Codable, Equatable {
    public let id: UUID
    public let bodyPart: BodyPart
    public let equipment: EquipmentType
    public var name: String
    public var sets: [SetRecord]
    public var supersetGroupId: UUID?
    public var order: Int
    
    public init(id: UUID = UUID(),
                bodyPart: BodyPart,
                equipment: EquipmentType,
                name: String,
                sets: [SetRecord] = [],
                supersetGroupId: UUID? = nil,
                order: Int = 0) {
        self.id = id
        self.bodyPart = bodyPart
        self.equipment = equipment
        self.name = name
        self.sets = sets
        self.supersetGroupId = supersetGroupId
        self.order = order
    }
    
    public mutating func addSet(_ set: SetRecord) {
        sets.append(set)
    }
    
    public var totalSets: Int {
        sets.count
    }
    
    public var isReady: Bool {
        sets.count >= 4
    }
    
    public var isPartOfSuperset: Bool {
        supersetGroupId != nil
    }
}
