//
//  ContentView.swift
//  InPurchase
//
//  Created by iOS on 2023/5/12.
//

import SwiftUI
import InPurchase
struct ContentView: View {
    @StateObject var storeKit = InPurchase.shared
    var body: some View {
        VStack(spacing: 15){

            if let products = storeKit.products{
                ForEach(products, id: \.self) { pd in
                    
                    VStack(alignment: .leading, spacing: 5){
                        Text(pd.displayName)
                            .font(.system(size: 17, weight: .medium))
                        
                        Text(pd.displayPrice)
                            .font(.system(size: 12))
                        
                        Text(pd.description)
                            .font(.system(size: 12))
                    }
                        
                }
            }

        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
