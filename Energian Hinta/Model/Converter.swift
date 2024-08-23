//
//  Converter.swift
//  Energian Hinta
//
//  Created by Veikko Arvonen on 16.8.2024.
//

import Foundation

//MARK: - Protocol for delegate communication and custom codable structs

protocol PriceSetDelegate: AnyObject {
    func passFetchedPrice(price: HoursPrice)
    func sortFetchedPrices()
}

struct ElectricityPrice: Codable {
    var price: Double
}

struct HoursPrice: Codable {
    var hour: String
    var price: Double?
}

//MARK: - Fetch prices and parse JSON

struct PriceManager2 {
    let hourStrings = ["00", "01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23"]
    let formatter = DateFormatter()
    var delegate: PriceSetDelegate?
 
    
    //Initialize request for each hour of the day
    func fetchDailyPrices(for date: Date) {
        let dispatchGroup = DispatchGroup()
        
        for i in 0..<hourStrings.count {
            dispatchGroup.enter()
            performRequest(for: date, hour: hourStrings[i])
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            delegate?.sortFetchedPrices()
        }
    }
    
    //Perform request
    func performRequest(for date: Date, hour: String) {
        formatter.dateFormat = "YYYY-MM-dd"
        let dateString = formatter.string(from: date)
        let hourString = hour
        let URLstring = "https://api.porssisahko.net/v1/price.json?date=\(dateString)&hour=\(hourString)"
        if let url = URL(string: URLstring) {
            let session = URLSession(configuration: .default)
            let task = session.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    print("Error in URL session")
                    let failedPrice = HoursPrice(hour: hour, price: nil)
                    delegate?.passFetchedPrice(price: failedPrice)
                    return
                }
                if let safeData = data {
                    parseLatestJSON(data: safeData, hour: hour)
                } else {
                    let failedPrice = HoursPrice(hour: hour, price: nil)
                    delegate?.passFetchedPrice(price: failedPrice)
                }
            }
            task.resume()
        }
    }
    
    //Parse JSON results and pass the to View Controller
    func parseLatestJSON(data: Data, hour: String) {
        let decoder = JSONDecoder()
        do {
            let decodedData = try decoder.decode(ElectricityPrice.self, from: data)
            let price = decodedData.price
            let fetchedPrice = HoursPrice(hour: hour, price: price)
            delegate?.passFetchedPrice(price: fetchedPrice)
        } catch {
            let failedPrice = HoursPrice(hour: hour, price: nil)
            delegate?.passFetchedPrice(price: failedPrice)
        }
    }
    
    
}
