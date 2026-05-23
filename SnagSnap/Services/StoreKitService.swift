//
//  StoreKitService.swift
//  SnagSnap
//
//  StoreKit 2 subscription management with async/await.
//

import Foundation
import StoreKit
import SwiftUI

/// Errors that can occur during StoreKit operations.
enum StoreKitServiceError: Error, LocalizedError {
    case productNotFound
    case purchaseFailed(underlying: Error)
    case purchasePending
    case purchaseCancelled
    case verificationFailed
    case noActiveSubscription
    case restoreFailed(underlying: Error)
    case transactionUpdateFailed
    case invalidProductID

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "The requested subscription product was not found in the App Store."
        case .purchaseFailed(let error):
            return "Purchase failed: \(error.localizedDescription)"
        case .purchasePending:
            return "Purchase is pending approval from a parent or guardian."
        case .purchaseCancelled:
            return "Purchase was cancelled."
        case .verificationFailed:
            return "Transaction verification failed. The purchase could not be validated."
        case .noActiveSubscription:
            return "No active subscription found."
        case .restoreFailed(let error):
            return "Failed to restore purchases: \(error.localizedDescription)"
        case .transactionUpdateFailed:
            return "Failed to process a transaction update."
        case .invalidProductID:
            return "The product ID is invalid or malformed."
        }
    }
}

/// Represents the user's current subscription state.
enum SubscriptionState: String, Codable, Sendable {
    /// No active subscription; user is on the free tier.
    case notSubscribed
    /// Active monthly Pro subscription.
    case monthly
    /// Active annual Pro subscription.
    case annual
    /// Unknown state, typically during initial loading.
    case unknown

    /// Whether the user has an active Pro subscription.
    var isPro: Bool {
        self == .monthly || self == .annual
    }

    /// Human-readable display name for the subscription state.
    var displayName: String {
        switch self {
        case .notSubscribed:
            return "Free"
        case .monthly:
            return "Pro Monthly"
        case .annual:
            return "Pro Annual"
        case .unknown:
            return "Loading..."
        }
    }

    /// A short badge label for UI display.
    var badgeLabel: String? {
        switch self {
        case .notSubscribed:
            return "FREE"
        case .monthly, .annual:
            return "PRO"
        case .unknown:
            return nil
        }
    }
}

/// Manages all StoreKit 2 operations for subscription handling.
///
/// `StoreKitService` provides a clean async/await interface for loading products,
/// making purchases, restoring transactions, and listening for subscription updates.
/// It gracefully handles environments without configured product IDs by falling back
/// to an empty product list.
///
/// ## Product IDs
/// - `snagsnap.pro.monthly` — Monthly Pro subscription
/// - `snagsnap.pro.annual` — Annual Pro subscription
///
/// ## Usage
/// ```swift
/// @State private var storeKit = StoreKitService.shared
///
/// Button("Subscribe") {
///     Task {
///         if let monthly = storeKit.monthlyProduct {
///             let success = await storeKit.purchase(monthly)
///         }
///     }
/// }
/// ```
@Observable
class StoreKitService {

    // MARK: - Shared Instance

    /// The shared singleton instance.
    static let shared = StoreKitService()

    // MARK: - Product IDs

    /// Product ID for the monthly Pro subscription.
    static let monthlyProductID = "snagsnap.pro.monthly"
    /// Product ID for the annual Pro subscription.
    static let annualProductID = "snagsnap.pro.annual"

    // MARK: - Published Properties

    /// Products loaded from the App Store.
    private(set) var products: [Product] = []

    /// Set of purchased product IDs.
    private(set) var purchasedProductIDs: Set<String> = []

    /// Current subscription state.
    private(set) var subscriptionState: SubscriptionState = .unknown

    /// Whether a StoreKit operation is in progress.
    private(set) var isLoading = false

    /// The most recent error message, if any.
    private(set) var errorMessage: String?

    /// Whether the user has an active Pro subscription.
    var isPro: Bool { subscriptionState.isPro }

    /// The monthly subscription product, if loaded.
    var monthlyProduct: Product? {
        products.first { $0.id == Self.monthlyProductID }
    }

    /// The annual subscription product, if loaded.
    var annualProduct: Product? {
        products.first { $0.id == Self.annualProductID }
    }

    // MARK: - Private Properties

    /// Task handle for the transaction update listener.
    private var updateListenerTask: Task<Void, Never>? = nil

    // MARK: - Initialization

    /// Creates a new `StoreKitService` and starts the transaction listener.
    init() {
        updateListenerTask = listenForTransactions()
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Public Methods - Product Loading

    /// Loads subscription products from the App Store.
    ///
    /// Fetches both monthly and annual subscription products. If product IDs
    /// are not yet configured in App Store Connect, the product list will be
    /// empty and no error is surfaced to the user.
    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let productIDs = [Self.monthlyProductID, Self.annualProductID]
            products = try await Product.products(for: productIDs)
            await checkSubscriptionStatus()
        } catch {
            // Graceful degradation: product IDs may not be configured yet
            errorMessage = "Subscription products are not available at this time."
            products = []
        }

        isLoading = false
    }

    // MARK: - Public Methods - Purchasing

    /// Initiates a purchase for the given product.
    ///
    /// - Parameter product: The `Product` to purchase.
    /// - Returns: `true` if the purchase was successful and verified.
    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await handleVerifiedTransaction(transaction)
                    isLoading = false
                    return true

                case .unverified(_, let error):
                    errorMessage = "Purchase verification failed: \(error.localizedDescription)"
                    isLoading = false
                    return false
                }

            case .userCancelled:
                errorMessage = nil // User cancellation is not an error
                isLoading = false
                return false

            case .pending:
                errorMessage = "Purchase is pending approval."
                isLoading = false
                return false

            @unknown default:
                errorMessage = "An unexpected purchase result occurred."
                isLoading = false
                return false
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    /// Purchases the monthly Pro subscription, if available.
    ///
    /// - Returns: `true` if the purchase was successful.
    @discardableResult
    func purchaseMonthly() async -> Bool {
        guard let product = monthlyProduct else {
            errorMessage = "Monthly subscription is not available."
            return false
        }
        return await purchase(product)
    }

    /// Purchases the annual Pro subscription, if available.
    ///
    /// - Returns: `true` if the purchase was successful.
    @discardableResult
    func purchaseAnnual() async -> Bool {
        guard let product = annualProduct else {
            errorMessage = "Annual subscription is not available."
            return false
        }
        return await purchase(product)
    }

    // MARK: - Public Methods - Restore

    /// Restores previously completed purchases from the App Store.
    ///
    /// - Returns: `true` if an active Pro subscription was found after restoring.
    @discardableResult
    func restorePurchases() async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()
            isLoading = false

            if subscriptionState.isPro {
                return true
            } else {
                errorMessage = "No previous purchases were found to restore."
                return false
            }
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    // MARK: - Public Methods - Subscription Status

    /// Checks the current subscription status by iterating entitlements.
    ///
    /// Updates `subscriptionState` and `purchasedProductIDs` based on
    /// the verified transaction entitlements.
    func checkSubscriptionStatus() async {
        var foundActiveSubscription = false

        for await entitlement in Transaction.currentEntitlements {
            switch entitlement {
            case .verified(let transaction):
                if transaction.productID == Self.monthlyProductID && transaction.isUpgraded == false {
                    subscriptionState = .monthly
                    purchasedProductIDs.insert(transaction.productID)
                    foundActiveSubscription = true
                } else if transaction.productID == Self.annualProductID && transaction.isUpgraded == false {
                    subscriptionState = .annual
                    purchasedProductIDs.insert(transaction.productID)
                    foundActiveSubscription = true
                }

            case .unverified(_, _):
                // Unverified entitlements are ignored
                break
            }
        }

        if !foundActiveSubscription {
            subscriptionState = .notSubscribed
        }
    }

    /// Refreshes both products and subscription status.
    ///
    /// Call this when the app returns to the foreground to ensure
    /// subscription state is up to date.
    func refresh() async {
        await loadProducts()
    }

    // MARK: - Public Methods - Pricing Information

    /// Returns the formatted display price for the monthly subscription.
    var monthlyPriceDisplay: String {
        monthlyProduct?.displayPrice ?? "$4.99/mo"
    }

    /// Returns the formatted display price for the annual subscription.
    var annualPriceDisplay: String {
        annualProduct?.displayPrice ?? "$39.99/yr"
    }

    /// Returns a savings description comparing annual vs monthly.
    var annualSavingsDescription: String {
        guard let monthly = monthlyProduct, let annual = annualProduct else {
            return "Save with annual billing"
        }

        let monthlyPrice = monthly.price
        let annualPrice = annual.price
        let monthlyEquivalent = annualPrice / 12

        if monthlyPrice > 0 {
            let savings = ((monthlyPrice - monthlyEquivalent) / monthlyPrice) * 100
            return "Save \(String(format: "%.0f", NSDecimalNumber(decimal: savings).doubleValue))% with annual"
        }

        return "Save with annual billing"
    }

    // MARK: - Private Methods - Transaction Handling

    /// Listens for transaction updates from the App Store.
    ///
    /// This runs as a detached task that monitors for transaction updates
    /// such as renewals, cancellations, or billing issue resolutions.
    ///
    /// - Returns: The task handle for the listener.
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await update in StoreKit.Transaction.updates {
                guard let self = self else { break }

                switch update {
                case .verified(let transaction):
                    await self.handleVerifiedTransaction(transaction)

                case .unverified(_, let error):
                    await MainActor.run {
                        self.errorMessage = "Transaction update failed: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    /// Processes a verified transaction.
    ///
    /// Updates subscription state, records the purchase, and marks
    /// the transaction as finished.
    ///
    /// - Parameter transaction: The verified `Transaction` to process.
    private func handleVerifiedTransaction(_ transaction: StoreKit.Transaction) async {
        purchasedProductIDs.insert(transaction.productID)

        if transaction.productID == Self.monthlyProductID {
            subscriptionState = .monthly
        } else if transaction.productID == Self.annualProductID {
            subscriptionState = .annual
        }

        // Mark the transaction as finished to stop further processing
        await transaction.finish()
    }

    /// Clears any error message.
    func clearError() {
        errorMessage = nil
    }
}
