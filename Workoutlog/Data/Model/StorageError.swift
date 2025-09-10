import Foundation

/// 저장소 관련 에러 타입
public enum StorageError: Error, LocalizedError {
    case sessionNotFound(UUID)
    case saveFailure(String)
    case loadFailure(String)
    case corruptedData(String)
    case diskSpaceInsufficient
    case sessionExpired(UUID)
    case invalidSessionData(String)
    case autosaveFailure(String)
    
    public var errorDescription: String? {
        switch self {
        case .sessionNotFound(let id):
            return "세션을 찾을 수 없습니다: \(id.uuidString)"
        case .saveFailure(let message):
            return "저장 실패: \(message)"
        case .loadFailure(let message):
            return "로드 실패: \(message)"
        case .corruptedData(let message):
            return "데이터 손상: \(message)"
        case .diskSpaceInsufficient:
            return "디스크 공간이 부족합니다"
        case .sessionExpired(let id):
            return "세션이 만료되었습니다: \(id.uuidString)"
        case .invalidSessionData(let message):
            return "잘못된 세션 데이터: \(message)"
        case .autosaveFailure(let message):
            return "자동저장 실패: \(message)"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .sessionNotFound:
            return "새로운 세션을 시작하세요."
        case .saveFailure, .autosaveFailure:
            return "저장 공간을 확인하고 다시 시도하세요."
        case .loadFailure, .corruptedData:
            return "앱을 재시작하거나 데이터를 초기화하세요."
        case .diskSpaceInsufficient:
            return "디스크 공간을 확보한 후 다시 시도하세요."
        case .sessionExpired:
            return "새로운 세션을 시작하세요."
        case .invalidSessionData:
            return "데이터를 확인하고 올바른 형식으로 입력하세요."
        }
    }
}