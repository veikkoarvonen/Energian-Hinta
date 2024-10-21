//
//  ViewController.swift
//  Energian Hinta
//
//  Created by Veikko Arvonen on 16.8.2024.
//

import UIKit

class ViewController: UIViewController, PriceSetDelegate {
    
    //MARK: - IBOutlets
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var cheapestPrice: UILabel!
    @IBOutlet weak var cheapestTime: UILabel!
    @IBOutlet weak var expensivePrice: UILabel!
    @IBOutlet weak var expensiveTime: UILabel!
    @IBOutlet weak var currentPrice: UILabel!
    @IBOutlet weak var currentTime: UILabel!
    
    @IBOutlet weak var reloadButton: UIButton!
    @IBAction func reloadPressed(_ sender: UIButton) {
        var comps = DateComponents()
        comps.year = 2024
        comps.month = 10
        comps.day = 15
        let date = Calendar.current.date(from: comps)
        priceFetcher.fetchDailyPrices(for: date!)
        reloadButton.isHidden = true
        reloadButton.isUserInteractionEnabled = false
    }
    
    //MARK: - Variables
    
    var priceFetcher = PriceFetcher()
    
    var sheetLines: [UIView] = []
    var hourLabels: [UILabel] = []
    var priceLabels: [UILabel] = []
    var priceViews: [UIView] = []
    
    var hasSetUI = false
    var isPortrait = Bool()
    
    var dailyPrices: [HoursPrice] = []
    
    var singlePricelabel = UILabel()

//MARK: - Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        priceFetcher.delegate = self
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        self.view.addGestureRecognizer(tapGesture)
        self.view.isUserInteractionEnabled = true
    }
    
    override func viewDidLayoutSubviews() {
        if !hasSetUI {
            initializeUI()
            checkOrientation()
            updateUI(isPortrait: isPortrait)
            hasSetUI = true
            
            var comps = DateComponents()
            comps.year = 2024
            comps.month = 10
            comps.day = 15
            let date = Calendar.current.date(from: comps)
            
            priceFetcher.fetchDailyPrices(for: Date())
        }
    }
    
    @objc func priceViewTapped(_ sender: UITapGestureRecognizer) {
        guard let tappedView = sender.view else { return }
        
        for v in priceViews {
            v.backgroundColor = UIColor(named: "theme")
        }
        let index = tappedView.tag
        priceViews[index].backgroundColor = .orange
        
        guard dailyPrices.count > index else { return }
        
        if let price = dailyPrices[index].price {
            singlePricelabel.isHidden = false
            singlePricelabel.center.x = hourLabels[index].center.x
            singlePricelabel.center.y = priceViews[index].frame.minY - 20
            singlePricelabel.text = "\(price) c/kWh"
        }
        
    }
    
    @objc private func viewTapped() {
        refreshSinglePriceView()
    }
    
    func refreshSinglePriceView() {
        for oneView in priceViews {
            oneView.backgroundColor = UIColor(named: "theme")
        }
        singlePricelabel.isHidden = true
    }
 
//MARK: - Deal with orientation changes
    
    //Handle orientation changes
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        refreshSinglePriceView()
        coordinator.animate(alongsideTransition: nil) { [self] _ in
            checkOrientation()
            updateUI(isPortrait: isPortrait)
            updatePriceUI(isPortrait: isPortrait, withAnimation: false)
            
        }
    }
    
    //Check orientation
    func checkOrientation() {
        let screenSize = UIScreen.main.bounds
        if screenSize.width > screenSize.height {
            print("Landscape mode")
            isPortrait = false
        } else {
            print("Portrait mode")
            isPortrait = true
        }
    }
    
//MARK: - Delegate functions from price fetcher
    
    func passFetchedPrice(price: HoursPrice) {
        DispatchQueue.main.async {
            self.dailyPrices.append(price)
            print("Passing fetched price: \(price)")
        }
    }
    
    func sortFetchedPrices() {
        DispatchQueue.main.async { [self] in
            dailyPrices.sort { $0.hour < $1.hour }
            updatePriceUI(isPortrait: isPortrait, withAnimation: true)
        }
    }

//MARK: - Update price displaying UI
    
    
    func updatePriceUI(isPortrait: Bool, withAnimation animate: Bool) {
        guard dailyPrices.count != 0 else {
            print("No prices in price array, exiting price UI function")
            didFailWithPriceFetch()
            return
        }
        
        let maxPrice = dailyPrices.compactMap({ $0.price != nil ? $0 : nil }).max(by: { $0.price! < $1.price! })
        let minPrice = dailyPrices.compactMap({ $0.price != nil ? $0 : nil }).min(by: { $0.price! < $1.price! })
        
        createSheetPriceRange(maxPrice: maxPrice)
        showMaxPrice(maxPrice: maxPrice)
        showMinPrice(minPrice: minPrice)
        showCurrentPrice()
        displayPrices(withAnimation: animate, maxPrice: maxPrice)
        
        
    }
    
    func displayPrices(withAnimation animate: Bool, maxPrice: HoursPrice?) {
        guard let maxP = maxPrice else { return }
        guard let p = maxP.price else { return }
        guard priceViews.count == hourLabels.count else {
            print("Cannot create priceviews. Count does not match hour label count")
            return
        }
        
        var maxPriceInSheet: Double = 5
        while maxPriceInSheet < p {
            maxPriceInSheet += 5
        }
        
        let sheetTopY = sheetLines.first!.center.y
        let sheetBottomY = sheetLines.last!.center.y
        
        let sheetHeight = sheetBottomY - sheetTopY
        let sheetWidth = sheetLines.first!.frame.width
        
        print(sheetHeight)
        print(maxPriceInSheet)
        
        for i in 0..<priceViews.count {
            guard i < dailyPrices.count else { continue }
            guard let price = dailyPrices[i].price else { continue }
            
            if price > 0 {
                
                let relativeHeight = price / maxPriceInSheet
                let height = sheetHeight * relativeHeight
                let width = sheetWidth / 24 - 5
                let y = sheetBottomY - height
                
                priceViews[i].frame = CGRect(x: 0, y: y, width: width, height: height)
                priceViews[i].center.x = hourLabels[i].center.x
                
                if animate {
                    priceViews[i].frame.size.height = 1
                    priceViews[i].frame.origin.y = sheetBottomY
                    UIView.animate(withDuration: 0.5) {
                        self.priceViews[i].frame.size.height = height
                        self.priceViews[i].frame.origin.y = y
                    }
                }
            } else {
                let absolutePrice = abs(price)
                let relativeHeight = absolutePrice / maxPriceInSheet
                let height = sheetHeight * relativeHeight
                let width = sheetWidth / 24 - 5
                let y = sheetBottomY
                
                priceViews[i].frame = CGRect(x: 0, y: y, width: width, height: height)
                priceViews[i].center.x = hourLabels[i].center.x
                
                if animate {
                    priceViews[i].frame.size.height = 1
                    UIView.animate(withDuration: 0.5) {
                        self.priceViews[i].frame.size.height = height
                    }
                }
            }
        }
      
    }
    
    
    func didFailWithPriceFetch() {
        reloadButton.isHidden = false
        reloadButton.isUserInteractionEnabled = true
    }
    
//MARK: - Generate sheet range & show max min current price
    
    func createSheetPriceRange(maxPrice: HoursPrice?) {
        if let p = dailyPrices.compactMap({ $0.price != nil ? $0 : nil }).max(by: { $0.price! < $1.price! }) {
            var maxPriceInSheet: Double = 5
            while maxPriceInSheet < p.price! {
                maxPriceInSheet += 5
            }
            
            for i in 0..<priceLabels.count {
                var width: Int {
                    if isPortrait {
                        return 25
                    } else {
                        return 55
                    }
                }
                let priceForLabel = Int(maxPriceInSheet) - i * (Int(maxPriceInSheet) / 5)
                
                priceLabels[i].text = "\(priceForLabel)"
                priceLabels[i].frame = CGRect(x: 0, y: 0, width: width, height: 20)
                priceLabels[i].center.y = sheetLines[i].center.y
            }
        } else {
            print("Failed to identify max price due to nil value, cannot create sheet range")
        }
    }
    
    func showMaxPrice(maxPrice: HoursPrice?) {
        if let p = maxPrice {
            let roundedMaxPrice = round(p.price! * 100) / 100
            expensivePrice.text = "\(roundedMaxPrice) c/kWh"
            expensiveTime.text = "klo \(p.hour)"
            
        } else {
            print("Failed to fetch the max price")
        }
    }
    
    func showMinPrice(minPrice: HoursPrice?) {
        if let p = dailyPrices.compactMap({ $0.price != nil ? $0 : nil }).min(by: { $0.price! < $1.price! }) {
            let roundedMinPrice = round(p.price! * 100) / 100
            cheapestPrice.text = "\(roundedMinPrice) c/kWh"
            cheapestTime.text = "klo \(p.hour)"
        } else {
            print("Failed to fetch the min price")
        }
    }
    
    func showCurrentPrice() {
        let now = Date()
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "Europe/Helsinki")!
        let hour = calendar.component(.hour, from: now)
        
        if hour < dailyPrices.count  {
            let priceNow = dailyPrices[hour]
            if let price = priceNow.price {
                let roundedPrice = round(price * 100) / 100
                currentPrice.text = "\(roundedPrice) c/kWh"
                currentTime.text = "klo \(hour)"
            }
        }
    }
    
}

extension ViewController {
    
    //MARK: - Finish UI programatically
    
    //Create and add rest of the elements
    private func initializeUI() {
        
        reloadButton.isHidden = true
        reloadButton.isUserInteractionEnabled = false
        
        //Lines in the price sheet
        for _ in 0...5 {
            let line = UIView()
            line.backgroundColor = .systemGray3
            view.addSubview(line)
            sheetLines.append(line)
            
            let label = UILabel()
            label.textColor = .systemGray2
            label.font = UIFont(name: "optima", size: 10)
            label.textAlignment = .center
            label.text = ""
            view.addSubview(label)
            priceLabels.append(label)
        }
        
        //Labels for hour numbers
        for i in 0...23 {
            let label = UILabel()
            label.textColor = .systemGray2
            label.font = UIFont(name: "optima", size: 10)
            label.textAlignment = .center
            label.text = "\(i)"
            view.addSubview(label)
            hourLabels.append(label)
        }
        
        //view's for displaying the prices
        for i in 0...23 {
            let priceView = UIView()
            priceView.backgroundColor = UIColor(named: "theme")
            priceView.tag = i
            view.addSubview(priceView)
            priceViews.append(priceView)
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(priceViewTapped(_:)))
            priceView.addGestureRecognizer(tapGesture)
            priceView.isUserInteractionEnabled = true
        }
        
    }
    
//MARK: - Updating UI
    
    //Update positions responsively
    private func updateUI(isPortrait: Bool) {
        
        if isPortrait {
            view.backgroundColor = UIColor(named: "theme")
            headerLabel.textAlignment = .left
        } else {
            view.backgroundColor = .white
            headerLabel.textAlignment = .center
        }
        
        var sheetXcord: Int {
            if isPortrait {
                return 25
            } else {
                return 55
            }
        }
        
        var sheetWidth: Int {
            if isPortrait {
                return Int(view.frame.width) - sheetXcord - 5
            } else {
                return Int(view.frame.width) - sheetXcord - 55
            }
        }
        
        var sheetTopYcord: CGFloat {
            if isPortrait {
                return view.safeAreaInsets.top + headerLabel.frame.height + 50
            } else {
                return headerLabel.frame.height + 30 + 25
            }
        }
        
        var sheetHeight: Int {
            if isPortrait {
                return 250
            } else {
                return Int(view.frame.height - headerLabel.frame.height - 100)
            }
        }
        
        var sheetlineYcords: [Int] = []
        for i in 0..<sheetLines.count {
            let y = Int(sheetTopYcord) + (sheetHeight / 5) * i
            sheetlineYcords.append(y)
        }
        
        for i in 0..<sheetLines.count {
            sheetLines[i].frame = CGRect(x: sheetXcord, y: sheetlineYcords[i], width: sheetWidth, height: 1)
        }
        
        //let c: [UIColor] = [.red, .orange, .red, .orange,.red, .orange,.red, .orange,.red, .orange,.red, .orange,.red, .orange,.red, .orange,.red, .orange,.red, .orange,.red, .orange,.red, .orange,.red, .orange,]
        
        for i in 0..<hourLabels.count {
            let x = sheetXcord + (sheetWidth / 24) * i
            //hourLabels[i].backgroundColor = c[i]
            let y = Int(sheetTopYcord) + sheetHeight + 25
            hourLabels[i].frame = CGRect(x: x, y: y, width: sheetWidth / 24, height: 20)
        }
        
        let label = UILabel()
        label.font = UIFont(name: "optima", size: 12)
        label.text = "8,8 c/kWh"
        label.textAlignment = .center
        label.backgroundColor = .white
        view.addSubview(label)
        singlePricelabel = label
        
        singlePricelabel.frame = CGRect(x: 0, y: 0, width: 80, height: 30)
        
        singlePricelabel.layer.shadowColor = UIColor.black.cgColor // Set the shadow color
        singlePricelabel.layer.shadowOpacity = 0.3 // Mild shadow opacity (0 = invisible, 1 = fully opaque)
        singlePricelabel.layer.shadowOffset = CGSize(width: 2, height: 2) // Slight offset for the shadow
        singlePricelabel.layer.shadowRadius = 3 // Mild blur for the shadow
        
        singlePricelabel.layer.cornerRadius = 10 // Adjust this value for more or less rounding
        singlePricelabel.clipsToBounds = false
        singlePricelabel.isUserInteractionEnabled = false
        singlePricelabel.isHidden = true

    }
}
  
/*
    

    
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


*/
