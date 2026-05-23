import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("selectedUseCase") private var selectedUseCase: String = ""

    @State private var currentStep = 0
    private let totalSteps = 3

    var body: some View {
        ZStack {
            Theme.groupedBackground.ignoresSafeArea()

            VStack(spacing: Theme.spacingXL) {
                Spacer()

                onboardingContent

                Spacer()

                onboardingButtons
            }
            .padding(Theme.spacingXL)
        }
    }

    @ViewBuilder
    private var onboardingContent: some View {
        switch currentStep {
        case 0:
            welcomeStep
        case 1:
            useCaseStep
        case 2:
            getStartedStep
        default:
            EmptyView()
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: Theme.spacingL) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 80))
                .foregroundStyle(Theme.primary)

            Text("Welcome to SnagSnap")
                .font(Theme.fontLargeTitle)
                .multilineTextAlignment(.center)

            Text("The professional inspection reporting app for builders, inspectors, and property managers.")
                .font(Theme.fontBody)
                .foregroundStyle(Theme.secondaryLabel)
                .multilineTextAlignment(.center)
        }
    }

    private var useCaseStep: some View {
        VStack(spacing: Theme.spacingL) {
            Text("What do you do?")
                .font(Theme.fontLargeTitle)

            Text("We'll customize the app for your workflow.")
                .font(Theme.fontBody)
                .foregroundStyle(Theme.secondaryLabel)
                .multilineTextAlignment(.center)

            VStack(spacing: Theme.spacingM) {
                ForEach(["Building Inspector", "Property Manager", "Contractor", "Home Owner"], id: \.self) { useCase in
                    Button {
                        selectedUseCase = useCase
                    } label: {
                        HStack {
                            Text(useCase)
                                .font(Theme.fontHeadline)
                            Spacer()
                            if selectedUseCase == useCase {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Theme.primary)
                            }
                        }
                        .padding(Theme.spacingM)
                        .background(
                            selectedUseCase == useCase
                                ? Theme.primaryLight
                                : Theme.secondaryGroupedBackground
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var getStartedStep: some View {
        VStack(spacing: Theme.spacingL) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundStyle(Theme.success)

            Text("You're All Set!")
                .font(Theme.fontLargeTitle)

            Text("Start creating professional inspection reports in minutes.")
                .font(Theme.fontBody)
                .foregroundStyle(Theme.secondaryLabel)
                .multilineTextAlignment(.center)
        }
    }

    private var onboardingButtons: some View {
        VStack(spacing: Theme.spacingM) {
            if currentStep < totalSteps - 1 {
                Button("Continue") {
                    withAnimation {
                        currentStep += 1
                    }
                }
                .buttonStyle(PrimaryButtonStyle())

                if currentStep > 0 {
                    Button("Back") {
                        withAnimation {
                            currentStep -= 1
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                } else {
                    Button("Skip") {
                        withAnimation {
                            currentStep = totalSteps - 1
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            } else {
                Button("Get Started") {
                    hasCompletedOnboarding = true
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
    }
}

#Preview {
    OnboardingView()
}
