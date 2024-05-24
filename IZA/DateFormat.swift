//
//  DateFormat.swift
//  IZA
//
//  Created by Adam Nieslanik on 16.05.2024.
//

import Foundation


// Format match time for short style in right time zone
class DateFormat {
    
    func format(date:String)-> String{
        // Format of parsed date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        // Return date in needed format
        if let date = dateFormatter.date(from: date) {
            
            // Returned format
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "HH:mm"
            
            let formattedDateString = outputFormatter.string(from: date)
            return formattedDateString
        }
        return "?"
    }
}
