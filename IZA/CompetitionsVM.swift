//
//  CompetitionsVM.swift
//  IZA
//
//  Created by Adam Nieslanik on 15.05.2024.
//

import Foundation
import Combine

class CompetitionsVM: ObservableObject {
    // Search text indicator
    @Published var searchText = ""
    
    // Published filtered names
    @Published var filteredCompetitions: [String] = []
    private var cancellables = Set<AnyCancellable>()
    
    // Competitions list model
    private let Model = Request.shared

    init() {
        $searchText
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] text in
                guard let self = self else { return }
                self.filterCompetitions(with: text)
            }
            .store(in: &cancellables)
    }

    // Filter competition's name
    private func filterCompetitions(with searchText: String) {
        
        // Pass all competition's names
        if searchText.isEmpty {
            filteredCompetitions = Model.competitionsList.map {$0.code}
        } else {
            // Pass filtered competition's names
            filteredCompetitions = Model.competitionsList.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }.map {$0.code}
        }
    }
}
