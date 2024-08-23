//
//  ViewController.swift
//  Energian Hinta
//
//  Created by Veikko Arvonen on 16.8.2024.
//

import UIKit

class ViewController: UIViewController, PriceSetDelegate {
    
    
    var sheetLabels = [UILabel]()
    var sheetLines = [UIView]()
    var pricesToDisplay = [HourlyPrice]()
    var priceViews = [UIView]()
    
    let labelYPositions = [450.0, 400.0, 350.0, 300.0, 250.0, 200.0]
    let labelTexts = ["","","","","",""]
    
    var dailyPrices: [HoursPrice] = []
    
    @IBOutlet weak var testLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setPriceSheet()
        var priceManager = PriceManager()
        priceManager.delegate = self
        var priceManager2 = PriceManager2()
        priceManager2.delegate = self
        priceManager2.fetchDailyPrices(for: Date())
        //priceManager.fetchPrice(from: Date())
        //priceManager.fetchLatestPrices()

    }

    private func setPriceSheet() {
        
        guard labelYPositions.count == labelTexts.count else { return }
        
        for i in 0..<labelYPositions.count {
            let label = UILabel()
            label.text = labelTexts[i]
            label.textColor = .systemGray
            label.textAlignment = .center
            label.font = UIFont(name: "Optima", size: 15.0)
            view.addSubview(label)
            let y = labelYPositions[i]
            label.frame = CGRect(x: 0, y: y, width: 30, height: 30)
            sheetLabels.append(label)
        }
        
        for i in 0..<labelYPositions.count {
            
            let line = UIView()
            line.backgroundColor = .systemGray3
            view.addSubview(line)
            let x = 30.0
            line.frame = CGRect(x: x, y: 10, width: view.frame.width - x - 10.0, height: 1)
            let center = sheetLabels[i].center.y
            line.center.y = center
            sheetLines.append(line)
            
        }
        
        let sheetWidth = view.frame.width - 40
        let hourWidth = sheetWidth / 24
        
        for i in 0..<24 {
            let label = UILabel()
            label.text = "\(i)"
            label.textColor = .systemGray
            label.textAlignment = .center
            label.font = UIFont(name: "Optima", size: 10.0)
            view.addSubview(label)
            let x = 35 + (hourWidth / 2) + (hourWidth * Double(i))
            label.frame = CGRect(x: 10, y: 470, width: hourWidth, height: 30)
            label.center.x = x
        }
        
    }
    
    
    func passFetchedPrice(price: HoursPrice) {
        DispatchQueue.main.async {
            self.dailyPrices.append(price)
        }
    }
    
    func sortFetchedPrices() {
        DispatchQueue.main.async {
            self.dailyPrices.sort { $0.hour < $1.hour }
            var prices: [Double?] {
                var p: [Double?] = []
                for price in self.dailyPrices {
                    p.append(price.price)
                }
                return p
            }
            self.displayDailyPrices(prices: prices)
        }
    }
    
    
    
    func setPrice(price: Double?) {
        DispatchQueue.main.async {
            if let p = price {
                var maxPrice: Double = 5.0
                
                while p > maxPrice {
                    maxPrice += 5
                }
                
                guard self.sheetLines.count >= 2 else { return }
                
                let priceView = UIView()
                priceView.backgroundColor = UIColor(named: "theme")
                self.view.addSubview(priceView)
                
                let x = 100.0
                let sheetHeight = 250.0
                let heightPercentage = p / maxPrice
                let finalHeight = sheetHeight * heightPercentage
                let y = (self.sheetLines.first?.center.y)! - finalHeight
                let width = self.view.frame.width - 2 * x
                
            
                priceView.frame = CGRect(x: x, y: y, width: width, height: finalHeight)
                
            }
        }
    }
    
    func updateSheet(price: Double?) {
        DispatchQueue.main.async {
            if let p = price {
                
                var maxPrice: Double = 5.0
                
                while p > maxPrice {
                    maxPrice += 5
                }
                
                for i in 0..<self.sheetLabels.count {
                    let d = Double(i)
                    let sheetPrice = maxPrice / 5.0 * d
                    self.sheetLabels[i].text = "\(Int(sheetPrice))"
                }
                
                
            }
        }
    }
    
    func updatePriceArray(prices: [HourlyPrice]) {
        DispatchQueue.main.async {
            
            let formatter = DateFormatter()
            formatter.dateFormat = "YYYY-MM-dd"
            
            let todaysString = formatter.string(from: Date())
            
            for i in 0..<prices.count {
                if prices[i].startDate.contains(todaysString) {
                    self.pricesToDisplay.append(prices[i])
                }
            }
            self.getDailyPrices()
        }
    }
    
    func getDailyPrices() {
        var prices: [Double?] = []
        
        let priceFilters = ["00:00:00", "01:00:00", "02:00:00", "03:00:00", "04:00:00", "05:00:00", "06:00:00", "07:00:00", "08:00:00", "09:00:00", "10:00:00", "11:00:00", "12:00:00", "13:00:00", "14:00:00", "15:00:00", "16:00:00", "17:00:00", "18:00:00", "19:00:00", "20:00:00", "21:00:00", "22:00:00", "23:00:00"]

        for i in 0..<priceFilters.count {
            
            let filter = priceFilters[i]
            if let p = pricesToDisplay.first(where:  { $0.startDate.contains(filter) }) {
                prices.append(p.price)
            } else {
                prices.append(nil)
            }
        }
        print(pricesToDisplay)
        displayDailyPrices(prices: prices)
        
    }
    
    func displayDailyPrices(prices: [Double?]) {
        
        if let highestPrice = prices.compactMap({ $0 }).max() {
            
            var maxPrice: Double = 0
            while maxPrice < highestPrice {
                maxPrice += 5
            }
            
            for i in 0..<sheetLabels.count {
                let priceForLabel = maxPrice / 5 * Double(i)
                sheetLabels[i].text = "\(Int(priceForLabel))"
            }
            
            let screenWidth = view.frame.width
            let sheetWidth = screenWidth - 40
            let hourWidth = sheetWidth / 24
            
            let viewWidth = hourWidth - 5
            
            for i in 0..<prices.count {
                let priceView = UIView()
                priceView.backgroundColor = UIColor(named: "theme")
                view.addSubview(priceView)
                
                let viewWidth = hourWidth - 5
                let centerX = 35 + (hourWidth / 2) + (hourWidth * Double(i))
                
                var y: Double {
                    if let p = prices[i] {
                        let h = 250 * (p / maxPrice)
                        return 465 - h
                    } else {
                        return 465
                    }
                }
                
                var height: Double {
                    if let p = prices[i] {
                        let h = 250 * (p / maxPrice)
                        return h
                    } else {
                        return 1
                    }
                }
                
                priceView.frame = CGRect(x: 30, y: y, width: viewWidth, height: height)
                priceView.center.x = centerX
                
                
            }
            
            
            
            
        } else {
            print("The array contains only nil values or is empty")
        }
        
    }
    
    
    
}




