//
//  TableView.swift
//  IZA
//
//  Created by Adam Nieslanik on 15.05.2024.
//

import Foundation
import SwiftUI

struct TableView: View {
    // Competition to show its table
    let competition:Competitions
    
    // Competition list model
    @StateObject var Model = Request.shared
    
    // Table for specific competition
    @State private var table: [String:Standings]?
    
    var body: some View{
        
        // List for each table's position
        List{
            HStack {
                Text("Position")
                Spacer()
                Text("Points")
            }
            
            // Get table for this competition
            if let tableView = self.table?[competition.code]{
                
                // Show details for each position
                ForEach(tableView.table){ list in
                    HStack {
                        Text("\(list.position).")
                        Spacer()
                        
                        Text("\(list.team.name)")
                        Spacer()
                        
                        Text("\(list.points)")
                    }
                }
            }
            
        }.onAppear{
            // When this view appears, fetch competition's table details
            Model.fetchTable(code: competition.code) { table in
                
                self.table = table
                
            }
        }
        .navigationTitle("Table")
    }
}
