import Foundation

public struct LogFormatter {
    
    public static func formatSession(_ session: WorkoutSession) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        var result = ""
        
        let startTimeString = dateFormatter.string(from: session.startTime)
        if let endTime = session.endTime {
            let endTimeString = dateFormatter.string(from: endTime)
            result += "\(startTimeString)~\(String(endTimeString.suffix(5)))\n"
        } else {
            result += "\(startTimeString)~진행중\n"
        }
        
        let sortedExercises = session.exercises.sorted { $0.order < $1.order }
        let supersetExercises = Set(session.supersets.flatMap { $0.exerciseIds })
        
        var exerciseIndex = 1
        var processedExercises = Set<UUID>()
        
        for exercise in sortedExercises {
            if processedExercises.contains(exercise.id) {
                continue
            }
            
            if let supersetGroup = session.supersets.first(where: { $0.exerciseIds.contains(exercise.id) }) {
                result += formatSuperset(supersetGroup, exercises: session.exercises, index: exerciseIndex)
                processedExercises.formUnion(supersetGroup.exerciseIds)
            } else {
                result += formatSingleExercise(exercise, index: exerciseIndex)
                processedExercises.insert(exercise.id)
            }
            
            exerciseIndex += 1
        }
        
        return result
    }
    
    private static func formatSingleExercise(_ exercise: ExerciseEntry, index: Int) -> String {
        var result = "\(index)) \(exercise.name) (\(exercise.equipment.displayName))\n"
        
        for (setIndex, set) in exercise.sets.enumerated() {
            let setNumber = setIndex + 1
            result += "  \(formatSet(set, setNumber: setNumber))\n"
        }
        
        return result
    }
    
    private static func formatSuperset(_ superset: SupersetGroup, exercises: [ExerciseEntry], index: Int) -> String {
        guard let exerciseA = exercises.first(where: { $0.id == superset.firstExerciseId }),
              let exerciseB = exercises.first(where: { $0.id == superset.secondExerciseId }) else {
            return "[S\(index)] 슈퍼세트 (운동 정보 없음)\n"
        }
        
        var result = "[S\(index)] \(exerciseA.name)(\(exerciseA.equipment.displayName)) ^ \(exerciseB.name)(\(exerciseB.equipment.displayName))\n"
        
        let allSets = (exerciseA.sets.map { (set: $0, exercise: "A") } +
                      exerciseB.sets.map { (set: $0, exercise: "B") })
            .sorted { $0.set.timestamp < $1.set.timestamp }
        
        for (setIndex, item) in allSets.enumerated() {
            let setNumber = setIndex + 1
            result += "  \(item.exercise) \(formatSet(item.set, setNumber: setNumber))\n"
        }
        
        return result
    }
    
    private static func formatSet(_ set: SetRecord, setNumber: Int) -> String {
        var components: [String] = []
        
        components.append("\(setNumber):")
        
        if let weight = set.weightKg {
            components.append("\(formatWeight(weight))kg")
        }
        
        components.append("x\(set.reps)")
        
        var flags: [String] = []
        if set.isWarmUp {
            flags.append("W")
        }
        if set.isFailure {
            flags.append("F")
        }
        
        if !flags.isEmpty {
            components.append("(\(flags.joined(separator: ",")))")
        }
        
        if let restSeconds = set.restSecondsBeforeNext {
            components.append("(Rest \(restSeconds)s)")
        }
        
        return components.joined(separator: " ")
    }
    
    private static func formatWeight(_ weight: Double) -> String {
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(weight))
        } else {
            return String(weight)
        }
    }
}
