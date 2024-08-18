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
    let labelYPositions = [200.0, 250.0, 300.0, 350.0, 400.0, 450.0]
    let labelTexts = ["25", "20", "15", "10", "5", "0"]
    
    
    @IBOutlet weak var testLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setPriceSheet()
        var priceManager = PriceManager()
        priceManager.delegate = self
        priceManager.fetchPrice(from: Date())

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
    }
    
    
    
    
    
    
    func setPrice(price: Double?) {
        DispatchQueue.main.async {
            print(price)
        }
    }
    
    func updateSheet(price: Double?) {
        DispatchQueue.main.async {
            if let p = price {
                
                var maxPrice: Double = 0.0
                
                while p > maxPrice {
                    maxPrice += 5
                }
                
                
                
                
            }
        }
    }
    
    
}




