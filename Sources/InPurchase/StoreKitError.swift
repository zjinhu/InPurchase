//
//  Notification.swift
//  Eraser
//
//  Created by 狄烨 on 2023/8/2.
//

import Foundation
import StoreKit

public struct UnwrappedVerificationResult<T> {
    public let transaction: T
    public let verified: Bool
    public let verificationError: VerificationResult<T>.VerificationError?
}

public struct TransactionUpdate: Hashable {
    let productId: ProductId
    let date: Date
    let status: TransactionStatus
    let transactionId: String
}

public enum TransactionStatus { case purchased, subscribed, inGracePeriod, inBillingRetryPeriod, revoked, expired, unknown
    public func info() -> String {
        switch self {
            case .purchased:            return "已购买"
            case .subscribed:           return "已订阅"
            case .inGracePeriod:        return "宽限期内"
            case .inBillingRetryPeriod: return "计费重试期内"
            case .revoked:              return "已撤销"
            case .expired:              return "已到期"
            case .unknown:              return "未知"
        }
    }
}

public enum PurchaseState {
    case notStarted, userCannotMakePayments, inProgress, purchased, pending, cancelled, failed, failedVerification, unknown, notPurchased
    
    public func info() -> String {
        switch self {
            case .notStarted:               return "购买尚未开始"
            case .userCannotMakePayments:   return "用户无法付款"
            case .inProgress:               return "购买进行中"
            case .purchased:                return "已购买"
            case .pending:                  return "待购买"
            case .cancelled:                return "购买已取消"
            case .failed:                   return "购买失败"
            case .failedVerification:       return "购买验证失败"
            case .unknown:                  return "购买状态未知"
            case .notPurchased:             return "未购买"
        }
    }
}


extension StoreKitError: Equatable {
    public static func == (lhs: StoreKitError, rhs: StoreKitError) -> Bool {
        switch (lhs, rhs) {
        case (.unknown, .unknown): return true
        case (.userCancelled, .userCancelled): return true
        case (.networkError, .networkError): return true
        case (.systemError, .systemError): return true
        case (.notAvailableInStorefront, .notAvailableInStorefront): return true
        case (.notEntitled, .notEntitled): return true
        default: return false
        }
    }
}

public enum UnderlyingError: Equatable {
    case purchase(Product.PurchaseError)
    case storeKit(StoreKitError)

    public init?(error: Error) {
        if let purchaseError = error as? Product.PurchaseError {
            self = .purchase(purchaseError)
        } else if let skError = error as? StoreKitError {
            self = .storeKit(skError)
        } else {
            return nil
        }
    }
}

public enum StoreException: Error, Equatable {
    case purchaseException(UnderlyingError?)
    case purchaseInProgressException
    case transactionVerificationFailed
    case productTypeNotSupported
    
    public func info() -> String {
        switch self {
            case .purchaseException:             return "StoreKit 在处理购买时抛出异常"
            case .purchaseInProgressException:   return "您尚无法开始另一次购买，一项已在进行中"
            case .transactionVerificationFailed: return "交易未通过 StoreKit 自动验证"
            case .productTypeNotSupported:       return "不支持非自动续费的产品"
        }
    }
}

public enum StoreNotification: Error, Equatable {

    case requestProductsStarted
    case requestProductsSuccess
    case requestProductsFailure
    
    case purchaseUserCannotMakePayments
    case purchaseAlreadyInProgress
    case purchaseInProgress
    case purchaseCancelled
    case purchasePending
    case purchaseSuccess
    case purchaseFailure
    
    case transactionReceived
    case transactionValidationSuccess
    case transactionValidationFailure
    case transactionFailure
    case transactionSuccess
    case transactionSubscribed
    case transactionRevoked
    case transactionRefundRequested
    case transactionRefundFailed
    case transactionNoExpire
    case transactionExpired
    case transactionUpgraded
    case transactionInGracePeriod
 
    case requestPurchaseStatusStarted
    case requestPurchaseStatusSucess
    case requestPurchaseStatusFailure
    
    case productIsPurchasedFromTransaction
    case productIsPurchasedFromCache
    case productIsPurchased
    case productIsNotPurchased
    case productIsNotPurchasedNoEntitlement

    case appStoreNotAvailable

    public func info() -> String {
        switch self {     
            case .requestProductsStarted:               return "开始从 App Store 请求产品"
            case .requestProductsSuccess:               return "从 App Store 请求产品成功"
            case .requestProductsFailure:               return "从 App Store 请求产品失败"
                        
            case .purchaseUserCannotMakePayments:       return "由于用户无法付款，购买失败"
            case .purchaseAlreadyInProgress:            return "购买已在进行中"
            case .purchaseInProgress:                   return "购买进行中"
            case .purchasePending:                      return "购买正在进行中。 等待授权"
            case .purchaseCancelled:                    return "购买已取消"
            case .purchaseSuccess:                      return "购买成功"
            case .purchaseFailure:                      return "购买失败"
                        
            case .transactionReceived:                  return "交易已收到"
            case .transactionValidationSuccess:         return "交易验证成功"
            case .transactionValidationFailure:         return "交易验证失败"
            case .transactionFailure:                   return "交易失败"
            case .transactionSuccess:                   return "交易成功"
            case .transactionSubscribed:                return "认购交易成功"
            case .transactionRevoked:                   return "交易被 App Store 撤销（退款）"
            case .transactionRefundRequested:           return "交易退款申请成功"
            case .transactionRefundFailed:              return "交易退款申请失败"
            case .transactionExpired:                   return "认购交易已过期"
            case .transactionNoExpire:                 return  "认购交易订阅期内"
            case .transactionUpgraded:                  return "交易被更高价值的认购取代"
            case .transactionInGracePeriod:             return "认购交易处于宽限期内"
 
            case .requestPurchaseStatusStarted:         return "请求所有产品购买状态已开始"
            case .requestPurchaseStatusSucess:          return "请求所有产品购买状态成功"
            case .requestPurchaseStatusFailure:         return "请求所有产品购买状态失败"
                
            case .productIsPurchasedFromTransaction:    return "购买的产品（通过交易）"
            case .productIsPurchasedFromCache:          return "购买的产品（通过缓存）"
            case .productIsPurchased:                   return "购买的产品"
            case .productIsNotPurchased:                return "未购买产品"
            case .productIsNotPurchasedNoEntitlement:   return "未购买产品（无权利）"

            case .appStoreNotAvailable:                 return "应用商店不可用"
        }
    }
 
}
