//
//  ProductEx.swift
//  Eraser
//
//  Created by 狄烨 on 2023/8/6.
//

import Foundation
import StoreKit

public extension Product {
    //试用天数
    var tryDays: Int {
        self.subscription?.introductoryOffer?.period.value ?? 0
    }
}

typealias RenewalState = Product.SubscriptionInfo.RenewalState

public extension Product {
    //判断有没有优惠资格,是否展示试用期
    var isEligibleForIntroOffer: Bool {
        get async {
            await subscription?.isEligibleForIntroOffer ?? false
        }
    }
    //时候还在订阅有效期
    var hasActiveSubscription: Bool {
        get async {
            await (try? subscription?.status.first?.state == RenewalState.subscribed) ?? false
        }
    }
}

extension UIWindowScene {
    /// Get UIWindowScene
    static var currentWindowSence: UIWindowScene?  {
        for scene in UIApplication.shared.connectedScenes{
            if scene.activationState == .foregroundActive{
                return scene as? UIWindowScene
            }
        }
        return nil
    }
}
