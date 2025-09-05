// filepath: /Users/jiin/WorksoutLog/WorkoutLog/WorkoutLog/Domains/Core/Model/SessionModels.swift
import Foundation
import SwiftUI

// MARK: - Session State
enum SessionState {
    case idle
    case selecting
    case active
    case completed
}

// MARK: - Navigation Route
enum Route: Hashable {
    case bodyPart
    case equipment(String) // bodyPart
    case exerciseType(String, Equipment) // bodyPart, equipment
    case exerciseLog(ExerciseType)
    case summary
}

// MARK: - Workout Session
@MainActor
class Session: ObservableObject {
    @Published var state: SessionState = .idle
    @Published var navPath = NavigationPath()
    
    // Session Data
    @Published var startTime: Date?
    @Published var endTime: Date?
    @Published var bodyPart: String = ""
    @Published var selectedEquipment: Equipment?
    @Published var currentExerciseName: String = ""
    @Published var exercises: [Exercise] = []
    
    // MARK: - Navigation Methods
    func resetNavigation() {
        navPath = NavigationPath()
    }
    
    func navigateTo(_ route: Route) {
        navPath.append(route)
    }
    
    func popToRoot() {
        navPath.removeLast(navPath.count)
    }
    
    // MARK: - Session Management
    func startNewSession() {
        resetSession(preserveDate: false)
        state = .selecting
        startTime = Date()
    }
    
    func resetSession(preserveDate: Bool = false) {
        if !preserveDate {
            startTime = nil
            endTime = nil
        }
        
        state = .idle
        bodyPart = ""
        selectedEquipment = nil
        currentExerciseName = ""
        exercises.removeAll()
        resetNavigation()
    }
    
    func completeSession() {
        state = .completed
        endTime = Date()
        navPath.append(Route.summary)
    }
    
    func addExercise(_ exercise: Exercise) {
        exercises.append(exercise)
    }
}
