//
//  ContentView.swift
//  IZA
//
//  Created by Adam Nieslanik on 13.05.2024.
//

import SwiftUI
import SwiftData
import Combine

struct AppView: View {
    // Competition list model
    @StateObject var Model = Request()
    
    // Indicates for cover view
    @State var cover:Bool = true
    
    var body: some View {
      
        // Tab view with dates
        DateView()
    }
    
}

// Screen cover while fetching data
struct FetchView: View {
    var body: some View {
        VStack {
            Text("iSports")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            Spacer()
            Image("Image")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
            Spacer()
            
            
            Text("Loading data..")
            
        }
    }
}

struct ContentView: View {
    @StateObject private var Model  = Request.shared
    var body: some View {
        // When app view appears, fetch competitions and match data for today
        AppView().onAppear(perform: {
            Model.fetchCompetitions()
            Model.fetchMatches(day: 1)
        }).fullScreenCover(isPresented: $Model.fetching){
            // Cover screen until completion of data fetching
            FetchView()
        }
        
    }
}

