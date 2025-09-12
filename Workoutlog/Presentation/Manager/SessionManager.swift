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
    
    // MARK: - Exercise Management
    
    public func addExercise(_ exercise: ExerciseEntry) {
        guard var session = currentSession else {
            error = .noActiveSession
            return
        }
        
        session.addExercise(exercise)
        currentSession = session
        
        updateSessionReadiness()
        
        Task {
            await saveCurrentSessionIfNeeded()
        }
    }
    
    public func addSuperset(_ superset: SupersetGroup) {
        guard var session = currentSession else {
            error = .noActiveSession
            return
        }
        
        session.addSuperset(superset)
        currentSession = session
        
        updateSessionReadiness()
        
        Task {
            await saveCurrentSessionIfNeeded()
        }
    }
    
    // MARK: - Set Management
    
    public func addSetToCurrentExercise(exerciseId: UUID, set: SetRecord) {
        guard var session = currentSession else {
            error = .noActiveSession
            return
        }
        
        do {
            _ = try SessionReadinessValidator.validateSetRecord(
                weightKg: set.weightKg,
                equipment: getExerciseEquipment(exerciseId: exerciseId)
            )
            
            _ = try SessionReadinessValidator.validateReps(set.reps)
            
            session.addSetToExercise(exerciseId: exerciseId, set: set)
            currentSession = session
            
            updateSessionReadiness()
            
            Task {
                await saveCurrentSessionIfNeeded()
            }
            
        } catch {
            self.error = .validationFailed([error.localizedDescription])
        }
    }
    
    // MARK: - Exercise Query Methods
    
    public func getCurrentExercises() -> [ExerciseEntry] {
        return currentSession?.exercises ?? []
    }
    
    public func getCurrentSupersets() -> [SupersetGroup] {
        return currentSession?.supersets ?? []
    }
    
    public func getExercise(by id: UUID) -> ExerciseEntry? {
        return currentSession?.exercises.first { $0.id == id }
    }
    
    public func isExerciseInSuperset(_ exerciseId: UUID) -> Bool {
        return currentSession?.supersets.contains { $0.exerciseIds.contains(exerciseId) } ?? false
    }
    
    public func getSuperset(containing exerciseId: UUID) -> SupersetGroup? {
        return currentSession?.supersets.first { $0.exerciseIds.contains(exerciseId) }
    }
    
    // MARK: - Set Query Methods
    
    public func getSets(for exerciseId: UUID) -> [SetRecord] {
        return getExercise(by: exerciseId)?.sets ?? []
    }
    
    public func getSetCount(for exerciseId: UUID) -> Int {
        return getSets(for: exerciseId).count
    }
    
    public func canAddSetToExercise(_ exerciseId: UUID) -> Bool {
        guard let exercise = getExercise(by: exerciseId) else { return false }
        
        if let superset = getSuperset(containing: exerciseId) {
            return superset.isReady(exercises: getCurrentExercises()) == false
        } else {
            return exercise.isReady == false || exercise.sets.count < 8
        }
    }
    
    public func isExerciseReady(_ exerciseId: UUID) -> Bool {
        return getExercise(by: exerciseId)?.isReady ?? false
    }
    
    public func isSupersetReady(_ supersetId: UUID) -> Bool {
        guard let superset = getCurrentSupersets().first(where: { $0.id == supersetId }) else {
            return false
        }
        return superset.isReady(exercises: getCurrentExercises())
    }
    
    // MARK: - Session Statistics
    
    public func getTotalSets() -> Int {
        return currentSession?.totalSets ?? 0
    }
    
    public func getTotalExercises() -> Int {
        return getCurrentExercises().count
    }
    
    public func getSessionDuration() -> TimeInterval? {
        guard let session = currentSession else { return nil }
        
        if let endTime = session.endTime {
            return endTime.timeIntervalSince(session.startTime)
        } else {
            return Date().timeIntervalSince(session.startTime)
        }
    }
    
    // MARK: - Private Helpers
    
    private func getExerciseEquipment(exerciseId: UUID) -> EquipmentType {
        return getExercise(by: exerciseId)?.equipment ?? .bodyweight
    }
    // MARK: - Recovery (Phase 3)
    
    public func attemptRecovery() async -> Bool {
        return await withErrorHandling {
            isLoading = true
            
            // 가장 최근 활성 세션 찾기
            guard let recentSession = try await store.getMostRecentActiveSession() else {
                hasRecoverableSession = false
                isLoading = false
                return false
            }
            
            // 만료 여부 확인
            if recentSession.isExpired {
                // 만료된 세션 정리
                try await store.delete(id: recentSession.id)
                hasRecoverableSession = false
                isLoading = false
                throw SessionError.sessionExpired
            }
            
            // 세션 복구
            await stopAutosave()
            
            currentSession = recentSession
            hasRecoverableSession = false
            
            await startAutosave()
            updateSessionReadiness()
            
            isLoading = false
            return true
        } ?? false
    }
    
    public func checkRecoveryAvailability() async {
        await withErrorHandling {
            let mostRecentSession = try await store.getMostRecentActiveSession()
            
            if let session = mostRecentSession {
                hasRecoverableSession = !session.isExpired
                
                // 만료된 세션이 있다면 자동 정리
                if session.isExpired {
                    try await store.delete(id: session.id)
                    hasRecoverableSession = false
                }
            } else {
                hasRecoverableSession = false
            }
        }
    }
    
    public func getRecoverableSessionInfo() async -> (id: UUID, startTime: Date, exerciseCount: Int, setCount: Int)? {
        return await withErrorHandling {
            guard let session = try await store.getMostRecentActiveSession() else {
                throw SessionError.recoveryFailed("복구 가능한 세션이 없습니다.")
            }
            
            guard !session.isExpired else {
                throw SessionError.sessionExpired
            }
            
            return (
                id: session.id,
                startTime: session.startTime,
                exerciseCount: session.exercises.count,
                setCount: session.totalSets
            )
        }
    }
    
    public func discardRecoverableSession() async -> Bool {
        return await withErrorHandling {
            guard let session = try await store.getMostRecentActiveSession() else {
                hasRecoverableSession = false
                return true
            }
            
            try await store.delete(id: session.id)
            hasRecoverableSession = false
            return true
        } ?? false
    }
    
    // MARK: - Session Management Utilities
    
    public func forceCompleteCurrentSession() async -> String? {
        return await withErrorHandling {
            guard var session = currentSession else {
                throw SessionError.noActiveSession
            }
            
            isLoading = true
            
            // 강제 완료 (4세트 미만이라도 완료)
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
    
    public func pauseCurrentSession() async -> Bool {
        return await withErrorHandling {
            guard let session = currentSession else {
                throw SessionError.noActiveSession
            }
            
            // 현재 세션 저장 후 해제 (복구 가능한 상태로 남겨둠)
            try await store.save(session)
            
            currentSession = nil
            canCompleteSession = false
            hasRecoverableSession = true
            
            await stopAutosave()
            
            return true
        } ?? false
    }
    
    public func clearAllData() async -> Bool {
        return await withErrorHandling {
            // 현재 세션 중지
            if currentSession != nil {
                await stopAutosave()
                currentSession = nil
                canCompleteSession = false
            }
            
            // 모든 세션 데이터 삭제
            try await store.clearAllData()
            hasRecoverableSession = false
            
            return true
        } ?? false
    }
    
    // MARK: - Error Recovery
    
    public func recoverFromError() async {
        await withErrorHandling {
            error = nil
            isLoading = false
            
            // 세션 상태 재확인
            if let session = currentSession {
                if session.isExpired {
                    currentSession = nil
                    canCompleteSession = false
                    hasRecoverableSession = false
                    await stopAutosave()
                } else {
                    updateSessionReadiness()
                    if !isAutosaveEnabled {
                        await startAutosave()
                    }
                }
            }
            
            // 복구 가능한 세션 재확인
            await checkRecoveryAvailability()
        }
    }
    
    // MARK: - Session Validation & Repair
    
    public func validateAndRepairCurrentSession() async -> Bool {
        return await withErrorHandling {
            guard var session = currentSession else {
                return true // 세션이 없으면 문제 없음
            }
            
            var wasModified = false
            
            // 1. 만료된 세션 처리
            if session.isExpired {
                currentSession = nil
                canCompleteSession = false
                await stopAutosave()
                throw SessionError.sessionExpired
            }
            
            // 2. 고아 운동 정리 (슈퍼세트에 속하지만 그룹이 없는 운동)
            let validSupersetIds = Set(session.supersets.map { $0.id })
            
            session.exercises = session.exercises.map { exercise in
                var cleanedExercise = exercise
                if let supersetId = exercise.supersetGroupId,
                   !validSupersetIds.contains(supersetId) {
                    cleanedExercise.supersetGroupId = nil
                    wasModified = true
                }
                return cleanedExercise
            }
            
            // 3. 빈 슈퍼세트 정리 (운동이 없는 슈퍼세트)
            let exerciseIds = Set(session.exercises.map { $0.id })
            let supersetsBeforeClean = session.supersets.count
            
            session.supersets = session.supersets.filter { superset in
                superset.exerciseIds.allSatisfy { exerciseIds.contains($0) }
            }
            
            if session.supersets.count != supersetsBeforeClean {
                wasModified = true
            }
            
            // 4. 세트 순서 정리 (타임스탬프 기준)
            for i in 0..<session.exercises.count {
                let sortedSets = session.exercises[i].sets.sorted { $0.timestamp < $1.timestamp }
                if session.exercises[i].sets != sortedSets {
                    session.exercises[i].sets = sortedSets
                    wasModified = true
                }
            }
            
            if wasModified {
                currentSession = session
                updateSessionReadiness()
                try await store.save(session)
                print("세션 데이터 무결성 복구 완료")
            }
            
            return true
        } ?? false
    }
}
