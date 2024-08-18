//
//  Converter.swift
//  Energian Hinta
//
//  Created by Veikko Arvonen on 16.8.2024.
//

import Foundation

protocol PriceSetDelegate: AnyObject {
    func setLabel(price: Double?)
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
                    delegate?.setLabel(price: jsonResult)
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
    
}

struct ElectricityPrice: Codable {
    var price: Double
}
