import SwiftUI

struct SubjectPicker: View {
    @Binding var selectedSubject: Subject?

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            ForEach(Subject.allCases) { subject in
                Button {
                    selectedSubject = subject
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: subject.icon)
                            .font(.title2)
                        Text(subject.rawValue)
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(selectedSubject == subject
                                ? subject.color.opacity(0.15)
                                : Color(.systemGray6))
                    .foregroundStyle(selectedSubject == subject ? subject.color : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(selectedSubject == subject ? subject.color : Color.clear, lineWidth: 2)
                    )
                }
            }
        }
    }
}

#Preview {
    SubjectPicker(selectedSubject: .constant(.math))
        .padding()
}
