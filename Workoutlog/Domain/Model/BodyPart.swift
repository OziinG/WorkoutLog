import Foundation

public enum BodyPart: String, CaseIterable, Codable, Equatable {
    case shoulder
    case back
    case chest
    case legs
    case abs
    case arms
    case custom
    
    public var displayName: String {
        switch self {
        case .shoulder: return "어깨"
        case .back: return "등"
        case .chest: return "가슴"
        case .legs: return "하체"
        case .abs: return "복근"
        case .arms: return "팔"
        case .custom: return "사용자 지정"
        }
    }
}
