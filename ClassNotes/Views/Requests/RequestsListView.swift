import SwiftUI

// The requests list is embedded in GroupFeedView's requests tab.
// This file contains the CreateRequestView for creating new requests.

struct CreateRequestView: View {
    let group: ClassGroup
    @ObservedObject var requestService: RequestService
    @ObservedObject var groupService: GroupService
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSubjectInfo: SubjectInfo?
    @State private var showAddCustomSubject = false
    @State private var selectedDate = Date()
    @State private var selectedTargetUser: AppUser? // nil = ask everyone
    @State private var groupMembers: [AppUser] = []
    @State private var isLoadingMembers = false
    @State private var message = ""
    @State private var isLoading = false
    @State private var step = 0 // 0 = subject, 1 = date, 2 = ask whom, 3 = message

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { i in
                        Circle()
                            .fill(i <= step ? Color.teal : Color(.systemGray4))
                            .frame(width: 10, height: 10)
                    }
                }
                .padding(.top, 12)

                Group {
                    switch step {
                    case 0:
                        subjectSelection
                    case 1:
                        dateSelection
                    case 2:
                        memberSelection
                    default:
                        messageStep
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Buttons
                bottomButtons
            }
            .navigationTitle(stepTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var stepTitle: String {
        switch step {
        case 0: return "Which Subject?"
        case 1: return "Which Date?"
        case 2: return "Ask Whom?"
        default: return "Add Details"
        }
    }

    // MARK: - Subject Selection

    private var subjectSelection: some View {
        VStack(spacing: 24) {
            Spacer()

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(group.allSubjects) { subject in
                    Button {
                        selectedSubjectInfo = subject
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: subject.icon)
                                .font(.title2)
                            Text(subject.name)
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(selectedSubjectInfo == subject
                                    ? subject.color.opacity(0.15)
                                    : Color(.systemGray6))
                        .foregroundStyle(selectedSubjectInfo == subject ? subject.color : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(selectedSubjectInfo == subject ? subject.color : Color.clear, lineWidth: 2)
                        )
                    }
                }

                // Add Subject button
                Button {
                    showAddCustomSubject = true
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.title2)
                        Text("Add Subject")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(Color(.systemGray6))
                    .foregroundStyle(.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                            .foregroundStyle(Color(.systemGray3))
                    )
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .sheet(isPresented: $showAddCustomSubject) {
            AddCustomSubjectView(group: group, groupService: groupService) { newSubject in
                selectedSubjectInfo = newSubject
            }
        }
    }

    // MARK: - Date Selection

    private var dateSelection: some View {
        VStack(spacing: 24) {
            Spacer()

            HStack(spacing: 12) {
                quickDateButton("Today", date: Date())
                quickDateButton("Yesterday", date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
            }
            .padding(.horizontal, 24)

            DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(.teal)
                .padding(.horizontal, 16)

            Spacer()
        }
    }

    private func quickDateButton(_ label: String, date: Date) -> some View {
        Button {
            selectedDate = date
        } label: {
            Text(label)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Calendar.current.isDate(selectedDate, inSameDayAs: date)
                            ? Color.teal.opacity(0.15) : Color(.systemGray6))
                .foregroundStyle(Calendar.current.isDate(selectedDate, inSameDayAs: date) ? .teal : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Member Selection

    private var memberSelection: some View {
        VStack(spacing: 16) {
            Spacer()

            if isLoadingMembers {
                ProgressView()
                    .scaleEffect(1.2)
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        // "Everyone" option
                        memberRow(
                            name: "Everyone in the group",
                            icon: "person.3.fill",
                            isSelected: selectedTargetUser == nil
                        ) {
                            selectedTargetUser = nil
                        }

                        // Individual members (exclude current user)
                        ForEach(groupMembers.filter { $0.id != authService.currentUserId }) { member in
                            memberRow(
                                name: member.name.isEmpty ? "Parent" : member.name,
                                icon: "person.circle.fill",
                                isSelected: selectedTargetUser?.id == member.id
                            ) {
                                selectedTargetUser = member
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }

            Spacer()
        }
        .onAppear { loadMembers() }
    }

    private func memberRow(name: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? .teal : .secondary)
                    .frame(width: 32)

                Text(name)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.teal)
                }
            }
            .padding(14)
            .background(isSelected ? Color.teal.opacity(0.08) : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.teal : Color.clear, lineWidth: 1.5)
            )
        }
    }

    private func loadMembers() {
        guard groupMembers.isEmpty else { return }

        if AppMode.isDemo {
            // Use demo users
            groupMembers = DemoData.users
        } else {
            isLoadingMembers = true
            NotificationService.shared.fetchGroupMembers(memberIds: group.members) { users in
                groupMembers = users
                isLoadingMembers = false
            }
        }
    }

    // MARK: - Message Step

    private var messageStep: some View {
        VStack(spacing: 20) {
            Spacer()

            if let subject = selectedSubjectInfo {
                HStack(spacing: 8) {
                    Text(subject.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(subject.color.opacity(0.15))
                        .foregroundStyle(subject.color)
                        .clipShape(Capsule())

                    Text(selectedDate.displayString)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let target = selectedTargetUser {
                        Text("→ \(target.name)")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Add a message (optional)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("e.g. Need pages 45-50", text: $message)
                    .padding(14)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    // MARK: - Bottom Buttons

    private var bottomButtons: some View {
        HStack(spacing: 12) {
            if step > 0 {
                Button {
                    withAnimation { step -= 1 }
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.bordered)
                .tint(.teal)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            if step == 3 {
                Button {
                    submitRequest()
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    } else {
                        Label("Ask", systemImage: "hand.raised.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.teal)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .disabled(isLoading)
            } else {
                Button {
                    withAnimation { step += 1 }
                } label: {
                    Label("Next", systemImage: "chevron.right")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .tint(.teal)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .disabled(step == 0 && selectedSubjectInfo == nil)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

    // MARK: - Actions

    private func submitRequest() {
        guard selectedSubjectInfo != nil else { return }
        isLoading = true

        requestService.createRequest(
            groupId: group.id,
            authorId: authService.currentUserId,
            authorName: authService.currentUserName,
            subjectName: selectedSubjectInfo?.name ?? "",
            date: selectedDate,
            description: message,
            targetUserId: selectedTargetUser?.id,
            targetUserName: selectedTargetUser?.name
        ) { result in
            isLoading = false
            if case .success = result {
                dismiss()
            }
        }
    }
}
