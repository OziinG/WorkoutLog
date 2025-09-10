import Foundation

public actor InMemorySessionStore: WorkoutSessionStore {
    // MARK: - Private Properties

    private var sessions: [UUID: WorkoutSession] = [:]
    private var autosaveTimer: Timer?
    private var autosaveInterval: TimeInterval = 0
    private var isAutosaveActive = false
    
    private let storageKey = "WorkoutLog.InMemoryStore.Sessions"
    
    // MARK: - Initialization
    
    public init() {
        Task {
            await loadFromPersistence()
        }
    }
    
    // MARK: - CRUD Operations
    
    public func save(_ session: WorkoutSession) async throws {
        sessions[session.id] = session
        await triggerAutosaveIfEnabled()
    }
    
    public func load(id: UUID) async throws -> WorkoutSession? {
        return sessions[id]
    }
    
    public func loadAll() async throws -> [WorkoutSession] {
        return Array(sessions.values)
    }
    
    public func delete(id: UUID) async throws {
        guard sessions[id] != nil else {
            throw StorageError.sessionNotFound(id)
        }
        sessions.removeValue(forKey: id)
        await triggerAutosaveIfEnabled()
    }
    
    public func updateSession(_ session: WorkoutSession) async throws {
        sessions[session.id] = session
        await triggerAutosaveIfEnabled()
    }
    
    // MARK: - 세션 상태 관리
    
    public func getActiveSession() async throws -> WorkoutSession? {
        let activeSessions = sessions.values.filter { $0.status == .active && !$0.isExpired }
        return activeSessions.max { $0.lastUpdated < $1.lastUpdated }
    }
    
    public func getActiveSessions() async throws -> [WorkoutSession] {
        return sessions.values.filter { $0.status == .active && !$0.isExpired }
    }
    
    public func getCompletedSessions() async throws -> [WorkoutSession] {
        return sessions.values.filter { $0.status == .completed }
            .sorted { $0.startTime > $1.startTime }
    }
    
    // MARK: - 자동저장 관리
    
    public func enableAutosave(interval: TimeInterval) async {
        autosaveInterval = interval
        isAutosaveActive = true
        await scheduleAutosave()
    }
    
    public func disableAutosave() async {
        isAutosaveActive = false
        autosaveTimer?.invalidate()
        autosaveTimer = nil
    }
    
    public func isAutosaveEnabled() async -> Bool {
        return isAutosaveActive
    }
    
    // MARK: - 만료 관리
    
    public func pruneExpiredSessions() async throws -> [UUID] {
        let expiredIds = sessions.compactMap { (id, session) in
            session.isExpired ? id : nil
        }
        
        for id in expiredIds {
            sessions.removeValue(forKey: id)
        }
        
        if !expiredIds.isEmpty {
            await triggerAutosaveIfEnabled()
        }
        
        return expiredIds
    }
    
    public func getExpiredSessions() async throws -> [WorkoutSession] {
        return sessions.values.filter { $0.isExpired }
    }
    
    public func isSessionExpired(id: UUID) async throws -> Bool {
        guard let session = sessions[id] else {
            throw StorageError.sessionNotFound(id)
        }
        return session.isExpired
    }
    
    // MARK: - 복구 관리
    
    public func getMostRecentActiveSession() async throws -> WorkoutSession? {
        let activeSessions = try await getActiveSessions()
        return activeSessions.max { $0.lastUpdated < $1.lastUpdated }
    }
    
    public func canRecover(sessionId: UUID) async throws -> Bool {
        guard let session = sessions[sessionId] else {
            return false
        }
        return session.status == .active && !session.isExpired
    }
    
    public func recoverAllSessions() async throws -> [WorkoutSession] {
        await loadFromPersistence()
        return try await getActiveSessions()
    }
    
    // MARK: - 통계/유틸리티
    
    public func getTotalSessionCount() async throws -> Int {
        return sessions.count
    }
    
    public func getStorageSize() async throws -> Int64 {
        do {
            let data = try JSONEncoder().encode(Array(sessions.values))
            return Int64(data.count)
        } catch {
            return 0
        }
    }
    
    public func clearAllData() async throws {
        sessions.removeAll()
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
    
    // MARK: - Private Methods
    
    private func triggerAutosaveIfEnabled() async {
        guard isAutosaveActive else { return }
        await saveToPersistence()
    }
    
    private func scheduleAutosave() async {
        await MainActor.run {
            autosaveTimer?.invalidate()
            autosaveTimer = Timer.scheduledTimer(withTimeInterval: autosaveInterval, repeats: true) { [weak self] _ in
                Task {
                    await self?.saveToPersistence()
                }
            }
        }
    }
    
    private func saveToPersistence() async {
        do {
            let data = try JSONEncoder().encode(Array(sessions.values))
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("자동저장 실패: \(error.localizedDescription)")
        }
    }
    
    private func loadFromPersistence() async {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        
        do {
            let loadedSessions = try JSONDecoder().decode([WorkoutSession].self, from: data)
            sessions = Dictionary(uniqueKeysWithValues: loadedSessions.map { ($0.id, $0) })
        } catch {
            print("데이터 로드 실패: \(error.localizedDescription)")
        }
    }
}
