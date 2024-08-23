//
//  Converter.swift
//  Energian Hinta
//
//  Created by Veikko Arvonen on 16.8.2024.
//

import Foundation

protocol PriceSetDelegate: AnyObject {
    func setPrice(price: Double?)
    func updateSheet(price: Double?)
    func updatePriceArray(prices: [HourlyPrice])
    func passFetchedPrice(price: HoursPrice)
    func sortFetchedPrices()
}

struct PriceManager {
    let formatter = DateFormatter()
    var delegate: PriceSetDelegate?
    
    func fetchPrice(from date: Date) {
        formatter.dateFormat = "YYYY-MM-dd"
        let dateString = formatter.string(from: date)
        formatter.dateFormat = "HH"
        let hourstring = formatter.string(from: date)
        let URL = "https://api.porssisahko.net/v1/price.json?date=\(dateString)&hour=\(hourstring)"
        performRequest(with: URL)
    }
    
    func performRequest(with url: String) {
        if let url = URL(string: url) {
            let session = URLSession(configuration: .default)
            let task = session.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    print("Error in URL session")
                    return
                }
                if let safeData = data {
                    let jsonResult = parseJSON(data: safeData)
                    delegate?.setPrice(price: jsonResult)
                    delegate?.updateSheet(price: jsonResult)
                }
            }
            task.resume()
        }
    }
    
    func parseJSON(data: Data) -> Double? {
        let decoder = JSONDecoder()
        do {
            let decodedData = try decoder.decode(ElectricityPrice.self, from: data)
            let price = decodedData.price
            return price
        } catch {
            return nil
        }
    }
    
    
    func fetchLatestPrices() {
        let URL = "https://api.porssisahko.net/v1/latest-prices.json"
        performDayRequest(with: URL)
    }
    
    func performDayRequest(with url: String) {
        if let url = URL(string: url) {
            let session = URLSession(configuration: .default)
            let task = session.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    print("Error in day URL session")
                    return
                }
                
                
                
                if let safeData = data {
                    parseLatestJSON(data: safeData)
                }
            }
            task.resume()
        }
    }
    
    func parseLatestJSON(data: Data) {
        let decoder = JSONDecoder()
        do {
            let decodedData = try decoder.decode(ElectricityPriceResponse.self, from: data)
        
            delegate?.updatePriceArray(prices: decodedData.prices)
        } catch {
            print("Could not parse latest JSON")
        }
    }
    
}

struct ElectricityPrice: Codable {
    var price: Double
}

struct ElectricityPriceResponse: Codable {
    let prices: [HourlyPrice]
}

struct HourlyPrice: Codable {
    let price: Double
    let startDate: String
    let endDate: String
}

struct HoursPrice: Codable {
    var hour: String
    var price: Double?
}

struct PriceManager2 {
    let hourStrings = ["00", "01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23"]
    let formatter = DateFormatter()
    var JSONresults: [HoursPrice] = []
    var delegate: PriceSetDelegate?
    
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
