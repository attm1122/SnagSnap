import SwiftUI

/// A staged loading overlay for multi-step operations like PDF generation.
///
/// Displays a ProgressView with animated stage labels that highlight
/// the current step while dimming completed and pending steps.
struct SSStagedLoadingView: View {

    let stages: [String]
    let currentStage: Int  // 0-based index
    let title: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Color.black.opacity(0.32)
                .ignoresSafeArea()

            VStack(spacing: Theme.spacingL) {
                // Title
                Text(title)
                    .font(Theme.title3)
                    .foregroundStyle(.primary)

                // Progress view
                ProgressView(value: Double(currentStage + 1), total: Double(stages.count))
                    .progressViewStyle(LinearProgressViewStyle(tint: Theme.primary))
                    .frame(maxWidth: 240)

                // Stage labels
                VStack(alignment: .leading, spacing: Theme.spacingS) {
                    ForEach(Array(stages.enumerated()), id: \.offset) { index, stage in
                        HStack(spacing: Theme.spacingS) {
                            // Status icon
                            Group {
                                if index < currentStage {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Theme.success)
                                } else if index == currentStage {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                        .tint(Theme.primary)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(.tertiary)
                                }
                            }

                            Text(stage)
                                .font(index == currentStage ? Theme.callout : Theme.footnote)
                                .foregroundStyle(
                                    index < currentStage ? Theme.success :
                                    index == currentStage ? .primary : .tertiary
                                )
                                .strikethrough(index < currentStage)
                        }
                        .opacity(reduceMotion ? 1.0 : (index <= currentStage ? 1.0 : 0.5))
                    }
                }
                .padding(.horizontal, Theme.spacingM)
            }
            .padding(Theme.spacingXL)
            .background(
                Theme.cardBackground
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusL, style: .continuous))
            )
            .shadow(color: Color.black.opacity(0.2), radius: 24, x: 0, y: 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): stage \(currentStage + 1) of \(stages.count), \(stages[currentStage])")
    }
}

extension View {
    func stagedLoadingOverlay(isPresented: Bool, stages: [String], currentStage: Int, title: String = "Processing...") -> some View {
        self.overlay {
            if isPresented {
                SSStagedLoadingView(stages: stages, currentStage: currentStage, title: title)
                    .transition(.opacity.animation(.easeInOut(duration: 0.25)))
            }
        }
    }
}

// MARK: - Preview

#Preview("Staged Loading - Stage 1") {
    SSStagedLoadingView(
        stages: ["Collecting photos", "Analyzing issues", "Building PDF", "Finalizing"],
        currentStage: 0,
        title: "Generating Report..."
    )
}

#Preview("Staged Loading - Stage 2") {
    SSStagedLoadingView(
        stages: ["Collecting photos", "Analyzing issues", "Building PDF", "Finalizing"],
        currentStage: 1,
        title: "Generating Report..."
    )
}

#Preview("Staged Loading - Stage 3") {
    SSStagedLoadingView(
        stages: ["Collecting photos", "Analyzing issues", "Building PDF", "Finalizing"],
        currentStage: 3,
        title: "Generating Report..."
    )
}
