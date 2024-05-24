import Foundation
import SwiftUI
import Combine
import SwiftData


// Structures for storing fetched data to according variable
struct Match: Codable,Identifiable {
    var homeTeam: Team
    var awayTeam: Team
    var utcDate: String
    let id: Int
    let status: String
    let minute: String?
    let goals: [Goals]?
    let score: Score?
    let competition: Competitions
}

struct Team: Codable {
    let shortName: String
    let crest: String
    let id: Int
    var image: Data?
    
}

struct Score: Codable {
    let fullTime: FullTime?
    let winner: String?
}

struct FullTime: Codable {
    let home: Int?
    let away: Int?
}

struct Goals: Codable,Identifiable {
    let minute: Int
    let scorer: Scorer?
    var id = UUID()
}

struct Scorer: Codable {
    let name: String?
}

struct Competitions: Codable,Identifiable {
    let id: Int
    let name: String
    let emblem: String?
    let code: String
    var matches: [Match]?
}

struct Standings: Codable,Identifiable {
    let table: [Table]
    let type: String
    var id: String {type}
}

struct Table: Codable,Identifiable {
    let position:Int
    var id:Int {position}
    let points: Int
    let team: Teams
}
struct Teams:Codable {
    let id: Int
    let name: String
}

class Request: ObservableObject {
    
    static let shared = Request()
    
    // Indicates if fetching is still in process
    @Published var fetching = true
    
    // List of matches for each competition
    var matches: [Match] = []
    
    // Table for each competition
    private var table: [String: Standings] = [:]
    
    // Logos of each competition
    @Published var leagueCrests: [Int: UIImage] = [:]
    
    // Logos of each team
    @Published var teamCrests: [Int: UIImage] = [:]
    
    // Final list of fetched competitions with its data
    @Published var competitionsList: [Competitions] = []
        
    private var cancellables = Set<AnyCancellable>()
    
    // Api token
    private let apiToken = "1ee022aa3fcb45f382a51409c3d02589"
    
    // Fetch specific data for API
    private func makeRequest<T: Decodable>(urlString: String, jsonKey: String, type: T.Type, completion: @escaping ([T]) -> Void) {
            // Set API url
            guard let url = URL(string: urlString) else {
                print("Invalid URL")
                return
            }
            
            // Set url request
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            
            // Set request parameters
            let headers = [
                "X-Auth-Token": apiToken,
                "X-Unfold-Goals": "true"
            ]
            headers.forEach { key, value in
                request.addValue(value, forHTTPHeaderField: key)
            }
            
            // Create task for request
            URLSession.shared.dataTask(with: request) { data, response, error in
                // Check for an error
                if let error = error {
                    print("Error:", error)
                    return
                }
                
                // Check if any data were received
                guard let data = data else {
                    print("No data received")
                    return
                }
                
                do {
                    // Serialize data into dictionary
                    let jsonDictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    
                    // Check for the passed key in dictinary
                    guard let jsonArray = jsonDictionary?[jsonKey] as? [[String: Any]] else {
                        print("Error: '\(jsonKey)' key not found in JSON dictionary")
                        return
                    }
                    
                    // Select decoder
                    let decoder = JSONDecoder()
                    
                    // Decode json array into decoded array
                    let result = try jsonArray.map {
                        try decoder.decode(T.self, from: JSONSerialization.data(withJSONObject: $0, options: []))
                    }
                    
                    DispatchQueue.main.async {
                        // Return result as a completion of this function
                        completion(result)
                    }
                } catch {
                    // Catch error with json decoding
                    print("Error parsing JSON:", error)
                }
            }.resume() // Start request task
        }
    
    
    // Make request for fetching competitions
    func fetchCompetitions() {
        makeRequest(urlString: "https://api.football-data.org/v4/competitions", jsonKey: "competitions", type: Competitions.self) { competitions in
                    // Store fetched result
                    self.competitionsList = competitions
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        // Change value to uncover FetchView after 4 seconds of completion
                        self.fetching = false
                    }
                  
                }
    }
    
    // Setup request url according to selected day
    func fetchMatches(day:Int) {
        var Day:String
        
        switch(day){
            case 0:
                Day = "?date=YESTERDAY"
            case 1:
                Day = ""
            case 2:
                Day = "?date=TOMORROW"
            default:
                Day = ""
        }
        
        makeRequest(urlString: "https://api.football-data.org/v4/matches" + Day, jsonKey: "matches", type: Match.self) { matches in
  
                // Clear already stored match data for each competition
                for index in self.competitionsList.indices {
                    
                    self.competitionsList[index].matches?.removeAll()
                    }
            
                // Connect match to concrete competition
                self.organizeMatches(matches: matches)
            
        }
    }
    
    
    // Fetch table for selected competition
    func fetchTable(code: String, completion: @escaping ([String:Standings]) -> Void) {
        let url = "https://api.football-data.org/v4/competitions/" + code + "/standings"
        makeRequest(urlString: url, jsonKey: "standings", type: Standings.self) { standings in
            
            // Set fetched data at according place by competition's code
            self.table[code] = standings.first
            
            // Return table
            completion(self.table)
        }
    }
    
    //
    // Connects match to concrete competition according to its id
    private func organizeMatches(matches: [Match]){
        
        var competitionsDictionary: [Int: [Match]] = [:]

        // Assign match to according competition's dictionary by id
        for match in matches {
            if competitionsDictionary[match.competition.id] != nil {
                competitionsDictionary[match.competition.id]?.append(match)
            } else {
                competitionsDictionary[match.competition.id] = [match]
            }
        }

        // Assign matches to the according competition in competition list
        for (competitionId, matches) in competitionsDictionary {
            if let index = self.competitionsList.firstIndex(where: { $0.id == competitionId }) {
                self.competitionsList[index].matches = matches
            }
        }

        
    }
    
    // Fetch image from selected url
    func fetchImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        // If error occurs with url, return default image
        guard let url = URL(string: urlString) else {
            completion(UIImage(systemName: "camera.metering.unknown"))
            return
        }
        
        // Get image from url
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            
            // Check for valid image fetched
            guard let image = UIImage(data: data) else {
                completion(UIImage(systemName: "camera.metering.unknown"))
                return
            }
            
            // Return fetched image
            completion(image)
        }.resume() // Start task
    }
}

// Persistent data for storing liked competition's code
@Model
class ListModel {
    //
    var code:String
    
    var id: UUID
    
    init(code:String){
        
        self.code = code
        self.id = UUID()
    }
}

// Indicates dark mode
class DarkModeModel: ObservableObject{
    @Published var darkMode = false
    
    static let shared = DarkModeModel()
    
}
