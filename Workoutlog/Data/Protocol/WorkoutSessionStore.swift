import Foundation

public protocol WorkoutSessionStore: Actor {
    
    // MARK: - CRUD Operations
    func save(_ session: WorkoutSession) async throws
    func load(id: UUID) async throws -> WorkoutSession?
    func loadAll() async throws -> [WorkoutSession]
    func delete(id: UUID) async throws
    func updateSession(_ session: WorkoutSession) async throws
    
    // MARK: - 세션 상태 관리
    func getActiveSession() async throws -> WorkoutSession?
    func getActiveSessions() async throws -> [WorkoutSession]
    func getCompletedSessions() async throws -> [WorkoutSession]
    
    // MARK: - 자동저장 관리
    func enableAutosave(interval: TimeInterval) async
    func disableAutosave() async
    func isAutosaveEnabled() async -> Bool
    
    // MARK: - 만료 관리
    func pruneExpiredSessions() async throws -> [UUID]
    func getExpiredSessions() async throws -> [WorkoutSession]
    func isSessionExpired(id: UUID) async throws -> Bool
    
    // MARK: - 복구 관리
    func getMostRecentActiveSession() async throws -> WorkoutSession?
    func canRecover(sessionId: UUID) async throws -> Bool

    func recoverAllSessions() async throws -> [WorkoutSession]
    
    // MARK: - 통계/유틸리티
    func getTotalSessionCount() async throws -> Int
    func getStorageSize() async throws -> Int64
    func clearAllData() async throws
}
