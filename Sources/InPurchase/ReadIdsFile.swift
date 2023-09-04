//
//  File.swift
//  
//
//  Created by 狄烨 on 2023/9/3.
//

import Foundation
public struct ReadIdsFile {

    public static func read(filename: String) -> [ProductId] {
        guard let plistURL = Bundle.main.url(forResource: filename, withExtension: "plist"),
              let plistData = try? Data(contentsOf: plistURL) else {
            fatalError("Unable to locate or read Plist file.")
        }
        
        do {
            let decoder = PropertyListDecoder()
            let items = try decoder.decode([ProductId].self, from: plistData)
            return items
        } catch {
            fatalError("Error decoding Plist file: \(error)")
        }
    }
}
