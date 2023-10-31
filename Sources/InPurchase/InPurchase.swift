//
//  InPurchase.swift
//  Eraser
//
//  Created by 狄烨 on 2023/8/2.
//

import Foundation
import StoreKit
import SwiftUI
public typealias ProductId = String
public typealias ShouldAddStorePaymentHandler = (_ payment: SKPayment, _ product: SKProduct) -> Bool
public let InPurchaseStorage = "isPro.InPurchase"
public class InPurchase: ObservableObject {

    //判断有买过没,是否展示试用期---暂时不用
//    @AppStorage("isPayed.InPurchase") public var isPayed: Bool = false
    //判断是否VIP用户,内购有限期内
    @AppStorage(InPurchaseStorage) public var isPro: Bool = false
    
    public private(set) var purchaseState: PurchaseState = .unknown
    
    @MainActor @Published public private(set) var showLoading: Bool = false
    @Published public private(set) var products: [Product]?
    @Published public var selectProduct: Product?
    
    public private(set) var isAppStoreAvailable = false
    public private(set) var isRefreshingProducts = false
    public var hasStarted: Bool { transactionListener != nil && isAppStoreAvailable }
    public var hasProducts: Bool { products?.count ?? 0 > 0 ? true : false }
    
    //Storekit1
    private var paymentQueue: PaymentQueue?
    public private(set) var transactionUpdateCache = [TransactionUpdate]()
    public var shouldAddStorePaymentHandler: ShouldAddStorePaymentHandler?
    
    private var transactionListener: Task<Void, Error>? = nil
    private var productIds: [ProductId] = ReadIdsFile.read(filename: "ProductIds")
    
//    public static let shared = InPurchase()
    
    public init() {
        paymentQueue = PaymentQueue(inPurchase: self)

        Task(priority: .background){
            // Listen for App Store transactions
            transactionListener = await handleTransactions()
            await startAsync()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
}
//MARK: 获取数据
extension InPurchase{
    @MainActor public func start() {
        guard !hasStarted else { return }
        refreshProductsFromAppStore()
    }
    
    @MainActor public func refreshProductsFromAppStore() {
        Task {
            await requestProductsFromAppStore(productIds: productIds)
            guard let products else { return }
            await fetchUserStatus()
            selectProduct = products.first(where: { pd in
                (pd.subscription?.introductoryOffer?.period.value ?? 0) >= 3 //默认选中试用天数不为0的
            })
        }
    }
    
    @MainActor public func startAsync() async {
        guard !hasStarted else { return }
        await requestProductsFromAppStore(productIds: productIds)
        guard let products else { return }
        await fetchUserStatus()
        selectProduct = products.first(where: { pd in
            (pd.subscription?.introductoryOffer?.period.value ?? 0) >= 3 //默认选中试用天数不为0的
        })
    }
    
    @MainActor public func requestProductsFromAppStore(productIds: [ProductId]) async {
        defer { isRefreshingProducts = false }
        
        logger.log(StoreNotification.requestProductsStarted.info())
        
        isAppStoreAvailable = false
        isRefreshingProducts = true
        
        do {
            let items = try await Product.products(for: productIds)
            products = items.sorted(by: { $0.price > $1.price })
            isAppStoreAvailable = true
            logger.log(StoreNotification.requestProductsSuccess.info())
        } catch {
            logger.log(StoreNotification.requestProductsFailure.info())
        }
    }
    
    @MainActor public func fetchUserStatus() async {
        guard hasProducts else {
            logger.log(StoreNotification.requestPurchaseStatusFailure.info())
            return
        }
        logger.log(StoreNotification.requestPurchaseStatusStarted.info())
        isPro = await isProUser()
        logger.log(StoreNotification.requestPurchaseStatusSucess.info())
        
//        for product in products {
//            if let payed = try? await isPurchased(product: product) {
//                if payed{
//                    isPayed = true
//                }
//            }
//        }
    }
    
}

//MARK: 产品
extension InPurchase{

    public func restore(){
        Task{
            try await AppStore.sync()
            isPro = await isProUser()
        }
    }

    public func product(from productId: ProductId) -> Product? {
        
        guard let p = products else { return nil }
        
        let matchingProduct = p.filter { product in
            product.id == productId
        }
        
        guard matchingProduct.count == 1 else { return nil }
        return matchingProduct.first
    }
}
//MARK: 购买
extension InPurchase{

    public func purchase(product: Product){
        Task{
            let _ = try? await purchasing(product)
        }
    }
    
    @MainActor public func purchasing(_ product: Product, options: Set<Product.PurchaseOption> = [])
    async throws -> (transaction: StoreKit.Transaction?, purchaseState: PurchaseState)  {
        
        guard hasStarted else {
            logger.log("Please call InPurchase.start(ids:) before use.")
            return (nil, .notStarted)
        }
        
        guard AppStore.canMakePayments else {
            logger.log(StoreNotification.purchaseUserCannotMakePayments.info())
            return (nil, .userCannotMakePayments)
        }
        
        guard purchaseState != .inProgress else {
            logger.log("\(StoreException.purchaseInProgressException.info()), productId: \(product.id)")
            throw StoreException.purchaseInProgressException
        }
        
        showLoading = true
        purchaseState = .inProgress
        logger.log("\(StoreNotification.purchaseInProgress.info()), productId: \(product.id)")
        
        let result: Product.PurchaseResult
        do {
            result = try await product.purchase(options: options)
        } catch {
            purchaseState = .failed
            showLoading = false
            logger.log("\(StoreNotification.purchaseFailure.info()), productId: \(product.id)")
            throw StoreException.purchaseException(.init(error: error))
        }
        
        switch result {
        case .success(let verificationResult):
            
            let checkResult = checkVerificationResult(result: verificationResult)
            if !checkResult.verified {
                purchaseState = .failedVerification
                showLoading = false
                logger.log("\(StoreNotification.transactionValidationFailure.info()), productId: \(checkResult.transaction.productID), transactionId: \(checkResult.transaction.id)")
                
                throw StoreException.transactionVerificationFailed
            }
            
            let validatedTransaction = checkResult.transaction  // The transaction was successfully validated
            await validatedTransaction.finish()  // Tell the App Store we delivered the purchased content to the user
            
            purchaseState = .purchased
            showLoading = false
            logger.log("\(StoreNotification.purchaseSuccess.info()), productId: \(product.id), transactionId: \(validatedTransaction.id)")
            return (transaction: validatedTransaction, purchaseState: .purchased)
            
        case .userCancelled:
            purchaseState = .cancelled
            showLoading = false
            logger.log("\(StoreNotification.purchaseCancelled.info()), productId: \(product.id)")
            return (transaction: nil, .cancelled)
            
        case .pending:
            purchaseState = .pending
            logger.log("\(StoreNotification.purchasePending.info()), productId: \(product.id)")
            return (transaction: nil, .pending)
            
        default:
            purchaseState = .unknown
            showLoading = false
            logger.log("\(StoreNotification.purchaseFailure.info()), productId: \(product.id)")
            return (transaction: nil, .unknown)
        }
    }
    
}

//MARK: 判断
extension InPurchase{
    
    @MainActor public func isProUser() async -> Bool {
        var isPro = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }
            
            if transaction.productType == .nonConsumable, transaction.revocationDate == nil{
                logger.log("\(StoreNotification.transactionSuccess.info()), productId: \(transaction.productID), transactionId: \(transaction.id)")
                isPro = true
            }
            
            if transaction.productType == .autoRenewable{
                if transaction.revocationDate == nil,
                   let expirationDate = transaction.expirationDate,
                    expirationDate > Date(){
                    logger.log("\(StoreNotification.transactionNoExpire.info()), productId: \(transaction.productID), transactionId: \(transaction.id)")
                    isPro = true
                }else{
                    logger.log("\(StoreNotification.transactionExpired.info()), productId: \(transaction.productID), transactionId: \(transaction.id)")
                }
            }
        }
        return isPro
    }
    
    //验证购买过,不管过期没
    @MainActor public func isPurchased(product: Product) async throws -> Bool {
        var purchased = false
        
        guard hasStarted, isAppStoreAvailable, hasProducts else {
            logger.log(StoreNotification.appStoreNotAvailable.info())
            return purchased
        }
        
        guard let currentEntitlement = await Transaction.currentEntitlement(for: product.id) else {
            if product.type == .autoRenewable, let mruStatus = mostRecentSubscriptionUpdate(for: product.id) {
                
                if mruStatus == .purchased || mruStatus == .subscribed || mruStatus == .inGracePeriod || mruStatus == .inBillingRetryPeriod {
                    logger.log("\(StoreNotification.productIsPurchasedFromCache.info()), productId: \(product.id)")
                    return true
                }
            }
            logger.log("\(StoreNotification.productIsNotPurchasedNoEntitlement.info()), productId: \(product.id)")
            return false
        }
        
        let result = checkVerificationResult(result: currentEntitlement)
        
        if !result.verified {
            logger.log("\(StoreNotification.transactionValidationFailure.info()), productId: \(result.transaction.productID), transactionId: \(result.transaction.id)")
            throw StoreException.transactionVerificationFailed
        }
        
        
        switch product.type {
        case .autoRenewable:
            purchased = result.transaction.revocationDate == nil && !result.transaction.isUpgraded
        case .nonConsumable:
            purchased = result.transaction.revocationDate == nil
        default:
            throw StoreException.productTypeNotSupported
        }
        
        logger.log("\(purchased ? StoreNotification.productIsPurchasedFromTransaction.info() : StoreNotification.productIsNotPurchased.info()), productId: \(product.id), transactionId: \(result.transaction.id)")
        
        return purchased
    }

}

//MARK: 处理购买结果
extension InPurchase{
    @MainActor public func checkVerificationResult<T>(result: VerificationResult<T>) -> UnwrappedVerificationResult<T> {
        switch result {
        case .unverified(let unverifiedTransaction, let error):
            return UnwrappedVerificationResult(transaction: unverifiedTransaction, verified: false, verificationError: error)
            
        case .verified(let verifiedTransaction):
            return UnwrappedVerificationResult(transaction: verifiedTransaction, verified: true, verificationError: nil)
        }
    }
    
    public func mostRecentSubscriptionUpdate(for productId: ProductId) -> TransactionStatus? {
        
        guard transactionUpdateCache.count > 0 else { return nil }
        
        let relevantUpdates = transactionUpdateCache.filter { $0.productId == productId }
        guard relevantUpdates.count > 0 else { return nil }
        
        let sortedUpdates = relevantUpdates.sorted { $0.date < $1.date }
        guard let mostRecent = sortedUpdates.last else { return nil }
        
        return mostRecent.status
    }

    @MainActor private func handleTransactions() -> Task<Void, Error> {
        
        Task(priority: .background) { [ unowned self] in
            for await verificationResult in Transaction.updates {
                let checkResult = self.checkVerificationResult(result: verificationResult)
                
                guard checkResult.verified else {
                    logger.log("\(StoreNotification.transactionFailure.info()), productId: \(checkResult.transaction.productID), transactionId: \(checkResult.transaction.id)")
                    return
                }
                
                let transaction = checkResult.transaction
                logger.log("\(StoreNotification.transactionReceived.info()), productId: \(transaction.productID), transactionId: \(transaction.id)")
                
                if let _ = transaction.revocationDate {
                    logger.log("\(StoreNotification.transactionRevoked.info()), productId: \(transaction.productID), transactionId: \(transaction.id)")
                    return
                }
                
                if let expirationDate = transaction.expirationDate, expirationDate < Date() {
                    logger.log("\(StoreNotification.transactionExpired.info()), productId: \(transaction.productID), transactionId: \(transaction.id)")
                    return
                }
                
                if transaction.isUpgraded {
                    logger.log("\(StoreNotification.transactionUpgraded.info()), productId: \(transaction.productID), transactionId: \(transaction.id)")
                    return
                }
                
                logger.log("\(StoreNotification.transactionSuccess.info()), productId: \(transaction.productID), transactionId: \(transaction.id)")
                
                await transaction.finish()
            }
        }
    }
}

//MARK: StoreKit1
extension InPurchase{
    
    @MainActor public func productPurchased(_ productId: ProductId, transactionId: String)  {
        purchaseState = .purchased
        logger.log("\(StoreNotification.purchaseSuccess.info()), productId: \(productId), transactionId: \(transactionId)")
    }
    
    @MainActor public func handleStoreKit1Transactions(productId: ProductId, date: Date, status: TransactionStatus, transaction: SKPaymentTransaction) async {
        var transactionStatus = TransactionStatus.unknown
        let transactionId = transaction.transactionIdentifier ?? "-1"
        
        switch status {
        case .purchased:
            logger.log("\(StoreNotification.transactionSuccess.info()), productId: \(productId), transactionId: \(transactionId)")
            transactionStatus = .purchased
            
        case .subscribed:
            logger.log("\(StoreNotification.transactionSubscribed.info()), productId: \(productId), transactionId: \(transactionId)")
            transactionStatus = .subscribed
            
        case .inGracePeriod:
            logger.log("\(StoreNotification.transactionInGracePeriod.info()), productId: \(productId), transactionId: \(transactionId)")
            transactionStatus = .inGracePeriod
            
        case .inBillingRetryPeriod:
            logger.log("\(StoreNotification.transactionInGracePeriod.info()), productId: \(productId), transactionId: \(transactionId)")
            transactionStatus = .inBillingRetryPeriod
            
        case .revoked:
            logger.log("\(StoreNotification.transactionRevoked.info()), productId: \(productId), transactionId: \(transactionId)")
            transactionStatus = .revoked
            
        case .expired:
            logger.log("\(StoreNotification.transactionExpired.info()), productId: \(productId), transactionId: \(transactionId)")
            transactionStatus = .expired
            
        default: return
        }
        
        if transactionUpdateCache.filter({ t in t.transactionId == transactionId && t.status == transactionStatus }).count == 0 {
            transactionUpdateCache.append(TransactionUpdate(productId: productId, date: Date(), status: transactionStatus, transactionId: transactionId))
        }
    }
}
