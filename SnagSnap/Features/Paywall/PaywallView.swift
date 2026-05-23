import SwiftUI
import StoreKit

// MARK: - Paywall View

struct PaywallView: View {

    // MARK: Properties

    @Bindable var viewModel = PaywallViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var showPurchaseSuccess = false

    private let benefits = [
        "Unlimited property reports",
        "Remove watermark from PDFs",
        "Add your company branding",
        "Export polished PDF reports",
        "Save complete report history",
        "Priority support"
    ]

    // MARK: Body

    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    headerView

                    // Benefits
                    benefitsView

                    // Product Cards
                    productsView

                    // Bottom Actions
                    bottomActionsView
                }
                .padding(.horizontal, Theme.spacingM)
                .padding(.bottom, Theme.spacingXL)
            }

            // Loading Overlay
            if viewModel.isPurchasing {
                loadingOverlay
            }
        }
        .task {
            await viewModel.loadProducts()
        }
        .alert("Oops", isPresented: .init(
            get: { viewModel.showErrorAlert },
            set: { if !$0 { viewModel.dismissError() } }
        )) {
            Button("OK", role: .cancel) {
                viewModel.dismissError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "Something went wrong.")
        }
        .onChange(of: viewModel.purchaseSuccess) { _, success in
            if success {
                HapticService.shared.play(.success)
                showPurchaseSuccess = true
                // Delay dismiss so user sees the success toast
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        }
        .toast(
            isPresented: $showPurchaseSuccess,
            message: "Welcome to Pro!",
            style: .success,
            duration: 2.5
        )
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: Theme.spacingL) {
            // Close Button
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Close")
            }

            // Crown Icon
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "crown.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }

            // Title & Subtitle
            VStack(spacing: 8) {
                Text("Create unlimited\nprofessional reports")
                    .font(Theme.title)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)

                Text("Upgrade to Pro and unlock the full power of SnagSnap")
                    .font(Theme.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, Theme.spacingM)
        .padding(.bottom, Theme.spacingXL)
    }

    // MARK: - Benefits

    private var benefitsView: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            ForEach(benefits, id: \.self) { benefit in
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Theme.success)

                    Text(benefit)
                        .font(Theme.body)
                        .foregroundStyle(.primary)

                    Spacer()
                }
            }
        }
        .padding(.horizontal, Theme.spacingL)
        .padding(.vertical, Theme.spacingL)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusL)
                .fill(Theme.cardBackground)
        )
        .padding(.bottom, Theme.spacingXL)
    }

    // MARK: - Products

    @ViewBuilder
    private var productsView: some View {
        if viewModel.isLoading && !viewModel.productsLoaded {
            loadingProductsView
        } else if viewModel.productsLoaded {
            productCardsView
        } else if viewModel.hasError {
            errorProductsView
        } else {
            loadingProductsView
        }
    }

    private var loadingProductsView: some View {
        VStack(spacing: Theme.spacingL) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(Theme.primary)

            Text("Loading subscription options...")
                .font(Theme.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.spacingXXL)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusL)
                .fill(Theme.cardBackground)
        )
        .padding(.bottom, Theme.spacingXL)
    }

    private var errorProductsView: some View {
        VStack(spacing: Theme.spacingL) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange)

            Text("Unable to load subscriptions")
                .font(Theme.headline)
                .foregroundStyle(.primary)

            Text(viewModel.productsErrorMessage ?? "Please check your connection and try again.")
                .font(Theme.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            SSButton(title: "Retry", style: .secondary) {
                Task {
                    await viewModel.loadProducts()
                }
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.spacingXXL)
        .padding(.horizontal, Theme.spacingL)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusL)
                .fill(Theme.cardBackground)
        )
        .padding(.bottom, Theme.spacingXL)
    }

    private var productCardsView: some View {
        VStack(spacing: Theme.spacingM) {
            // Annual Card
            if let annual = viewModel.annualProduct {
                ProductCard(
                    product: annual,
                    title: "Pro Annual",
                    subtitle: viewModel.subscriptionPeriodText(for: annual),
                    price: viewModel.formatPrice(for: annual),
                    pricePerMonth: viewModel.formatPricePerMonth(for: annual),
                    badge: "Best Value",
                    isSelected: viewModel.selectedProduct?.id == annual.id,
                    isProcessing: viewModel.isPurchasing
                ) {
                    HapticService.shared.play(.medium)
                    viewModel.selectProduct(annual)
                }
            }

            // Monthly Card
            if let monthly = viewModel.monthlyProduct {
                ProductCard(
                    product: monthly,
                    title: "Pro Monthly",
                    subtitle: viewModel.subscriptionPeriodText(for: monthly),
                    price: viewModel.formatPrice(for: monthly),
                    pricePerMonth: nil,
                    badge: nil,
                    isSelected: viewModel.selectedProduct?.id == monthly.id,
                    isProcessing: viewModel.isPurchasing
                ) {
                    HapticService.shared.play(.medium)
                    viewModel.selectProduct(monthly)
                }
            }

            // Purchase Button
            SSButton(title: purchaseButtonTitle, style: .primary) {
                Task {
                    await viewModel.purchaseSelectedProduct()
                }
            }
            .padding(.top, 8)
            .disabled(viewModel.selectedProduct == nil || viewModel.isPurchasing)
            .opacity(viewModel.selectedProduct == nil ? 0.6 : 1.0)
            .accessibilityLabel(purchaseButtonTitle)
        }
        .padding(.bottom, Theme.spacingXL)
    }

    private var purchaseButtonTitle: String {
        guard let product = viewModel.selectedProduct else {
            return "Select a Plan"
        }
        if product.id == StoreKitService.annualProductID {
            return "Start Pro Annual"
        } else {
            return "Start Pro Monthly"
        }
    }

    // MARK: - Bottom Actions

    private var bottomActionsView: some View {
        VStack(spacing: 12) {
            SSButton(title: "Restore Purchases", style: .tertiary) {
                Task {
                    await viewModel.restorePurchases()
                }
            }
            .disabled(viewModel.isPurchasing)

            SSButton(title: "Terms & Privacy", style: .tertiary) {}
                .disabled(true)

            Text("Subscriptions auto-renew until cancelled. Manage in Settings.")
                .font(Theme.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.4)
                    .tint(.white)

                Text("Processing...")
                    .font(Theme.headline)
                    .foregroundStyle(.white)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusXL)
                    .fill(Color(.systemGray6).opacity(0.9))
                    .shadow(radius: 20)
            )
        }
    }
}

// MARK: - Product Card

private struct ProductCard: View {
    let product: Product
    let title: String
    let subtitle: String
    let price: String
    let pricePerMonth: String?
    let badge: String?
    let isSelected: Bool
    let isProcessing: Bool
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: Theme.spacingM) {
                // Selection Indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Theme.primary : Color.gray.opacity(0.4), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Theme.primary)
                            .frame(width: 16, height: 16)

                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(Theme.headline)
                            .foregroundStyle(.primary)

                        if let badge = badge {
                            SSTag(text: badge, style: .accent)
                        }
                    }

                    Text(subtitle)
                        .font(Theme.callout)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Price
                VStack(alignment: .trailing, spacing: 2) {
                    Text(price)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.primary)

                    if let pricePerMonth = pricePerMonth {
                        Text(pricePerMonth)
                            .font(Theme.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(Theme.spacingM)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusL)
                    .fill(Theme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cornerRadiusL)
                            .stroke(
                                isSelected ? Theme.primary : Color.gray.opacity(0.2),
                                lineWidth: isSelected ? 2.5 : 1
                            )
                    )
                    .shadow(
                        color: isSelected ? Theme.primary.opacity(0.12) : Color.clear,
                        radius: isSelected ? 8 : 0
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isProcessing)
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
}
