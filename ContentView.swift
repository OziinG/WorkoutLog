import SwiftUI

struct ContentView: View {
    @StateObject private var session = Session()
    
    var body: some View {
        NavigationStack(path: $session.navPath) {
            WorkoutHomeView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .bodyPart:
                        BodyPartSelectionView()
                    case .equipment(let bodyPart):
                        EquipmentSelectionView(bodyPart: bodyPart)
                    case .exerciseType(let bodyPart, let equipment):
                        ExerciseSelectionView { exercise in
                            session.currentExerciseName = exercise.name
                            session.navPath.append(Route.exerciseLog(exercise))
                        }
                    case .exerciseLog(let exerciseType):
                        ExerciseLogView(exerciseType: exerciseType)
                    case .summary:
                        WorkoutSummaryView()
                    }
                }
        }
        .environmentObject(session)
    }
}

// MARK: - Temporary Views (구현 예정)
struct BodyPartSelectionView: View {
    @EnvironmentObject var session: Session
    
    var body: some View {
        Text("부위 선택 화면 (구현 예정)")
            .navigationTitle("운동 부위 선택")
            .onAppear {
                session.state = .selecting
            }
    }
}

struct EquipmentSelectionView: View {
    let bodyPart: String
    @EnvironmentObject var session: Session
    
    var body: some View {
        Text("기구 선택 화면 (구현 예정)")
            .navigationTitle("운동 기구 선택")
    }
}

struct ExerciseLogView: View {
    let exerciseType: ExerciseType
    @EnvironmentObject var session: Session
    
    var body: some View {
        Text("운동 기록 화면 (구현 예정)")
            .navigationTitle("운동 기록")
            .onAppear {
                session.state = .active
            }
    }
}

struct WorkoutSummaryView: View {
    @EnvironmentObject var session: Session
    
    var body: some View {
        VStack(spacing: 20) {
            Text("운동 완료!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if let startTime = session.startTime,
               let endTime = session.endTime {
                Text("운동 시간: \(formatDuration(from: startTime, to: endTime))")
                    .font(.headline)
            }
            
            Text("완료한 운동: \(session.exercises.count)개")
                .font(.title2)
            
            Button("처음으로 돌아가기") {
                session.resetSession(preserveDate: false)
                session.resetNavigation()
            }
            .font(.title2)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .cornerRadius(12)
        }
        .padding()
        .navigationTitle("운동 완료")
        .navigationBarBackButtonHidden(true)
    }
    
    private func formatDuration(from start: Date, to end: Date) -> String {
        let duration = end.timeIntervalSince(start)
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)시간 \(minutes)분"
        } else {
            return "\(minutes)분"
        }
    }
}

#Preview {
    ContentView()
}
