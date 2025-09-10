//
//  SessionManager.swift
//  Workoutlog
//
//  Created by GitHub Copilot on 9/10/25.
//

import Foundation
import SwiftUI

// MARK: - Session Error Types

enum SessionError: LocalizedError {
    case noActiveSession
    case recoveryFailed(String)
    case saveFailure(String)
    case validationFailed([String])
    case sessionExpired
    case storeNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .noActiveSession:
            return "현재 진행 중인 운동 세션이 없습니다."
        case .recoveryFailed(let reason):
            return "세션 복구에 실패했습니다: \(reason)"
        case .saveFailure(let reason):
            return "세션 저장에 실패했습니다: \(reason)"
        case .validationFailed(let errors):
            return "검증 실패: \(errors.joined(separator: ", "))"
        case .sessionExpired:
            return "세션이 만료되었습니다 (12시간 경과)."
        case .storeNotAvailable:
            return "저장소에 접근할 수 없습니다."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noActiveSession:
            return "새로운 운동 세션을 시작해주세요."
        case .recoveryFailed:
            return "새 세션을 시작하거나 앱을 재시작해보세요."
        case .saveFailure:
            return "저장 공간을 확인하고 다시 시도해주세요."
        case .validationFailed:
            return "입력값을 확인하고 다시 시도해주세요."
        case .sessionExpired:
            return "새로운 운동 세션을 시작해주세요."
        case .storeNotAvailable:
            return "앱을 재시작해주세요."
        }
    }
}

// MARK: - Session Manager

@MainActor
public class SessionManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var currentSession: WorkoutSession?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: SessionError?
    @Published private(set) var canCompleteSession: Bool = false
    @Published private(set) var hasRecoverableSession: Bool = false
    @Published private(set) var isAutosaveEnabled: Bool = false
    
    // MARK: - Private Properties
    
    private let store: WorkoutSessionStore
    private var autosaveTask: Task<Void, Never>?
    private let autosaveInterval: TimeInterval = 30.0
    
    // MARK: - Initialization
    
    public init(store: WorkoutSessionStore) {
        self.store = store
        
        Task {
            await performInitialSetup()
        }
    }
    
    deinit {
        autosaveTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    public func startNewSession() async {
        await withErrorHandling {
            isLoading = true
            
            await stopAutosave()
            
            let newSession = WorkoutSession()
            try await store.save(newSession)
            
            currentSession = newSession
            hasRecoverableSession = false
            
            await startAutosave()
            updateSessionReadiness()
            
            isLoading = false
        }
    }
    
    @discardableResult
    public func resumeSession(id sessionId: UUID) async -> Bool {
        return await withErrorHandling {
            isLoading = true
            
            guard let session = try await store.load(id: sessionId) else {
                throw SessionError.recoveryFailed("세션을 찾을 수 없습니다.")
            }
            
            guard session.status == .active else {
                throw SessionError.recoveryFailed("활성 상태가 아닌 세션은 복구할 수 없습니다.")
            }
            
            guard !session.isExpired else {
                throw SessionError.sessionExpired
            }
            
            await stopAutosave()
            
            currentSession = session
            hasRecoverableSession = false
            
            await startAutosave()
            updateSessionReadiness()
            
            isLoading = false
            return true
        } ?? false
    }
    
    @discardableResult
    public func completeCurrentSession() async -> String? {
        return await withErrorHandling {
            guard var session = currentSession else {
                throw SessionError.noActiveSession
            }
            
            guard canCompleteSession else {
                throw SessionError.validationFailed(["모든 운동을 4세트 이상 완료해야 합니다."])
            }
            
            isLoading = true
            
            session.complete()
            try await store.updateSession(session)
            
            let logString = LogFormatter.formatSession(session)
            
            currentSession = nil
            canCompleteSession = false
            hasRecoverableSession = false
            
            await stopAutosave()
            
            isLoading = false
            return logString
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func performInitialSetup() async {
        await withErrorHandling {
            let mostRecentSession = try await store.getMostRecentActiveSession()
            hasRecoverableSession = (mostRecentSession != nil)
            
            await clearExpiredSessions()
        }
    }
    
    @discardableResult
    private func withErrorHandling<T>(_ operation: () async throws -> T) async -> T? {
        do {
            error = nil
            return try await operation()
        } catch let sessionError as SessionError {
            error = sessionError
            isLoading = false
            return nil
        } catch {
            self.error = .saveFailure(error.localizedDescription)
            isLoading = false
            return nil
        }
    }
    
    private func updateSessionReadiness() {
        guard let session = currentSession else {
            canCompleteSession = false
            return
        }
        
        let singleExercises = session.exercises.filter { $0.supersetGroupId == nil }
        let singleExercisesReady = singleExercises.allSatisfy { $0.isReady }
        
        let supersetsReady = session.supersets.allSatisfy { superset in
            superset.isReady(exercises: session.exercises)
        }
        
        canCompleteSession = (singleExercises.isEmpty || singleExercisesReady) &&
                            (session.supersets.isEmpty || supersetsReady) &&
                            !session.exercises.isEmpty
    }
    
    private func startAutosave() async {
        guard autosaveTask == nil else { return }
        
        isAutosaveEnabled = true
        await store.enableAutosave(interval: autosaveInterval)
        
        autosaveTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(self?.autosaveInterval ?? 30.0) * 1_000_000_000)
                
                guard !Task.isCancelled else { break }
                
                await self?.saveCurrentSessionIfNeeded()
            }
        }
    }
    
    private func stopAutosave() async {
        autosaveTask?.cancel()
        autosaveTask = nil
        isAutosaveEnabled = false
        await store.disableAutosave()
    }
    
    private func saveCurrentSessionIfNeeded() async {
        guard let session = currentSession else { return }
        
        do {
            try await store.save(session)
        } catch {
            await MainActor.run {
                self.error = .saveFailure("자동저장 실패: \(error.localizedDescription)")
            }
        }
    }
    
    private func clearExpiredSessions() async {
        do {
            let prunedIds = try await store.pruneExpiredSessions()
            if !prunedIds.isEmpty {
                print("정리된 만료 세션 수: \(prunedIds.count)")
            }
        } catch {
            print("만료 세션 정리 실패: \(error.localizedDescription)")
        }
    }
}

// MARK: - Phase 2 & 3 Extensions

extension SessionManager {
    
    func addExercise(_ exercise: ExerciseEntry) {
        // TODO: Phase 2에서 구현
        fatalError("Not implemented yet - Phase 2")
    }
    
    func addSuperset(_ superset: SupersetGroup) {
        // TODO: Phase 2에서 구현
        fatalError("Not implemented yet - Phase 2")
    }
    
    func addSetToCurrentExercise(exerciseId: UUID, set: SetRecord) {
        // TODO: Phase 2에서 구현
        fatalError("Not implemented yet - Phase 2")
    }
    
    func attemptRecovery() async -> Bool {
        // TODO: Phase 3에서 구현
        fatalError("Not implemented yet - Phase 3")
    }
}
