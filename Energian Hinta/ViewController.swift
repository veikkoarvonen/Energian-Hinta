//
//  ViewController.swift
//  Energian Hinta
//
//  Created by Veikko Arvonen on 16.8.2024.
//

import UIKit

class ViewController: UIViewController, PriceSetDelegate {
    
//MARK: - Variables and viewDidLoad
    
    var sheetLabels = [UILabel]()
    var sheetLines = [UIView]()
    var priceViews = [UIView]()
    var dailyPrices: [HoursPrice] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setPriceSheet()
        var priceManager2 = PriceManager2()
        priceManager2.delegate = self
        priceManager2.fetchDailyPrices(for: Date())
    }

//MARK: - Functions
    
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
   
//MARK: Display fetched prices
    
    func displayDailyPrices(prices: [Double?]) {
        
        //Determine sheet range
        
        if let highestPrice = prices.compactMap({ $0 }).max() {
            
            var maxPrice: Double = 0
            while maxPrice < highestPrice {
                maxPrice += 5
            }
            
            for i in 0..<sheetLabels.count {
                let priceForLabel = maxPrice / 5 * Double(i)
                sheetLabels[i].text = "\(Int(priceForLabel))"
            }
          
        //Make UIViews for each hour's price
            
            let screenWidth = view.frame.width
            let sheetWidth = screenWidth - 40
            let hourWidth = sheetWidth / 24
            
            for i in 0..<prices.count {
                
                //Set the view
                let priceView = UIView()
                priceView.backgroundColor = UIColor(named: "theme")
                view.addSubview(priceView)
                
                //Determine and set frame
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

//MARK: - Set price sheet

extension ViewController {
    
    private func setPriceSheet() {
        
        let labelYPositions = [450.0, 400.0, 350.0, 300.0, 250.0, 200.0]
        let labelTexts = ["","","","","",""]
        
        guard labelYPositions.count == labelTexts.count else { return }
        
        //Number labels
        
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
        
        //Sheet lines
        
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
        
        //Hour labels
        
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
    
}


