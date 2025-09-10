import Foundation

public enum EquipmentType: Codable, Equatable, Hashable {
    case machine
    case cable
    case barbell
    case dumbbell
    case bodyweight
    case custom(String)
    
    public var requiresPositiveWeight: Bool {
        switch self {
        case .bodyweight:
            return false
        default:
            return true
        }
    }
    
    /// 한글 표시명
    public var displayName: String {
        switch self {
        case .machine: return "머신"
        case .cable: return "케이블"
        case .barbell: return "바벨"
        case .dumbbell: return "덤벨"
        case .bodyweight: return "맨몸"
        case .custom(let name): return name
        }
    }
}
