import SwiftUI

struct GroupsListView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var groupService: GroupService = AppMode.isDemo ? DemoGroupService() : GroupService()
    @State private var showCreateGroup = false
    @State private var showJoinGroup = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if groupService.groups.isEmpty {
                    emptyState
                } else {
                    groupsList
                }
            }
            .navigationTitle("Your Groups")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.body)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showCreateGroup = true
                        } label: {
                            Label("Create Group", systemImage: "plus.circle")
                        }

                        Button {
                            showJoinGroup = true
                        } label: {
                            Label("Join Group", systemImage: "person.badge.plus")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showCreateGroup) {
                CreateGroupView(groupService: groupService)
            }
            .sheet(isPresented: $showJoinGroup) {
                JoinGroupView(groupService: groupService)
            }
            .onAppear {
                groupService.loadGroups(for: authService.currentUserId)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.3")
                .font(.system(size: 64))
                .foregroundStyle(.teal.opacity(0.6))

            VStack(spacing: 8) {
                Text("No groups yet")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("Create or join your first class group\nto start sharing notes")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Button {
                    showCreateGroup = true
                } label: {
                    Label("Create a Group", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .tint(.teal)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Button {
                    showJoinGroup = true
                } label: {
                    Label("Join with Code", systemImage: "person.badge.plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.bordered)
                .tint(.teal)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Groups List

    private var groupsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(groupService.groups) { group in
                    NavigationLink(destination: GroupFeedView(group: group, groupService: groupService)) {
                        GroupCardView(group: group)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .refreshable {
            groupService.loadGroups(for: authService.currentUserId)
        }
    }
}

// MARK: - Group Card

struct GroupCardView: View {
    let group: ClassGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(group.school)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            Text(group.name)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            HStack(spacing: 16) {
                Label("\(group.members.count)", systemImage: "person.2")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    GroupsListView()
        .environmentObject(AuthService())
}
