import SwiftUI
import SwiftData

struct CompetitionsView: View {
    // Fetched competition's list model
    @StateObject var CompetitionsModel = Request.shared
    
    // Fetched competition's image
    @State private var image: UIImage?
    
    // Filtered competition's name
    @StateObject var CompsVM = CompetitionsVM()
    
    // Dark mode indicator
    @StateObject var DarkModeM = DarkModeModel.shared
    
    // Edit mode indicator
    @State var editMode:EditMode = .inactive
    
    // Liked competitions stored in swift data
    @Environment(\.modelContext) private var modelContext
    
    // Query for fetching stored competitions
    @Query(sort: \ListModel.code) private var likedCompetitions : [ListModel]
    
    // Current date's index
    var index:Int
    
    var body: some View {
        
        NavigationView {
            VStack{
                // Search bar for filtering competition's name
                TextField("Search competitions", text: $CompsVM.searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .autocorrectionDisabled(true)
                
                // Showing empty list if there is not any liked competition's
                if likedCompetitions.isEmpty{
                    Text("Your favourite competitions")
                        .foregroundStyle(Color.gray)
                        .font(.subheadline)
                }
                else{
                    // Loop over every competition fetched
                    List(CompetitionsModel.competitionsList){ competition in
                        // Check if the competition is liked
                        let check = likedCompetitions.filter{$0.code == competition.code}
                        
                        // Show liked competition
                        if !check.isEmpty{
                            showList(competition: competition, Model: CompetitionsModel)
                        }
                    }
                }
                
                // Loop over every fetched competition
                List(CompetitionsModel.competitionsList) { competition in
                    
                    // Check if competition is in liked competitions
                    let check = likedCompetitions.filter{$0.code == competition.code}
                    
                    // If competition is not in liked and passed name filter, show its details
                    if check.isEmpty && CompsVM.filteredCompetitions.contains(competition.code){
                        showList(competition: competition, Model: CompetitionsModel)
                    }
                    
                }
            }
            // Toggle edit mode on every list element
            .environment(\.editMode, $editMode)
            .navigationTitle("Competitions")
            .toolbar {
                // Button handling edit mode for liking each competition
                ToolbarItem(placement: .topBarTrailing){
                    Button(action: {
                        withAnimation {
                            // Toggle edit mode
                            editMode = editMode == .active ? .inactive : .active
                        }
                    }) {
                        // Edit's mode image
                        if editMode == .active{
                            Image(systemName: "heart.fill")
                        }
                        else {
                            Image(systemName: "heart")
                        }
                    }
                }
                // Button handling dark mode switching
                ToolbarItem(placement: .topBarLeading) {
                    Toggle("Dark mode",isOn: $DarkModeM.darkMode)
                }
            }
            
        }
    }
    
    // Store or delete competition's name of swift data
    private func toggleSelection(for item: String) {
        
        // Check, if competition's name is already stored
        let check = likedCompetitions.filter{$0.code == item}
        

        // Competition's name is not stored
        if check.isEmpty {
            let comp = ListModel(code: item)
            modelContext.insert(comp)
            
        } else {
            // Delete competiiton's name from swift data
            modelContext.delete(check.first!)
        }
    }
    
    
    // Shows competition's details
    private func showList(competition: Competitions, Model: Request) -> some View
    {
        NavigationLink(destination: CompetitionDetailView(competition: competition, Model: CompetitionsModel)) {
            HStack {
                // For liking this competition
                if editMode == .active {
                    let present = likedCompetitions.filter{$0.code == competition.code}
                    Image(systemName: present.isEmpty ? "heart" : "heart.fill")
                        .foregroundColor(.blue)
                        .onTapGesture {
                            // Move or delete from liked competition's list
                            toggleSelection(for: competition.code)
                        }
                }
                
                // Show competition's logo
                if let image = CompetitionsModel.leagueCrests[competition.id] {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                }
                // Unable to fetch logo, show default
                else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                }
                Text(competition.name)
                Spacer()
            }
            .onAppear {
                // Fetch competition's logo when this view appears
                if CompetitionsModel.leagueCrests[competition.id] == nil {
                    CompetitionsModel.fetchImage(from: competition.emblem ?? "default") { image in
                        if let image = image {
                            DispatchQueue.main.async {
                                CompetitionsModel.leagueCrests[competition.id] = image
                            }
                        }
                    }
                }
            }
        }
        
    }
}
    
    
// Competition's specific details
    struct CompetitionDetailView: View {
        // Competition to show its details
        let competition: Competitions
        
        // Competition list model
        @ObservedObject var Model: Request
        var defaultResult = "-:-"
        
        var body: some View {
            
            // Show its logo
            VStack(alignment: .center) {
                if let image = Model.leagueCrests[competition.id] {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                }
                
                // If match list is not empty, show every competition's match
                if let check = competition.matches {
                List {
                    Section(header: Text("Matches")) {
                            
                            ForEach(check) { match in
                                HStack {
                                    // Show team logos for this match
                                    if let homeImage = Model.teamCrests[match.homeTeam.id] {
                                        Image(uiImage: homeImage)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 30, height: 30)
                                    } else {
                                        Image(systemName: "photo")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 30, height: 30)
                                    }
                                    
                                    // Show home team's name
                                    Text("\(match.homeTeam.shortName)").frame(width: 80)
                                    
                                    Spacer()
                                    
                                    // Show details about match time
                                    VStack {
                                        Text("\(DateFormat().format(date: match.utcDate))")
                                        
                                        if match.status == "IN_PLAY" {
                                            Image(systemName: "clock")
                                        } else if match.status == "FINISHED" {
                                            Image(systemName: "flag.checkered")
                                        }
                                        else if (match.status == "TIMED") {
                                            Image(systemName: "calendar.badge.clock")
                                        }
                                        else {
                                            Image(systemName: "xmark.octagon")
                                        }
                                        
                                        // If match has stored its result, show details
                                        if let resultHome = match.score?.fullTime?.home, let resultAway = match.score?.fullTime?.away {
                                            Text("\(resultHome) : \(resultAway)")
                                        } else {
                                            Text(defaultResult)
                                        }
                                    }
                                    Spacer()
                                    
                                    // Show away team name
                                    Text("\(match.awayTeam.shortName)").frame(width: 80)
                                    //
                                    
                                    // Show away team logo
                                    if let awayImage = Model.teamCrests[match.awayTeam.id] {
                                        Image(uiImage: awayImage)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 30, height: 30)
                                    } else {
                                        Image(systemName: "photo")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 30, height: 30)
                                    }
                                }
                                .onAppear {
                                    // When this view appears, fetch team's logos
                                    if Model.teamCrests[match.homeTeam.id] == nil {
                                        Model.fetchImage(from: match.homeTeam.crest) { image in
                                            if let image = image {
                                                DispatchQueue.main.async {
                                                    Model.teamCrests[match.homeTeam.id] = image
                                                }
                                            }
                                        }
                                    }
                                    if Model.teamCrests[match.awayTeam.id] == nil {
                                        Model.fetchImage(from: match.awayTeam.crest) { image in
                                            if let image = image {
                                                DispatchQueue.main.async {
                                                    Model.teamCrests[match.awayTeam.id] = image
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                    }
                    
                }
                else{
                    // Match list is empty
                    Spacer()
                    Text("No matches on selected day")
                    Spacer()
                }
                
                // Navigate to competition's table
                NavigationLink(destination: TableView(competition: competition)) {
                    HStack{
                        Image(systemName: "trophy")
                        //
                        
                        Text("Table")
                            .padding()
                            .foregroundColor(.blue)
                    }
                    .padding()
                }
                
            }
            .navigationTitle(competition.name)
            
        }
        
    }

