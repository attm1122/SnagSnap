import SwiftUI
import StoreKit
import Observation

// MARK: - Paywall View Model

@Observable
final class PaywallViewModel {

    // MARK: Dependencies

    private let storeKitService = StoreKitService.shared

    // MARK: State

    var selectedProduct: Product?
    var isPurchasing = false
    var showErrorAlert = false
    var errorMessage: String?
    var purchaseSuccess = false

    // MARK: Computed Properties

    var isLoading: Bool {
        storeKitService.isLoading
    }

    var productsLoaded: Bool {
        !storeKitService.products.isEmpty
    }

    var monthlyProduct: Product? {
        storeKitService.monthlyProduct
    }

    var annualProduct: Product? {
        storeKitService.annualProduct
    }

    var hasError: Bool {
        storeKitService.errorMessage != nil
    }

    var productsErrorMessage: String? {
        storeKitService.errorMessage
    }

    // MARK: Actions

    func loadProducts() async {
        await storeKitService.loadProducts()

        if selectedProduct == nil {
            selectedProduct = annualProduct ?? monthlyProduct
        }
    }

    func selectProduct(_ product: Product) {
        selectedProduct = product
    }

    func purchaseSelectedProduct() async {
        guard let product = selectedProduct else {
            errorMessage = "Please select a subscription plan."
            showErrorAlert = true
            return
        }

        isPurchasing = true
        defer { isPurchasing = false }

        let success = await storeKitService.purchase(product)

        if success {
            purchaseSuccess = true
        } else {
            errorMessage = "Purchase was not completed. Please try again."
            showErrorAlert = true
        }
    }

    func restorePurchases() async {
        isPurchasing = true
        defer { isPurchasing = false }

        let success = await storeKitService.restorePurchases()

        if success {
            purchaseSuccess = true
        } else {
            errorMessage = "No previous purchases were found to restore."
            showErrorAlert = true
        }
    }

    func dismissError() {
        showErrorAlert = false
        errorMessage = nil
    }

    func formatPrice(for product: Product) -> String {
        return product.displayPrice
    }

    func formatPricePerMonth(for product: Product) -> String {
        if product.id == StoreKitService.annualProductID {
            let unit = product.subscription?.subscriptionPeriod.unit
            let value = product.subscription?.subscriptionPeriod.value ?? 1

            if unit == .year && value == 1 {
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = .currency
                numberFormatter.locale = product.priceFormatStyle.locale

                let annualPrice = Double(truncating: product.price as NSDecimalNumber)
                let monthlyEquivalent = annualPrice / 12.0

                if let formatted = numberFormatter.string(from: NSNumber(value: monthlyEquivalent)) {
                    return "\(formatted)/mo"
                }
            }
        }

        return "\(product.displayPrice)/mo"
    }

    func subscriptionPeriodText(for product: Product) -> String {
        if product.id == StoreKitService.monthlyProductID {
            return "per month"
        } else if product.id == StoreKitService.annualProductID {
            return "per year"
        }
        return ""
    }
}
