//
//  ViewController.swift
//  Energian Hinta
//
//  Created by Veikko Arvonen on 16.8.2024.
//

import UIKit

class ViewController: UIViewController, PriceSetDelegate {
    
    @IBOutlet weak var testLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var priceManager = PriceManager()
        priceManager.delegate = self
        priceManager.fetchPrice(from: Date())

    }

    
    func setLabel(price: Double?) {
        DispatchQueue.main.async {
            if let priceToDisplay = price {
                self.testLabel.text = "\(priceToDisplay) c/kWh"
            } else {
                self.testLabel.text = "Virhe hinnan haussa"
            }
        }
    }

    
}

