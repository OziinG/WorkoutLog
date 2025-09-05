import SwiftUI

struct ExerciseSelectionView: View {
    @StateObject private var viewModel = ExerciseSelectionViewModel()
    @Environment(\.dismiss) private var dismiss
    
    let onExerciseSelected: (ExerciseType) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                SearchBarView(text: $viewModel.searchText, onSearchChanged: {
                    viewModel.searchExercises()
                })
                
                // Filter Chips
                FilterChipsView(viewModel: viewModel)
                
                // Exercise List
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.filteredExercises.isEmpty {
                    EmptyStateView()
                } else {
                    ExerciseListView(
                        exercises: viewModel.filteredExercises,
                        onExerciseSelected: onExerciseSelected
                    )
                }
                
                Spacer()
            }
            .navigationTitle("운동 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
                
                if viewModel.hasFilters {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("초기화") {
                            viewModel.clearFilters()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Search Bar
struct SearchBarView: View {
    @Binding var text: String
    let onSearchChanged: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("운동 검색", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: text) {
                    onSearchChanged()
                }
            
            if !text.isEmpty {
                Button("지우기") {
                    text = ""
                    onSearchChanged()
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Filter Chips
struct FilterChipsView: View {
    @ObservedObject var viewModel: ExerciseSelectionViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(spacing: 8) {
                // Body Parts
                if !viewModel.availableBodyParts.isEmpty {
                    HStack(spacing: 8) {
                        Text("부위:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(viewModel.availableBodyParts, id: \.self) { bodyPart in
                            FilterChip(
                                title: bodyPart,
                                isSelected: viewModel.selectedBodyPart == bodyPart
                            ) {
                                if viewModel.selectedBodyPart == bodyPart {
                                    viewModel.selectBodyPart("")
                                } else {
                                    viewModel.selectBodyPart(bodyPart)
                                }
                            }
                        }
                        Spacer()
                    }
                }
                
                // Equipment
                if !viewModel.selectedBodyPart.isEmpty {
                    HStack(spacing: 8) {
                        Text("기구:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(viewModel.availableEquipment, id: \.self) { equipment in
                            FilterChip(
                                title: equipment.rawValue,
                                isSelected: viewModel.selectedEquipment == equipment
                            ) {
                                if viewModel.selectedEquipment == equipment {
                                    viewModel.selectEquipment(equipment)
                                } else {
                                    viewModel.selectEquipment(equipment)
                                }
                            }
                        }
                        Spacer()
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.2))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

// MARK: - Exercise List
struct ExerciseListView: View {
    let exercises: [ExerciseType]
    let onExerciseSelected: (ExerciseType) -> Void
    
    var body: some View {
        List(exercises) { exercise in
            ExerciseRowView(exercise: exercise) {
                onExerciseSelected(exercise)
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Exercise Row
struct ExerciseRowView: View {
    let exercise: ExerciseType
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Text(exercise.equipment.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                        
                        if let category = exercise.category {
                            Text(category.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .cornerRadius(4)
                        }
                        
                        Text(exercise.difficulty.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(4)
                    }
                    
                    Text("권장: \(exercise.recommendedSets.lowerBound)-\(exercise.recommendedSets.upperBound)세트, \(exercise.recommendedReps.lowerBound)-\(exercise.recommendedReps.upperBound)회")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("운동을 찾을 수 없습니다")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("다른 조건으로 검색해보세요")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ExerciseSelectionView { exercise in
        print("Selected: \(exercise.name)")
    }
}
