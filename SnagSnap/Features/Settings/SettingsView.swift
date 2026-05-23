import SwiftUI
import SwiftData

// MARK: - Settings View

struct SettingsView: View {

    // MARK: Properties

    @Bindable var viewModel: SettingsViewModel
    @State private var showPaywall = false
    @State private var showLegal = false
    @Environment(\.colorScheme) private var colorScheme

    // MARK: Body

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Theme.spacingL) {
                settingsHero
                    .entryAnimation(delay: 0.0)

                // Profile Section
                profileSection
                    .entryAnimation(delay: 0.05)

                // Subscription Section
                subscriptionSection
                    .entryAnimation(delay: 0.1)

                // Default Settings Section
                defaultSettingsSection
                    .entryAnimation(delay: 0.15)

                // About Section
                aboutSection
                    .entryAnimation(delay: 0.2)
            }
            .padding(.horizontal, Theme.spacingL)
            .padding(.vertical, Theme.spacingL)
        }
        .background(
            LinearGradient(
                colors: [Theme.blueSurfaceStrong, Theme.background, Theme.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.blueSurfaceStrong, for: .navigationBar)
        .dismissKeyboardOnDrag()
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showLegal) {
            NavigationStack {
                LegalView()
            }
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
        .alert("Export Failed", isPresented: $viewModel.showExportError) {
            Button("OK", role: .cancel) {
                viewModel.dismissExportError()
            }
        } message: {
            Text(viewModel.exportErrorMessage ?? "Unable to export app data.")
        }
    }

    // MARK: - Settings Hero

    private var settingsHero: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            Text("Workspace")
                .font(Theme.fontCaption.weight(.semibold))
                .foregroundStyle(Theme.primary)
                .textCase(.uppercase)

            Text("Tune your reports.")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(Theme.ink)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Theme.spacingM)
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        SSCard(padding: Theme.spacingL, cornerRadius: Theme.radiusLarge) {
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                SettingsSectionHeader(title: "Your Profile", icon: "person.fill")

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
        SSCard(padding: Theme.spacingL, cornerRadius: Theme.radiusLarge) {
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                SettingsSectionHeader(title: "Subscription", icon: "crown.fill")

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
                                    .foregroundStyle(viewModel.remainingFreeReports > 0 ? Theme.accent : Theme.error)
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
        SSCard(padding: Theme.spacingL, cornerRadius: Theme.radiusLarge) {
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                SettingsSectionHeader(title: "PDF Export Defaults", icon: "doc.text.fill")

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
        SSCard(padding: Theme.spacingL, cornerRadius: Theme.radiusLarge) {
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                SettingsSectionHeader(title: "About", icon: "info.circle.fill")

                VStack(spacing: 0) {
                    // Export Data Row
                    SettingsNavigationRow(
                        title: "Export Data",
                        icon: "square.and.arrow.up.fill",
                        iconColor: Theme.primary
                    ) {
                        exportData()
                    }

                    Divider()
                        .padding(.leading, 44)

                    // Privacy Policy Row
                    SettingsNavigationRow(
                        title: "Privacy Policy",
                        icon: "hand.raised.fill",
                        iconColor: Theme.accent
                    ) {
                        openPrivacyPolicy()
                    }

                    Divider()
                        .padding(.leading, 44)

                    SettingsNavigationRow(
                        title: "Support",
                        icon: "questionmark.bubble.fill",
                        iconColor: Theme.primary
                    ) {
                        openSupport()
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

    private func openPrivacyPolicy() {
        guard let url = URL(string: "https://snagsnap.app/privacy") else {
            showLegal = true
            return
        }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            showLegal = true
        }
    }

    private func openSupport() {
        guard let url = URL(string: "mailto:support@snagsnap.app?subject=SnagSnap%20Support") else { return }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    private func exportData() {
        do {
            let exportURL = try viewModel.makeDataExportFile()
            ShareService.shared.shareFile(exportURL)
        } catch {
            viewModel.setExportError(error)
        }
    }
}

struct LegalView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacingL) {
                legalSection(
                    title: "Privacy Policy",
                    body: "SnagSnap stores inspection reports, photos, annotations, PDF exports, and profile details on your device. The app uses camera and photo library access only when you choose to capture or attach inspection photos. SnagSnap does not sell your data or use third-party tracking."
                )

                legalSection(
                    title: "Data Export",
                    body: "You can export your report metadata from Settings. Photo and PDF files remain in app storage and can be shared from report workflows."
                )

                legalSection(
                    title: "Subscriptions",
                    body: "SnagSnap Pro subscriptions are processed by Apple through StoreKit. Subscriptions auto-renew until cancelled and can be managed from your App Store account settings."
                )

                legalSection(
                    title: "Terms of Use",
                    body: "SnagSnap is provided as a reporting tool. You are responsible for checking report content before sharing it with clients, tenants, contractors, or other parties."
                )

                legalSection(
                    title: "Support",
                    body: "Questions, privacy requests, and support issues can be sent to support@snagsnap.app."
                )
            }
            .padding(Theme.spacingL)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Terms & Privacy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }

    private func legalSection(title: String, body: String) -> some View {
        SSCard(padding: Theme.spacingL, cornerRadius: Theme.radiusLarge) {
            VStack(alignment: .leading, spacing: Theme.spacingS) {
                Text(title)
                    .font(Theme.fontHeadline)
                    .foregroundStyle(Theme.ink)
                Text(body)
                    .font(Theme.fontBody)
                    .foregroundStyle(Theme.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
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
                .foregroundStyle(Theme.secondaryLabel)

            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.primary)
                    .frame(width: 24, height: 24)

                TextField(placeholder, text: $text)
                    .font(Theme.body)
                    .foregroundStyle(Theme.ink)
                    .keyboardType(keyboardType)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.blueSurface)
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
                    .foregroundStyle(Theme.ink)

                Text(subtitle)
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryLabel)
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
                    .foregroundStyle(Theme.ink)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.tertiaryLabel)
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Section Header View

private struct SettingsSectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.primary)
                .frame(width: 34, height: 34)
                .background(Theme.blueSurface, in: Circle())

            Text(title)
                .font(Theme.headline)
                .foregroundStyle(Theme.ink)

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    let schema = Schema([UserProfile.self])
    let container = try! ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))

    NavigationStack {
        SettingsView(viewModel: SettingsViewModel(modelContext: container.mainContext))
    }
    .modelContainer(container)
}
