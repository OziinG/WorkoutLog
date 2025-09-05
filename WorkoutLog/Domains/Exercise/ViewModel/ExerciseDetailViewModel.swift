import Foundation
import SwiftUI

// MARK: - Exercise Detail ViewModel
@MainActor
class ExerciseDetailViewModel: ObservableObject {
    @Published var exerciseType: ExerciseType
    @Published var currentSets: [WorkoutSet] = []
    @Published var isCompleted: Bool = false
    
    init(exerciseType: ExerciseType) {
        self.exerciseType = exerciseType
    }
    
    // MARK: - Computed Properties
    var recommendationText: String {
        let sets = exerciseType.recommendedSets
        let reps = exerciseType.recommendedReps
        return "\(sets.lowerBound)-\(sets.upperBound)세트, \(reps.lowerBound)-\(reps.upperBound)회"
    }
    
    var totalVolume: Double {
        currentSets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }
    
    var averageWeight: Double {
        guard !currentSets.isEmpty else { return 0 }
        return currentSets.reduce(0) { $0 + $1.weight } / Double(currentSets.count)
    }
    
    // MARK: - Public Methods
    func addSet(weight: Double, reps: Int, restTime: TimeInterval = 60) {
        let newSet = WorkoutSet(weight: weight, reps: reps, restTime: restTime)
        currentSets.append(newSet)
    }
    
    func removeSet(at index: Int) {
        guard index < currentSets.count else { return }
        currentSets.remove(at: index)
    }
    
    func updateSet(at index: Int, weight: Double, reps: Int) {
        guard index < currentSets.count else { return }
        let restTime = currentSets[index].restTime
        currentSets[index] = WorkoutSet(weight: weight, reps: reps, restTime: restTime)
    }
    
    func completeExercise() -> Exercise {
        let exercise = Exercise(exerciseType: exerciseType, sets: currentSets)
        isCompleted = true
        return exercise
    }
    
    func resetSets() {
        currentSets.removeAll()
        isCompleted = false
    }
}
