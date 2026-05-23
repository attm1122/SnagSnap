import SwiftUI
import SwiftData

// MARK: - Settings View

struct SettingsView: View {

    // MARK: Properties

    @Bindable var viewModel: SettingsViewModel
    @State private var showPaywall = false
    @Environment(\.colorScheme) private var colorScheme

    // MARK: Body

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Theme.spacingL) {
                // Profile Section
                profileSection
                    .entryAnimation(delay: 0.0)

                // Subscription Section
                subscriptionSection
                    .entryAnimation(delay: 0.05)

                // Default Settings Section
                defaultSettingsSection
                    .entryAnimation(delay: 0.1)

                // About Section
                aboutSection
                    .entryAnimation(delay: 0.15)
            }
            .padding(.horizontal, Theme.spacingM)
            .padding(.vertical, Theme.spacingL)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Settings")
        .dismissKeyboardOnDrag()
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .alert("Restore Purchases", isPresented: $viewModel.showRestoreAlert) {
            Button("OK", role: .cancel) {
                viewModel.dismissRestoreAlert()
            }
        } message: {
            Text(viewModel.restoreMessage ?? "")
        }
        .alert(viewModel.profileSavedMessage ?? "", isPresented: $viewModel.showProfileSaved) {
            Button("OK", role: .cancel) {
                viewModel.dismissProfileSaved()
            }
        } message: {
            EmptyView()
        }
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        SSCard {
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                SSSectionHeader(title: "Your Profile", icon: "person.fill")

                VStack(spacing: Theme.spacingM) {
                    // Company Name
                    SettingsTextField(
                        title: "Company Name",
                        text: $viewModel.companyName,
                        icon: "building.2.fill",
                        placeholder: "Your company name"
                    )

                    // Inspector Name
                    SettingsTextField(
                        title: "Inspector Name",
                        text: $viewModel.inspectorName,
                        icon: "person.text.rectangle.fill",
                        placeholder: "Inspector full name"
                    )

                    // Phone
                    SettingsTextField(
                        title: "Phone",
                        text: $viewModel.phone,
                        icon: "phone.fill",
                        placeholder: "Contact phone number",
                        keyboardType: .phonePad
                    )

                    // Email
                    SettingsTextField(
                        title: "Email",
                        text: $viewModel.email,
                        icon: "envelope.fill",
                        placeholder: "Contact email address",
                        keyboardType: .emailAddress
                    )

                    // Save Button
                    SSButton(title: "Save Profile", style: .primary) {
                        HapticService.shared.play(.success)
                        viewModel.saveProfile()
                    }
                    .buttonStyle(.animated(haptic: .medium))
                    .accessibilityLabel("Save profile settings")
                    .padding(.top, 4)
                }
            }
        }
    }

    // MARK: - Subscription Section

    private var subscriptionSection: some View {
        SSCard {
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                SSSectionHeader(title: "Subscription", icon: "crown.fill")

                VStack(alignment: .leading, spacing: Theme.spacingM) {
                    // Current Plan Row
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Plan")
                                .font(Theme.callout)
                                .foregroundStyle(.secondary)

                            Text(viewModel.planDisplayName)
                                .font(Theme.headline)
                                .foregroundStyle(.primary)
                        }

                        Spacer()

                        if viewModel.isPro {
                            SSTag(text: "Pro", style: .success)
                        } else {
                            SSTag(text: "Free", style: .info)
                        }
                    }

                    Divider()

                    // Free User: Usage + Upgrade
                    if !viewModel.isPro {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Reports this month")
                                    .font(Theme.callout)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Text("\(viewModel.monthlyReportCount)")
                                    .font(Theme.headline)
                                    .foregroundStyle(.primary)
                            }

                            HStack {
                                Text("Remaining free reports")
                                    .font(Theme.callout)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Text("\(viewModel.remainingFreeReports)")
                                    .font(Theme.headline)
                                    .foregroundStyle(viewModel.remainingFreeReports > 0 ? Theme.success : .red)
                            }
                        }

                        SSButton(title: "Upgrade to Pro", style: .primary) {
                            HapticService.shared.play(.medium)
                            showPaywall = true
                        }
                        .accessibilityLabel("Upgrade to Pro subscription")
                        .padding(.top, 4)
                    }

                    // Pro User: Manage
                    if viewModel.isPro {
                        SSButton(title: "Manage Subscription", style: .secondary) {
                            HapticService.shared.play(.medium)
                            openSubscriptionManagement()
                        }
                        .accessibilityLabel("Manage subscription in App Store")
                    }

                    // Restore Purchases
                    SSButton(title: "Restore Purchases", style: .tertiary) {
                        Task {
                            await viewModel.restorePurchases()
                            HapticService.shared.play(viewModel.showRestoreAlert && viewModel.restoreMessage?.contains("success") == true ? .success : .warning)
                        }
                    }
                    .accessibilityLabel("Restore previous purchases")
                    .disabled(viewModel.isRestoring)
                }
            }
        }
    }

    // MARK: - Default Settings Section

    private var defaultSettingsSection: some View {
        SSCard {
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                SSSectionHeader(title: "PDF Export Defaults", icon: "doc.text.fill")

                VStack(spacing: Theme.spacingM) {
                    // Default Inspector Name
                    SettingsTextField(
                        title: "Default Inspector Name",
                        text: $viewModel.defaultInspectorName,
                        icon: "person.badge.key.fill",
                        placeholder: "Used on PDF cover page"
                    )

                    Divider()

                    // Toggles
                    SettingsToggle(
                        title: "Include cover page",
                        subtitle: "Add branded cover to PDF reports",
                        icon: "doc.richtext.fill",
                        isOn: $viewModel.includeCoverPage
                    )

                    SettingsToggle(
                        title: "Include summary",
                        subtitle: "Add issue summary section to PDF",
                        icon: "list.bullet.rectangle.fill",
                        isOn: $viewModel.includeSummary
                    )

                    SettingsToggle(
                        title: "Include timestamps",
                        subtitle: "Show date and time on each item",
                        icon: "clock.fill",
                        isOn: $viewModel.includeTimestamps
                    )
                }
            }
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        SSCard {
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                SSSectionHeader(title: "About", icon: "info.circle.fill")

                VStack(spacing: 0) {
                    // Export Data Row
                    SettingsNavigationRow(
                        title: "Export Data",
                        icon: "square.and.arrow.up.fill",
                        iconColor: Theme.primary
                    ) {
                        // Placeholder: Data export functionality
                    }

                    Divider()
                        .padding(.leading, 44)

                    // Privacy Policy Row
                    SettingsNavigationRow(
                        title: "Privacy Policy",
                        icon: "hand.raised.fill",
                        iconColor: Theme.accent
                    ) {
                        // Placeholder: Open privacy policy
                    }

                    Divider()
                        .padding(.leading, 44)

                    // App Version Row
                    HStack(spacing: 12) {
                        Image(systemName: "app.badge.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.secondary)
                            .frame(width: 28, height: 28)

                        Text("Version")
                            .font(Theme.body)
                            .foregroundStyle(.primary)

                        Spacer()

                        Text(viewModel.appVersion)
                            .font(Theme.callout)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 10)
                }
            }
        }
    }

    // MARK: - Helpers

    private func openSubscriptionManagement() {
        guard let url = URL(string: "https://apps.apple.com/account/subscriptions") else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Settings Text Field

private struct SettingsTextField: View {
    let title: String
    @Binding var text: String
    let icon: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(Theme.callout)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.primary)
                    .frame(width: 24, height: 24)

                TextField(placeholder, text: $text)
                    .font(Theme.body)
                    .foregroundStyle(.primary)
                    .keyboardType(keyboardType)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6).opacity(0.5))
            )
        }
    }
}

// MARK: - Settings Toggle

private struct SettingsToggle: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Theme.primary)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.body)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(Theme.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: Theme.primary))
                .labelsHidden()
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Settings Navigation Row

private struct SettingsNavigationRow: View {
    let title: String
    let icon: String
    let iconColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(iconColor)
                    .frame(width: 28, height: 28)

                Text(title)
                    .font(Theme.body)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Section Header View

private struct SSSectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.primary)

            Text(title)
                .font(Theme.headline)
                .foregroundStyle(.primary)

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    let schema = Schema([UserProfile.self])
    let container = try! ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))

    return NavigationStack {
        SettingsView(viewModel: SettingsViewModel(modelContext: container.mainContext))
    }
    .modelContainer(container)
}
