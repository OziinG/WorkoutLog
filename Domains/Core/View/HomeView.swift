import SwiftUI

struct WorkoutHomeView: View {
    @EnvironmentObject var session: Session
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // MARK: - Header
            VStack(spacing: 16) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.accentColor)
                
                Text("WorkoutLog")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("당신의 운동 여정을 함께합니다")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // MARK: - Session Status
            if session.state != .idle {
                SessionStatusCard()
                    .padding(.horizontal, 20)
            }
            
            // MARK: - Action Buttons
            VStack(spacing: 16) {
                // 운동 시작/계속하기 버튼
                Button(action: startWorkout) {
                    HStack(spacing: 8) {
                        Image(systemName: session.state == .idle ? "play.fill" : "arrow.right")
                        Text(session.state == .idle ? "운동 시작하기" : "운동 계속하기")
                    }
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 20)
                
                // 운동 종료 버튼 (세션이 진행 중일 때만)
                if session.state == .selecting || session.state == .active {
                    Button(action: endWorkout) {
                        Text("운동 종료")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                    }
                }
            }
            
            Spacer()
            Spacer()
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Actions
    private func startWorkout() {
        if session.state == .idle {
            session.startNewSession()
        }
        session.navigateTo(.bodyPart)
    }
    
    private func endWorkout() {
        // 운동 종료 확인 알럿을 보여주거나 직접 종료
        session.resetSession()
    }
}

// MARK: - Session Status Card
struct SessionStatusCard: View {
    @EnvironmentObject var session: Session
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                Text(statusText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if let startTime = session.startTime {
                    Text(formatElapsedTime(from: startTime))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
            }
            
            Text("현재 세션")
                .font(.headline)
                .fontWeight(.semibold)
            
            if !session.exercises.isEmpty {
                Text("\(session.exercises.count)개 운동 완료")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if !session.bodyPart.isEmpty {
                Text("\(session.bodyPart) 운동 진행중")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var statusColor: Color {
        switch session.state {
        case .idle: return .gray
        case .selecting: return .orange
        case .active: return .green
        case .completed: return .blue
        }
    }
    
    private var statusText: String {
        switch session.state {
        case .idle: return "대기 중"
        case .selecting: return "운동 선택 중"
        case .active: return "운동 진행 중"
        case .completed: return "완료"
        }
    }
    
    private func formatElapsedTime(from startTime: Date) -> String {
        let elapsed = Date().timeIntervalSince(startTime)
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    NavigationStack {
        WorkoutHomeView()
            .environmentObject(Session())
    }
}
