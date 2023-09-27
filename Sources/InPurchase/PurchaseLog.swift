//
//  File.swift
//  
//
//  Created by 狄烨 on 2023/9/3.
//

import Foundation
import os

let logger = PurchaseLog()

struct PurchaseLog {
    private let logger: Logger
     
    init(subsystem: String = "InPurchase", category: String = "InPurchase") {
        self.logger = Logger(subsystem: subsystem, category: category)
    }
}
 
extension PurchaseLog {
    func log(_ message: String){
        logger.log("💰\(message)")
    }
}
