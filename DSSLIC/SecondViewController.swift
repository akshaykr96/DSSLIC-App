//
//  SecondViewController.swift
//  DSSLICv2                                                               
//
//  Created by Akshay Kumar on 2019-08-13.
//  Copyright © 2019 SFU. All rights reserved.
//

import UIKit

class SecondViewController: UIViewController {
    

    
    
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
    }
    
    @IBAction func link(_ sender: Any) {
        
    let url = "https://arxiv.org/pdf/1806.03348.pdf"
        openUrl(urlStr: url)
    }
    
    func openUrl(urlStr: String!) {
        if let url = URL(string:urlStr), !url.absoluteString.isEmpty {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

}

