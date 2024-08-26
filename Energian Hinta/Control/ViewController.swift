//
//  ViewController.swift
//  Energian Hinta
//
//  Created by Veikko Arvonen on 16.8.2024.
//

import UIKit

class ViewController: UIViewController, PriceSetDelegate {
    
//MARK: - IBOutlets
    
    @IBOutlet weak var cheapestPrice: UILabel!
    @IBOutlet weak var cheapestTime: UILabel!
    @IBOutlet weak var expensivePrice: UILabel!
    @IBOutlet weak var expensiveTime: UILabel!
    @IBOutlet weak var currentPrice: UILabel!
    @IBOutlet weak var currentTime: UILabel!
    
//MARK: - Variables and viewDidLoad
    
    var sheetLabels = [UILabel]()
    var sheetLines = [UIView]()
    var priceViews = [UIView]()
    var dailyPrices: [HoursPrice] = []
    var singlePriceToDisplay = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setPriceSheet()
        var priceManager2 = PriceManager2()
        priceManager2.delegate = self
        priceManager2.fetchDailyPrices(for: Date())
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        self.view.addGestureRecognizer(tapGesture)
        self.view.isUserInteractionEnabled = true
    }

//MARK: - Delegate Functions
    
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
            self.updateLowerLabels()
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
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(priceViewTapped(_:)))
                priceView.addGestureRecognizer(tapGesture)
                priceView.tag = i
                priceView.isUserInteractionEnabled = true
                priceViews.append(priceView)
            }
        } else {
            print("The array contains only nil values or is empty")
        }
    }
    
//MARK: - Handle interaction with price views
    
    @objc func priceViewTapped(_ sender: UITapGestureRecognizer) {
        if let tappedView = sender.view {
            singlePriceToDisplay.removeFromSuperview()
            
            for oneView in priceViews {
                oneView.backgroundColor = UIColor(named: "theme")
            }
            
            let ID = tappedView.tag
            
            guard ID < dailyPrices.count else { return }
            
            let priceToDisplay = dailyPrices[ID]
            let priceView = singlePriceView(for: priceToDisplay)
            
            singlePriceToDisplay = priceView
            view.addSubview(singlePriceToDisplay)
            singlePriceToDisplay.frame = CGRect(x: 50, y: 250, width: 80, height: 40)
            
            let sheetWidth = view.frame.width - 40
            let hourWidth = sheetWidth / 24
            let centerX = 30 + (hourWidth / 2) + (hourWidth * Double(ID))
            
            let priceHeight = sender.view?.frame.height
            let centerY = 465 - 30 - priceHeight! - 20
            
            singlePriceToDisplay.center = CGPoint(x: centerX, y: centerY)
            priceViews[ID].backgroundColor = .orange
            
        }
    }
    
//MARK: - Dismiss the single price view when screen is tapped
    
    @objc private func viewTapped() {
        singlePriceToDisplay.removeFromSuperview()
        for oneView in priceViews {
            oneView.backgroundColor = UIColor(named: "theme")
        }
    }
    
    
    //MARK: - Set max, min & current price labels
    
    func updateLowerLabels() {
        
        //Set the highest price
        if let highestPrice = dailyPrices.max(by: { ($0.price ?? 0) < ($1.price ?? 0) }) {
            expensivePrice.text = "\(highestPrice.price!) c/kWh"
            expensiveTime.text = "klo \(highestPrice.hour)"
        }
        
        //Set the lowest price
        if let lowestPrice = dailyPrices.min(by: { ($0.price ?? 0) < ($1.price ?? 0) }) {
            cheapestPrice.text = "\(lowestPrice.price!) c/kWh"
            cheapestTime.text = "klo \(lowestPrice.hour)"
        }
        
        let now = Date()
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "Europe/Helsinki")!
        let hour = calendar.component(.hour, from: now)
        
        guard hour < dailyPrices.count else { return }
        
        let priceNow = dailyPrices[hour]
        
        // Update the current price label
        if let priceForLabel = priceNow.price {
            currentPrice.text = "\(priceForLabel) c/kWh"
        } else {
            currentPrice.text = "- c/kWh"
        }
        currentTime.text = "klo \(priceNow.hour)"
        
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
 
//MARK: - Single price view
    
    private func singlePriceView(for price: HoursPrice) -> UIView {
        let priceView = UIView()
        priceView.backgroundColor = .white
        priceView.clipsToBounds = true
        priceView.layer.cornerRadius = 5.0
        
        priceView.layer.shadowColor = UIColor.black.cgColor  // Color of the shadow
        priceView.layer.shadowOpacity = 0.5  // Opacity of the shadow (0.0 to 1.0)
        priceView.layer.shadowOffset = CGSize(width: 0, height: 2)  // Position of the shadow
        priceView.layer.shadowRadius = 4  // Blur radius of the shadow
        priceView.layer.masksToBounds = false
        
        let hourString = "klo \(price.hour)"
        
        let priceString: String = {
            if let p = price.price {
                return "\(p) c/kWh"
            } else {
                return "- c/kWh"
            }
        }()
        
        let hourLabel = UILabel()
        hourLabel.text = hourString
        hourLabel.textAlignment = .center
        hourLabel.font = UIFont(name: "optima", size: 15) ?? UIFont.systemFont(ofSize: 15)
        hourLabel.translatesAutoresizingMaskIntoConstraints = false
        priceView.addSubview(hourLabel)
        
        let priceLabel = UILabel()
        priceLabel.text = priceString
        priceLabel.textAlignment = .center
        priceLabel.font = UIFont(name: "optima", size: 12) ?? UIFont.systemFont(ofSize: 12)
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        priceView.addSubview(priceLabel)
        
        NSLayoutConstraint.activate([
            hourLabel.topAnchor.constraint(equalTo: priceView.topAnchor),
            hourLabel.leadingAnchor.constraint(equalTo: priceView.leadingAnchor),
            hourLabel.trailingAnchor.constraint(equalTo: priceView.trailingAnchor),
            hourLabel.heightAnchor.constraint(equalToConstant: 20.0),
            
            priceLabel.topAnchor.constraint(equalTo: hourLabel.bottomAnchor),
            priceLabel.leadingAnchor.constraint(equalTo: priceView.leadingAnchor),
            priceLabel.trailingAnchor.constraint(equalTo: priceView.trailingAnchor),
            priceLabel.bottomAnchor.constraint(equalTo: priceView.bottomAnchor),
            priceLabel.heightAnchor.constraint(equalToConstant: 20.0)
        ])
        
        return priceView
    }
    
}


