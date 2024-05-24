//
//  DateView.swift
//  IZA
//
//  Created by Adam Nieslanik on 14.05.2024.
//

import Foundation
import SwiftUI

struct DateView: View {
    
    // Matches for selected day
    @State private var selection = 1
    
    // Competition list model
    @StateObject var Model = Request.shared

    var body: some View {
        let dates = generateDates()
        
        // Tab for each day
        TabView(selection: $selection) {
            ForEach(0..<3) { index in
                // Show competitions for specific day
                CompetitionsView(index:index)
                    .tabItem {
                        // Day details
                        Label(dates[index].formattedDate(), systemImage: "calendar")
                    }
                    .tag(index)
                
            }.onChange(of: selection){
                // Fetch matches for selected day
                Model.fetchMatches(day: selection)
            }

        }
    }
    
    // Get closest days
    func generateDates() -> [Date] {
        let today = Date()
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        // Return 3 days to show
        return [yesterday, today, tomorrow]
    }
}

extension Date {
    // Format date to short style
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: self)
    }
}


