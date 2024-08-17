//
//  ViewController.swift
//  Energian Hinta
//
//  Created by Veikko Arvonen on 16.8.2024.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var testLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let priceManager = PriceManager()
        priceManager.fetchPrice(from: Date())

    }


    
}

