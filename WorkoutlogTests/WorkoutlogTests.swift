//
//  WorkoutlogTests.swift
//  WorkoutlogTests
//
//  Created by Lim jiin on 9/8/25.
//

import Testing
import Foundation
@testable import Workoutlog

struct DomainModelTests {
    
    // MARK: - BodyPart Tests
    
    @Test func bodyPartDisplayName() throws {
        #expect(BodyPart.shoulder.displayName == "어깨")
        #expect(BodyPart.back.displayName == "등")
        #expect(BodyPart.chest.displayName == "가슴")
        #expect(BodyPart.legs.displayName == "하체")
        #expect(BodyPart.abs.displayName == "복근")
        #expect(BodyPart.arms.displayName == "팔")
        #expect(BodyPart.custom.displayName == "사용자 지정")
    }
    
    @Test func bodyPartCaseIterable() throws {
        #expect(BodyPart.allCases.count == 7)
        #expect(BodyPart.allCases.contains(.shoulder))
        #expect(BodyPart.allCases.contains(.custom))
    }
    
    // MARK: - EquipmentType Tests
    
    @Test func equipmentTypeRequiresPositiveWeight() throws {
        #expect(EquipmentType.machine.requiresPositiveWeight == true)
        #expect(EquipmentType.cable.requiresPositiveWeight == true)
        #expect(EquipmentType.barbell.requiresPositiveWeight == true)
        #expect(EquipmentType.dumbbell.requiresPositiveWeight == true)
        #expect(EquipmentType.bodyweight.requiresPositiveWeight == false)
        #expect(EquipmentType.custom("test").requiresPositiveWeight == true)
    }
    
    @Test func equipmentTypeDisplayName() throws {
        #expect(EquipmentType.machine.displayName == "머신")
        #expect(EquipmentType.cable.displayName == "케이블")
        #expect(EquipmentType.barbell.displayName == "바벨")
        #expect(EquipmentType.dumbbell.displayName == "덤벨")
        #expect(EquipmentType.bodyweight.displayName == "맨몸")
        #expect(EquipmentType.custom("커스텀기구").displayName == "커스텀기구")
    }
    
    // MARK: - SetRecord Tests
    
    @Test func setRecordValidWeightForBodyweight() throws {
        let set = try SetRecord(
            weightKg: nil,
            reps: 10,
            equipment: .bodyweight
        )
        #expect(set.weightKg == nil)
        #expect(set.reps == 10)
        #expect(set.isWarmUp == false)
        #expect(set.isFailure == false)
    }
    
    @Test func setRecordValidWeightForMachine() throws {
        let set = try SetRecord(
            weightKg: 50.0,
            reps: 8,
            isWarmUp: true,
            equipment: .machine
        )
        #expect(set.weightKg == 50.0)
        #expect(set.reps == 8)
        #expect(set.isWarmUp == true)
    }
    
    @Test func setRecordInvalidWeightForMachine() throws {
        #expect(throws: SetRecordError.self) {
            try SetRecord(weightKg: 0, reps: 10, equipment: .machine)
        }
        
        #expect(throws: SetRecordError.self) {
            try SetRecord(weightKg: nil, reps: 10, equipment: .barbell)
        }
    }
    
    @Test func setRecordInvalidReps() throws {
        #expect(throws: SetRecordError.self) {
            try SetRecord(weightKg: 50, reps: 0, equipment: .machine)
        }
        
        #expect(throws: SetRecordError.self) {
            try SetRecord(weightKg: nil, reps: -1, equipment: .bodyweight)
        }
    }
    
    // MARK: - ExerciseEntry Tests
    
    @Test func exerciseEntryIsReadyWith4Sets() throws {
        var exercise = ExerciseEntry(
            bodyPart: .chest,
            equipment: .barbell,
            name: "벤치프레스"
        )
        
        #expect(exercise.isReady == false)
        #expect(exercise.totalSets == 0)
        
        // Add 3 sets
        for _ in 1...3 {
            let set = SetRecord(weightKg: 60.0, reps: 8)
            exercise.addSet(set)
        }
        
        #expect(exercise.isReady == false)
        #expect(exercise.totalSets == 3)
        
        // Add 4th set
        let fourthSet = SetRecord(weightKg: 65.0, reps: 6)
        exercise.addSet(fourthSet)
        
        #expect(exercise.isReady == true)
        #expect(exercise.totalSets == 4)
    }
    
    @Test func exerciseEntrySuperset() throws {
        let supersetId = UUID()
        let exercise = ExerciseEntry(
            bodyPart: .back,
            equipment: .cable,
            name: "랫풀다운",
            supersetGroupId: supersetId
        )
        
        #expect(exercise.isPartOfSuperset == true)
        #expect(exercise.supersetGroupId == supersetId)
    }
    
    // MARK: - SupersetGroup Tests
    
    @Test func supersetGroupValidCreation() throws {
        let exerciseId1 = UUID()
        let exerciseId2 = UUID()
        
        let superset = SupersetGroup(
            exerciseIds: [exerciseId1, exerciseId2],
            order: 1
        )
        
        #expect(superset.exerciseIds.count == 2)
        #expect(superset.firstExerciseId == exerciseId1)
        #expect(superset.secondExerciseId == exerciseId2)
        #expect(superset.order == 1)
        #expect(superset.isCompleted == false)
    }
    
    @Test func supersetGroupIsReady() throws {
        let exerciseId1 = UUID()
        let exerciseId2 = UUID()
        
        var exercise1 = ExerciseEntry(
            id: exerciseId1,
            bodyPart: .chest,
            equipment: .barbell,
            name: "벤치프레스"
        )
        
        var exercise2 = ExerciseEntry(
            id: exerciseId2,
            bodyPart: .back,
            equipment: .barbell,
            name: "바벨로우"
        )
        
        let superset = SupersetGroup(exerciseIds: [exerciseId1, exerciseId2])
        
        // Initially not ready
        #expect(superset.isReady(exercises: [exercise1, exercise2]) == false)
        
        // Add 4 sets to first exercise only
        for _ in 1...4 {
            exercise1.addSet(SetRecord(weightKg: 60.0, reps: 8))
        }
        
        // Still not ready - second exercise has no sets
        #expect(superset.isReady(exercises: [exercise1, exercise2]) == false)
        
        // Add 4 sets to second exercise
        for _ in 1...4 {
            exercise2.addSet(SetRecord(weightKg: 50.0, reps: 10))
        }
        
        // Now ready
        #expect(superset.isReady(exercises: [exercise1, exercise2]) == true)
    }
    
    // MARK: - WorkoutSession Tests
    
    @Test func workoutSessionBasicOperations() throws {
        var session = WorkoutSession()
        
        #expect(session.status == .active)
        #expect(session.exercises.isEmpty)
        #expect(session.supersets.isEmpty)
        #expect(session.totalSets == 0)
        #expect(session.isExpired == false)
        
        let exercise = ExerciseEntry(
            bodyPart: .arms,
            equipment: .dumbbell,
            name: "덤벨컬"
        )
        
        session.addExercise(exercise)
        #expect(session.exercises.count == 1)
    }
    
    @Test func workoutSessionAddSetToExercise() throws {
        var session = WorkoutSession()
        let exercise = ExerciseEntry(
            bodyPart: .legs,
            equipment: .barbell,
            name: "스쿼트"
        )
        
        session.addExercise(exercise)
        let exerciseId = session.exercises[0].id
        
        let set = SetRecord(weightKg: 80.0, reps: 10)
        session.addSetToExercise(exerciseId: exerciseId, set: set)
        
        #expect(session.exercises[0].sets.count == 1)
        #expect(session.totalSets == 1)
    }
    
    @Test func workoutSessionComplete() throws {
        var session = WorkoutSession()
        
        session.complete()
        
        #expect(session.status == .completed)
        #expect(session.endTime != nil)
    }
    
    @Test func workoutSessionExpiration() throws {
        let pastDate = Date().addingTimeInterval(-13 * 60 * 60) // 13 hours ago
        let session = WorkoutSession(lastUpdated: pastDate)
        
        #expect(session.isExpired == true)
    }
    
    @Test func workoutSessionDuration() throws {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(45 * 60) // 45 minutes
        
        let session = WorkoutSession(
            startTime: startTime,
            endTime: endTime,
            status: .completed
        )
        
        #expect(session.durationInMinutes == 45)
    }
}

// MARK: - Validation Tests

struct ValidationTests {
    
    @Test func sessionReadinessValidatorSingleExercise() throws {
        var exercise = ExerciseEntry(
            bodyPart: .chest,
            equipment: .barbell,
            name: "벤치프레스"
        )
        
        #expect(SessionReadinessValidator.canCompleteExercise(exercise) == false)
        
        for _ in 1...4 {
            exercise.addSet(SetRecord(weightKg: 70.0, reps: 8))
        }
        
        #expect(SessionReadinessValidator.canCompleteExercise(exercise) == true)
    }
    
    @Test func sessionReadinessValidatorSuperset() throws {
        let exerciseId1 = UUID()
        let exerciseId2 = UUID()
        
        var exercise1 = ExerciseEntry(
            id: exerciseId1,
            bodyPart: .chest,
            equipment: .barbell,
            name: "벤치프레스"
        )
        
        var exercise2 = ExerciseEntry(
            id: exerciseId2,
            bodyPart: .back,
            equipment: .barbell,
            name: "바벨로우"
        )
        
        let superset = SupersetGroup(exerciseIds: [exerciseId1, exerciseId2])
        
        // Not ready initially
        #expect(SessionReadinessValidator.canCompleteSuperset(superset, exercises: [exercise1, exercise2]) == false)
        
        // Add 4 sets to first only
        for _ in 1...4 {
            exercise1.addSet(SetRecord(weightKg: 70.0, reps: 8))
        }
        
        #expect(SessionReadinessValidator.canCompleteSuperset(superset, exercises: [exercise1, exercise2]) == false)
        
        // Add 4 sets to second
        for _ in 1...4 {
            exercise2.addSet(SetRecord(weightKg: 60.0, reps: 10))
        }
        
        #expect(SessionReadinessValidator.canCompleteSuperset(superset, exercises: [exercise1, exercise2]) == true)
    }
    
    @Test func sessionReadinessValidatorWeightValidation() throws {
        #expect(throws: ValidationError.self) {
            try SessionReadinessValidator.validateSetRecord(weightKg: 0, equipment: .machine)
        }
        
        #expect(throws: ValidationError.self) {
            try SessionReadinessValidator.validateSetRecord(weightKg: nil, equipment: .barbell)
        }
        
        // Should not throw for bodyweight
        #expect(try SessionReadinessValidator.validateSetRecord(weightKg: nil, equipment: .bodyweight) == true)
    }
    
    @Test func sessionReadinessValidatorRepsValidation() throws {
        #expect(throws: ValidationError.self) {
            try SessionReadinessValidator.validateReps(0)
        }
        
        #expect(throws: ValidationError.self) {
            try SessionReadinessValidator.validateReps(-5)
        }
        
        #expect(try SessionReadinessValidator.validateReps(10) == true)
    }
    
    @Test func sessionExpiration() throws {
        let expiredSession = WorkoutSession(lastUpdated: Date().addingTimeInterval(-13 * 60 * 60))
        #expect(SessionReadinessValidator.isSessionExpired(expiredSession) == true)
        
        let activeSession = WorkoutSession()
        #expect(SessionReadinessValidator.isSessionExpired(activeSession) == false)
    }
}

// MARK: - LogFormatter Tests

struct LogFormatterTests {
    
    @Test func formatSingleExerciseSession() throws {
        var exercise = ExerciseEntry(
            bodyPart: .chest,
            equipment: .barbell,
            name: "벤치프레스",
            order: 1
        )
        
        exercise.addSet(SetRecord(weightKg: 60.0, reps: 10, isWarmUp: true))
        exercise.addSet(SetRecord(weightKg: 70.0, reps: 8))
        exercise.addSet(SetRecord(weightKg: 75.0, reps: 6, isFailure: true))
        exercise.addSet(SetRecord(weightKg: 70.0, reps: 8, restSecondsBeforeNext: 90))
        
        var session = WorkoutSession()
        session.addExercise(exercise)
        session.complete()
        
        let log = LogFormatter.formatSession(session)
        
        #expect(log.contains("1) 벤치프레스 (바벨)"))
        #expect(log.contains("1: 60kg x10 (W)"))
        #expect(log.contains("2: 70kg x8"))
        #expect(log.contains("3: 75kg x6 (F)"))
        #expect(log.contains("4: 70kg x8 (Rest 90s)"))
    }
    
    @Test func formatSupersetSession() throws {
        let exerciseId1 = UUID()
        let exerciseId2 = UUID()
        let supersetId = UUID()
        
        var exercise1 = ExerciseEntry(
            id: exerciseId1,
            bodyPart: .chest,
            equipment: .barbell,
            name: "벤치프레스",
            supersetGroupId: supersetId,
            order: 1
        )
        
        var exercise2 = ExerciseEntry(
            id: exerciseId2,
            bodyPart: .back,
            equipment: .barbell,
            name: "바벨로우",
            supersetGroupId: supersetId,
            order: 2
        )
        
        // Add sets with different timestamps to test ordering
        let baseTime = Date()
        exercise1.addSet(SetRecord(weightKg: 70.0, reps: 10, timestamp: baseTime))
        exercise2.addSet(SetRecord(weightKg: 60.0, reps: 10, timestamp: baseTime.addingTimeInterval(30)))
        exercise1.addSet(SetRecord(weightKg: 75.0, reps: 8, timestamp: baseTime.addingTimeInterval(60)))
        exercise2.addSet(SetRecord(weightKg: 65.0, reps: 8, timestamp: baseTime.addingTimeInterval(90)))
        
        let superset = SupersetGroup(
            id: supersetId,
            exerciseIds: [exerciseId1, exerciseId2],
            order: 1
        )
        
        var session = WorkoutSession()
        session.addExercise(exercise1)
        session.addExercise(exercise2)
        session.addSuperset(superset)
        session.complete()
        
        let log = LogFormatter.formatSession(session)
        
        #expect(log.contains("[S1] 벤치프레스(바벨) ^ 바벨로우(바벨)"))
        #expect(log.contains("A 1: 70kg x10"))
        #expect(log.contains("B 2: 60kg x10"))
        #expect(log.contains("A 3: 75kg x8"))
        #expect(log.contains("B 4: 65kg x8"))
    }
}

// MARK: - Storage Tests

struct StorageTests {
    
    @Test func inMemoryStoreBasicCRUD() async throws {
        let store = InMemorySessionStore()
        
        // Create test session
        let session = WorkoutSession()
        
        // Save
        try await store.save(session)
        
        // Load by ID
        let loadedSession = try await store.load(id: session.id)
        #expect(loadedSession != nil)
        #expect(loadedSession?.id == session.id)
        
        // Load all
        let allSessions = try await store.loadAll()
        #expect(allSessions.count == 1)
        #expect(allSessions.first?.id == session.id)
        
        // Update
        var updatedSession = session
        updatedSession.status = .completed
        try await store.updateSession(updatedSession)
        
        let reloadedSession = try await store.load(id: session.id)
        #expect(reloadedSession?.status == .completed)
        
        // Delete
        try await store.delete(id: session.id)
        let deletedSession = try await store.load(id: session.id)
        #expect(deletedSession == nil)
        
        // Delete non-existent should throw
        await #expect(throws: StorageError.self) {
            try await store.delete(id: UUID())
        }
    }
    
    @Test func inMemoryStoreActiveSessionManagement() async throws {
        let store = InMemorySessionStore()
        
        // Create multiple sessions
        let activeSession1 = WorkoutSession()
        let activeSession2 = WorkoutSession()
        var completedSession = WorkoutSession()
        completedSession.status = .completed
        
        try await store.save(activeSession1)
        try await store.save(activeSession2)
        try await store.save(completedSession)
        
        // Get active sessions
        let activeSessions = try await store.getActiveSessions()
        #expect(activeSessions.count == 2)
        
        // Get completed sessions
        let completedSessions = try await store.getCompletedSessions()
        #expect(completedSessions.count == 1)
        #expect(completedSessions.first?.status == .completed)
        
        // Get most recent active session
        let mostRecent = try await store.getMostRecentActiveSession()
        #expect(mostRecent != nil)
        #expect([activeSession1.id, activeSession2.id].contains(mostRecent!.id))
    }
    
    @Test func inMemoryStoreAutosaveManagement() async throws {
        let store = InMemorySessionStore()
        
        // Initially autosave should be disabled
        let initiallyEnabled = await store.isAutosaveEnabled()
        #expect(initiallyEnabled == false)
        
        // Enable autosave
        await store.enableAutosave(interval: 1.0)
        let enabledAfter = await store.isAutosaveEnabled()
        #expect(enabledAfter == true)
        
        // Disable autosave
        await store.disableAutosave()
        let disabledAfter = await store.isAutosaveEnabled()
        #expect(disabledAfter == false)
    }
    
    @Test func inMemoryStoreExpirationHandling() async throws {
        let store = InMemorySessionStore()
        
        // Create expired session (13 hours ago)
        let expiredDate = Date().addingTimeInterval(-13 * 60 * 60)
        let expiredSession = WorkoutSession(lastUpdated: expiredDate)
        let activeSession = WorkoutSession()
        
        try await store.save(expiredSession)
        try await store.save(activeSession)
        
        // Check expired sessions
        let expiredSessions = try await store.getExpiredSessions()
        #expect(expiredSessions.count == 1)
        #expect(expiredSessions.first?.id == expiredSession.id)
        
        // Check specific session expiration
        let isExpired = try await store.isSessionExpired(id: expiredSession.id)
        #expect(isExpired == true)
        
        let isActiveExpired = try await store.isSessionExpired(id: activeSession.id)
        #expect(isActiveExpired == false)
        
        // Prune expired sessions
        let prunedIds = try await store.pruneExpiredSessions()
        #expect(prunedIds.count == 1)
        #expect(prunedIds.contains(expiredSession.id))
        
        // Verify expired session was removed
        let remainingSessions = try await store.loadAll()
        #expect(remainingSessions.count == 1)
        #expect(remainingSessions.first?.id == activeSession.id)
    }
    
    @Test func inMemoryStoreRecoveryOperations() async throws {
        let store = InMemorySessionStore()
        
        // Create sessions with different states
        let activeSession = WorkoutSession()
        var expiredSession = WorkoutSession(lastUpdated: Date().addingTimeInterval(-13 * 60 * 60))
        expiredSession.status = .active
        var completedSession = WorkoutSession()
        completedSession.status = .completed
        
        try await store.save(activeSession)
        try await store.save(expiredSession)
        try await store.save(completedSession)
        
        // Test recovery capability
        let canRecoverActive = try await store.canRecover(sessionId: activeSession.id)
        #expect(canRecoverActive == true)
        
        let canRecoverExpired = try await store.canRecover(sessionId: expiredSession.id)
        #expect(canRecoverExpired == false)
        
        let canRecoverCompleted = try await store.canRecover(sessionId: completedSession.id)
        #expect(canRecoverCompleted == false)
        
        // Test recover all sessions
        let recoveredSessions = try await store.recoverAllSessions()
        #expect(recoveredSessions.count == 1)
        #expect(recoveredSessions.first?.id == activeSession.id)
    }
    
    @Test func inMemoryStoreStatisticsAndUtilities() async throws {
        let store = InMemorySessionStore()
        try await store.clearAllData()
        
        // Initially empty
        let initialCount = try await store.getTotalSessionCount()
        #expect(initialCount == 0)
        
        let initialSize = try await store.getStorageSize()
        #expect(initialSize == 0)
        
        // Add sessions
        let session1 = WorkoutSession()
        let session2 = WorkoutSession()
        
        try await store.save(session1)
        try await store.save(session2)
        
        // Check counts
        let afterCount = try await store.getTotalSessionCount()
        #expect(afterCount == 2)
        
        let afterSize = try await store.getStorageSize()
        #expect(afterSize > 0)
        
        // Clear all data
        try await store.clearAllData()
        
        let clearedCount = try await store.getTotalSessionCount()
        #expect(clearedCount == 0)
        
        let clearedSessions = try await store.loadAll()
        #expect(clearedSessions.isEmpty)
    }
    
    @Test func inMemoryStoreErrorHandling() async throws {
        let store = InMemorySessionStore()
        
        let nonExistentId = UUID()
        
        // Loading non-existent session should return nil
        let nonExistentSession = try await store.load(id: nonExistentId)
        #expect(nonExistentSession == nil)
        
        // Deleting non-existent session should throw
        await #expect(throws: StorageError.self) {
            try await store.delete(id: nonExistentId)
        }
        
        // Checking expiration of non-existent session should throw
        await #expect(throws: StorageError.self) {
            _ = try await store.isSessionExpired(id: nonExistentId)
        }
        
        // Can't recover non-existent session
        let canRecoverNonExistent = try await store.canRecover(sessionId: nonExistentId)
        #expect(canRecoverNonExistent == false)
    }
    
    @Test func inMemoryStoreComplexWorkflowScenario() async throws {
        let store = InMemorySessionStore()
        
        // Enable autosave
        await store.enableAutosave(interval: 0.1)
        
        // Create session with exercises
        var session = WorkoutSession()
        
        let exercise = ExerciseEntry(
            bodyPart: .chest,
            equipment: .barbell,
            name: "벤치프레스"
        )
        
        session.addExercise(exercise)
        
        // Add sets to exercise
        for i in 1...5 {
            let set = SetRecord(weightKg: Double(50 + i * 5), reps: 8)
            session.addSetToExercise(exerciseId: exercise.id, set: set)
        }
        
        // Save session
        try await store.save(session)
        
        // Verify data integrity
        let savedSession = try await store.load(id: session.id)
        #expect(savedSession?.exercises.count == 1)
        #expect(savedSession?.exercises.first?.sets.count == 5)
        #expect(savedSession?.totalSets == 5)
        
        // Complete session
        session.complete()
        try await store.updateSession(session)
        
        // Verify completion
        let completedSession = try await store.load(id: session.id)
        #expect(completedSession?.status == .completed)
        #expect(completedSession?.endTime != nil)
        
        // Verify it's no longer in active sessions
        let activeSessions = try await store.getActiveSessions()
        #expect(activeSessions.isEmpty)
        
        // Verify it's in completed sessions
        let completedSessions = try await store.getCompletedSessions()
        #expect(completedSessions.count == 1)
        
        await store.disableAutosave()
    }
}
// MARK: - SessionManager Tests

struct SessionManagerTests {
    
    // MARK: - Initialization & Basic State Tests
    
    @Test func sessionManagerInitialization() async throws {
        let store = InMemorySessionStore()
        try await store.clearAllData() // 테스트 시작 전 초기화
        let manager = await SessionManager(store: store)
        
        // Wait for initial setup
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        #expect(await manager.currentSession == nil)
        #expect(await manager.isLoading == false)
        #expect(await manager.error == nil)
        #expect(await manager.canCompleteSession == false)
        #expect(await manager.hasRecoverableSession == false)
        #expect(await manager.isAutosaveEnabled == false)
    }
    
    @Test func sessionManagerStartNewSession() async throws {
        let store = InMemorySessionStore()
        try await store.clearAllData()
        let manager = await SessionManager(store: store)
        
        await manager.startNewSession()
        
        #expect(await manager.currentSession != nil)
        #expect(await manager.currentSession?.status == .active)
        #expect(await manager.hasRecoverableSession == false)
        #expect(await manager.isAutosaveEnabled == true)
        #expect(await manager.error == nil)
    }
    
    @Test func sessionManagerCompleteSession() async throws {
        let store = InMemorySessionStore()
        try await store.clearAllData()
        let manager = await SessionManager(store: store)
        
        await manager.startNewSession()
        
        let exercise = ExerciseEntry(bodyPart: .chest, equipment: .barbell, name: "벤치프레스")
        await manager.addExercise(exercise)
        
        for i in 1...4 {
            let set = SetRecord(weightKg: Double(60 + i * 5), reps: 8)
            await manager.addSetToCurrentExercise(exerciseId: exercise.id, set: set)
        }
        
        #expect(await manager.canCompleteSession == true)
        
        let logString = await manager.completeCurrentSession()
        
        #expect(logString != nil)
        #expect(logString!.contains("벤치프레스"))
        #expect(await manager.currentSession == nil)
        #expect(await manager.canCompleteSession == false)
        #expect(await manager.isAutosaveEnabled == false)
    }
    
    // MARK: - Exercise Management Tests
    
    @Test func sessionManagerAddExercise() async throws {
        let store = InMemorySessionStore()
        try await store.clearAllData()
        let manager = await SessionManager(store: store)
        
        await manager.startNewSession()
        
        let exercise = ExerciseEntry(bodyPart: .back, equipment: .cable, name: "랫풀다운")
        await manager.addExercise(exercise)
        
        #expect(await manager.getCurrentExercises().count == 1)
        #expect(await manager.getCurrentExercises().first?.name == "랫풀다운")
        #expect(await manager.getTotalExercises() == 1)
    }
    
    @Test func sessionManagerAddSuperset() async throws {
        let store = InMemorySessionStore()
        try await store.clearAllData()
        let manager = await SessionManager(store: store)
        
        await manager.startNewSession()
        
        let exercise1 = ExerciseEntry(bodyPart: .chest, equipment: .barbell, name: "벤치프레스")
        let exercise2 = ExerciseEntry(bodyPart: .back, equipment: .barbell, name: "바벨로우")
        
        await manager.addExercise(exercise1)
        await manager.addExercise(exercise2)
        
        let superset = SupersetGroup(exerciseIds: [exercise1.id, exercise2.id], order: 1)
        await manager.addSuperset(superset)
        
        #expect(await manager.getCurrentSupersets().count == 1)
        #expect(await manager.isExerciseInSuperset(exercise1.id) == true)
        #expect(await manager.isExerciseInSuperset(exercise2.id) == true)
    }
    
    // MARK: - Set Management Tests
    
    @Test func sessionManagerAddSetToExercise() async throws {
        let store = InMemorySessionStore()
        try await store.clearAllData()
        let manager = await SessionManager(store: store)
        
        await manager.startNewSession()
        
        let exercise = ExerciseEntry(bodyPart: .legs, equipment: .barbell, name: "스쿼트")
        await manager.addExercise(exercise)
        
        let set = SetRecord(weightKg: 100.0, reps: 10)
        await manager.addSetToCurrentExercise(exerciseId: exercise.id, set: set)
        
        #expect(await manager.getSets(for: exercise.id).count == 1)
        #expect(await manager.getSetCount(for: exercise.id) == 1)
        #expect(await manager.getTotalSets() == 1)
        #expect(await manager.isExerciseReady(exercise.id) == false) // Only 1 set
    }
    
    @Test func sessionManagerSetValidation() async throws {
        let store = InMemorySessionStore()
        try await store.clearAllData()
        let manager = await SessionManager(store: store)
        
        await manager.startNewSession()
        
        let exercise = ExerciseEntry(bodyPart: .chest, equipment: .barbell, name: "벤치프레스")
        await manager.addExercise(exercise)
        
        let invalidSet = SetRecord(weightKg: 0, reps: 10)
        await manager.addSetToCurrentExercise(exerciseId: exercise.id, set: invalidSet)
        
        #expect(await manager.error != nil)
        #expect(await manager.getSets(for: exercise.id).count == 0) // Set should not be added
    }
    
    @Test func sessionManagerExerciseReadiness() async throws {
        let store = InMemorySessionStore()
        try await store.clearAllData()
        let manager = await SessionManager(store: store)
        
        await manager.startNewSession()
        
        let exercise = ExerciseEntry(bodyPart: .arms, equipment: .dumbbell, name: "덤벨컬")
        await manager.addExercise(exercise)
        
        for i in 1...3 {
            let set = SetRecord(weightKg: Double(10 + i * 2), reps: 10)
            await manager.addSetToCurrentExercise(exerciseId: exercise.id, set: set)
        }
        
        #expect(await manager.isExerciseReady(exercise.id) == false)
        #expect(await manager.canCompleteSession == false)
        
        let fourthSet = SetRecord(weightKg: 18.0, reps: 8)
        await manager.addSetToCurrentExercise(exerciseId: exercise.id, set: fourthSet) // 문법 오류 수정
        
        #expect(await manager.isExerciseReady(exercise.id) == true)
        #expect(await manager.canCompleteSession == true)
    }
    
    // MARK: - Superset Management Tests
    
    @Test func sessionManagerSupersetReadiness() async throws {
        let store = InMemorySessionStore()
        try await store.clearAllData()
        let manager = await SessionManager(store: store)
        
        await manager.startNewSession()
        
        let exercise1 = ExerciseEntry(bodyPart: .chest, equipment: .barbell, name: "벤치프레스")
        let exercise2 = ExerciseEntry(bodyPart: .back, equipment: .barbell, name: "바벨로우")
        
        await manager.addExercise(exercise1)
        await manager.addExercise(exercise2)
        
        let superset = SupersetGroup(exerciseIds: [exercise1.id, exercise2.id], order: 1)
        await manager.addSuperset(superset)
        
        for i in 1...4 {
            let set = SetRecord(weightKg: Double(70 + i * 5), reps: 8)
            await manager.addSetToCurrentExercise(exerciseId: exercise1.id, set: set)
        }
        
        #expect(await manager.isExerciseReady(exercise1.id) == true)
        #expect(await manager.isExerciseReady(exercise2.id) == false)
        #expect(await manager.isSupersetReady(superset.id) == false)
        #expect(await manager.canCompleteSession == false)
        
        for i in 1...4 {
            let set = SetRecord(weightKg: Double(60 + i * 5), reps: 10)
            await manager.addSetToCurrentExercise(exerciseId: exercise2.id, set: set)
        }
        
        #expect(await manager.isExerciseReady(exercise2.id) == true)
        #expect(await manager.isSupersetReady(superset.id) == true)
        #expect(await manager.canCompleteSession == true)
    }
    
    // MARK: - Recovery Tests (Phase 3)
    
    @Test func sessionManagerRecovery() async throws {
        let store = InMemorySessionStore()
        try await store.clearAllData()
        let manager = await SessionManager(store: store)
        
        await manager.startNewSession()
        let exercise = ExerciseEntry(bodyPart: .chest, equipment: .barbell, name: "벤치프레스")
        await manager.addExercise(exercise)
        
        let set = SetRecord(weightKg: 60.0, reps: 10)
        await manager.addSetToCurrentExercise(exerciseId: exercise.id, set: set)
        
        let originalSessionId = await manager.currentSession?.id
        
        let pauseSuccess = await manager.pauseCurrentSession()
        #expect(pauseSuccess == true)
        #expect(await manager.currentSession == nil)
        #expect(await manager.hasRecoverableSession == true)
        
        let recoverySuccess = await manager.attemptRecovery()
        #expect(recoverySuccess == true)
        #expect(await manager.currentSession?.id == originalSessionId)
        #expect(await manager.getCurrentExercises().count == 1)
        #expect(await manager.getTotalSets() == 1)
    }
    
    @Test func sessionManagerGetRecoverableSessionInfo() async throws {
        let store = InMemorySessionStore()
        try await store.clearAllData()
        let manager = await SessionManager(store: store)
        
        await manager.startNewSession()
        
        let exercise = ExerciseEntry(bodyPart: .legs, equipment: .barbell, name: "스쿼트")
        await manager.addExercise(exercise)
        
        for i in 1...3 {
            let set = SetRecord(weightKg: Double(80 + i * 10), reps: 10)
            await manager.addSetToCurrentExercise(exerciseId: exercise.id, set: set)
        }
        
        let pauseSuccess = await manager.pauseCurrentSession()
        #expect(pauseSuccess == true)
        
        let sessionInfo = await manager.getRecoverableSessionInfo()
        #expect(sessionInfo != nil)
        #expect(sessionInfo?.exerciseCount == 1)
        #expect(sessionInfo?.setCount == 3)
    }
    
    @Test func sessionManagerDiscardRecoverableSession() async throws {
        let store = InMemorySessionStore()
        try await store.clearAllData()
        let manager = await SessionManager(store: store)
        
        await manager.startNewSession()
        let exercise = ExerciseEntry(bodyPart: .chest, equipment: .dumbbell, name: "덤벨플라이")
        await manager.addExercise(exercise)
        
        let pauseSuccess = await manager.pauseCurrentSession()
        #expect(pauseSuccess == true)
        #expect(await manager.hasRecoverableSession == true)
        
        let discardSuccess = await manager.discardRecoverableSession()
        #expect(discardSuccess == true)
        #expect(await manager.hasRecoverableSession == false)
    }
    
    // MARK: - Error Recovery Tests
    
    @Test func sessionManagerRecoverFromError() async throws {
        let store = InMemorySessionStore()
        try await store.clearAllData()
        let manager = await SessionManager(store: store)
        
        await manager.startNewSession()
        
        await manager.addSetToCurrentExercise(exerciseId: UUID(), set: SetRecord(weightKg: 50, reps: 10))
        #expect(await manager.error != nil)
        
        await manager.recoverFromError()
        #expect(await manager.error == nil)
        #expect(await manager.isLoading == false)
    }
    
    @Test func sessionManagerValidateAndRepairSession() async throws {
        let store = InMemorySessionStore()
        try await store.clearAllData()
        let manager = await SessionManager(store: store)
        
        await manager.startNewSession()
        
        let exercise = ExerciseEntry(bodyPart: .chest, equipment: .barbell, name: "벤치프레스")
        await manager.addExercise(exercise)
        
        let isValid = await manager.validateAndRepairCurrentSession()
        #expect(isValid == true)
    }
    
    // MARK: - Force Complete Tests
    
    @Test func sessionManagerForceCompleteSession() async throws {
        let store = InMemorySessionStore()
        try await store.clearAllData()
        let manager = await SessionManager(store: store)
        
        await manager.startNewSession()
        
        let exercise = ExerciseEntry(bodyPart: .chest, equipment: .barbell, name: "벤치프레스")
        await manager.addExercise(exercise)
        
        for i in 1...2 {
            let set = SetRecord(weightKg: Double(60 + i * 5), reps: 8)
            await manager.addSetToCurrentExercise(exerciseId: exercise.id, set: set)
        }
        
        #expect(await manager.canCompleteSession == false)
        
        let logString = await manager.forceCompleteCurrentSession()
        #expect(logString != nil)
        #expect(logString!.contains("벤치프레스"))
        #expect(await manager.currentSession == nil)
    }
    
    // MARK: - Clear Data Tests
    
    @Test func sessionManagerClearAllData() async throws {
        let store = InMemorySessionStore()
        try await store.clearAllData()
        let manager = await SessionManager(store: store)
        
        await manager.startNewSession()
        
        let exercise = ExerciseEntry(bodyPart: .chest, equipment: .barbell, name: "벤치프레스")
        await manager.addExercise(exercise)
        
        #expect(await manager.currentSession != nil)
        
        let clearSuccess = await manager.clearAllData()
        #expect(clearSuccess == true)
        #expect(await manager.currentSession == nil)
        #expect(await manager.hasRecoverableSession == false)
        #expect(await manager.isAutosaveEnabled == false)
    }
    
    // MARK: - Session Statistics Tests
    
    @Test func sessionManagerStatistics() async throws {
        let store = InMemorySessionStore()
        try await store.clearAllData()
        let manager = await SessionManager(store: store)
        
        await manager.startNewSession()
        
        let exercise1 = ExerciseEntry(bodyPart: .chest, equipment: .barbell, name: "벤치프레스")
        let exercise2 = ExerciseEntry(bodyPart: .back, equipment: .cable, name: "랫풀다운")
        
        await manager.addExercise(exercise1)
        await manager.addExercise(exercise2)
        
        for i in 1...3 {
            let set1 = SetRecord(weightKg: Double(60 + i * 5), reps: 8)
            let set2 = SetRecord(weightKg: Double(40 + i * 3), reps: 10)
            
            await manager.addSetToCurrentExercise(exerciseId: exercise1.id, set: set1)
            await manager.addSetToCurrentExercise(exerciseId: exercise2.id, set: set2)
        }
        
        #expect(await manager.getTotalExercises() == 2)
        #expect(await manager.getTotalSets() == 6)
        
        let duration = await manager.getSessionDuration()
        #expect(duration != nil)
        #expect(duration! > 0)
    }
    
    // MARK: - Edge Cases and Error Handling
    
    @Test func sessionManagerNoActiveSessionOperations() async throws {
        let store = InMemorySessionStore()
        try await store.clearAllData()
        let manager = await SessionManager(store: store)
        
        let exercise = ExerciseEntry(bodyPart: .chest, equipment: .barbell, name: "벤치프레스")
        
        await manager.addExercise(exercise)
        #expect(await manager.error != nil)
        #expect(await manager.getCurrentExercises().isEmpty)
        
        await manager.recoverFromError()
        #expect(await manager.error == nil)
    }
    
    @Test func sessionManagerQueryMethods() async throws {
        let store = InMemorySessionStore()
        try await store.clearAllData()
        let manager = await SessionManager(store: store)
        
        await manager.startNewSession()
        
        let exerciseId = UUID()
        let exercise = ExerciseEntry(id: exerciseId, bodyPart: .arms, equipment: .dumbbell, name: "덤벨컬")
        
        await manager.addExercise(exercise)
        
        #expect(await manager.getExercise(by: exerciseId) != nil)
        #expect(await manager.getExercise(by: exerciseId)?.name == "덤벨컬")
        #expect(await manager.canAddSetToExercise(exerciseId) == true)
        
        for i in 1...8 {
            let set = SetRecord(weightKg: Double(10 + i), reps: 10)
            await manager.addSetToCurrentExercise(exerciseId: exerciseId, set: set)
        }
        
        #expect(await manager.getSetCount(for: exerciseId) == 8)
        #expect(await manager.canAddSetToExercise(exerciseId) == false) // Max 8 sets reached
    }
}
