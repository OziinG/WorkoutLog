import Foundation
import SwiftUI

@MainActor
class ExerciseSelectionViewModel: ObservableObject {
    @Published var selectedBodyPart: String = ""
    @Published var selectedEquipment: Equipment?
    @Published var filteredExercises: [ExerciseType] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    
    // 뷰에서 사용하는 추가 프로퍼티들
    @Published var selectedBodyParts: Set<String> = []
    @Published var selectedEquipments: Set<Equipment> = []
    
    private let database = ExerciseDatabase.shared
    
    init() {
        setupInitialData()
    }
    
    // MARK: - Computed Properties
    var availableBodyParts: [String] {
        database.allBodyParts
    }
    
    var availableEquipment: [Equipment] {
        database.allEquipment
    }
    
    var hasFilters: Bool {
        !selectedBodyPart.isEmpty || selectedEquipment != nil || !searchText.isEmpty || !selectedBodyParts.isEmpty
    }
    
    // MARK: - Public Methods
    func selectBodyPart(_ bodyPart: String) {
        selectedBodyPart = bodyPart
        selectedEquipment = nil // 부위 선택 시 기구 초기화
        updateFilteredExercises()
    }
    
    func selectEquipment(_ equipment: Equipment) {
        selectedEquipment = equipment
        updateFilteredExercises()
    }
    
    // 뷰에서 사용하는 메서드들 추가
    func toggleBodyPart(_ bodyPart: String) {
        if selectedBodyParts.contains(bodyPart) {
            selectedBodyParts.remove(bodyPart)
        } else {
            selectedBodyParts.insert(bodyPart)
        }
        updateFilteredExercises()
    }
    
    func toggleEquipment(_ equipment: Equipment) {
        if selectedEquipments.contains(equipment) {
            selectedEquipments.remove(equipment)
        } else {
            selectedEquipments.insert(equipment)
        }
        updateFilteredExercises()
    }
    
    func loadExercises() {
        updateFilteredExercises()
    }
    
    func clearFilters() {
        selectedBodyPart = ""
        selectedEquipment = nil
        searchText = ""
        selectedBodyParts.removeAll()
        selectedEquipments.removeAll()
        updateFilteredExercises()
    }
    
    func searchExercises() {
        updateFilteredExercises()
    }
    
    // MARK: - Private Methods
    private func setupInitialData() {
        updateFilteredExercises()
    }
    
    private func updateFilteredExercises() {
        isLoading = true
        
        var exercises = database.exercises
        
        // 부위 필터 (단일 선택)
        if !selectedBodyPart.isEmpty {
            exercises = database.getExercises(for: selectedBodyPart)
        }
        
        // 부위 필터 (다중 선택)
        if !selectedBodyParts.isEmpty {
            exercises = exercises.filter { exercise in
                selectedBodyParts.contains(exercise.bodyPart)
            }
        }
        
        // 기구 필터 (단일 선택)
        if let equipment = selectedEquipment {
            if !selectedBodyPart.isEmpty {
                exercises = database.getExercises(for: selectedBodyPart, equipment: equipment)
            } else {
                exercises = database.getExercises(for: equipment)
            }
        }
        
        // 기구 필터 (다중 선택)
        if !selectedEquipments.isEmpty {
            exercises = exercises.filter { exercise in
                selectedEquipments.contains(exercise.equipment)
            }
        }
        
        // 검색 필터
        if !searchText.isEmpty {
            exercises = exercises.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        filteredExercises = exercises.sorted { $0.name < $1.name }
        isLoading = false
    }
}
