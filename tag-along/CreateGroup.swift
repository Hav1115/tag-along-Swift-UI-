import SwiftUI



import SwiftUI

struct CreateGroup: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject var groupVM: GroupViewModel 
    @Environment(\.dismiss) private var dismiss

    // theme
    private let primaryGreen = Color(hex: "#07462F")
    private let tanBorder    = Color(hex: "#C4A78B")

    // minutes in [60, 1440] (1–24h), 15-min steps
    @State private var durationMin: Double = 60

    var body: some View {
        VStack(spacing: 24) {
            // Back button (navigation-style)
            HStack {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(size: 17, weight: .semibold))
                }
                .buttonStyle(.plain)
                .tint(primaryGreen)
                Spacer()
            }
            .padding(.top, 8)

            if let current = groupVM.currentGroup {
                activeGroupView(group: current)
            } else {
                createGroupView
            }
        }
        .padding(.horizontal, 20)
        .navigationBarBackButtonHidden(true)
        .alert("Error", isPresented: $groupVM.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(groupVM.errorMessage ?? "An unknown error occurred")
        }
        // keep VM in sync if you store minutes there
        .onChange(of: durationMin) { groupVM.selectedMinutes = Int($0) }
        .onAppear {
            durationMin = Double(max(60, min(1440, groupVM.selectedMinutes)))
        }
    }

    // MARK: - Create view (matches your mock)
    private var createGroupView: some View {
        VStack(spacing: 28) {
            Text("Create Group")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(primaryGreen)

            // Rounded input with tan border
            TextField("Enter Group Name", text: $groupVM.groupName)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .padding(.vertical, 18)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(tanBorder, lineWidth: 3)
                )

            Text("Enter Time")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(primaryGreen)

            // Slider with small diamond marker above the thumb
            VStack(spacing: 12) {
                SliderWithMarker(value: $durationMin,
                                 range: 60...1440,
                                 step: 15,
                                 trackColor: tanBorder,
                                 markerColor: tanBorder)

                // Readout like "6 hr 15 min"
                Text(formatDuration(minutes: Int(durationMin)))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(primaryGreen)
            }

            // Create button (capsule)
            Button {
                groupVM.selectedMinutes = Int(durationMin)
                groupVM.createGroup()
            } label: {
                Text("Create")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 56)
            }
            .background(isCreateDisabled ? Color.gray : primaryGreen)
            .clipShape(Capsule())
            .disabled(isCreateDisabled)
        }
    }

    private var isCreateDisabled: Bool {
        groupVM.groupName.trimmingCharacters(in: .whitespaces).isEmpty || groupVM.isLoading
    }

    // MARK: - Active group view (your original, lightly styled)
    private func activeGroupView(group: GroupDetails) -> some View {
        VStack(spacing: 20) {
            Text("Active Group")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(primaryGreen)

            VStack(alignment: .leading, spacing: 10) {
                Text("Name: \(group.name)").font(.headline)
                Text("Group Code: \(group.code)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("Members (\(group.members.count)):")
                    .font(.headline)

                ForEach(group.members, id: \.self) { member in
                    Text("• \(member)")
                        .foregroundColor(.secondary)
                }

                Text("Time Remaining: \(formatCountdown(group.timeRemaining))")
                    .font(.headline)
                    .foregroundColor(primaryGreen)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)

            Button {
                groupVM.cancelGroup()
            } label: {
                Text("End Group")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .background(Color.red)
            .cornerRadius(12)
        }
    }

    // MARK: - Helpers
    private func formatDuration(minutes: Int) -> String {
        let h = minutes / 60, m = minutes % 60
        return m == 0 ? "\(h) hr" + (h == 1 ? "" : "s") : "\(h) hr \(m) min"
    }

    private func formatCountdown(_ seconds: Int) -> String {
        let m = seconds / 60, s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

// Small diamond marker over a Slider (approximate positioning)
private struct SliderWithMarker: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let trackColor: Color
    let markerColor: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                Slider(value: $value, in: range, step: step)
                    .tint(trackColor)
                    .frame(height: 44)

                // diamond marker
                let fraction = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
                let padding: CGFloat = 16 // approximate slider side insets
                let usableWidth = geo.size.width - padding * 2
                let x = padding + usableWidth * fraction

                Rectangle()
                    .fill(markerColor)
                    .frame(width: 18, height: 18)
                    .rotationEffect(.degrees(45))
                    .offset(x: min(max(x - 9, padding - 9), geo.size.width - padding - 9), y: -20)
                    .allowsHitTesting(false)
            }
        }
        .frame(height: 44)
    }
}
